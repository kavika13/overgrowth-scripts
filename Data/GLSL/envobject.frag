#version 150

#if defined(WATER)
#define NO_DECALS
#endif

#define FIRE_DECAL_ENABLED
//#define RAINY

uniform float time;


#include "object_frag150.glsl"
#include "object_shared150.glsl"
#include "ambient_tet_mesh.glsl"

#ifdef PARTICLE
    uniform sampler2D tex0; // Colormap
    #ifndef INSTANCED
        uniform vec4 color_tint;
    #endif
    #ifndef DEPTH_ONLY
        uniform sampler2D tex1; // Normalmap
        uniform samplerCube tex2; // Diffuse cubemap
        uniform samplerCube tex3; // Diffuse cubemap
        uniform sampler2D tex5; // Screen depth texture TODO: make this work with msaa properly
        UNIFORM_SHADOW_TEXTURE
        UNIFORM_LIGHT_DIR
        #ifndef INSTANCED
            uniform float size;
        #endif
        uniform vec2 viewport_dims;
        uniform sampler3D tex16;
        uniform sampler2DArray tex19;

        uniform mat4 reflection_capture_matrix[10];
        uniform mat4 reflection_capture_matrix_inverse[10];
        uniform int reflection_capture_num;

        uniform mat4 light_volume_matrix[10];
        uniform mat4 light_volume_matrix_inverse[10];
        uniform int light_volume_num;

        uniform float haze_mult;
    #endif
    #ifdef INSTANCED
    const int kMaxInstances = 100;

    uniform InstanceInfo {
        vec4 instance_color[kMaxInstances];
        mat4 instance_transform[kMaxInstances];
    };
    #endif
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

    uniform float haze_mult;

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
    uniform mat4 reflection_capture_matrix_inverse[10];
    uniform int reflection_capture_num;

    uniform mat4 light_volume_matrix[10];
    uniform mat4 light_volume_matrix_inverse[10];
    uniform int light_volume_num;
    uniform mat4 prev_projection_view_mat;

    uniform float haze_mult;

    //#define EMISSIVE

    #ifdef TERRAIN
    #elif defined(CHARACTER) || defined(ITEM)
    #else
        #define INSTANCED_MESH
        const int kMaxInstances = 100;

        uniform InstanceInfo {
            mat4 model_mat[kMaxInstances];
            mat3 model_rotation_mat[kMaxInstances];
            vec4 color_tint[kMaxInstances];
            vec4 detail_scale[kMaxInstances];
        };
    #endif
#endif // PARTICLE

#ifdef CAN_USE_LIGHT_PROBES
    uniform usamplerBuffer ambient_grid_data;
    uniform usamplerBuffer ambient_color_buffer;
    uniform int num_light_probes;
    uniform int num_tetrahedra;

    uniform vec3 grid_bounds_min;
    uniform vec3 grid_bounds_max;
    uniform int subdivisions_x;
    uniform int subdivisions_y;
    uniform int subdivisions_z;
#endif

uniform vec3 cam_pos;
uniform mat4 shadow_matrix[4];
uniform mat4 projection_view_mat;

#include "decals.glsl"

in vec3 world_vert;

#ifdef PARTICLE
    in vec2 tex_coord;
    #if defined(NORMAL_MAP_TRANSLUCENT) || defined(WATER) || defined(SPLAT)
        in vec3 tangent_to_world1;
        in vec3 tangent_to_world2;
        in vec3 tangent_to_world3;
    #endif
    flat in int instance_id;
#elif defined(DETAIL_OBJECT)
    in vec2 frag_tex_coords;
    in vec2 base_tex_coord;
    in mat3 tangent_to_world;
#elif defined(ITEM)
    #ifndef DEPTH_ONLY
        #ifndef NO_VELOCITY_BUF
            in vec3 vel;
        #endif
    #ifdef TANGENT
        in vec3 frag_normal;
    #endif
    #endif
    in vec2 frag_tex_coords;
#elif defined(TERRAIN)
    #ifdef DETAILMAP4
        in vec3 frag_tangent;
    #endif
    #if !defined(SIMPLE_SHADOW)
         //in float alpha;
    #endif
    in vec4 frag_tex_coords;
#elif defined(CHARACTER)
    in vec2 fur_tex_coord;
    #ifndef DEPTH_ONLY
    in vec3 concat_bone1;
    in vec3 concat_bone2;
    in vec2 tex_coord;
    in vec2 morphed_tex_coord;
    in vec3 orig_vert;
        #ifndef NO_VELOCITY_BUF
        in vec3 vel;
        #endif
    #endif
#else
    #ifdef TANGENT
    in mat3 tan_to_obj;
    #endif
    in vec2 frag_tex_coords;
    #ifndef NO_INSTANCE_ID
    flat in int instance_id;
    #endif
#endif
#pragma bind_out_color
out vec4 out_color;

#ifndef NO_VELOCITY_BUF

#pragma bind_out_vel
out vec4 out_vel;

#endif  // NO_VELOCITY_BUF

#define shadow_tex_coords tc1
#define tc0 frag_tex_coords

//#ifdef PARTICLE

float LinearizeDepth(float z) {
  float n = 0.1; // camera z near
  float epsilon = 0.000001;
  float z_scaled = z * 2.0 - 1.0; // Scale from 0 - 1 to -1 - 1
  float B = (epsilon-2.0)*n;
  float A = (epsilon - 1.0);
  float result = B / (z_scaled + A);
  if(result < 0.0){
    result = 99999999.0;
  }
  return result;
}
//#endif

