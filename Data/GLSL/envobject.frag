#version 150
#include "object_frag150.glsl"
#include "object_shared150.glsl"
#include "ambient_tet_mesh.glsl"
#include "decals.glsl"

#extension GL_ARB_texture_cube_map_array: enable
#extension GL_ARB_separate_shader_objects: enable

#ifdef PARTICLE
    uniform sampler2D tex0; // Colormap
    uniform sampler2D tex1; // Normalmap
    uniform samplerCube tex2; // Diffuse cubemap
    uniform samplerCube tex3; // Diffuse cubemap
    uniform sampler2D tex5; // Screen depth texture TODO: make this work with msaa properly
    UNIFORM_SHADOW_TEXTURE
    UNIFORM_LIGHT_DIR
    uniform float size;
    uniform vec2 viewport_dims;
    uniform vec4 color_tint;
    uniform sampler3D tex16;
    uniform sampler2DArray tex19;

    uniform mat4 reflection_capture_matrix[10];
    uniform int reflection_capture_num;
#elif defined(DETAIL_OBJECT)
    #ifdef PLANT
    #pragma transparent
    #endif

    #define base_color_tex tex6
    #define base_normal_tex tex7

    UNIFORM_COMMON_TEXTURES
    #ifdef PLANT
    UNIFORM_TRANSLUCENCY_TEXTURE
    #endif
    uniform sampler2D base_color_tex;
    uniform sampler2D base_normal_tex;
    uniform float overbright;
    uniform float max_distance;

    UNIFORM_LIGHT_DIR
    uniform vec3 avg_color;
    uniform vec3 color_tint;

    uniform mat3 normal_matrix;
    uniform sampler3D tex16;

    #define tc0 frag_tex_coords
    #define tc1 base_tex_coord
#else
    UNIFORM_COMMON_TEXTURES
    #ifdef PLANT
        UNIFORM_TRANSLUCENCY_TEXTURE
    #endif
    UNIFORM_LIGHT_DIR
    #ifdef DETAILMAP4
        UNIFORM_DETAIL4_TEXTURES
        UNIFORM_AVG_COLOR4
    #endif
    #ifdef TERRAIN
        uniform sampler2D tex14;
        #define warp_tex tex14
    #endif
    #ifdef CHARACTER
        UNIFORM_BLOOD_TEXTURE
        UNIFORM_TINT_TEXTURE
        UNIFORM_FUR_TEXTURE
        UNIFORM_TINT_PALETTE
    #endif
    #ifdef ITEM
        UNIFORM_BLOOD_TEXTURE
        UNIFORM_COLOR_TINT
        uniform mat3 model_rotation_mat;
    #endif
    uniform sampler3D tex16;
    uniform sampler2D tex17;
    uniform sampler2D tex18;
    uniform sampler2DArray tex19;

    uniform mat4 reflection_capture_matrix[10];
    uniform int reflection_capture_num;

    //#define EMISSIVE

    #ifdef TERRAIN
    #elif defined(CHARACTER) || defined(ITEM)
    #else
        const int kMaxInstances = 100;

        uniform InstanceInfo {
            mat4 model_mat[kMaxInstances];
            mat3 model_rotation_mat[kMaxInstances];
            vec4 color_tint[kMaxInstances];
            vec4 detail_scale[kMaxInstances];
        };
    #endif
#endif // PARTICLE

uniform usamplerBuffer ambient_grid_data;
uniform usamplerBuffer ambient_color_buffer;
uniform int num_light_probes;
uniform int num_tetrahedra;

uniform vec3 grid_bounds_min;
uniform vec3 grid_bounds_max;
uniform int subdivisions_x;
uniform int subdivisions_y;
uniform int subdivisions_z;

uniform vec3 cam_pos;
uniform mat4 shadow_matrix[4];
uniform mat4 mvp;
uniform mat4 projection_view_mat;

uniform float time;

#ifdef PARTICLE
    in vec2 tex_coord;
    in vec3 world_vert;
    in vec3 tangent_to_world1;
    in vec3 tangent_to_world2;
    in vec3 tangent_to_world3;
#elif defined(DETAIL_OBJECT)
    in vec2 frag_tex_coords;
    in vec2 base_tex_coord;
    in mat3 tangent_to_world;
    in vec3 ws_vertex;
    in vec3 world_vert;
    in vec4 shadow_coords[4];
#elif defined(ITEM)
    #ifndef DEPTH_ONLY
    in vec3 ws_vertex;
    in vec3 world_vert;
    in vec3 vel;
    #endif
    in vec2 frag_tex_coords;
#elif defined(TERRAIN)
    in vec3 frag_tangent;
    in float alpha;
    in vec4 frag_tex_coords;
    in vec3 world_vert;
#elif defined(CHARACTER)
    in vec2 fur_tex_coord;
    #ifndef DEPTH_ONLY
    in vec3 concat_bone1;
    in vec3 concat_bone2;
    in vec2 tex_coord;
    in vec2 morphed_tex_coord;
    in vec3 world_vert;
    in vec3 vel;
    #endif
#else
    #ifdef TANGENT
    in mat3 tan_to_obj;
    #endif
    in vec2 frag_tex_coords;
    in vec3 world_vert;
    #ifndef NO_INSTANCE_ID
    flat in int instance_id;
    #endif
#endif
layout (location = 0) out vec4 out_color;
layout (location = 1) out vec4 out_vel;

#define shadow_tex_coords tc1
#define tc0 frag_tex_coords

//#ifdef PARTICLE
float LinearizeDepth(float z) {
  float n = 0.1; // camera z near
  float f = 100000.0; // camera z far
  float depth = (2.0 * n) / (f + n - z * (f - n));
  return (f-n)*depth + n;
}
//#endif

void CalculateLightContribParticle(inout vec3 diffuse_color, vec3 world_vert) {
    uint num_lights_ = uint(num_lights);

    uint num_z_clusters = grid_size.z;

    vec4 ndcPos;
    ndcPos.xy = ((2.0 * gl_FragCoord.xy) - (2.0 * viewport.xy)) / (viewport.zw) - 1;
    ndcPos.z = 2.0 * gl_FragCoord.z - 1; // this assumes gl_DepthRange is not changed
    ndcPos.w = 1.0;

    vec4 clipPos = ndcPos / gl_FragCoord.w;
    vec4 eyePos = inv_proj_mat * clipPos;

    float zVal = ZCLUSTERFUNC(eyePos.z);

    zVal = max(0u, min(zVal, num_z_clusters - 1u));

    uvec3 g = uvec3(gl_FragCoord.xy / 32.0, zVal);

    // index of cluster we're in
    uint light_cluster_index = NUM_GRID_COMPONENTS * ((g.y * grid_size.x + g.x) * num_z_clusters + g.z) + 1u;
    uint val = texelFetch(cluster_buffer, int(light_cluster_index)).x;

    // number of lights in current cluster
    uint light_count = (val >> 16) & 0xFFFFU;

    // index into cluster_lights
    uint first_light_index = val & 0xFFFFU;

    // light list data is immediately after cluster lookup data
    uint num_clusters = grid_size.x * grid_size.y * grid_size.z;
    first_light_index = first_light_index + uint(light_cluster_data_offset);

    // debug option, uncomment to visualize clusters
    //out_color = vec3(min(light_count, 63u) / 63.0);
    //out_color = vec3(g.z / num_z_clusters);

    for (uint i = 0u; i < light_count; i++) {
        uint light_index = texelFetch(cluster_buffer, int(first_light_index + i)).x;

        PointLightData l = FetchPointLight(light_index);

        vec3 to_light = l.pos - world_vert;
        // TODO: inverse square falloff
        // TODO: real light equation
        float dist = length(to_light);
        float falloff = max(0.0, (1.0 / dist / dist) * (1.0 - dist / l.radius));

        diffuse_color += falloff * l.color * 0.5;
    }
}

