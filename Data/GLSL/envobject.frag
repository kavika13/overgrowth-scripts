#version 150
#include "object_frag150.glsl"
#include "object_shared150.glsl"
#include "ambient_tet_mesh.glsl"
#include "decals.glsl"

UNIFORM_COMMON_TEXTURES
#ifdef PLANT
UNIFORM_TRANSLUCENCY_TEXTURE
#endif
UNIFORM_LIGHT_DIR
UNIFORM_EXTRA_AO
#ifdef DETAILMAP4
UNIFORM_DETAIL4_TEXTURES
UNIFORM_AVG_COLOR4
#endif
#ifdef TERRAIN
    uniform sampler2D tex14;
    #define warp_tex tex14
#endif

//#define EMISSIVE

#ifndef TERRAIN
const int kMaxInstances = 100;

uniform InstanceInfo {
    mat4 model_mat[kMaxInstances];
    mat3 model_rotation_mat[kMaxInstances];
    vec4 color_tint[kMaxInstances];
    vec4 detail_scale[kMaxInstances];
};
#endif

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

#ifdef TERRAIN
in vec3 frag_tangent;
in float alpha;
in vec4 frag_tex_coords;
in vec3 world_vert;
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

out vec4 out_color;

#define shadow_tex_coords tc1
#define tc0 frag_tex_coords

