#include "object_shared.glsl"
#include "object_frag.glsl"

#ifdef GL_ARB_sample_shading_available
#extension GL_ARB_sample_shading: enable
#endif

UNIFORM_COMMON_TEXTURES
UNIFORM_BLOOD_TEXTURE
UNIFORM_PROJECTED_SHADOW_TEXTURE

UNIFORM_LIGHT_DIR
UNIFORM_EXTRA_AO
UNIFORM_STIPPLE_FADE
UNIFORM_STIPPLE_BLUR
UNIFORM_SIMPLE_SHADOW_CATCH
UNIFORM_COLOR_TINT

VARYING_REL_POS
VARYING_SHADOW

void main()
{            
    CALC_MOTION_BLUR
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
    CALC_EXPOSURE
    CALC_FINAL
}