#if !defined(PLANT) && !defined(DETAIL_OBJECT)
vec3 LookupSphereReflectionPos(vec3 world_vert, vec3 spec_map_vec, int which) {
    //vec3 sphere_pos = world_vert - reflection_capture_pos[which];
    //sphere_pos /= reflection_capture_scale[which];
    vec3 sphere_pos = (inverse(reflection_capture_matrix[which]) * vec4(world_vert, 1.0)).xyz;
    if(length(sphere_pos) > 1.0){
        return spec_map_vec;
    }
    // Ray trace reflection in sphere
    float test = (2 * dot(sphere_pos, spec_map_vec)) * (2 * dot(sphere_pos, spec_map_vec)) - 4 * (dot(sphere_pos, sphere_pos)-1.0) * dot(spec_map_vec, spec_map_vec);
    test = 0.5 * pow(test, 0.5);
    test = test - dot(spec_map_vec, sphere_pos);
    test = test / dot(spec_map_vec, spec_map_vec);
    return sphere_pos + spec_map_vec * test;
    /*
    // Brute force approach
    float t = 0.0;
    for(int i=0; i<100; ++i){
        t += 0.02;
        vec3 test_point = (sphere_pos + spec_map_vec * t);
        if(dot(test_point, test_point) >= 1.0){
            return sphere_pos + spec_map_vec * t;
        }
    }
    return spec_map_vec;*/
}
#endif


float GetWaterHeight(vec2 pos){
    float scale = 0.0005;
    float height = 0.0;
    float water_speed = 0.03;
    height += texture(tex0, pos + normalize(vec2(0.0, 1.0))*time*water_speed).x * scale;
    height += texture(tex0, pos * 0.3 + normalize(vec2(1.0, 0.0))*time*water_speed * pow(0.3, 0.5)).x * scale / 0.3;
    height += texture(tex0, pos * 0.1 + normalize(vec2(-1.0, 0.0))*time*water_speed * pow(0.1, 0.5)).x * scale / 0.1;
    height += texture(tex0, pos * 0.05 + normalize(vec2(-1.0, 1.0))*time*water_speed * pow(0.05, 0.5)).x * scale / 0.05;
    /*
    height += sin(pos.x * 11.0 + time * water_speed) * scale;
    height += sin(pos.y * 3.0 + time * water_speed) * scale * 2.0;
    height += sin(dot(pos, normalize(vec2(1,1))) * 7.0 + time * water_speed) * scale;
    height += sin(dot(pos, normalize(vec2(1,-1))) * 13.0 + time * water_speed) * scale * 0.9;
    height += sin(dot(pos, normalize(vec2(-1,-1))) * 29.0 + time * water_speed) * scale * 0.5;
    height += sin(dot(pos, normalize(vec2(-1,-0.1))) * 43.0 + time * water_speed) * scale * 0.4;
    height += sin(dot(pos, normalize(vec2(1,-0.1))) * 51.0 + time * water_speed) * scale * 0.4;*/
    return height;
}

void ClampCoord(inout vec2 coord, float lod){
    float threshold = 1.0 / (256.0 / pow(2.0, lod+1.0));
    coord[0] = min(coord[0], 1.0 - threshold);
    coord[0] = max(coord[0], threshold);
    coord[1] = min(coord[1], 1.0 - threshold);
    coord[1] = max(coord[1], threshold);
}

vec2 LookupFauxCubemap(vec3 vec, float lod) {
    vec2 coord;
    if(vec.x > abs(vec.y) && vec.x > abs(vec.z)){
        vec3 hit_point = vec3(1.0, vec.y / vec.x, vec.z / vec.x);
        coord = vec2(hit_point.z, hit_point.y) * -0.5 + vec2(0.5);
        ClampCoord(coord, lod);
    }
    if(vec.z > abs(vec.y) && vec.z > abs(vec.x)){
        vec3 hit_point = vec3(1.0, vec.y / vec.z, vec.x / vec.z);
        coord = vec2(hit_point.z*-1.0, hit_point.y) * -0.5 + vec2(0.5);
        ClampCoord(coord, lod);
        coord += vec2(4.0, 0.0);
    }
    if(vec.x < -abs(vec.y) && vec.x < -abs(vec.z)){
        vec3 hit_point = vec3(1.0, vec.y / vec.x, vec.z / vec.x);
        coord = vec2(hit_point.z*-1.0, hit_point.y) * 0.5 + vec2(0.5);
        ClampCoord(coord, lod);
        coord += vec2(1.0, 0.0);
    }
    if(vec.z < -abs(vec.y) && vec.z < -abs(vec.x)){
        vec3 hit_point = vec3(1.0, vec.y / vec.z, vec.x / vec.z);
        coord = vec2(hit_point.z, hit_point.y) * 0.5 + vec2(0.5);
        ClampCoord(coord, lod);
        coord += vec2(5.0, 0.0);
    }
    if(vec.y < -abs(vec.z) && vec.y < -abs(vec.x)){
        vec3 hit_point = vec3(1.0, vec.z / vec.y, vec.x / vec.y);
        coord = vec2(-hit_point.z, hit_point.y) * 0.5 + vec2(0.5);
        ClampCoord(coord, lod);
        coord += vec2(3.0, 0.0);
    }
    if(vec.y > abs(vec.z) && vec.y > abs(vec.x)){
        vec3 hit_point = vec3(1.0, vec.z / vec.y, vec.x / vec.y);
        coord = vec2(hit_point.z, hit_point.y) * 0.5 + vec2(0.5);
        ClampCoord(coord, lod);
        coord += vec2(2.0, 0.0);
    }
    coord.x /= 6.0;
    return coord;
}

vec3 GetAmbientColor(vec3 world_vert, vec3 ws_normal) {    
    uint guess = 0u;
    int grid_coord[3];
    bool in_grid = true;
    for(int i=0; i<3; ++i){            
        if(world_vert[i] > grid_bounds_max[i] || world_vert[i] < grid_bounds_min[i]){
            in_grid = false;
            break;
        }
    }
    bool use_amb_cube = false;
    bool use_3d_tex = false;
    vec3 ambient_cube_color[6];
    if(in_grid){
        grid_coord[0] = int((world_vert[0] - grid_bounds_min[0]) / (grid_bounds_max[0] - grid_bounds_min[0]) * float(subdivisions_x));
        grid_coord[1] = int((world_vert[1] - grid_bounds_min[1]) / (grid_bounds_max[1] - grid_bounds_min[1]) * float(subdivisions_y));
        grid_coord[2] = int((world_vert[2] - grid_bounds_min[2]) / (grid_bounds_max[2] - grid_bounds_min[2]) * float(subdivisions_z));
        int cell_id = ((grid_coord[0] * subdivisions_y) + grid_coord[1])*subdivisions_z + grid_coord[2];
        uvec4 data = texelFetch(ambient_grid_data, cell_id/4);
        guess = data[cell_id%4];
        use_amb_cube = GetAmbientCube(world_vert, num_tetrahedra, ambient_color_buffer, ambient_cube_color, guess);
    } else {
        for(int i=0; i<6; ++i){
            ambient_cube_color[i] = vec3(0.0);
        }
    }
    vec3 ambient_color;
    vec3 tex_3d = vec3(world_vert.x, world_vert.y, world_vert.z);
    tex_3d *= 0.001;
    tex_3d += vec3(0.5);
    if(false && tex_3d[0] > 0.0 && tex_3d[1] > 0.0 && tex_3d[2] > 0.0 && tex_3d[0] < 1.0 && tex_3d[1] < 1.0 && tex_3d[2] < 1.0){
        for(int i=0; i<6; ++i){
            ambient_cube_color[i] = texture(tex16, vec3((tex_3d[0] + i)/ 6.0, tex_3d[1], tex_3d[2])).xyz * 4.0;            
        }
        ambient_color = SampleAmbientCube(ambient_cube_color, ws_normal);
        use_3d_tex = true;
    } else if(!use_amb_cube){
        ambient_color = LookupCubemapSimpleLod(ws_normal, spec_cubemap, 5.0);
    } else {
        ambient_color = SampleAmbientCube(ambient_cube_color, ws_normal);
    }
    return ambient_color;
}

