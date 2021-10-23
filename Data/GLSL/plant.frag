#pragma transparent
#include "object_frag.glsl"
#include "object_shared.glsl"

UNIFORM_COMMON_TEXTURES
UNIFORM_TRANSLUCENCY_TEXTURE

uniform float time;
uniform float plant_shake;
UNIFORM_LIGHT_DIR
UNIFORM_EXTRA_AO
UNIFORM_STIPPLE_FADE
UNIFORM_COLOR_TINT

VARYING_TAN_TO_WORLD
VARYING_REL_POS
VARYING_SHADOW
//varying float wind_color;

void main()
{    
    CALC_STIPPLE_FADE
    CALC_TAN_NORMAL
    #define shadow_tex_coords tc1
    CALC_SHADOWED
    CALC_DIFFUSE_TRANSLUCENT_LIGHTING
    
    CALC_COLOR_MAP

    vec3 translucent_map = texture2D(translucency_tex,tc0).xyz;
    vec3 color = diffuse_color * colormap.xyz + translucent_lighting * translucent_map;
    color *= color_tint;

    CALC_COLOR_ADJUST
    CALC_HAZE
    CALC_EXPOSURE
    CALC_DISTANCE_ADJUSTED_ALPHA
    CALC_FINAL_ALPHA    
    //gl_FragColor = vec4(vec3(wind_color), 1.0);
}