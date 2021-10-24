#version 150
#include "object_shared150.glsl"
#include "object_frag150.glsl"
#include "ambient_tet_mesh.glsl"

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
UNIFORM_EXTRA_AO
uniform vec3 avg_color;
uniform vec3 color_tint;

uniform usamplerBuffer ambient_color_buffer;
uniform int num_light_probes;
uniform int num_tetrahedra;
uniform mat3 normal_matrix;

in vec2 frag_tex_coords;
in vec2 base_tex_coord;
in mat3 tangent_to_world;
in vec3 ws_vertex;
in vec3 world_vert;
in vec4 shadow_coords[4];

out vec4 out_color;

#define tc0 frag_tex_coords
#define tc1 base_tex_coord

void main()
{    
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
        diffuse_color += LookupCubemapSimpleLod(ws_normal, spec_cubemap, 5.0) *
                 GetAmbientContrib(shadow_tex.g);
    } else {
        diffuse_color += SampleAmbientCube(ambient_cube_color, ws_normal) *
                         GetAmbientContrib(shadow_tex.g);
    }

    // Put it all together
    vec3 base_color = texture(base_color_tex,tc1).rgb * color_tint;
    float overbright_adjusted = dist_fade * overbright;
    colormap.xyz = base_color * mix(vec3(1.0), colormap.xyz / avg_color, dist_fade);
    colormap.xyz *= 1.0 + overbright_adjusted;
    vec3 color = diffuse_color * colormap.xyz;

    CALC_COLOR_ADJUST
    CALC_HAZE
#ifdef PLANT
    CALC_FINAL_ALPHA
#else
    CALC_FINAL
#endif
}
