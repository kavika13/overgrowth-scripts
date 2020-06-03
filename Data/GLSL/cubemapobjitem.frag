#version 150

#ifdef ARB_sample_shading_available
#extension GL_ARB_sample_shading: enable
#endif

#include "object_shared150.glsl"
#include "object_frag150.glsl"

UNIFORM_COMMON_TEXTURES
UNIFORM_BLOOD_TEXTURE
UNIFORM_PROJECTED_SHADOW_TEXTURE

UNIFORM_LIGHT_DIR
UNIFORM_EXTRA_AO
UNIFORM_STIPPLE_FADE
UNIFORM_STIPPLE_BLUR
UNIFORM_SIMPLE_SHADOW_CATCH
UNIFORM_COLOR_TINT
uniform mat3 model_rotation_mat;

#ifndef DEPTH_ONLY
in vec3 ws_vertex;
in vec2 frag_tex_coords;
in vec4 shadow_coords[4];
#endif

out vec4 out_color;

#define tc0 frag_tex_coords

void main()
{            
#ifdef HALFTONE_STIPPLE
    CALC_HALFTONE_STIPPLE
#endif
    CALC_MOTION_BLUR
#ifdef DEPTH_ONLY
    out_color = vec4(1.0);
#else
    CALC_STIPPLE_FADE
    CALC_BLOOD_AMOUNT
    CALC_OBJ_NORMAL
    CALC_DYNAMIC_SHADOWED
    CALC_DIFFUSE_LIGHTING
    CALC_BLOODY_WEAPON_SPEC
    CALC_COLOR_MAP
    CALC_BLOOD_ON_COLOR_MAP
    CALC_COMBINED_COLOR_WITH_NORMALMAP_TINT;
    CALC_COLOR_ADJUST
    CALC_HAZE
    CALC_FINAL
#endif
}