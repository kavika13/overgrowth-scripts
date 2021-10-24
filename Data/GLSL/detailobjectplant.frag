#include "object_shared.glsl"
#include "object_frag.glsl"

#pragma transparent

#define base_color_tex tex6
#define base_normal_tex tex7

UNIFORM_COMMON_TEXTURES
UNIFORM_TRANSLUCENCY_TEXTURE
uniform sampler2D base_color_tex;
uniform sampler2D base_normal_tex;
uniform float overbright;
uniform float max_distance;

UNIFORM_LIGHT_DIR
UNIFORM_EXTRA_AO
uniform vec3 avg_color;
uniform vec3 color_tint;

varying mat3 tangent_to_world;
VARYING_REL_POS
VARYING_SHADOW

void main()
{    
    float dist_fade = 1.0 - length(ws_vertex)/max_distance;

    vec4 normalmap = texture2D(normal_tex,tc0);
    vec3 normal = UnpackTanNormal(normalmap);
    vec3 ws_normal = tangent_to_world * normal;

    vec3 base_normalmap = texture2D(base_normal_tex,tc1).xyz;
    #ifdef TERRAIN
        vec3 base_normal = normalize((base_normalmap*vec3(2.0))-vec3(1.0));
    #else
        vec3 base_normal = normalize(normalMatrix * UnpackObjNormalV3(base_normalmap.xyz));
    #endif
    ws_normal = mix(ws_normal,base_normal,min(1.0,1.0-dist_fade*0.5));
     
    #define shadow_tex_coords tc1
    CALC_SHADOWED
    CALC_DIFFUSE_TRANSLUCENT_LIGHTING
    
    // Put it all together
    vec3 base_color = texture2D(base_color_tex,tc1).rgb * color_tint;
    CALC_COLOR_MAP
    float overbright_adjusted = dist_fade * overbright;
    colormap.xyz = mix(base_color * colormap.xyz / avg_color, colormap.xyz, overbright_adjusted * 0.5);
    colormap.xyz *= 1.0 + overbright_adjusted;
    vec3 translucent_map = texture2D(translucency_tex,tc0).xyz;
    vec3 color = diffuse_color * colormap.xyz;
    
    colormap.a = pow(colormap.a, max(0.1,min(1.0,3.0/length(ws_vertex))));

    #ifndef TERRAIN
        colormap.a -= max(0.0f, -1.0f + (length(ws_vertex)/max_distance * (1.0+rand(gl_FragCoord.xy)*0.5f))*2.0f);
    #endif

    CALC_COLOR_ADJUST
    CALC_HAZE
    CALC_EXPOSURE
    CALC_FINAL_ALPHA

    //gl_FragColor.xyz = normalMatrix * base_normal;
    //gl_FragColor.xyz = vec3(length(ws_vertex)/max_distance);
}