void main() {   
    #ifdef TERRAIN
        vec2 test_offset = (texture(warp_tex,frag_tex_coords.xy*200.0).xy-0.5)*0.001;
        vec2 base_tex_coords = frag_tex_coords.xy + test_offset;
        vec2 detail_coords = frag_tex_coords.zw;
    #else
        vec2 base_tex_coords = frag_tex_coords;
    #endif
    vec4 colormap = texture(tex0, base_tex_coords);

	vec3 ws_vertex;
	vec4 shadow_coords[4];

	#ifndef DEPTH_ONLY
        ws_vertex = world_vert - cam_pos;
        shadow_coords[0] = shadow_matrix[0] * vec4(world_vert, 1.0);
        shadow_coords[1] = shadow_matrix[1] * vec4(world_vert, 1.0);
        shadow_coords[2] = shadow_matrix[2] * vec4(world_vert, 1.0);
        shadow_coords[3] = shadow_matrix[3] * vec4(world_vert, 1.0);
    #endif

    #if defined(ALPHA) && !defined(ALPHA_TO_COVERAGE)
        if(colormap.a < 0.5){
            discard;
        }
    #endif
    #ifdef DEPTH_ONLY
    #ifdef ALPHA
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
                vec4 normalmap = (texture(detail_normal, vec3(detail_coords, 0)) * weight_map[0] +
                                  texture(detail_normal, vec3(detail_coords, 1)) * weight_map[1] +
                                  texture(detail_normal, vec3(detail_coords, 2)) * weight_map[2] +
                                  texture(detail_normal, vec3(detail_coords, 3)) * weight_map[3]);
            #else
                vec4 normalmap = (texture(detail_normal, vec3(base_tex_coords*detail_scale[instance_id][0], detail_normal_indices.x)) * weight_map[0] +
                                  texture(detail_normal, vec3(base_tex_coords*detail_scale[instance_id][1], detail_normal_indices.y)) * weight_map[1] +
                                  texture(detail_normal, vec3(base_tex_coords*detail_scale[instance_id][2], detail_normal_indices.z)) * weight_map[2] +
                                  texture(detail_normal, vec3(base_tex_coords*detail_scale[instance_id][3], detail_normal_indices.w)) * weight_map[3]);
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
            colormap = texture(detail_color, vec3(detail_coords, detail_color_indices.x)) * weight_map[0] +
                       texture(detail_color, vec3(detail_coords, detail_color_indices.y)) * weight_map[1] +
                       texture(detail_color, vec3(detail_coords, detail_color_indices.z)) * weight_map[2] +
                       texture(detail_color, vec3(detail_coords, detail_color_indices.w)) * weight_map[3];
        #else
            colormap = texture(detail_color, vec3(base_tex_coords*detail_scale[instance_id][0], detail_color_indices.x)) * weight_map[0] +
                        texture(detail_color, vec3(base_tex_coords*detail_scale[instance_id][1], detail_color_indices.y)) * weight_map[1] +
                        texture(detail_color, vec3(base_tex_coords*detail_scale[instance_id][2], detail_color_indices.z)) * weight_map[2] +
                        texture(detail_color, vec3(base_tex_coords*detail_scale[instance_id][3], detail_color_indices.w)) * weight_map[3];
        #endif
        colormap.xyz = mix(colormap.xyz * tint, base_color, detail_fade);
        #ifndef TERRAIN
            colormap.xyz = mix(colormap.xyz,colormap.xyz*color_tint[instance_id].xyz,color_tint_alpha);
        #endif
        colormap.a = max(0.0,colormap.a); 
    #else
        #ifdef TANGENT
            vec3 ws_normal;
            vec4 normalmap = texture(normal_tex,tc0);
            {
                vec3 unpacked_normal = UnpackTanNormal(normalmap);
                ws_normal = normalize((model_mat[instance_id] * vec4((tan_to_obj * unpacked_normal),0.0)).xyz);
            }
        #else 
            vec4 normalmap = texture(tex1,tc0);
            vec3 os_normal = UnpackObjNormal(normalmap);
            vec3 ws_normal = model_rotation_mat[instance_id] * os_normal;
        #endif
    #endif

    CalculateDecals(colormap, ws_normal, world_vert);

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
    if(!use_amb_cube){
        ambient_color = LookupCubemapSimpleLod(ws_normal, spec_cubemap, 5.0);
    } else {
        ambient_color = SampleAmbientCube(ambient_cube_color, ws_normal);
    }
    diffuse_color += ambient_color * GetAmbientContrib(shadow_tex.g);
    #ifdef PLANT
        vec3 translucent_lighting = GetDirectColor(shadow_tex.r) * primary_light_color.a; 
        translucent_lighting += ambient_color; 
        translucent_lighting *= GammaCorrectFloat(0.6);
        vec3 color = diffuse_color * colormap.xyz  * mix(vec3(1.0),color_tint[instance_id].xyz,normalmap.a);
        vec3 translucent_map = texture(translucency_tex, frag_tex_coords).xyz;
        color += translucent_lighting * translucent_map;
    #else
        vec3 spec_color = vec3(0.0);
        float amb_mult = 0.5;
        {
            vec3 H = normalize(normalize(ws_vertex*-1.0) + normalize(ws_light));
            float spec = GetSpecContrib(ws_light, ws_normal, ws_vertex, shadow_tex.r);
            spec_color = primary_light_color.xyz * vec3(spec);
            vec3 spec_map_vec = reflect(ws_vertex,ws_normal);
            if(!use_amb_cube){
                spec_color += LookupCubemapSimple(spec_map_vec, spec_cubemap) * amb_mult *
                              GetAmbientContrib(shadow_tex.g);
            } else {
                spec_color += SampleAmbientCube(ambient_cube_color, spec_map_vec) * amb_mult *
                              GetAmbientContrib(shadow_tex.g);
            }
        }
        #ifdef ALPHA
            float spec_amount = normalmap.a;
        #else
            float spec_amount = colormap.a;
        #endif
        #if !defined(ALPHA) && !defined(DETAILMAP4)
            colormap.xyz *= mix(vec3(1.0),color_tint[instance_id].xyz,normalmap.a);
        #endif
        vec3 color = diffuse_color * colormap.xyz +
                     spec_color * GammaCorrectFloat(spec_amount);
    #endif
    CALC_COLOR_ADJUST
    //CALC_HAZE
    //AddHaze(color, ws_vertex, spec_cubemap);
    if(!use_amb_cube){
        vec3 fog_color = textureLod(spec_cubemap,ws_vertex,5.0).xyz;
        color = mix(color, fog_color, GetHazeAmount(ws_vertex));
    } else {
        vec3 fog_color = SampleAmbientCube(ambient_cube_color, ws_vertex);
        color = mix(color, fog_color, GetHazeAmount(ws_vertex));        
    }

    #ifndef TERRAIN
    //#ifdef EMISSIVE
    if(color_tint[instance_id].r > 1.0){
        color.xyz = colormap.xyz * color_tint[instance_id].xyz;
    }
    //#endif
    #endif

    #ifdef ALPHA
        out_color = vec4(color,colormap.a);
    #else
        out_color = vec4(color,1.0);
    #endif
    #endif // DEPTH_ONLY
}