#if !defined(PLANT) && !defined(DETAIL_OBJECT)
vec3 LookUpReflectionShapes(sampler2DArray reflections_tex, vec3 world_vert, vec3 reflect_dir, float lod) {
    vec3 reflection_color;
    float total = 0.0;
    {
        /*float weight = 0.00000001;
        vec2 coord = LookupFauxCubemap(reflect_dir, lod);    
        reflection_color.xyz += textureLod(reflections_tex, vec3(coord, 0), lod).xyz * weight;
        total += weight;     */       
    }
    for(int i=0; i<reflection_capture_num; ++i){
        //vec3 temp = (world_vert - reflection_capture_pos[i]) / reflection_capture_scale[i];
        vec3 temp = (inverse(reflection_capture_matrix[i]) * vec4(world_vert, 1.0)).xyz;
        vec3 scale_vec = (reflection_capture_matrix[i] * vec4(1.0, 1.0, 1.0, 0.0)).xyz;
        float scale = dot(scale_vec, scale_vec);
        float val = dot(temp, temp);
        if(val < 1.0){
            vec3 lookup = LookupSphereReflectionPos(world_vert, reflect_dir, i);
            vec2 coord = LookupFauxCubemap(lookup, lod);    
            float weight = pow((1.0 - val), 8.0);
            weight /= pow(scale, 2.0);
            reflection_color.xyz += textureLod(reflections_tex, vec3(coord, i+1), lod).xyz * weight;
            total += weight;
        }
    }
    if(total > 0.0){
        reflection_color.xyz /= total;
    }
    return reflection_color;
}
#endif

