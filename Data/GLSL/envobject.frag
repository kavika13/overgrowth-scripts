#version 150
#include "object_frag150.glsl"
#include "object_shared150.glsl"
#include "ambient_tet_mesh.glsl"

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

#ifdef DECAL
const int kMaxDecals = 100;

uniform DecalInfo {
    mat4 decal_transform[kMaxDecals];
    vec4 decal_tint[kMaxDecals];
    vec2 decal_uv_start[kMaxDecals];
    vec2 decal_uv_size[kMaxDecals];
};
#endif

const int kMaxInstances = 100;

uniform InstanceInfo {
    mat4 model_mat[kMaxInstances];
    mat3 model_rotation_mat[kMaxInstances];
    vec4 color_tint[kMaxInstances];
    vec4 detail_scale[kMaxInstances];
};

#ifdef DECAL
uniform int num_decals;
//Disabled because we've run out of texture sampler.
//uniform sampler2D tex28; // decal normal texture
uniform sampler2D tex29; // decal color texture
#endif
uniform usamplerBuffer tex30;
uniform usamplerBuffer tex31;
uniform int num_light_probes;
uniform int num_tetrahedra;
uniform mat4 decal_mat;

uniform vec3 grid_bounds_min;
uniform vec3 grid_bounds_max;
uniform int subdivisions_x;
uniform int subdivisions_y;
uniform int subdivisions_z;

#ifdef TANGENT
in mat3 tan_to_obj;
#endif
in vec3 ws_vertex;
in vec2 frag_tex_coords;
in vec4 shadow_coords[4];
in vec3 world_vert;
#ifndef NO_INSTANCE_ID
flat in int instance_id;
#endif

out vec4 out_color;

#define shadow_tex_coords tc1
#define tc0 frag_tex_coords