#if !defined(DEPTH_ONLY)
void CalculateLightContribParticle(inout vec3 diffuse_color, vec3 world_vert, uint light_val) {
    // number of lights in current cluster
    uint light_count = (light_val >> COUNT_BITS) & COUNT_MASK;

    // index into cluster_lights
    uint first_light_index = light_val & INDEX_MASK;

    // light list data is immediately after cluster lookup data
    uint num_clusters = grid_size.x * grid_size.y * grid_size.z;
    first_light_index = first_light_index + uint(light_cluster_data_offset);

    // debug option, uncomment to visualize clusters
    //out_color = vec3(min(light_count, 63u) / 63.0);
    //out_color = vec3(g.z / grid_size.z);

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
#endif //!DEPTH_ONLY

#if !defined(DETAIL_OBJECT) && !defined(DEPTH_ONLY)
vec3 LookupSphereReflectionPos(vec3 world_vert, vec3 spec_map_vec, int which) {
    //vec3 sphere_pos = world_vert - reflection_capture_pos[which];
    //sphere_pos /= reflection_capture_scale[which];
    vec3 sphere_pos = (reflection_capture_matrix_inverse[which] * vec4(world_vert, 1.0)).xyz;
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


const float water_speed = 0.03;

float GetWaterHeight(vec2 pos, vec3 tint){
    float scale = 0.1 * tint[0];
    float height = 0.0;
    float uv_scale = tint[1];
    float scaled_water_speed = water_speed * uv_scale;
    pos *= uv_scale;
    height = texture(tex0, pos  * 0.3 + normalize(vec2(0.0, 1.0))*time*scaled_water_speed).x;
    height += texture(tex0, pos * 0.7 + normalize(vec2(1.0, 0.0))*time*3.0*scaled_water_speed).x;
    height += texture(tex0, pos * 1.1 + normalize(vec2(-1.0, 0.0))*time*5.0*scaled_water_speed).x;
    height += texture(tex0, pos * 0.6 + normalize(vec2(-1.0, 1.0))*time*7.0*scaled_water_speed).x;
    height *= scale;

    //height += texture(tex0, pos * 0.3 + normalize(vec2(1.0, 0.0))*time*water_speed * pow(0.3, 0.5)).x * scale / 0.3;
    //height += texture(tex0, pos * 0.1 + normalize(vec2(-1.0, 0.0))*time*water_speed * pow(0.1, 0.5)).x * scale / 0.1;
    //height += texture(tex0, pos * 0.05 + normalize(vec2(-1.0, 1.0))*time*water_speed * pow(0.05, 0.5)).x * scale / 0.05;

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

#ifndef DEPTH_ONLY

#if defined(CAN_USE_3D_TEX) && !defined(DETAIL_OBJECT)
bool Query3DTexture(inout vec3 ambient_color, vec3 pos, vec3 normal) {
    bool use_3d_tex = false;
    vec3 ambient_cube_color[6];
    for(int i=0; i<6; ++i){
        ambient_cube_color[i] = vec3(0.0);
    }
    for(int i=0; i<light_volume_num; ++i){
        //vec3 temp = (world_vert - reflection_capture_pos[i]) / reflection_capture_scale[i];
        vec3 temp = (light_volume_matrix_inverse[i] * vec4(pos, 1.0)).xyz;
        vec3 scale_vec = (light_volume_matrix[i] * vec4(1.0, 1.0, 1.0, 0.0)).xyz;
        float scale = dot(scale_vec, scale_vec);
        float val = dot(temp, temp);
        if(temp[0] <= 1.0 && temp[0] >= -1.0 &&
           temp[1] <= 1.0 && temp[1] >= -1.0 &&
           temp[2] <= 1.0 && temp[2] >= -1.0)
        {
            vec3 tex_3d = temp * 0.5 + vec3(0.5);
            vec4 test = texture(tex16, vec3((tex_3d[0] + 0)/ 6.0, tex_3d[1], tex_3d[2]));
            if(test.a >= 1.0){
                for(int j=1; j<6; ++j){
                    ambient_cube_color[j] = texture(tex16, vec3((tex_3d[0] + j)/ 6.0, tex_3d[1], tex_3d[2])).xyz;
                }
                ambient_cube_color[0] = test.xyz;
                ambient_color = SampleAmbientCube(ambient_cube_color, normal);
                use_3d_tex = true;
            }
            //out_color.xyz = world_vert * 0.01;
        }
    }
    return use_3d_tex;
}
#endif

vec3 GetAmbientColor(vec3 world_vert, vec3 ws_normal) {
    vec3 ambient_color = vec3(0.0);
#if defined(CAN_USE_3D_TEX) && !defined(DETAIL_OBJECT)
    bool use_3d_tex = Query3DTexture(ambient_color, world_vert, ws_normal);
#else
    bool use_3d_tex = false;
#endif
    if(!use_3d_tex){
        bool use_amb_cube = false;
        vec3 ambient_cube_color[6];
        for(int i=0; i<6; ++i){
            ambient_cube_color[i] = vec3(0.0);
        }
        #ifdef CAN_USE_LIGHT_PROBES
            uint guess = 0u;
            int grid_coord[3];
            bool in_grid = true;
            for(int i=0; i<3; ++i){
                if(world_vert[i] > grid_bounds_max[i] || world_vert[i] < grid_bounds_min[i]){
                    in_grid = false;
                    break;
                }
            }
            if(in_grid){
                grid_coord[0] = int((world_vert[0] - grid_bounds_min[0]) / (grid_bounds_max[0] - grid_bounds_min[0]) * float(subdivisions_x));
                grid_coord[1] = int((world_vert[1] - grid_bounds_min[1]) / (grid_bounds_max[1] - grid_bounds_min[1]) * float(subdivisions_y));
                grid_coord[2] = int((world_vert[2] - grid_bounds_min[2]) / (grid_bounds_max[2] - grid_bounds_min[2]) * float(subdivisions_z));
                int cell_id = ((grid_coord[0] * subdivisions_y) + grid_coord[1])*subdivisions_z + grid_coord[2];
                uvec4 data = texelFetch(ambient_grid_data, cell_id/4);
                guess = data[cell_id%4];
                use_amb_cube = GetAmbientCube(world_vert, num_tetrahedra, ambient_color_buffer, ambient_cube_color, guess);
            }
        #endif
        if(!use_amb_cube){
            ambient_color = LookupCubemapSimpleLod(ws_normal, spec_cubemap, 5.0);
        } else {
            ambient_color = SampleAmbientCube(ambient_cube_color, ws_normal);
        }
    }
    return ambient_color;
}
#endif

#if !defined(DETAIL_OBJECT) && !defined(DEPTH_ONLY)
vec3 LookUpReflectionShapes(sampler2DArray reflections_tex, vec3 world_vert, vec3 reflect_dir, float lod) {
    #ifdef NO_REFLECTION_CAPTURE
        return vec3(0.0);
    #else
        vec3 reflection_color = vec3(0.0);
        float total = 0.0;
        for(int i=0; i<reflection_capture_num; ++i){
            //vec3 temp = (world_vert - reflection_capture_pos[i]) / reflection_capture_scale[i];
            vec3 temp = (reflection_capture_matrix_inverse[i] * vec4(world_vert, 1.0)).xyz;
            vec3 scale_vec = (reflection_capture_matrix[i] * vec4(1.0, 1.0, 1.0, 0.0)).xyz;
            float scale = dot(scale_vec, scale_vec);
            float val = dot(temp, temp);
            if(val < 1.0){
                vec3 lookup = LookupSphereReflectionPos(world_vert, reflect_dir, i);
                vec2 coord = LookupFauxCubemap(lookup, lod);
                float weight = pow((1.0 - val), 8.0);
                weight *= 100000.0;
                weight /= pow(scale, 2.0);
                reflection_color.xyz += textureLod(reflections_tex, vec3(coord, i+1), lod).xyz * weight;
                total += weight;
            }
        }
        if(total < 0.0000001){
            float weight = 0.00000001;
            vec2 coord = LookupFauxCubemap(reflect_dir, lod);
            reflection_color.xyz += textureLod(reflections_tex, vec3(coord, 0), lod).xyz * weight;
            total += weight;
        }
        if(total > 0.0){
            reflection_color.xyz /= total;
        }
        return reflection_color;
    #endif
}
#endif

// From http://www.thetenthplanet.de/archives/1180
mat3 cotangent_frame( vec3 N, vec3 p, vec2 uv )
{
    // get edge vectors of the pixel triangle
    vec3 dp1 = dFdx( p );
    vec3 dp2 = dFdy( p );
    vec2 duv1 = dFdx( uv );
    vec2 duv2 = dFdy( uv );
 
    // solve the linear system
    vec3 dp2perp = cross( dp2, N );
    vec3 dp1perp = cross( N, dp1 );
    vec3 T = dp2perp * duv1.x + dp1perp * duv2.x;
    vec3 B = dp2perp * duv1.y + dp1perp * duv2.y;
 
    // construct a scale-invariant frame 
    float invmax = inversesqrt( max( dot(T,T), dot(B,B) ) );
    return mat3( T * invmax, B * invmax, N );
}

//#define CAN_USE_3D_TEX
//#define TEXEL_DENSITY_VIZ
//#define ALBEDO_ONLY
//#define NO_DECALS
//#define NO_DETAILMAPS

void main() {
    vec3 ws_vertex = world_vert - cam_pos;

    vec4 ndcPos;
    ndcPos.xy = ((2.0 * gl_FragCoord.xy) - (2.0 * viewport.xy)) / (viewport.zw) - 1;
    ndcPos.z = 2.0 * gl_FragCoord.z - 1; // this assumes gl_DepthRange is not changed
    ndcPos.w = 1.0;

    vec4 clipPos = ndcPos / gl_FragCoord.w;
    vec4 eyePos = inv_proj_mat * clipPos;

    float zVal = ZCLUSTERFUNC(eyePos.z);

    zVal = max(0u, min(zVal, grid_size.z - 1u));

    uvec3 g = uvec3(uvec2(gl_FragCoord.xy) / cluster_width, zVal);

    out_color = vec4(0.0);

    // decal/light cluster stuff
#if !(defined(NO_DECALS) || defined(DEPTH_ONLY))
    uint decal_cluster_index = NUM_GRID_COMPONENTS * ((g.y * grid_size.x + g.x) * grid_size.z + g.z);
    uint decal_val = texelFetch(cluster_buffer, int(decal_cluster_index)).x;
    uint decal_count = (decal_val >> COUNT_BITS) & COUNT_MASK;
    /*out_color.xyz = vec3(decal_count * 0.1);
    out_color.a = 1.0;
    return;*/
#endif  // NO_DECALS

    uint light_cluster_index = NUM_GRID_COMPONENTS * ((g.y * grid_size.x + g.x) * grid_size.z + g.z) + 1u;
#if defined(DEPTH_ONLY)
    uint light_val = 0U;
#else
    uint light_val = texelFetch(cluster_buffer, int(light_cluster_index)).x;
#endif //DEPTH_ONLY

    #ifdef DETAIL_OBJECT
        float dist_fade = 1.0 - length(ws_vertex)/max_distance;
        CALC_COLOR_MAP
        #ifdef PLANT
            colormap.a = pow(colormap.a, max(0.1,min(1.0,3.0/length(ws_vertex))));
        #ifndef TERRAIN
                colormap.a -= max(0.0, -1.0 + (length(ws_vertex)/max_distance * (1.0+rand(gl_FragCoord.xy)*0.5))*2.0);
        #endif
        #ifndef ALPHA_TO_COVERAGE
            if(colormap.a < 0.5){
                discard;
            }
        #else
            colormap.a = 0.5 + (colormap.a - 0.5) * 2.0;
            if(colormap.a < 0.0){
                discard;
            }
        #endif
        #ifdef DEPTH_ONLY
            out_color = vec4(vec3(1.0), colormap.a);
            return;
        #endif
        #endif // PLANT
        #ifdef DEPTH_ONLY
            out_color = vec4(1.0);
            return;
        #else  // DEPTH_ONLY
            vec4 normalmap = texture(normal_tex,tc0);
            vec3 normal = UnpackTanNormal(normalmap);
            vec3 ws_normal = tangent_to_world * normal;

            vec3 base_normalmap = texture(base_normal_tex,tc1).xyz;
        #ifdef TERRAIN
                vec3 base_normal = normalize((base_normalmap*vec3(2.0))-vec3(1.0));
        #else  // TERRAIN
                //I'm assuming this normal is supposed to be in world space --Max
                vec3 base_normal = normalize(normal_matrix * UnpackObjNormalV3(base_normalmap.xyz));
        #endif  // TERRAIN
            ws_normal = mix(ws_normal,base_normal,min(1.0,1.0-(dist_fade-0.5)));

            float ambient_mult = 1.0;
            float env_ambient_mult = 1.0;
            float roughness = 1.0;
        #ifndef NO_DECALS
            float spec_amount = 0.0;
            vec3 flame_final_color = vec3(0.0, 0.0, 0.0);;
            float flame_final_contrib = 0.0;
            CalculateDecals(colormap, ws_normal, spec_amount, roughness, ambient_mult, env_ambient_mult, world_vert, time, decal_val, flame_final_color, flame_final_contrib);
        #endif
        #define shadow_tex_coords tc1
            vec4 shadow_coords[4];
            shadow_coords[0] = shadow_matrix[0] * vec4(world_vert, 1.0);
            shadow_coords[1] = shadow_matrix[1] * vec4(world_vert, 1.0);
            shadow_coords[2] = shadow_matrix[2] * vec4(world_vert, 1.0);
            shadow_coords[3] = shadow_matrix[3] * vec4(world_vert, 1.0);
            CALC_SHADOWED
            #ifdef SIMPLE_SHADOW
                shadow_tex.r *= ambient_mult;
            #endif

            vec3 ambient_cube_color[6];
            for(int i=0; i<6; ++i){
                ambient_cube_color[i] = vec3(0.0);
            }
            bool use_amb_cube = false;

            #ifdef CAN_USE_LIGHT_PROBES
                use_amb_cube = GetAmbientCube(world_vert, num_tetrahedra, ambient_color_buffer, ambient_cube_color, 0u);
            #endif
            CALC_DIRECT_DIFFUSE_COLOR
            if(!use_amb_cube){
                diffuse_color += LookupCubemapSimpleLod(ws_normal, spec_cubemap, 5.0) * GetAmbientContrib(1.0) * ambient_mult * env_ambient_mult;
            } else {
                diffuse_color += SampleAmbientCube(ambient_cube_color, ws_normal) * GetAmbientContrib(1.0) * ambient_mult * env_ambient_mult;
            }

            vec3 spec_color = vec3(0.0);
            
            CalculateLightContrib(diffuse_color, spec_color, ws_vertex, world_vert, ws_normal, roughness, light_val, 1.0);

            // Put it all together
            vec3 base_color = texture(base_color_tex,tc1).rgb * color_tint;
            float overbright_adjusted = dist_fade * overbright;
            colormap.xyz = base_color * mix(vec3(1.0), colormap.xyz / avg_color, dist_fade);
            colormap.xyz *= 1.0 + overbright_adjusted;
            vec3 color = diffuse_color * colormap.xyz;
        #ifdef ALBEDO_ONLY
            out_color = colormap;
            return;
        #endif

            float haze_amount = GetHazeAmount(ws_vertex, haze_mult);
            vec3 fog_color = textureLod(spec_cubemap,ws_vertex ,5.0).xyz;
            color = mix(color, fog_color, haze_amount);
        #ifdef PLANT
            CALC_FINAL_ALPHA
        #else
            CALC_FINAL
        #endif
        return;
        #endif // DEPTH_ONLY
    #elif defined(PARTICLE)
        #ifdef INSTANCED
            vec4 color_tint = instance_color[instance_id];
            float size = length(instance_transform[instance_id] * vec4(0,0,1,0));
        #endif
        vec4 colormap = texture(tex0, tex_coord);
        float random = rand(gl_FragCoord.xy);
        #ifdef DEPTH_ONLY
            if(colormap.a *color_tint.a < random){
                discard;
            }
            return;
        #else
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
                float surface_lighting = GetDirectContribSoft(ws_light, ws_normal, 1.0);
                float subsurface_lighting = GetDirectContribSoft(ws_light, ws_light, 1.0) * 0.5;
                float thickness = min(1.0,pow(colormap.a*color_tint.a*depth_blend,2.0)*2.0);
                float NdotL = mix(subsurface_lighting, surface_lighting, thickness);
                NdotL *= (1.0-shadowed);
                vec3 diffuse_color = GetDirectColor(NdotL);
                vec3 ambient_color = GetAmbientColor(world_vert, ws_normal);//LookupCubemapSimpleLod(ws_normal, tex3, 5.0);
            #elif defined(SPLAT)
                vec4 normalmap = texture(tex1, tex_coord);
                //normalmap.xyz = vec3(0.5, 0.5, 1.0);
                vec3 ws_normal = vec3(tangent_to_world3 * normalmap.b +
                                      tangent_to_world1 * (normalmap.r*2.0-1.0) +
                                      tangent_to_world2 * (normalmap.g*2.0-1.0));
                ws_normal = normalize(ws_normal);
                vec3 diffuse_color = GetDirectColor(GetDirectContribSoft(ws_light, ws_normal, 1.0 - shadowed)*0.5);

                vec3 ambient_color = GetAmbientColor(world_vert, ws_normal);//LookupCubemapSimpleLod(ws_normal, tex3, 5.0);
            #elif defined(WATER)
                vec4 normalmap = texture(tex1, tex_coord);
                vec3 ws_normal = vec3(tangent_to_world3 * normalmap.b +
                                      tangent_to_world1 * (normalmap.r*2.0-1.0) +
                                      tangent_to_world2 * (normalmap.g*2.0-1.0));

                vec3 diffuse_color;
                //Prevent compile warning, this value might be used by water later.
                vec3 ambient_color = vec3(0.0);
            #else
                float NdotL = GetDirectContribSimple((1.0-shadowed)*0.25);
                vec3 diffuse_color = GetDirectColor(NdotL);
                //vec3 ambient_color = LookupCubemapSimpleLod(cam_pos - world_vert, tex3, 5.0);
                vec3 ambient_color = GetAmbientColor(world_vert, cam_pos - world_vert);
            #endif

            diffuse_color += ambient_color * GetAmbientContrib(1.0);

            CalculateLightContribParticle(diffuse_color, world_vert, light_val);

            vec3 color = diffuse_color * colormap.xyz *color_tint.xyz;

            #ifdef SPLAT
                vec3 blood_spec = vec3(GetSpecContrib(ws_light, normalize(ws_normal), ws_vertex, 1.0, 200.0)) * (1.0-shadowed);
                blood_spec *= 10.0;
                vec3 spec_map_vec = reflect(ws_vertex, mix(tangent_to_world3, ws_normal, 0.5));
                vec3 reflection_color = LookUpReflectionShapes(tex19, world_vert, normalize(spec_map_vec), 0.0);
                color = mix(color, (blood_spec + reflection_color), 0.1);
            #elif defined(WATER)
                vec3 blood_spec = vec3(GetSpecContrib(ws_light, normalize(ws_normal), ws_vertex, 1.0, 200.0)) * (1.0-shadowed);
                blood_spec *= 10.0;
                vec3 spec_map_vec = reflect(ws_vertex,ws_normal);
                vec3 reflection_color = LookUpReflectionShapes(tex19, world_vert, normalize(spec_map_vec), 0.0);
                float glancing = max(0.0, min(1.0, 1.0 + dot(normalize(ws_vertex), ws_normal)));
                float fresnel = pow(glancing, 6.0);
                fresnel = mix(fresnel, 1.0, 0.05);
                //color = pow(max(0.0, dot(ws_light, mix(normalize(ws_vertex), -ws_normal, 0.2))), 5.0) * (1.0-shadowed) * 2.0 * primary_light_color.a * primary_light_color.xyz;
                color = LookUpReflectionShapes(tex19, world_vert, normalize(mix(normalize(ws_vertex), -ws_normal, 0.5)), 0.0);
                color = mix(color, (blood_spec + reflection_color), fresnel);
                colormap.a *= 0.5;
            #endif

            #ifdef GLOW
                color.xyz = colormap.xyz*color_tint.xyz*5.0;
            #endif

            float alpha = min(1.0, colormap.a*color_tint.a*depth_blend);
            #ifdef SPLAT
                if(alpha < 0.3){
                    discard;
                }
                alpha = min(1.0, (alpha - 0.3) * 6.0);
            #endif

            float haze_amount = GetHazeAmount(ws_vertex, haze_mult);
            vec3 fog_color = textureLod(spec_cubemap,ws_vertex ,5.0).xyz;
            color = mix(color, fog_color, haze_amount);

            out_color = vec4(color, alpha);
        #ifdef ALBEDO_ONLY
            out_color = vec4(colormap.xyz*color_tint.xyz, alpha);
            return;
        #endif
        #endif
        //out_color.xyz = vec3(pow(colormap.a,2.0));
        //out_color = vec4(1.0);
    #else
    #ifdef NO_INSTANCE_ID
        int instance_id = 0;
    #endif
    #ifdef CHARACTER
        float alpha = texture(fur_tex, fur_tex_coord).a;
    #else
        #ifdef TERRAIN
            vec2 test_offset = (texture(warp_tex,frag_tex_coords.xy*200.0).xy-0.5)*0.001;
            vec2 base_tex_coords = frag_tex_coords.xy + test_offset;
            vec2 detail_coords = frag_tex_coords.zw;
        #else
            vec2 base_tex_coords = frag_tex_coords;
            #ifdef DETAILMAP4
            vec2 detail_coords = base_tex_coords*detail_scale[instance_id].xy;
            #endif
        #endif
        vec4 colormap = texture(tex0, base_tex_coords);
    #endif

    vec4 shadow_coords[4];

    #ifndef DEPTH_ONLY
        shadow_coords[0] = shadow_matrix[0] * vec4(world_vert, 1.0);
        shadow_coords[1] = shadow_matrix[1] * vec4(world_vert, 1.0);
        shadow_coords[2] = shadow_matrix[2] * vec4(world_vert, 1.0);
        shadow_coords[3] = shadow_matrix[3] * vec4(world_vert, 1.0);
    #endif

    #ifdef CHARACTER
        #ifndef ALPHA_TO_COVERAGE
            if(alpha < 0.6){
                discard;
            }
        #else
            if(alpha < 0.0){
                discard;
            }
        #endif
    #else
        #if defined(ALPHA)
            #if !defined(ALPHA_TO_COVERAGE)
                if(colormap.a < 0.5){
                    discard;
                }                
            #else
                colormap.a = 0.5 + (colormap.a - 0.5) * 2.0;            
                if(colormap.a < 0.0){
                    discard;
                }
            #endif
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
    #ifdef MAGMA_FLOOR
        vec2 temp_tex_coords = frag_tex_coords.xy * 3.0;
        temp_tex_coords.x += sin(world_vert.x*4.0 + time * 2.0) * 0.004;
        temp_tex_coords.y += sin(world_vert.z*4.0 + time * 2.6) * 0.004;
        vec2 frag_tex_coordsB = temp_tex_coords;                            //copy the variable
        frag_tex_coordsB.x += time * 0.05;     //makes texture move back and fourth
        //frag_tex_coordsB.y += sin(frag_tex_coordsB.x + time * 1) * 0.02;

        vec3 temp_color = texture(tex0, temp_tex_coords).xyz;

        out_color.xyz = temp_color * 16.0 * mix(1.0, texture(tex1, frag_tex_coordsB).a, pow(temp_color.r,0.2));
        out_color.a = 1.0;
        return;
    #endif
    #ifdef MAGMA_FLOW
        vec2 frag_tex_coordsB = frag_tex_coords;                            //copy the variable
        vec2 frag_tex_coordsC = frag_tex_coords;                            //copy the variable
        frag_tex_coordsB.y += time * 0.3;                                   //makes texture 'scroll' in the y axis
        frag_tex_coordsC.y += time * 0.5;

        vec3 temp_color = texture(tex0, frag_tex_coordsB).xyz * (pow(texture(tex1, frag_tex_coordsC).a, 2.2) + 0.1);
        out_color.xyz = temp_color * 2.0;
        out_color.a = 1.0;
        return;
    #endif

    #ifdef DETAILMAP4
        #ifdef TEXEL_DENSITY_VIZ
            int max_res[2];
            max_res[0] = max(textureSize(tex0,0)[0], textureSize(tex1,0)[0]);
            max_res[1] = max(textureSize(tex0,0)[1], textureSize(tex1,0)[1]);
            out_color.xyz = vec3((int(tc0[0] * max_res[0] / 32.0)+int(tc0[1] * max_res[1] / 32.0))%2);
            max_res[0] = max(textureSize(detail_color, 0)[0], textureSize(detail_normal, 0)[0]);
            max_res[1] = max(textureSize(detail_color, 0)[1], textureSize(detail_normal, 0)[1]);
            out_color.xyz += vec3((int(detail_coords[0] * max_res[0] / 32.0)+int(detail_coords[1] * max_res[1] / 32.0))%2);
            out_color.xyz *= 0.5;
            out_color.a = 1.0;
            return;
        #endif

        #ifndef TERRAIN
            vec3 temp_scale;
            {
                mat3 temp_mat = mat3(model_mat[instance_id][0].xyz, model_mat[instance_id][1].xyz, model_mat[instance_id][2].xyz);
                temp_mat = inverse(model_rotation_mat[instance_id]) * temp_mat;
                temp_scale = vec3(temp_mat[0][0], temp_mat[1][1], temp_mat[2][2]);
            }
        #endif

        vec4 weight_map = GetWeightMap(weight_tex, base_tex_coords);
        #ifdef HEIGHT_BLEND
            float heights[4];
            for(int i=0; i<4; ++i){
                heights[i] = weight_map[i] + texture(detail_normal, vec3(detail_coords, i)).a;
            }
            for(int i=0; i<4; ++i){
                weight_map[i] = pow(heights[i], 16.0);
            }
        #endif
        float total = weight_map[0] + weight_map[1] + weight_map[2] + weight_map[3];
        weight_map /= total;
        CALC_DETAIL_FADE
        // Get normal
        float color_tint_alpha;
        mat3 ws_from_ns;

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

            {
                if(temp_scale[0] < 0.0){
                    base_tangent[0] *= -1.0;
                    base_bitangent[0] *= -1.0;
                    base_normal[0] *= -1.0;
                }
                if(temp_scale[1] < 0.0){
                    base_tangent[1] *= -1.0;
                    base_bitangent[1] *= -1.0;
                    base_normal[1] *= -1.0;
                }
                if(temp_scale[2] < 0.0){
                    base_tangent[2] *= -1.0;
                    base_bitangent[2] *= -1.0;
                    base_normal[2] *= -1.0;
                }
            }
        #endif

        ws_from_ns = mat3(base_tangent,
                          base_bitangent,
                          base_normal);


        vec3 ws_normal;
        vec4 normalmap;
        {
            #ifdef TERRAIN
                normalmap = vec4(0.0);
                if(detail_fade < 1.0){
                    for(int i=0; i<4; ++i){
                        if(weight_map[i] > 0.0){
                            normalmap += texture(detail_normal, vec3(detail_coords, i)) * weight_map[i] ;
                        }
                    }
                }
            #elif defined(AXIS_UV)
                normalmap = vec4(0.0);
                if(detail_fade < 1.0){
                    vec3 temp_pos = (inverse(model_mat[instance_id]) * vec4(world_vert, 1.0)).xyz;
                    temp_pos *= temp_scale;

                    vec2 temp_uv;
                    temp_uv = base_tex_coords;
                    temp_uv.x *= abs(dot(temp_scale, base_tangent));
                    temp_uv.y *= abs(dot(temp_scale, base_bitangent));
                    for(int i=0; i<4; ++i){
                        if(weight_map[i] > 0.0){
                            normalmap += texture(detail_normal, vec3(temp_uv, detail_normal_indices[i])) * weight_map[i];
                        }
                    }
                }
            #else
                normalmap = vec4(0.0);
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
            #ifdef NO_DETAILMAPS
                normalmap.xyz = vec3(0.0,0.0,1.0);
            #endif

            #ifdef TERRAIN
                ws_normal = ws_from_ns * normalmap.xyz;
            #else
                ws_normal = normalize(model_rotation_mat[instance_id] * (ws_from_ns * normalmap.xyz));
            #endif

        }

        // Get color
        vec4 base_color = texture(color_tex,base_tex_coords);
        #ifndef KEEP_SPEC
        base_color.a = 0.0;
        #endif
        vec4 tint;
        {
            vec4 average_color = avg_color0 * weight_map[0] +
                                 avg_color1 * weight_map[1] +
                                 avg_color2 * weight_map[2] +
                                 avg_color3 * weight_map[3];
            average_color = max(average_color, vec4(0.01));
            tint = base_color / average_color;
        #ifdef TERRAIN
            tint[3] = 1.0;
            base_color[3] = average_color[3];
        #endif
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
        #elif defined(AXIS_UV)
            colormap = vec4(0.0);
            if(detail_fade < 1.0){
                vec3 temp_pos = (inverse(model_mat[instance_id]) * vec4(world_vert, 1.0)).xyz;
                temp_pos *= temp_scale;

                vec2 temp_uv;
                temp_uv = base_tex_coords;
                temp_uv.x *= abs(dot(temp_scale, base_tangent));
                temp_uv.y *= abs(dot(temp_scale, base_bitangent));
                for(int i=0; i<4; ++i){
                    if(weight_map[i] > 0.0){
                        colormap += texture(detail_color, vec3(temp_uv, detail_color_indices[i])) * weight_map[i];
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
        colormap = mix(colormap * tint, base_color, detail_fade);
            #ifdef NO_DETAILMAPS
                colormap = base_color;
            #endif
        #ifndef TERRAIN
            colormap.xyz = mix(colormap.xyz,colormap.xyz*color_tint[instance_id].xyz,color_tint_alpha);
        #endif
        colormap.a = min(1.0, max(0.0,colormap.a));

            /*//colormap.xyz = mix(colormap.xyz, vec3(1.0,0.0,0.0), weight_map[1]);
            out_color.xyz = colormap.xyz;
            out_color.a = 1.0;
            return;
*/
        //colormap.a = mix(colormap.a, 1.0, weight_map[1]);
        /*float a = avg_color0.a;
        float b = texture(detail_color, vec3(detail_coords, detail_color_indices[0])).a;
        float val = mix(a, b, sin(time)*0.5+0.5);
        out_color.xyz = vec3(val);
        out_color.a = 1.0;
        return;*/
    #elif defined(ITEM)
        #ifdef TEXEL_DENSITY_VIZ
            int max_res[2];
            max_res[0] = max(textureSize(tex0,0)[0], textureSize(tex1,0)[0]);
            max_res[1] = max(textureSize(tex0,0)[1], textureSize(tex1,0)[1]);
            out_color.xyz = vec3((int(tc0[0] * max_res[0] / 32.0)+int(tc0[1] * max_res[1] / 32.0))%2);
            return;
        #endif

        float blood_amount, wetblood;
        vec4 blood_texel = textureLod(blood_tex, tc0, 0.0);
        blood_amount = min(blood_texel.r*5.0, 1.0);
        wetblood = max(0.0,blood_texel.g*1.4-0.4);

        vec4 normalmap = texture(tex1,tc0);
        #ifndef TANGENT
        vec3 os_normal = UnpackObjNormal(normalmap);
        vec3 ws_normal = model_rotation_mat * os_normal;
        #else
        vec3 unpacked_normal = UnpackTanNormal(normalmap);
        //vec3 world_dx = dFdx(world_vert);
        //vec3 world_dy = dFdy(world_vert);
        //vec3 ws_normal = normalize(cross(world_dx, world_dy));
        vec3 ws_normal = model_rotation_mat * frag_normal;
        mat3 cotangent_frame = cotangent_frame(ws_normal, normalize(world_vert - cam_pos), tc0);
        ws_normal = cotangent_frame * unpacked_normal;
        #endif
        ws_normal = normalize(ws_normal);
        colormap.xyz *= mix(vec3(1.0),color_tint,normalmap.a);
        //out_color.xyz = ws_normal;
        //out_color.a = 1.0;
        //return;

        normalmap.a = mix(normalmap.a, 1.0, blood_amount * 0.5);
        //CALC_BLOOD_ON_COLOR_MAP
    #elif defined(CHARACTER)
        #ifdef TEXEL_DENSITY_VIZ
            int max_res[2];
            max_res[0] = max(textureSize(color_tex,0)[0], textureSize(normal_tex,0)[0]);
            max_res[1] = max(textureSize(color_tex,0)[1], textureSize(normal_tex,0)[1]);
            out_color.xyz = vec3((int(morphed_tex_coord[0] * max_res[0] / 32.0)+int(morphed_tex_coord[1] * max_res[1] / 32.0))%2);
            return;
        #endif
        // Reconstruct third bone axis
        vec3 concat_bone3 = cross(concat_bone1, concat_bone2);

        float blood_amount, wetblood;
        vec4 blood_texel = textureLod(blood_tex, tex_coord, 0.0);
        ReadBloodTex(blood_tex, tex_coord, blood_amount, wetblood);

        vec2 tex_offset = vec2(pow(blood_texel.g, 8.0)) * 0.001;

        // Get world space normal
        vec4 normalmap = texture(normal_tex, tex_coord + tex_offset);
        vec3 unrigged_normal = UnpackObjNormal(normalmap);
        vec3 ws_normal = normalize(concat_bone1 * unrigged_normal.x +
                                   concat_bone2 * unrigged_normal.y +
                                   concat_bone3 * unrigged_normal.z);

        vec4 colormap = texture(color_tex, morphed_tex_coord + tex_offset);
        vec4 tintmap = texture(tint_map, morphed_tex_coord + tex_offset);
        float tint_total = max(1.0, tintmap[0] + tintmap[1] + tintmap[2] + tintmap[3]);
        tintmap /= tint_total;
        vec3 tint_mult = mix(vec3(0.0), tint_palette[0], tintmap.r) +
                         mix(vec3(0.0), tint_palette[1], tintmap.g) +
                         mix(vec3(0.0), tint_palette[2], tintmap.b) +
                         mix(vec3(0.0), tint_palette[3], tintmap.a) +
                         mix(vec3(0.0), tint_palette[4], 1.0-(tintmap.r+tintmap.g+tintmap.b+tintmap.a));
        colormap.xyz *= tint_mult;
        CALC_BLOOD_ON_COLOR_MAP
    #else
        #ifdef TEXEL_DENSITY_VIZ
            int max_res[2];
            max_res[0] = max(textureSize(tex0,0)[0], textureSize(tex1,0)[0]);
            max_res[1] = max(textureSize(tex0,0)[1], textureSize(tex1,0)[1]);
            out_color.xyz = vec3((int(tc0[0] * max_res[0] / 32.0)+int(tc0[1] * max_res[1] / 32.0))%2);
            out_color.a = 1.0;
            return;
        #endif
        #ifdef WATER
            vec3 base_ws_normal;
            vec3 base_water_offset;
            float water_depth = LinearizeDepth(gl_FragCoord.z);
        #endif
        #ifdef TANGENT
            vec3 ws_normal;
            vec4 normalmap = texture(normal_tex,tc0);
            {
                vec3 unpacked_normal = UnpackTanNormal(normalmap);
                #ifdef WATER
                    vec3 tint = color_tint[instance_id].xyz;
                    float sample_height[3];
                    float eps = 0.015 / tint[1];
                    vec2 water_uv = world_vert.xz * 0.2;
                    vec4 proj_test_point = (projection_view_mat * vec4(world_vert, 1.0));
                    proj_test_point /= proj_test_point.w;
                    proj_test_point.xy += vec2(1.0);
                    proj_test_point.xy *= 0.5;
                    float old_depth = LinearizeDepth(texture(tex18, proj_test_point.xy).r);
                    sample_height[0] = GetWaterHeight(water_uv, tint);
                    /*if(gl_FrontFacing){
                        water_depth += sample_height[0] * tint.x * 8.0 * (normalize(ws_vertex).y+1.0);
                        if(water_depth > old_depth){
                            discard;
                        }
                    }*/
                    /*out_color.xyz = vec3(sample_height[0]);
                    out_color.a = 1.0;
                    return;*/
                    sample_height[1] = GetWaterHeight(water_uv + vec2(eps, 0.0), tint);
                    sample_height[2] = GetWaterHeight(water_uv + vec2(0.0, eps), tint);
                    unpacked_normal.x = sample_height[1] - sample_height[0];
                    unpacked_normal.y = sample_height[2] - sample_height[0];
                    unpacked_normal.z = eps;

                    base_water_offset = normalize(unpacked_normal);

                    #ifdef ALBEDO_ONLY
                        if(base_water_offset[0] < 0.0 || base_water_offset[1] < 0.0){
                            discard;
                        } else {
                            out_color = vec4(vec3(0.4), 1.0);
                            return;
                        }
                    #endif

                    base_ws_normal = normalize((model_rotation_mat[instance_id] * (tan_to_obj * vec3(0,0,1))).xyz);
                #endif
                #ifdef MEGASCAN_TEST
                unpacked_normal.y *= -1.0;
                #endif
                ws_normal = normalize((model_rotation_mat[instance_id] * (tan_to_obj * unpacked_normal)).xyz);
                #ifdef WATER
                    //ws_normal = vec3(0,1,0);
                    //ws_normal = normalize(vec3(unpacked_normal.x, unpacked_normal.z, unpacked_normal.y));
                #endif
            }
        #else
            vec4 normalmap = texture(tex1,tc0);
            vec3 os_normal = UnpackObjNormal(normalmap);
            vec3 ws_normal = model_rotation_mat[instance_id] * os_normal;
        #endif
        #ifndef WATER
            colormap.xyz *= color_tint[instance_id].xyz;
        #endif
    #endif
#ifndef PLANT
#ifdef ALPHA
    float spec_amount = normalmap.a;
#else
    float spec_amount = colormap.a;
    #if !defined(CHARACTER) && !defined(ITEM) && !defined(METALNESS_PBR)
        spec_amount = GammaCorrectFloat(spec_amount);
    #endif
#endif

#endif

    #ifdef CHARACTER
        spec_amount = GammaCorrectFloat(spec_amount);
        float roughness = pow(1.0 - spec_amount, 20.0);
    #elif defined(ITEM)
        float roughness = normalmap.a;
    #elif defined(METALNESS_PBR)
        float roughness = (1.0 - normalmap.a);
    #elif defined(MEGASCAN_TEST)
        float roughness = pow(normalmap.a, 0.25);
        spec_amount = 0.0;
    #elif defined(TERRAIN)
        #ifdef SNOWY
           float old_spec = spec_amount;
            float roughness = 0.99;
            roughness = mix(roughness, 0.7, weight_map[1]);
            roughness = mix(roughness, 0.2, weight_map[0]);
            spec_amount = mix(spec_amount, 0.4, weight_map[1]);
            spec_amount = mix(spec_amount, 0.5, weight_map[0]);
            colormap.xyz *= mix(1.0, 0.25, weight_map[2]);
            colormap.xyz *= mix(1.0, 0.5, weight_map[3]);
            colormap.xyz *= mix(1.0, 0.8, weight_map[0]);
        #else
            float roughness = 0.99;
        #endif
        /*out_color.xyz = vec3(spec_amount);//colormap.a);
        out_color.a = 1.0;
        return;*/
    #elif defined(KEEP_SPEC)
        float roughness = (1.0 - normalmap.a);
    #else
        float roughness = mix(0.7, 1.0, pow((colormap.x + colormap.y + colormap.z) / 3.0, 0.01));
    #endif



    //out_color = vec4(vec3(roughness), 1.0);
    //return;

    //out_color = vec4(vec3(ws_normal), 1.0);
    //return;

// wet character
#ifdef CHARACTER
    float wet = 0.0;
    if(blood_texel.g < 1.0){
        wet = blood_texel.g;//pow(max(blood_texel.g-0.2, 0.0)/0.8, 0.5);
        #ifdef RAINY
            wet = 1.0;
        #else
            colormap.xyz *= mix(1.0, 0.5, wet);
        #endif
        roughness = mix(roughness, 0.3, wet);
    }
#endif

    float ambient_mult = 1.0;
    float env_ambient_mult = 1.0;

    vec3 flame_final_color = vec3(0.0, 0.0, 0.0);
    float flame_final_contrib = 0.0;

#if !defined(NO_DECALS)
#ifdef PLANT
    float spec_amount = 0.0;
#endif
    #ifdef INSTANCED_MESH
        if(color_tint[instance_id][3] != -1.0)
    #endif
    { 
        CalculateDecals(colormap, ws_normal, spec_amount, roughness, ambient_mult, env_ambient_mult, world_vert, time, decal_val, flame_final_color, flame_final_contrib);
    }
#endif

    #ifdef ALBEDO_ONLY
        out_color = vec4(colormap.xyz,1.0);
        return;
    #endif
    vec3 shadow_tex = vec3(1.0);

    #ifdef SIMPLE_SHADOW
        {
            vec3 X = dFdx(world_vert);
            vec3 Y = dFdy(world_vert);
            vec3 norm = normalize(cross(X, Y));
            float slope_dot = dot(norm, ws_light);
            shadow_tex.r = GetCascadeShadow(tex4, shadow_coords, length(ws_vertex), slope_dot);
        }
        shadow_tex.r *= ambient_mult;
    #else
        shadow_tex.r = GetCascadeShadow(tex4, shadow_coords, length(ws_vertex));
    #endif
    CALC_DIRECT_DIFFUSE_COLOR

    bool use_amb_cube = false;
    bool use_3d_tex = false;
    vec3 ambient_cube_color[6];
    for(int i=0; i<6; ++i){
        ambient_cube_color[i] = vec3(0.0);
    }
    vec3 ambient_color = vec3(0.0);

#ifdef CAN_USE_3D_TEX
    for(int i=0; i<light_volume_num; ++i){
        //vec3 temp = (world_vert - reflection_capture_pos[i]) / reflection_capture_scale[i];
        vec3 temp = (light_volume_matrix_inverse[i] * vec4(world_vert, 1.0)).xyz;
        vec3 scale_vec = (light_volume_matrix[i] * vec4(1.0, 1.0, 1.0, 0.0)).xyz;
        float scale = dot(scale_vec, scale_vec);
        float val = dot(temp, temp);
        if(temp[0] <= 1.0 && temp[0] >= -1.0 &&
           temp[1] <= 1.0 && temp[1] >= -1.0 &&
           temp[2] <= 1.0 && temp[2] >= -1.0)
        {
            vec3 tex_3d = temp * 0.5 + vec3(0.5);
            vec4 test = texture(tex16, vec3((tex_3d[0] + 0)/ 6.0, tex_3d[1], tex_3d[2]));
            if(test.a >= 1.0 && tex_3d[0] > 0.01 && tex_3d[0] < 0.99){
                for(int j=1; j<6; ++j){
                    ambient_cube_color[j] = texture(tex16, vec3((tex_3d[0] + j)/ 6.0, tex_3d[1], tex_3d[2])).xyz;
                }
                ambient_cube_color[0] = test.xyz;
                ambient_color = SampleAmbientCube(ambient_cube_color, ws_normal);
                use_3d_tex = true;
            }
        }
    }
#endif

    if(!use_3d_tex){
        use_amb_cube = false;
        #ifdef CAN_USE_LIGHT_PROBES
            uint guess = 0u;
            int grid_coord[3];
            bool in_grid = true;
            for(int i=0; i<3; ++i){
                if(world_vert[i] > grid_bounds_max[i] || world_vert[i] < grid_bounds_min[i]){
                    in_grid = false;
                    break;
                }
            }
            if(in_grid){
                grid_coord[0] = int((world_vert[0] - grid_bounds_min[0]) / (grid_bounds_max[0] - grid_bounds_min[0]) * float(subdivisions_x));
                grid_coord[1] = int((world_vert[1] - grid_bounds_min[1]) / (grid_bounds_max[1] - grid_bounds_min[1]) * float(subdivisions_y));
                grid_coord[2] = int((world_vert[2] - grid_bounds_min[2]) / (grid_bounds_max[2] - grid_bounds_min[2]) * float(subdivisions_z));
                int cell_id = ((grid_coord[0] * subdivisions_y) + grid_coord[1])*subdivisions_z + grid_coord[2];
                uvec4 data = texelFetch(ambient_grid_data, cell_id/4);
                guess = data[cell_id%4];
                use_amb_cube = GetAmbientCube(world_vert, num_tetrahedra, ambient_color_buffer, ambient_cube_color, guess);
            }

            ambient_color = SampleAmbientCube(ambient_cube_color, ws_normal);
        #endif
        if(!use_amb_cube){
            ambient_color = LookupCubemapSimpleLod(ws_normal, spec_cubemap, 5.0);
        }
    }


    diffuse_color += ambient_color * GetAmbientContrib(shadow_tex.g) * ambient_mult * env_ambient_mult;
    #if defined(PLANT)
        vec3 spec_color = vec3(0.0);
        vec3 translucent_lighting = GetDirectColor(shadow_tex.r) * primary_light_color.a;
        translucent_lighting += ambient_color * GetAmbientContrib(shadow_tex.g) * ambient_mult * env_ambient_mult;
        translucent_lighting *= GammaCorrectFloat(0.6);
        vec3 translucent_map = texture(translucency_tex, frag_tex_coords).xyz;
        /*
        roughness = 0.0;
        float spec_pow = mix(1200.0, 20.0, pow(roughness,2.0));
        float reflection_roughness = roughness;
        roughness = mix(0.00001, 0.9, roughness);
        float spec = GetSpecContrib(ws_light, ws_normal, ws_vertex, shadow_tex.r,spec_pow);
        spec *= 100.0* mix(1.0, 0.01, roughness);
        spec_color = primary_light_color.xyz * vec3(spec);
        vec3 spec_map_vec = normalize(reflect(ws_vertex,ws_normal));


        vec3 reflection_color = LookUpReflectionShapes(tex19, world_vert, spec_map_vec, reflection_roughness * 3.0);
        spec_color += reflection_color;

        float spec_amount = 0.0;
        float glancing = max(0.0, min(1.0, 1.0 + dot(normalize(ws_vertex), ws_normal)));
        float base_reflectivity = spec_amount;
        float fresnel = pow(glancing, 4.0) * (1.0 - roughness) * 0.05;
        float spec_val = mix(base_reflectivity, 1.0, fresnel);
        spec_amount = spec_val;*/

        CalculateLightContrib(diffuse_color, spec_color, ws_vertex, world_vert, ws_normal, roughness, light_val, ambient_mult * env_ambient_mult);
        diffuse_color *= colormap.xyz;
        diffuse_color += translucent_lighting * translucent_map;
        diffuse_color *= color_tint[instance_id].xyz;

        //vec3 color = mix(diffuse_color, spec_color, spec_amount);
        vec3 color = diffuse_color;
    #elif defined(WATERFALL)
        vec3 spec_color = vec3(0.0);

        CalculateLightContrib(diffuse_color, spec_color, ws_vertex, world_vert, ws_normal, roughness, light_val, ambient_mult * env_ambient_mult);
        vec3 color = diffuse_color;
        diffuse_color = GetDirectColor(shadow_tex.r) + GetAmbientColor(world_vert, normalize(-ws_vertex)) * ambient_mult * env_ambient_mult;
        color = diffuse_color * 0.5;
    #else
        vec3 spec_color = vec3(0.0);
        #ifdef CHARACTER
            float reflection_roughness = roughness;
            roughness = mix(0.00001, 0.9, roughness);

            float spec_pow = 2/pow(max(0.3, roughness), 4.0) - 2.0;
            float spec = GetSpecContrib(ws_light, ws_normal, ws_vertex, shadow_tex.r,spec_pow);
            spec *= (spec_pow + 8) / (8 * 3.141592);
            spec_color = primary_light_color.xyz * vec3(spec);

            vec3 spec_map_vec = reflect(ws_vertex,ws_normal);

            vec3 reflection_color = LookUpReflectionShapes(tex19, world_vert, normalize(spec_map_vec), reflection_roughness*3.0);
            spec_color += reflection_color * ambient_mult * env_ambient_mult;

            float glancing = max(0.0, min(1.0, 1.0 + dot(normalize(ws_vertex), ws_normal)));
            float base_reflectivity = mix(spec_amount * 0.1, 0.03, wet);
            float fresnel = pow(glancing, 6.0) * (1.0 - roughness * 0.5);
            fresnel = mix(fresnel, pow(glancing, 5.0), wet);
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
        /*#elif defined(ITEM)
            float reflection_roughness = roughness;
            roughness = mix(0.00001, 0.9, roughness);
            float spec_pow = mix(1200.0, 20.0, pow(roughness,2.0));
            float spec = GetSpecContrib(ws_light, ws_normal, ws_vertex, shadow_tex.r,spec_pow);
            spec *= 20.0 * mix(1.0, 0.01, roughness);
            spec_color = primary_light_color.xyz * vec3(spec);
            vec3 spec_map_vec = reflect(ws_vertex,ws_normal);

            vec3 reflection_color = LookUpReflectionShapes(tex19, world_vert, spec_map_vec, reflection_roughness * 3.0);
            spec_color += reflection_color;
            float glancing = max(0.0, min(1.0, 1.0 + dot(normalize(ws_vertex), ws_normal)));
            float base_reflectivity = spec_amount;
            float fresnel = pow(glancing, 6.0) * mix(0.7, 1.0, blood_amount);
            float spec_val = mix(base_reflectivity, 1.0, fresnel);
            spec_amount = spec_val;*/
        #elif defined(METALNESS_PBR) || defined(ITEM) || defined(KEEP_SPEC) || defined(TERRAIN)
            #if defined(RAINY)
                #ifndef TERRAIN
                    roughness *= 0.3;
                    spec_amount = mix(spec_amount, 1.0, 0.1);
                #else 
                    roughness *= 0.6;
                #endif
            #endif
            #ifdef ITEM
                spec_amount = GammaCorrectFloat(spec_amount);

                colormap.xyz = mix(colormap.xyz, blood_tint * 0.4, blood_amount);
                spec_amount = mix(spec_amount, 0.0, blood_amount);
                roughness = mix(roughness, 0.0, blood_amount * 0.2);
            #endif
            float reflection_roughness = roughness;
            roughness = mix(0.00001, 0.9, roughness);
            float metalness = pow(spec_amount, 0.3);
            /*#if defined(ITEM)
                spec_amount = mix((1.0 - roughness) * 0.15, 1.0, metalness);
            #endif*/
            float spec_pow = 2/pow(max(0.25, roughness), 4.0) - 2.0;
            float spec = GetSpecContrib(ws_light, ws_normal, ws_vertex, shadow_tex.r,spec_pow);
            spec *= (spec_pow + 8) / (8 * 3.141592);
            spec_color = primary_light_color.xyz * vec3(spec);
            vec3 spec_map_vec = normalize(reflect(ws_vertex,ws_normal));


            vec3 reflection_color = LookUpReflectionShapes(tex19, world_vert, spec_map_vec, min(2.5, reflection_roughness * 5.0));
            // Disabled in case ambient_cube_color is not initialized
            //reflection_color = mix(reflection_color, SampleAmbientCube(ambient_cube_color, spec_map_vec), max(0.0, reflection_roughness * 2.0 - 1.0));
            spec_color += reflection_color * ambient_mult * env_ambient_mult;

            float glancing = max(0.0, min(1.0, 1.0 + dot(normalize(ws_vertex), ws_normal)));
            float base_reflectivity = spec_amount;
            float fresnel = pow(glancing, 4.0) * (1.0 - roughness) * mix(0.5, 1.0, metalness);
            float spec_val = mix(base_reflectivity, 1.0, fresnel);
            spec_amount = spec_val;
            //out_color.xyz = vec3(colormap.xyz);
            //out_color.a = 1.0;
            //return;
        #else // Standard envobject
            #if defined(RAINY)
                roughness *= 0.5;
                spec_amount = mix(spec_amount, 1.0, 0.01);
            #endif
            #ifdef WATER
                roughness = color_tint[instance_id].x * 0.3;
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
            float reflection_roughness = roughness;
            roughness = mix(0.00001, 0.9, roughness);
            float spec = GetSpecContrib(ws_light, ws_normal, ws_vertex, shadow_tex.r,spec_pow);
            spec *= 100.0* mix(1.0, 0.01, roughness);
            spec_color = primary_light_color.xyz * vec3(spec);
            vec3 spec_map_vec = normalize(reflect(ws_vertex,ws_normal));


            vec3 reflection_color = LookUpReflectionShapes(tex19, world_vert, spec_map_vec, reflection_roughness * 3.0);
            spec_color += reflection_color * ambient_mult * env_ambient_mult;

            float glancing = max(0.0, min(1.0, 1.0 + dot(normalize(ws_vertex), ws_normal)));
            float base_reflectivity = spec_amount;
            #ifdef WATER
                float fresnel;
                if(!gl_FrontFacing){
                    fresnel = pow(glancing, 0.2);
                } else {
                    fresnel = pow(glancing, 3.0);
                }
                float spec_val = mix(base_reflectivity, 1.0, fresnel);
                spec_amount = 1.0;
                //out_color.xyz = reflection_color;
                //return;
            #else
                float fresnel = pow(glancing, 4.0) * (1.0 - roughness) * 0.05;
                float spec_val = mix(base_reflectivity, 1.0, fresnel);
                spec_amount = spec_val;
            #endif
        #endif
        #ifndef WATER
            #if defined(METALNESS_PBR)
                colormap.xyz *= color_tint[instance_id].xyz;
            #elif !defined(ALPHA) && !defined(DETAILMAP4) && !defined(CHARACTER) && !defined(ITEM)
                colormap.xyz *= mix(vec3(1.0),color_tint[instance_id].xyz,normalmap.a);
            #endif
        #endif

        CalculateLightContrib(diffuse_color, spec_color, ws_vertex, world_vert, ws_normal, roughness, light_val, ambient_mult);
        #if defined(METALNESS_PBR) || defined(ITEM)
            spec_color = mix(spec_color, spec_color * colormap.xyz, metalness);
        #endif
        vec3 color = mix(diffuse_color * colormap.xyz, spec_color, spec_amount);
    #endif
    #ifdef CHARACTER
        // Add rim highlight
        vec3 view = normalize(ws_vertex*-1.0);
        float back_lit = max(0.0,dot(normalize(ws_vertex),ws_light));
        float rim_lit = max(0.0,(1.0-dot(view,ws_normal)));
        rim_lit *= pow((dot(ws_light,ws_normal)+1.0)*0.5,0.5);
        color += vec3(back_lit*rim_lit) * (1.0 - blood_amount) * normalmap.a * primary_light_color.xyz * primary_light_color.a * shadow_tex.r * mix(vec3(1.0), colormap.xyz, 0.8);
    #endif
    //CALC_HAZE
    //AddHaze(color, ws_vertex, spec_cubemap);


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

#ifdef WATER // Handle water transparency, refraction, fog
    vec4 proj_test_point = (projection_view_mat * vec4(world_vert, 1.0));
    proj_test_point /= proj_test_point.w;
    proj_test_point.xy += vec2(1.0);
    proj_test_point.xy *= 0.5;
    // proj_test_point is now world position in screen space
    float old_depth = LinearizeDepth(texture(tex18, proj_test_point.xy).r) - water_depth;
    // old_depth is now the amount of water we are looking through
    const float refract_mult = 1.0;
    vec2 distort = vec2(base_water_offset.xy);
    distort *= max(0.0, min(old_depth, 1.0) ); // Scale refraction based on depth
    distort /= (water_depth * 1.0 + 0.3); // Reduce refraction based on camera distance from water
    distort *= refract_mult; // Arbitrarily control refraction amount
    proj_test_point.xy += distort;
    float depth = LinearizeDepth(texture(tex18, proj_test_point.xy).r) - water_depth;
    { // Prevent objects above the water from bleeding into the refraction
        if(depth < 0.25){
            proj_test_point.xy -= distort * 0.5;
            depth = LinearizeDepth(texture(tex18, proj_test_point.xy).r) - water_depth;
        }
        if(depth < 0.125){
            proj_test_point.xy -= distort * 0.5;
            depth = LinearizeDepth(texture(tex18, proj_test_point.xy).r) - water_depth;
        }
    }
    vec3 under_water = texture(tex17, proj_test_point.xy).xyz; // color texture from opaque objects
    if(gl_FrontFacing){ // Only add foam and fog if water is viewed from outside of water
        //#if !defined(NO_DECALS)
            under_water = mix(under_water, diffuse_color * colormap.xyz, max(0.0, min(1.0, pow(depth * 0.3, 0.2)))); // Add fog
        //#endif
        float min_depth = -0.3;
        float max_depth = 0.1;
        float foam_detail = texture(tex0, (world_vert.xz + normalize(vec2(0.0, 1.0))*time*water_speed)*5.0).y + 
                            texture(tex0, (world_vert.xz * 0.5 + normalize(vec2(1.0, 0.0))*time*water_speed)*7.0).y;
        foam_detail *= 0.5;
        foam_detail = min(1.0, foam_detail+0.3);
        if(depth < max_depth && depth > min_depth && abs(old_depth - depth) < 0.1){ // Blend in foam
            if(depth > 0.0){
                under_water = mix(diffuse_color * 0.3, under_water, min(1.0, depth/max_depth + foam_detail));
            } else {
                under_water = mix(diffuse_color * 0.3, under_water, depth/-min_depth);
            }
        }
        color.xyz = mix(under_water, color.xyz, spec_val);
        //out_color.xyz = vec3(old_depth);
        //out_color.xyz = vec3(max(0.0, min(1.0, pow(depth * 0.1,0.8))));
    } else {
        color.xyz *= 0.1;
        color.xyz = mix(under_water, color.xyz, spec_val);
    }
#endif  // WATER

    #ifdef SNOWY
    // Snow sparkle
        if(old_spec > 0.4 && sin((world_vert.x - cam_pos.x * 0.5)*20.0) > 0.0 && sin((world_vert.z - cam_pos.z * 0.5)*13.0) > 0.0 && sin((world_vert.y - cam_pos.y * 0.5)*15.0) > 0.0){
            color.xyz += reflection_color * 1.5;//vec3(1.0);
            color.xyz += GetDirectColor(shadow_tex.r) * primary_light_color.a * 1.5;//vec3(1.0);
        }
    #endif


    float haze_amount = GetHazeAmount(ws_vertex, haze_mult);
    vec3 fog_color;
    if(use_3d_tex){
        fog_color = SampleAmbientCube(ambient_cube_color, normalize(ws_vertex) * -1.0);
        /*
        #ifdef CAN_USE_3D_TEX
        vec3 dir = normalize(ws_vertex) * -1.0;
        vec3 sample_color;
        fog_color = vec3(0.0);
        for(int i=0; i<10; ++i){
            Query3DTexture(sample_color, mix(cam_pos, world_vert, (i+1)/10.0), dir);
            fog_color += sample_color;
        }
        fog_color /= 10.0;
        #endif*/
    } else if(!use_amb_cube){
        fog_color = textureLod(spec_cubemap,ws_vertex ,5.0).xyz;
    } else {
        fog_color = SampleAmbientCube(ambient_cube_color, ws_vertex * -1.0);
    }

    #if !defined(TERRAIN) && !defined(CHARACTER) && !defined(ITEM)
    #ifdef EMISSIVE
    //if(color_tint[instance_id].r > 1.0){
        color.xyz = colormap.xyz * color_tint[instance_id].xyz;
    //}
    #endif
    #endif

    color = mix(color, fog_color, haze_amount);


    #ifdef ALPHA
        out_color = vec4(color,colormap.a);
    #elif defined(WATER)
        out_color = vec4(color,spec_val);
    #else
        out_color = vec4(color,1.0);
    #endif

   #ifndef NO_VELOCITY_BUF

    #ifdef CHARACTER
        out_vel.xyz = vel;
        out_vel.a = 1.0;
    #elif defined(ITEM)
        out_vel.xyz = vel * 60.0;
        out_vel.a = 1.0;
    #else
        out_vel = vec4(0.0);
    #endif

   #endif  // NO_VELOCITY_BUF

// Screen space reflection test
//#define SCREEN_SPACE_REFLECTION
#if defined(SCREEN_SPACE_REFLECTION) && !defined(DEPTH_ONLY)
   #if defined(WATER)
    {

    vec3 spec_map_vec = normalize(reflect(ws_vertex,ws_normal));
    //out_color.xyz = vec3(0.0);
    bool done = false;
    bool good = false;
    int count = 0;
    vec4 proj_test_point;
    float step_size = 0.01;
    vec3 march = world_vert;
    float screen_step_mult = abs(dot(spec_map_vec, normalize(ws_vertex)));
    float random = rand(gl_FragCoord.xy);

    vec3 test_point = march;
        proj_test_point = (projection_view_mat * vec4(test_point, 1.0));
    proj_test_point /= proj_test_point.w;
    proj_test_point.xy += vec2(1.0);
    proj_test_point.xy *= 0.5;
    vec2 a = proj_test_point.xy;

    test_point += spec_map_vec * 0.1;
        proj_test_point = (projection_view_mat * vec4(test_point, 1.0));
    proj_test_point /= proj_test_point.w;
    proj_test_point.xy += vec2(1.0);
    proj_test_point.xy *= 0.5;
    vec2 b = proj_test_point.xy;

    screen_step_mult = length(a - b) * 10.0;
    step_size /= screen_step_mult;

    while(!done){
        march += spec_map_vec * step_size;
        test_point = march + (spec_map_vec * step_size * random * 1.5);
            proj_test_point = (projection_view_mat * vec4(test_point, 1.0));
        proj_test_point /= proj_test_point.w;
        proj_test_point.xy += vec2(1.0);
        proj_test_point.xy *= 0.5;
        proj_test_point.z = (proj_test_point.z + 1.0) * 0.5;
        proj_test_point.z = LinearizeDepth(proj_test_point.z);
        float depth = LinearizeDepth(texture(tex18, proj_test_point.xy).r);
        ++count;
        if(count > 20 || proj_test_point.x < 0.0 || proj_test_point.y < 0.0 || proj_test_point.x > 1.0 || proj_test_point.y > 1.0){
            done = true;
        }
        if( depth < proj_test_point.z && abs(depth - proj_test_point.z) < step_size * 2.0){
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
    reflect_amount = 1.0;
    float screen_space_amount = 0.0;
    //good = false;
    vec3 reflect_color;
    if(good){
        /*proj_test_point = (prev_projection_view_mat * vec4(test_point, 1.0));
        proj_test_point /= proj_test_point.w;
        proj_test_point.xy += vec2(1.0);
        proj_test_point.xy *= 0.5;
        proj_test_point.z = (proj_test_point.z + 1.0) * 0.5;
        proj_test_point.z = LinearizeDepth(proj_test_point.z);*/

        reflect_color = texture(tex17, proj_test_point.xy).xyz;
        screen_space_amount = 1.0;
        screen_space_amount *= min(1.0, max(0.0, pow((0.5 - abs(proj_test_point.x-0.5))*2.0, 1.0))*8.0);
        screen_space_amount *= min(1.0, max(0.0, pow((0.5 - abs(proj_test_point.y-0.5))*2.0, 1.0))*8.0);
    }
    reflect_color = mix(reflect_color,
                        LookUpReflectionShapes(tex19, world_vert, spec_map_vec, 0.0/*roughness * 3.0*/),
                        1.0 - screen_space_amount);

    out_color.xyz = mix(out_color.xyz, reflect_color, reflect_amount);
    //out_color.xyz = vec3(reflect_amount);
    //out_color.xyz = vec3(abs(depth - proj_test_point.z) * 0.1);
    }
    #endif  // WATER
    #endif  // defined(SCREEN_SPACE_REFLECTION) && !defined(DEPTH_ONLY)

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

    #if defined(FIRE_DECAL_ENABLED) && !defined(NO_DECALS)
        out_color.xyz = mix(out_color.xyz, flame_final_color, flame_final_contrib);
    #endif // FIRE_DECAL_ENABLED

    #ifdef CHARACTER
        vec3 temp = orig_vert * 2.0;

        int burn_int = int(blood_texel.b * 255.0);
        if(burn_int > 0){
            int on_fire = 0;
            if(burn_int > 127){
                on_fire = 1;
            }
            int burnt_amount = burn_int - on_fire * 128;

            float burned = abs(fractal(temp.xz*11.0)+fractal(temp.xy*7.0)+fractal(temp.yz*5.0));
            out_color.xyz *= mix(1.0, burned*0.3, float(burnt_amount)/127.0);
            if(on_fire == 1){
                float fade = 0.4;// max(0.0, (0.5 - length(temp))*8.0)* max(0.0, fractal(temp.xz*7.0)+0.3);
                float fire = abs(fractal(temp.xz*11.0+time*3.0)+fractal(temp.xy*7.0-time*3.0)+fractal(temp.yz*5.0-time*3.0));
                float flame_amount = max(0.0, 0.5 - (fire*0.5 / pow(fade, 2.0))) * 2.0;
                //fade = pow(abs(fractal(temp.xz*3.0+time)+fractal(temp.xy*2.0-time)+fractal(temp.yz*3.0-time))*0.9, 4.0);
                flame_amount += pow(max(0.0, 0.7-fire), 2.0);
                float opac = mix(pow(1.0-abs(dot(ws_normal, -normalize(ws_vertex))), 12.0), 1.0, pow((ws_normal.y+1.0)/2.0, 20.0));
                out_color.xyz = mix(out_color.xyz,
                                vec3(1.5 * pow(flame_amount, 0.7), 0.5 * flame_amount, 0.1 * pow(flame_amount, 2.0)),
                                opac);

#ifndef NO_VELOCITY_BUF

                out_vel.xyz += vec3(0.0, fire, 0.0) * 10.0 * on_fire;

#endif  // NO_VELOCITY_BUF

            }
        }
    #endif
/*
    #ifdef CHARACTER
        float dark_world_amount = sin(time)*0.5+0.5;
        out_color.xyz = mix(out_color.xyz, vec3(mix(1.0,0.8, dark_world_amount) - dot(ws_normal, -normalize(ws_vertex))),dark_world_amount);
        out_color.a = 1.0;
    #endif*/

    #ifdef CHARACTER
        out_color.a = alpha;
    #endif

    #endif // DEPTH_ONLY
    #endif // PARTICLE

/*
    #if !defined(DEPTH_ONLY) && !defined(PLANT)
      //out_color.xyz = vec3(blood_texel.b);
      out_color.xyz = LookUpReflectionShapes(tex19, world_vert, normalize(ws_vertex), 0.0);
    #endif*/

    //out_color.xyz = colormap.xyz; // albedo
    //out_color.xyz = vec3(colormap.a); // metalness
}