void main() {   
    #ifdef DETAIL_OBJECT
        CALC_COLOR_MAP    
        #ifdef PLANT
            colormap.a = pow(colormap.a, max(0.1,min(1.0,3.0/length(ws_vertex))));
        #ifndef TERRAIN
                colormap.a -= max(0.0f, -1.0f + (length(ws_vertex)/max_distance * (1.0+rand(gl_FragCoord.xy)*0.5f))*2.0f);
        #endif
        #ifndef ALPHA_TO_COVERAGE
            if(colormap.a < 0.5){
                discard;
            }
        #endif
        #endif
            float dist_fade = 1.0 - length(ws_vertex)/max_distance;

            vec4 normalmap = texture(normal_tex,tc0);
            vec3 normal = UnpackTanNormal(normalmap);
            vec3 ws_normal = tangent_to_world * normal;

            vec3 base_normalmap = texture(base_normal_tex,tc1).xyz;
        #ifdef TERRAIN
                vec3 base_normal = normalize((base_normalmap*vec3(2.0))-vec3(1.0));
        #else
                //I'm assuming this normal is supposed to be in world space --Max
                vec3 base_normal = normalize(normal_matrix * UnpackObjNormalV3(base_normalmap.xyz));
        #endif
            ws_normal = mix(ws_normal,base_normal,min(1.0,1.0-(dist_fade-0.5)));
             
        #define shadow_tex_coords tc1
            CALC_SHADOWED
            
            vec3 ambient_cube_color[6];
            bool use_amb_cube = GetAmbientCube(world_vert, num_tetrahedra, ambient_color_buffer, ambient_cube_color, 0u);
            CALC_DIRECT_DIFFUSE_COLOR
            if(!use_amb_cube){
                diffuse_color += LookupCubemapSimpleLod(ws_normal, spec_cubemap, 5.0);
            } else {
                diffuse_color += SampleAmbientCube(ambient_cube_color, ws_normal);
            }

            // Put it all together
            vec3 base_color = texture(base_color_tex,tc1).rgb * color_tint;
            float overbright_adjusted = dist_fade * overbright;
            colormap.xyz = base_color * mix(vec3(1.0), colormap.xyz / avg_color, dist_fade);
            colormap.xyz *= 1.0 + overbright_adjusted;
            vec3 color = diffuse_color * colormap.xyz;

            CALC_HAZE
        #ifdef PLANT
            CALC_FINAL_ALPHA
        #else
            CALC_FINAL
        #endif
        return;
    #elif defined(PARTICLE)
        vec4 colormap = texture(tex0, tex_coord);
        float random = rand(gl_FragCoord.xy);
        #ifdef DEPTH_ONLY
            if(colormap.a *color_tint.a < random){
                discard;
            }
            return;
        #endif
        vec3 ws_vertex;
        vec4 shadow_coords[4];

        int num_samples = 2;
        vec3 far = world_vert + normalize(world_vert-cam_pos) * size * 0.5;
        vec3 near = world_vert - normalize(world_vert-cam_pos) * size * 0.5;
        float shadowed = 0.0;
        for(int i=0; i<num_samples; ++i){
            vec3 sample_vert = mix(far, near, (i+random)/float(num_samples));
            ws_vertex = sample_vert - cam_pos;
            shadow_coords[0] = shadow_matrix[0] * vec4(sample_vert, 1.0);
            shadow_coords[1] = shadow_matrix[1] * vec4(sample_vert, 1.0);
            shadow_coords[2] = shadow_matrix[2] * vec4(sample_vert, 1.0);
            shadow_coords[3] = shadow_matrix[3] * vec4(sample_vert, 1.0);
            float len = length(ws_vertex);
            shadowed += GetCascadeShadow(shadow_sampler, shadow_coords, len);
        }
        shadowed /= float(num_samples);
        shadowed = 1.0 - shadowed;

        float env_depth = LinearizeDepth(texture(tex5,gl_FragCoord.xy / viewport_dims).r);
        float particle_depth = LinearizeDepth(gl_FragCoord.z);
        float depth = env_depth - particle_depth;
        float depth_blend = depth / size * 0.5;
        depth_blend = max(0.0,min(1.0,depth_blend));
        depth_blend *= max(0.0,min(1.0, particle_depth*0.5-0.1));
        
        #ifdef NORMAL_MAP_TRANSLUCENT
            vec4 normalmap = texture(tex1, tex_coord);
            vec3 ws_normal = vec3(tangent_to_world3 * normalmap.b +
                                  tangent_to_world1 * (normalmap.r*2.0-1.0) +
                                  tangent_to_world2 * (normalmap.g*2.0-1.0));            
            float NdotL = GetDirectContrib(ws_light, ws_normal, 1.0);
            float thin = min(1.0,pow(colormap.a*color_tint.a*depth_blend,2.0)*2.0);
            NdotL = max(NdotL, max(0.0,(1.0-thin*0.5)));
            NdotL *= (1.0-shadowed);
            vec3 diffuse_color = GetDirectColor(NdotL);
            vec3 ambient_color = GetAmbientColor(world_vert, ws_normal);//LookupCubemapSimpleLod(ws_normal, tex3, 5.0);
        #elif defined(SPLAT)
            vec4 normalmap = texture(tex1, tex_coord);
            vec3 ws_normal = vec3(tangent_to_world3 * normalmap.b +
                                  tangent_to_world1 * (normalmap.r*2.0-1.0) +
                                  tangent_to_world2 * (normalmap.g*2.0-1.0));     

            float NdotL;
            NdotL = dot(ws_light, ws_normal)*0.5+0.5;
            NdotL = mix(NdotL, 1.0, (1.0 - pow(colormap.a,2.0))*0.5);
            NdotL *= (1.0-shadowed);

            vec3 diffuse_color = GetDirectColor(NdotL);
            vec3 ambient_color = GetAmbientColor(world_vert, ws_normal);//LookupCubemapSimpleLod(ws_normal, tex3, 5.0);
            //out_color.xyz = ws_normal;
            //out_color.a = colormap.a*color_tint.a*depth_blend;
            //return;
        #else
            float NdotL = GetDirectContribSimple((1.0-shadowed)*0.5);
            vec3 diffuse_color = GetDirectColor(NdotL);
            //vec3 ambient_color = LookupCubemapSimpleLod(cam_pos - world_vert, tex3, 5.0);
            vec3 ambient_color = GetAmbientColor(world_vert, cam_pos - world_vert);
        #endif

        diffuse_color += ambient_color * GetAmbientContrib(1.0);
        CalculateLightContribParticle(diffuse_color, world_vert);

        vec3 color = diffuse_color * colormap.xyz *color_tint.xyz;
        
        #ifdef SPLAT
            ws_vertex = world_vert - cam_pos;
            vec3 blood_spec = vec3(GetSpecContrib(ws_light, normalize(ws_normal), ws_vertex, 1.0, 200.0)) * (1.0-shadowed);
            blood_spec *= 10.0;
            vec3 spec_map_vec = reflect(ws_vertex,ws_normal); 
            vec3 reflection_color = LookUpReflectionShapes(tex19, world_vert, normalize(spec_map_vec), 0.0);
            float glancing = max(0.0, min(1.0, 1.0 + dot(normalize(ws_vertex), ws_normal)));
            float fresnel = pow(glancing, 6.0);
            fresnel = mix(fresnel, 1.0, 0.05);
            color = mix(color, (blood_spec + reflection_color), fresnel);
        #endif

        float alpha = colormap.a*color_tint.a*depth_blend;
        #ifdef SPLAT
            if(alpha < 0.3){
                discard;
            }
            alpha = min(1.0, (alpha - 0.3) * 6.0);
        #endif
        out_color = vec4(color, alpha);
        //out_color.xyz = vec3(pow(colormap.a,2.0));
        //out_color = vec4(1.0);
    #else
    #ifdef CHARACTER
        float alpha = texture(fur_tex, fur_tex_coord).a;
    #else
        #ifdef TERRAIN
            vec2 test_offset = (texture(warp_tex,frag_tex_coords.xy*200.0).xy-0.5)*0.001;
            vec2 base_tex_coords = frag_tex_coords.xy + test_offset;
            vec2 detail_coords = frag_tex_coords.zw;
        #else
            vec2 base_tex_coords = frag_tex_coords;
        #endif
        vec4 colormap = texture(tex0, base_tex_coords);
    #endif

	vec3 ws_vertex;
	vec4 shadow_coords[4];

	#ifndef DEPTH_ONLY
        ws_vertex = world_vert - cam_pos;
        shadow_coords[0] = shadow_matrix[0] * vec4(world_vert, 1.0);
        shadow_coords[1] = shadow_matrix[1] * vec4(world_vert, 1.0);
        shadow_coords[2] = shadow_matrix[2] * vec4(world_vert, 1.0);
        shadow_coords[3] = shadow_matrix[3] * vec4(world_vert, 1.0);
    #endif

    #ifdef CHARACTER
        //#ifndef ALPHA_TO_COVERAGE
            if(alpha < 0.6){
                discard;
            }
        //#endif
    #else
    #if defined(ALPHA) && !defined(ALPHA_TO_COVERAGE)
        if(colormap.a < 0.5){
            discard;
        }
    #endif
    #endif

    #ifdef DEPTH_ONLY
        #if defined(CHARACTER)
            out_color = vec4(0.0, 0.0, 0.0, alpha);
        #elif defined(ALPHA)
            out_color = vec4(vec3(1.0), colormap.a);
        #else
            out_color = vec4(vec3(1.0), 1.0);
        #endif
        return;
    #else

    #ifdef NO_INSTANCE_ID
        int instance_id = 0;
    #endif
    #ifdef DETAILMAP4
        vec4 weight_map = GetWeightMap(weight_tex, base_tex_coords);
        float total = weight_map[0] + weight_map[1] + weight_map[2] + weight_map[3];
        weight_map /= total;
        CALC_DETAIL_FADE
        // Get normal
        float color_tint_alpha;
        mat3 ws_from_ns;
        {
            #ifdef TERRAIN
                vec3 base_normalmap = texture(tex1,base_tex_coords).xyz;
                vec3 base_normal = normalize((base_normalmap*vec3(2.0))-vec3(1.0));
                vec3 base_bitangent = normalize(cross(frag_tangent,base_normal));
                vec3 base_tangent = normalize(cross(base_normal,base_bitangent));
            #else
                vec4 base_normalmap = texture(tex1,base_tex_coords);
                color_tint_alpha = base_normalmap.a;
                #ifdef BASE_TANGENT
                    vec3 base_normal = normalize(tan_to_obj * UnpackTanNormal(base_normalmap));
                #else
                    vec3 base_normal = UnpackObjNormalV3(base_normalmap.xyz);
                #endif
                vec3 base_bitangent = normalize(cross(base_normal,tan_to_obj[0]));
                vec3 base_tangent = normalize(cross(base_bitangent,base_normal));
                base_bitangent *= 1.0 - step(dot(base_bitangent, tan_to_obj[1]),0.0) * 2.0;
            #endif

            ws_from_ns = mat3(base_tangent,
                              base_bitangent,
                              base_normal);
        }

        vec3 ws_normal;
        {
            #ifdef TERRAIN
                vec4 normalmap;
                if(detail_fade < 1.0){
                    for(int i=0; i<4; ++i){
                        if(weight_map[i] > 0.0){
                            normalmap += texture(detail_normal, vec3(detail_coords, i)) * weight_map[i] ;
                        }
                    }
                }
            #else
                vec4 normalmap;
                if(detail_fade < 1.0){
                    // TODO: would it be possible to reduce this to two samples by using the tex coord z to interpolate?
                    for(int i=0; i<4; ++i){
                        if(weight_map[i] > 0.0){
                            normalmap += texture(detail_normal, vec3(base_tex_coords*detail_scale[instance_id][i], detail_normal_indices[i])) * weight_map[i];
                        }
                    }
                }
            #endif
            normalmap.xyz = UnpackTanNormal(normalmap);
            normalmap.xyz = mix(normalmap.xyz,vec3(0.0,0.0,1.0),detail_fade);

            #ifdef TERRAIN
                ws_normal = ws_from_ns * normalmap.xyz;
            #else
                ws_normal = normalize((model_mat[instance_id] * vec4((ws_from_ns * normalmap.xyz),0.0)).xyz);
            #endif
        }

        // Get color
        vec3 base_color = texture(color_tex,base_tex_coords).xyz;
        vec3 tint;
        {
            vec3 average_color = avg_color0 * weight_map[0] +
                                 avg_color1 * weight_map[1] +
                                 avg_color2 * weight_map[2] +
                                 avg_color3 * weight_map[3];
            average_color = max(average_color, vec3(0.01));
            tint = base_color / average_color;
        }

        #ifdef TERRAIN
            colormap = vec4(0.0);
            if(detail_fade < 1.0){
                for(int i=0; i<4; ++i){
                    if(weight_map[i] > 0.0){
                        colormap += texture(detail_color, vec3(detail_coords, detail_color_indices[i])) * weight_map[i] ;
                    }
                }
            }
        #else
            colormap = vec4(0.0);
            if(detail_fade < 1.0){
                for(int i=0; i<4; ++i){
                    if(weight_map[i] > 0.0){
                        colormap += texture(detail_color, vec3(base_tex_coords*detail_scale[instance_id][i], detail_color_indices[i])) * weight_map[i];
                    }
                }
            }
        #endif
        colormap.xyz = mix(colormap.xyz * tint, base_color, detail_fade);
        #ifndef TERRAIN
            colormap.xyz = mix(colormap.xyz,colormap.xyz*color_tint[instance_id].xyz,color_tint_alpha);
        #endif
        colormap.a = max(0.0,colormap.a); 
    #elif defined(ITEM)
        float blood_amount, wetblood;
        ReadBloodTex(blood_tex, tc0, blood_amount, wetblood);
        vec4 normalmap = texture(tex1,tc0); 
        vec3 os_normal = UnpackObjNormal(normalmap); 
        vec3 ws_normal = model_rotation_mat * os_normal; 
        ws_normal = normalize(ws_normal);
        colormap.xyz *= mix(vec3(1.0),color_tint,normalmap.a);
        CALC_BLOOD_ON_COLOR_MAP
    #elif defined(CHARACTER)
        // Reconstruct third bone axis
        vec3 concat_bone3 = cross(concat_bone1, concat_bone2);

        // Get world space normal
        vec4 normalmap = texture(normal_tex, tex_coord);
        vec3 unrigged_normal = UnpackObjNormal(normalmap);
        vec3 ws_normal = normalize(concat_bone1 * unrigged_normal.x +
                                   concat_bone2 * unrigged_normal.y +
                                   concat_bone3 * unrigged_normal.z);
        float blood_amount, wetblood;
        ReadBloodTex(blood_tex, tex_coord, blood_amount, wetblood);

        vec4 colormap = texture(color_tex, morphed_tex_coord);
        vec4 tintmap = texture(tint_map, morphed_tex_coord);
        vec3 tint_mult = mix(vec3(0.0), tint_palette[0], tintmap.r) +
                         mix(vec3(0.0), tint_palette[1], tintmap.g) +
                         mix(vec3(0.0), tint_palette[2], tintmap.b) +
                         mix(vec3(0.0), tint_palette[3], tintmap.a) +
                         mix(vec3(0.0), tint_palette[4], 1.0-(tintmap.r+tintmap.g+tintmap.b+tintmap.a));
        colormap.xyz *= tint_mult;
        CALC_BLOOD_ON_COLOR_MAP
    #else
        #ifdef WATER
            vec3 base_ws_normal;
            vec3 base_water_offset;
        #endif
        #ifdef TANGENT
            vec3 ws_normal;
            vec4 normalmap = texture(normal_tex,tc0);
            {
                vec3 unpacked_normal = UnpackTanNormal(normalmap);
                #ifdef WATER
                    float sample_height[3];
                    float eps = 0.01;
                    vec2 water_uv = world_vert.xz * 0.2;
                    //water_uv.y -= time;
                    sample_height[0] = GetWaterHeight(water_uv);
                    sample_height[1] = GetWaterHeight(water_uv + vec2(eps, 0.0));
                    sample_height[2] = GetWaterHeight(water_uv + vec2(0.0, eps));
                    unpacked_normal.x = sample_height[1] - sample_height[0];
                    unpacked_normal.y = sample_height[2] - sample_height[0];
                    unpacked_normal.z = eps;
                    base_water_offset = normalize(unpacked_normal);
                    base_ws_normal = normalize((model_mat[instance_id] * vec4((tan_to_obj * vec3(0,0,1)),0.0)).xyz);
                #endif
                ws_normal = normalize((model_mat[instance_id] * vec4((tan_to_obj * unpacked_normal),0.0)).xyz);
            }
        #else 
            vec4 normalmap = texture(tex1,tc0);
            vec3 os_normal = UnpackObjNormal(normalmap);
            vec3 ws_normal = model_rotation_mat[instance_id] * os_normal;
        #endif
    #endif
#ifndef PLANT
#ifdef ALPHA
    float spec_amount = normalmap.a;
#else
    float spec_amount = GammaCorrectFloat(colormap.a);
#endif

// wet character
/*#ifdef CHARACTER
    spec_amount = mix(spec_amount, 1.0, 0.4);
    colormap.xyz *= 0.4;
#endif*/

#endif
    
    #ifdef CHARACTER
        float roughness = pow(1.0 - spec_amount, 20.0);
    #elif defined(ITEM)
        float roughness = mix(normalmap.a, 0.5, blood_amount);
    #else
        float roughness = mix(0.7, 1.0, pow((colormap.x + colormap.y + colormap.z) / 3.0, 0.01));
    #endif


    float ambient_mult = 1.0;
#if !defined(PLANT)
    CalculateDecals(colormap, ws_normal, spec_amount, roughness, ambient_mult, world_vert);
#endif

    CALC_SHADOWED
    CALC_DIRECT_DIFFUSE_COLOR
    uint guess = 0u;
    int grid_coord[3];
    bool in_grid = true;
    for(int i=0; i<3; ++i){            
        if(world_vert[i] > grid_bounds_max[i] || world_vert[i] < grid_bounds_min[i]){
            in_grid = false;
            break;
        }
    }
    
    bool use_amb_cube = false;
    bool use_3d_tex = false;
    vec3 ambient_cube_color[6];
    if(in_grid){
        grid_coord[0] = int((world_vert[0] - grid_bounds_min[0]) / (grid_bounds_max[0] - grid_bounds_min[0]) * float(subdivisions_x));
        grid_coord[1] = int((world_vert[1] - grid_bounds_min[1]) / (grid_bounds_max[1] - grid_bounds_min[1]) * float(subdivisions_y));
        grid_coord[2] = int((world_vert[2] - grid_bounds_min[2]) / (grid_bounds_max[2] - grid_bounds_min[2]) * float(subdivisions_z));
        int cell_id = ((grid_coord[0] * subdivisions_y) + grid_coord[1])*subdivisions_z + grid_coord[2];
        uvec4 data = texelFetch(ambient_grid_data, cell_id/4);
        guess = data[cell_id%4];
        use_amb_cube = GetAmbientCube(world_vert, num_tetrahedra, ambient_color_buffer, ambient_cube_color, guess);
    } else {
        for(int i=0; i<6; ++i){
            ambient_cube_color[i] = vec3(0.0);
        }
    }
    vec3 ambient_color;
    vec3 tex_3d = vec3(world_vert.x, world_vert.y, world_vert.z);
    tex_3d *= 0.001;
    tex_3d += vec3(0.5);
    if(false && tex_3d[0] > 0.0 && tex_3d[1] > 0.0 && tex_3d[2] > 0.0 && tex_3d[0] < 1.0 && tex_3d[1] < 1.0 && tex_3d[2] < 1.0){
        for(int i=0; i<6; ++i){
            ambient_cube_color[i] = texture(tex16, vec3((tex_3d[0] + i)/ 6.0, tex_3d[1], tex_3d[2])).xyz * 4.0;            
        }
        ambient_color = SampleAmbientCube(ambient_cube_color, ws_normal);
        use_3d_tex = true;
    } else if(!use_amb_cube){
        ambient_color = LookupCubemapSimpleLod(ws_normal, spec_cubemap, 5.0);
    } else {
        ambient_color = SampleAmbientCube(ambient_cube_color, ws_normal);
    }
    diffuse_color += ambient_color * GetAmbientContrib(shadow_tex.g) * ambient_mult;
    #ifdef PLANT
        vec3 translucent_lighting = GetDirectColor(shadow_tex.r) * primary_light_color.a; 
        translucent_lighting += ambient_color; 
        translucent_lighting *= GammaCorrectFloat(0.6);
        vec3 color = diffuse_color * colormap.xyz  * mix(vec3(1.0),color_tint[instance_id].xyz,normalmap.a);
        vec3 translucent_map = texture(translucency_tex, frag_tex_coords).xyz;
        color += translucent_lighting * translucent_map;
    #else
        vec3 spec_color = vec3(0.0);
        #ifdef CHARACTER
            float spec_pow = mix(1200.0, 20.0, pow(roughness,2.0));
            float spec = GetSpecContrib(ws_light, ws_normal, ws_vertex, shadow_tex.r, spec_pow); 
            spec *= 100.0 * mix(1.0, 0.01, roughness); 
            spec_color = primary_light_color.xyz * vec3(spec); 
            vec3 spec_map_vec = reflect(ws_vertex,ws_normal); 

            vec3 reflection_color = LookUpReflectionShapes(tex19, world_vert, normalize(spec_map_vec), roughness*3.0);
            spec_color += reflection_color;

            float glancing = max(0.0, min(1.0, 1.0 + dot(normalize(ws_vertex), ws_normal)));
            float base_reflectivity = spec_amount * 0.1;
            float fresnel = pow(glancing, 6.0) * (1.0 - roughness * 0.5);
            fresnel *= (1.0 + ws_normal.y) * 0.5;

            float spec_val = mix(base_reflectivity, 1.0, fresnel);
            spec_amount = spec_val;
            /*if(!use_amb_cube && !use_3d_tex){
                CALC_BLOODY_CHARACTER_SPEC
            } else {
                float spec = GetSpecContrib(ws_light, ws_normal, ws_vertex, shadow_tex.r,
                    mix(200.0,50.0,(1.0-wetblood)*blood_amount));
                spec *= 5.0; 
                spec_color = primary_light_color.xyz * vec3(spec) * 0.3;
                vec3 spec_map_vec = reflect(ws_vertex, ws_normal);
                spec_color += SampleAmbientCube(ambient_cube_color, spec_map_vec) * 0.2 * max(0.0,(1.0 - blood_amount * 2.0));
            }*/
        #elif defined(ITEM)
            float spec_pow = mix(1200.0, 20.0, pow(roughness,2.0));
            float spec = GetSpecContrib(ws_light, ws_normal, ws_vertex, shadow_tex.r,spec_pow); 
            spec *= 20.0 * mix(1.0, 0.01, roughness); 
            spec_color = primary_light_color.xyz * vec3(spec); 
            vec3 spec_map_vec = reflect(ws_vertex,ws_normal); 
            
            vec3 reflection_color = LookUpReflectionShapes(tex19, world_vert, spec_map_vec, roughness * 3.0);
            spec_color += reflection_color;
            float glancing = max(0.0, min(1.0, 1.0 + dot(normalize(ws_vertex), ws_normal)));
            float base_reflectivity = spec_amount;
            float fresnel = pow(glancing, 6.0) * mix(0.7, 1.0, blood_amount);
            float spec_val = mix(base_reflectivity, 1.0, fresnel);
            spec_amount = spec_val;
        #else
            #ifdef WATER
                roughness = 0.0;
                spec_amount = 0.03;
                //colormap.xyz = vec3(0.0, 0.01, 0.01);
                colormap.xyz = vec3(0.02, 0.03, 0.02);
                float spec_pow = 2500;
                if(!gl_FrontFacing){
                    ws_normal *= -1.0;
                }
            #else
                float spec_pow = mix(1200.0, 20.0, pow(roughness,2.0));
            #endif
            float spec = GetSpecContrib(ws_light, ws_normal, ws_vertex, shadow_tex.r,spec_pow); 
            spec *= 100.0* mix(1.0, 0.01, roughness); 
            spec_color = primary_light_color.xyz * vec3(spec); 
            vec3 spec_map_vec = normalize(reflect(ws_vertex,ws_normal)); 


            vec3 reflection_color = LookUpReflectionShapes(tex19, world_vert, spec_map_vec, roughness * 3.0);
            spec_color += reflection_color;

            float glancing = max(0.0, min(1.0, 1.0 + dot(normalize(ws_vertex), ws_normal)));
            float base_reflectivity = spec_amount;
            #ifdef WATER
                float fresnel;
                if(!gl_FrontFacing){
                    fresnel = pow(glancing, 0.2);
                } else {
                    fresnel = pow(glancing, 5.0);
                }
                float spec_val = mix(base_reflectivity, 1.0, fresnel);
                spec_amount = 1.0;
            #else
                float fresnel = pow(glancing, 10.0) * (1.0 - roughness);
                float spec_val = mix(base_reflectivity, 1.0, fresnel);
                spec_amount = spec_val;
            #endif
        #endif
        #if !defined(ALPHA) && !defined(DETAILMAP4) && !defined(CHARACTER) && !defined(ITEM)
            colormap.xyz *= mix(vec3(1.0),color_tint[instance_id].xyz,normalmap.a);
        #endif
        CalculateLightContrib(diffuse_color, spec_color, ws_vertex, world_vert, ws_normal);
        vec3 color = mix(diffuse_color * colormap.xyz, spec_color, spec_amount);
    #endif

    #ifdef CHARACTER
        // Add rim highlight
        vec3 view = normalize(ws_vertex*-1.0);
        float back_lit = max(0.0,dot(normalize(ws_vertex),ws_light)); 
        float rim_lit = max(0.0,(1.0-dot(view,ws_normal)));
        rim_lit *= pow((dot(ws_light,ws_normal)+1.0)*0.5,0.5);
        color += vec3(back_lit*rim_lit) * (1.0 - blood_amount) * normalmap.a * primary_light_color.xyz * primary_light_color.a * shadow_tex.r;
    #endif
    //CALC_HAZE
    //AddHaze(color, ws_vertex, spec_cubemap);
    if(use_3d_tex){
        vec3 fog_color = SampleAmbientCube(ambient_cube_color, ws_vertex);
        color = mix(color, fog_color, GetHazeAmount(ws_vertex));        
    } else if(!use_amb_cube){
        vec3 fog_color = textureLod(spec_cubemap,ws_vertex,5.0).xyz;
        color = mix(color, fog_color, GetHazeAmount(ws_vertex));
    } else {
        vec3 fog_color = SampleAmbientCube(ambient_cube_color, ws_vertex);
        color = mix(color, fog_color, GetHazeAmount(ws_vertex));        
    }

    #if !defined(TERRAIN) && !defined(CHARACTER) && !defined(ITEM)
    //#ifdef EMISSIVE
    if(color_tint[instance_id].r > 1.0){
        color.xyz = colormap.xyz * color_tint[instance_id].xyz;
    }
    //#endif
    #endif

    #ifdef ALPHA
        out_color = vec4(color,colormap.a);
    #elif defined(WATER)
        out_color = vec4(color,spec_val);
    #else
        out_color = vec4(color,1.0);
    #endif

    #ifdef CHARACTER
        out_vel.xyz = vel;
        out_vel.a = 1.0;
    #elif defined(ITEM)
        out_vel.xyz = vel * 60.0;
        out_vel.a = 1.0;
    #else
        out_vel = vec4(0.0);
    #endif

    /*#ifdef CHARACTER
        out_color.xyz = vec3(roughness);
        out_color.xyz = LookupCubemapSimpleLod(spec_map_vec, tex2, roughness * 5.0);
    
        out_color.xyz = vec3(spec_color);
    #endif*/
/*
#ifdef CHARACTER
                vec3 spec_map_vec = reflect(ws_vertex,ws_normal);
                float fresnel = dot(ws_normal, normalize(ws_vertex));
    out_color.xyz = mix(textureLod(spec_cubemap,spec_map_vec,1.0).xyz, textureLod(spec_cubemap,ws_normal,5.0).xyz, 0.0);//max(0.0, min(1.0, pow(fresnel * -1.0, 2.0))));
    out_color.xyz = textureLod(spec_cubemap,ws_vertex + ws_normal,0.0).xyz;
    
#endif*/
#ifdef ITEM   
   // out_color.xyz = spec_color.xyz;
#endif

#ifdef WATER
    if(gl_FrontFacing){
        vec4 proj_test_point = (projection_view_mat * vec4(world_vert, 1.0));
        proj_test_point /= proj_test_point.w;
        proj_test_point.xy += vec2(1.0);
        proj_test_point.xy *= 0.5;
        float water_depth = LinearizeDepth(gl_FragCoord.z);
        float old_depth = LinearizeDepth(texture(tex18, proj_test_point.xy).r) - water_depth;
        vec2 distort = vec2(base_water_offset.xy) * max(0.4, min(old_depth, 1.0) ) / (water_depth * 0.1 + 1.0);
        proj_test_point.xy += distort;
        float depth = LinearizeDepth(texture(tex18, proj_test_point.xy).r) - LinearizeDepth(gl_FragCoord.z);
        if(depth < 0.0){        
            proj_test_point.xy -= distort * 0.5;
            depth = LinearizeDepth(texture(tex18, proj_test_point.xy).r) - LinearizeDepth(gl_FragCoord.z);
        }
        if(depth < 0.0){
            proj_test_point.xy -= distort * 0.5;
            depth = LinearizeDepth(texture(tex18, proj_test_point.xy).r) - LinearizeDepth(gl_FragCoord.z);
        }
        vec3 under_water = texture(tex17, proj_test_point.xy).xyz;
        under_water = mix(under_water, diffuse_color * colormap.xyz, max(0.0, min(1.0, pow(depth * 0.3, 0.2))));
        float min_depth = -0.3;
        float max_depth = 0.1;
        if(depth < max_depth && depth > min_depth && abs(old_depth - depth) < 0.1){
            if(depth > 0.0){
                under_water = mix(diffuse_color * 0.3, under_water, depth/max_depth);
            } else {
                under_water = mix(diffuse_color * 0.3, under_water, depth/-min_depth);            
            }
        }
        out_color.xyz = mix(under_water, out_color.xyz, spec_val);
        //out_color.xyz = vec3(max(0.0, min(1.0, pow(depth * 0.1,0.8))));
        out_color.a = 1.0;
    } else {
        vec4 proj_test_point = (projection_view_mat * vec4(world_vert, 1.0));
        proj_test_point /= proj_test_point.w;
        proj_test_point.xy += vec2(1.0);
        proj_test_point.xy *= 0.5;
        float water_depth = LinearizeDepth(gl_FragCoord.z);
        float old_depth = LinearizeDepth(texture(tex18, proj_test_point.xy).r) - water_depth;;
        vec2 distort = vec2(base_water_offset.xy) * max(0.4, min(old_depth, 1.0) ) / (water_depth * 0.1 + 1.0);
        proj_test_point.xy += distort;
        float depth = LinearizeDepth(texture(tex18, proj_test_point.xy).r) - LinearizeDepth(gl_FragCoord.z);
        if(depth < 0.0){        
            proj_test_point.xy -= distort * 0.5;
            depth = LinearizeDepth(texture(tex18, proj_test_point.xy).r) - LinearizeDepth(gl_FragCoord.z);
        }
        if(depth < 0.0){
            proj_test_point.xy -= distort * 0.5;
            depth = LinearizeDepth(texture(tex18, proj_test_point.xy).r) - LinearizeDepth(gl_FragCoord.z);
        }
        vec3 under_water = texture(tex17, proj_test_point.xy).xyz;
        out_color.xyz *= 0.1;
        out_color.xyz = mix(under_water, out_color.xyz, spec_val);
        out_color.a = 1.0;
    }
#endif

// Screen space reflection test
#ifdef SCREEN_SPACE_REFLECTION
   #ifdef WATER 
    {
    vec3 spec_map_vec = normalize(reflect(ws_vertex,ws_normal));
    //out_color.xyz = vec3(0.0);
    bool done = false;
    bool good = false;
    int count = 0;
    vec4 proj_test_point;
    float step_size = 0.1;
    vec3 march = world_vert;
    float screen_step_mult = abs(dot(spec_map_vec, normalize(ws_vertex)));
    float random = rand(gl_FragCoord.xy);
    while(!done){
        march += spec_map_vec * step_size / screen_step_mult;
        vec3 test_point = march + (spec_map_vec * step_size / screen_step_mult * random);
        #ifdef TERRAIN
            proj_test_point = (mvp * vec4(test_point, 1.0));
        #else
            proj_test_point = (projection_view_mat * vec4(test_point, 1.0));
        #endif
        proj_test_point /= proj_test_point.w;
        proj_test_point.xy += vec2(1.0);
        proj_test_point.xy *= 0.5;
        proj_test_point.z = LinearizeDepth(proj_test_point.z);
        float depth = LinearizeDepth(texture(tex18, proj_test_point.xy).r) * 0.5;
        ++count;
        if(count > 15 || proj_test_point.x < 0.0 || proj_test_point.y < 0.0 || proj_test_point.x > 1.0 || proj_test_point.y > 1.0){
            done = true;
        }
        if( depth < proj_test_point.z && abs(depth - proj_test_point.z) < step_size*2.0){
            done = true;
            good = true;
        }
        step_size *= 1.5;
    }
    //out_color.r = depth * 0.01;
    //out_color.g = proj_test_point.z * 0.01;
    //out_color.b = 0.0;
    //out_color.xyz = texture(tex17, proj_test_point.xy).xyz;
    //out_color.xyz = vec3(proj_test_point.x);
    float reflect_amount = min(1.0, pow(-abs(dot(ws_normal, normalize(ws_vertex))) + 1.0, 2.0));
    if(good){
        out_color.xyz = mix(out_color.xyz, texture(tex17, proj_test_point.xy).xyz, reflect_amount);
    } else {
        out_color.xyz = mix(out_color.xyz, LookupCubemapSimple(spec_map_vec, spec_cubemap), reflect_amount);        
    }
    //out_color.xyz = vec3(reflect_amount);
    //out_color.xyz = vec3(abs(depth - proj_test_point.z) * 0.1);
    } 
    #endif
    #endif
    
 // volume light test
    /*{
        vec3 color = vec3(0.0);
        int num_samples = 5;
        float random = rand(gl_FragCoord.xy);
        float total = 0.0;
        for(int i=0; i<num_samples; ++i){
            vec3 sample_vert = mix(world_vert, cam_pos, (i+random)/float(num_samples));
            ws_vertex = sample_vert - cam_pos;
            shadow_coords[0] = shadow_matrix[0] * vec4(sample_vert, 1.0);
            shadow_coords[1] = shadow_matrix[1] * vec4(sample_vert, 1.0);
            shadow_coords[2] = shadow_matrix[2] * vec4(sample_vert, 1.0);
            shadow_coords[3] = shadow_matrix[3] * vec4(sample_vert, 1.0);
            float len = length(ws_vertex);
            float weight = 1.0;
            color += GetCascadeShadow(shadow_sampler, shadow_coords, len) * weight;
            if(use_3d_tex){
                vec3 tex_3d = vec3(sample_vert.x, sample_vert.y, sample_vert.z);
                tex_3d *= 0.001;
                tex_3d += vec3(0.5);
                tex_3d[0] /= 6.0;
                if(tex_3d[0] > 0.0 && tex_3d[1] > 0.0 && tex_3d[2] > 0.0 && tex_3d[0] < 1.0 && tex_3d[1] < 1.0 && tex_3d[2] < 1.0){
                    color.xyz += texture(tex16, tex_3d).xyz * weight;
                }
            }
            total += weight;
        }
        color /= total;

        out_color.xyz = mix(out_color.xyz, color.xyz, length(world_vert - cam_pos) * 0.006);//vec3(mix(surf_shadow, color, min(1.0, length(ws_vertex) * length(ws_vertex) * 0.001)));
    }*/
/*
    vec3 avg;
    for(int i=0; i<6; ++i){
        avg += ambient_cube_color[i];
    }
    avg /= 6.0;
    out_color.xyz = avg;
    out_color.xyz = ambient_color;*/
//#ifndef WATER
#ifdef WATER_DECAL_ENABLED
    { // Water decal
        uint num_z_clusters = grid_size.z;

        vec4 ndcPos;
        ndcPos.xy = ((2.0 * gl_FragCoord.xy) - (2.0 * viewport.xy)) / (viewport.zw) - 1;
        ndcPos.z = 2.0 * gl_FragCoord.z - 1; // this assumes gl_DepthRange is not changed
        ndcPos.w = 1.0;

        vec4 clipPos = ndcPos / gl_FragCoord.w;
        vec4 eyePos = inv_proj_mat * clipPos;

        float zVal = ZCLUSTERFUNC(eyePos.z);

        zVal = max(0u, min(zVal, num_z_clusters - 1u));

        uvec3 g = uvec3(gl_FragCoord.xy / 32.0, zVal);

        // index of cluster we're in
        uint decal_cluster_index = NUM_GRID_COMPONENTS * ((g.y * grid_size.x + g.x) * num_z_clusters + g.z);
        uint val = texelFetch(cluster_buffer, int(decal_cluster_index)).x;

        // number of decals in current cluster
        uint decal_count = (val >> 16) & 0xFFFFU;

        // debug option, uncomment to visualize clusters
        //colormap.xyz = vec3(min(decal_count, 63u) / 63.0);
        //colormap.xyz = vec3(g.z / num_z_clusters);

        // index into cluster_decals
        uint first_decal_index = val & 0xFFFFU;

        // decal list data is immediately after cluster lookup data
        uint num_clusters = grid_size.x * grid_size.y * grid_size.z;
        first_decal_index = first_decal_index + 2u * num_clusters;

        vec3 world_dx = dFdx(world_vert);
        vec3 world_dy = dFdy(world_vert);
        for (uint i = 0u; i < decal_count; ++i) {
            // texelFetch takes int
            uint decal_index = texelFetch(cluster_buffer, int(first_decal_index + i)).x;

            DecalData decal = FetchDecal(decal_index);

            mat4 test = inverse(decal.transform);

            vec3 temp = (test * vec4(world_vert, 1.0)).xyz;

            if(temp[0] < -0.5 || temp[0] > 0.5 || temp[1] < -0.5 || temp[1] > 0.5 || temp[2] < -0.5 || temp[2] > 0.5){
            } else {
                //spec_amount = mix(spec_amount, 1.0, 0.1);
                //colormap.xyz *= 0.4;
                // Find water surface
                vec3 cam_temp = (test * vec4(cam_pos, 1.0)).xyz;
                //mix(cam_temp[1], temp[1], t) = 0.5;
                //cam_temp[1] - t * cam_temp[1] + temp[1] * t = 0.5;
                float t = (cam_temp[1] - 0.5) / (cam_temp[1] - temp[1]);
                vec3 world_vert_surface_temp = mix(cam_temp, temp, t);
                //vec3 world_vert_surface = (decal.transform * vec4(world_vert_surface_temp, 1.0)).xyz;//mix(cam_pos, world_vert, t);
                vec3 world_vert_surface = mix(cam_pos, world_vert, t);
                vec3 world_vert_up = (decal.transform * vec4(vec3(temp.x, 0.5, temp.z), 1.0)).xyz;
                float surface_depth = (test * vec4(world_vert_surface, 1.0)).xyz[1];
                float world_depth = (test * vec4(world_vert, 1.0)).xyz[1];
                float fog_dist;
                if(cam_temp[1] > 0.5){
                    fog_dist = length(world_vert - world_vert_surface);                 
                } else {
                    fog_dist = length(world_vert - cam_pos);                      
                }
                float fog_amount = min(1.0, fog_dist * 0.2);
                float water_depth = distance(world_vert_up, world_vert);
                vec3 start;
                float start_depth;
                if(cam_temp[1] > 0.5){
                    start = world_vert_surface;
                    start_depth = 0.0;
                } else {
                    start = cam_pos;   
                    vec3 cam_pos_up = (decal.transform * vec4(vec3(cam_temp.x, 0.5, cam_temp.z), 1.0)).xyz;
                    start_depth = distance(cam_pos_up, cam_pos);
                }
                const int num_samples = 5;
                vec3 total_color = vec3(0.0);
                float total = 0.0;
                for(int i=0; i<num_samples; ++i){
                    float t = i / float(num_samples-1);
                    float temp_depth = mix(start_depth, water_depth, t);
                    vec3 pos = mix(start, world_vert, t);
                    float weight = 1.0 / (length(start-pos)+1.0);
                    total_color += vec3(1.0 - pow(temp_depth * 0.5, 1.0)) * weight;
                    total += weight;
                }
                vec3 fog_color = total_color / total;
                fog_color *= vec3(0.05, 0.03, 0.03);
                #ifndef WATER
                float caustics = (sin(world_vert.x*-10.0 + time * 5.0) + sin(world_vert.z*-7.0 + time * 3.0) + sin(world_vert.z*11.0 + world_vert.x * 5.0 + time * 2.0)+ sin(world_vert.z*-13.0 + world_vert.x * 7.0 + time * 1.4))/8.0;
                caustics = pow(max(0.0, min(1.0, 1.0 - abs(caustics) * 4.0)), 2.0) * 2.0;
                out_color.xyz *= vec3(mix(1.0, caustics, min(1.0, water_depth * 0.3)));
                #endif
                vec3 shadow_color;
                vec3 right = normalize(cross(vec3(0.0, 1.0, 0.0), ws_light));
                vec3 up = normalize(cross(right, ws_light));
                {
                    vec3 color = vec3(0.0);
                    int num_samples = 5;
                    float random = rand(gl_FragCoord.xy);
                    vec3 target_vert = world_vert;
                    float max_length = 2.0;
                    if(length(target_vert - start) > max_length){
                        target_vert = normalize(target_vert - start) * max_length + start;
                    }
                    float total = 0.0;
                    for(int i=0; i<num_samples; ++i){
                        vec3 sample_vert = mix(target_vert, start, (i+random)/float(num_samples));
                        ws_vertex = sample_vert - start;
                        shadow_coords[0] = shadow_matrix[0] * vec4(sample_vert, 1.0);
                        shadow_coords[1] = shadow_matrix[1] * vec4(sample_vert, 1.0);
                        shadow_coords[2] = shadow_matrix[2] * vec4(sample_vert, 1.0);
                        shadow_coords[3] = shadow_matrix[3] * vec4(sample_vert, 1.0);
                        float len = length(ws_vertex);
                        float weight = 1.0;
                        float lit = GetCascadeShadow(shadow_sampler, shadow_coords, len) * weight;
                        vec2 temp = vec2(dot(right, sample_vert), dot(up, sample_vert));
                        lit *= abs((sin(temp.x*-5.0 + time * 2.0) + sin(temp.y*-7.0 + time * 1.5) + sin(temp.x*3.0+temp.y*4.0 + time * 2.3))/3.0);
                        color += lit;
                        total += weight;
                    }
                    color /= total;
                    shadow_color = color;
                }
                fog_color.xyz *= (shadow_color * 2.0 + 1.0);
                out_color.xyz = mix(out_color.xyz, out_color.xyz * fog_color, min(1.0, pow(water_depth * 0.5, 1.0)));
                out_color.xyz = mix(out_color.xyz, fog_color, fog_amount);
            }
        }
    }

    #endif // WATER_DECAL_ENABLED
    #if !defined(CHARACTER) && !defined(TERRAIN) && !defined(PLANT)


    #endif
    #endif // DEPTH_ONLY
    #endif // PARTICLE
}