void main() {   
    vec4 colormap = texture(tex0,frag_tex_coords);
    #if defined(ALPHA) && !defined(ALPHA_TO_COVERAGE)
        if(colormap.a < 0.5){
            discard;
        }
    #endif
    #ifdef DEPTH_ONLY
        out_color = vec4(vec3(1.0), colormap.a);
        return;
    #endif
    #ifdef NO_INSTANCE_ID
        int instance_id = 0;
    #endif
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
        uvec4 data = texelFetch(tex30, cell_id/4);
        guess = data[cell_id%4];
        use_amb_cube = GetAmbientCube(world_vert, num_light_probes, tex31, ambient_cube_color, guess);
    } else {
        for(int i=0; i<3; ++i){
            ambient_cube_color[i] = vec3(0.0);
        }
    }
    #ifdef DETAILMAP4
        vec4 weight_map = GetWeightMap(weight_tex, frag_tex_coords);
        float total = weight_map[0] + weight_map[1] + weight_map[2] + weight_map[3];
        weight_map /= total;
        CALC_DETAIL_FADE

        // Get normal
        float color_tint_alpha;
        mat3 ws_from_ns;
        {
            vec4 base_normalmap = texture(tex1,frag_tex_coords);
            color_tint_alpha = base_normalmap.a;

            #ifdef BASE_TANGENT
                vec3 base_normal = normalize(tan_to_obj * UnpackTanNormal(base_normalmap));
            #else
                vec3 base_normal = UnpackObjNormalV3(base_normalmap.xyz);
            #endif

            vec3 base_bitangent = normalize(cross(base_normal,tan_to_obj[0]));
            vec3 base_tangent = normalize(cross(base_bitangent,base_normal));
            base_bitangent *= 1.0 - step(dot(base_bitangent, tan_to_obj[1]),0.0) * 2.0;
        
            ws_from_ns = mat3(base_tangent,
                              base_bitangent,
                              base_normal);
        }

        vec3 ws_normal;
        {
            vec4 normalmap = (texture(detail_normal_0,frag_tex_coords*detail_scale[instance_id][0]) * weight_map[0] +
                              texture(detail_normal_1,frag_tex_coords*detail_scale[instance_id][1]) * weight_map[1] +
                              texture(detail_normal_2,frag_tex_coords*detail_scale[instance_id][2]) * weight_map[2] +
                              texture(detail_normal_3,frag_tex_coords*detail_scale[instance_id][3]) * weight_map[3]);
            normalmap.xyz = UnpackTanNormal(normalmap);
            normalmap.xyz = mix(normalmap.xyz,vec3(0.0,0.0,1.0),detail_fade);

            ws_normal = normalize((model_mat[instance_id] * vec4((ws_from_ns * normalmap.xyz),0.0)).xyz);
        }

        // Get color
        vec3 base_color = texture(color_tex,frag_tex_coords).xyz;
        vec3 tint;
        {
            vec3 average_color = avg_color0 * weight_map[0] +
                                 avg_color1 * weight_map[1] +
                                 avg_color2 * weight_map[2] +
                                 avg_color3 * weight_map[3];
            average_color = max(average_color, vec3(0.01));
            tint = base_color / average_color;
        }

        colormap = texture(detail_color_0,frag_tex_coords*detail_scale[instance_id][0]) * weight_map[0] +
                        texture(detail_color_1,frag_tex_coords*detail_scale[instance_id][1]) * weight_map[1] +
                        texture(detail_color_2,frag_tex_coords*detail_scale[instance_id][2]) * weight_map[2] +
                        texture(detail_color_3,frag_tex_coords*detail_scale[instance_id][3]) * weight_map[3];
        colormap.xyz = mix(colormap.xyz * tint, base_color, detail_fade);
        colormap.xyz = mix(colormap.xyz,colormap.xyz*color_tint[instance_id].xyz,color_tint_alpha);
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

    #ifdef DECAL
    for(int decal_index=0; decal_index<num_decals; ++decal_index){
        mat4 test = inverse(decal_transform[decal_index]);
        vec2 start_uv = decal_uv_start[decal_index];
        vec2 size_uv = decal_uv_size[decal_index];

        //test = inverse(model_mat[0]);
        vec3 temp = (test * vec4(world_vert, 1.0)).xyz;
        if(temp[0] < -0.5 || temp[0] > 0.5 || temp[1] < -0.5 || temp[1] > 0.5 || temp[2] < -0.5 || temp[2] > 0.5){
            
        } else {
            vec4 decal_color = texture(tex29, start_uv + size_uv * vec2(temp[0]+0.5, temp[2]+0.5));
            colormap.xyz = mix(colormap.xyz, decal_color.xyz * decal_tint[decal_index].xyz, decal_color.a);
            //vec4 decal_normal = texture(tex28, start_uv + size_uv * vec2(temp[0]+0.5, temp[2]+0.5));
            //Setting it to the object normal because we're out of texture samplers for now, no normals on decals.
            /*
            vec4 decal_normal = vec4(ws_normal,0.0);

            vec3 decal_tan = normalize(cross(ws_normal, (decal_transform[decal_index] * vec4(0.0, 0.0, 1.0, 0.0)).xyz));
            vec3 decal_bitan = cross(ws_normal, decal_tan);
            vec3 new_normal = vec3(0);
            new_normal += ws_normal * (decal_normal.b*2.0-1.0);
            new_normal += (decal_normal.r*2.0-1.0) * decal_tan;
            new_normal += (decal_normal.g*2.0-1.0) * decal_bitan;
            ws_normal = normalize(new_normal);
            */
        }
    }
    #endif
    CALC_SHADOWED
    CALC_DIRECT_DIFFUSE_COLOR
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
    CALC_HAZE
    #ifdef ALPHA
        out_color = vec4(color,colormap.a);
    #else
        out_color = vec4(color,1.0);
    #endif
/*
    #ifdef DECAL
        vec3 temp = (inverse(decal_mat) * vec4(world_vert, 1.0)).xyz;
        if(temp[0] < -0.5 || temp[0] > 0.5 || temp[1] < -0.5 || temp[1] > 0.5 || temp[2] < -0.5 || temp[2] > 0.5){
            discard;
        }
        out_color = vec4(diffuse_color, 1.0);
    #endif*/
}





