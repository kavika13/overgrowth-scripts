#include "object_shared.glsl"
#include "object_frag.glsl"

UNIFORM_COMMON_TEXTURES
UNIFORM_BLOOD_TEXTURE
UNIFORM_PROJECTED_SHADOW_TEXTURE
UNIFORM_FUR_TEXTURE
UNIFORM_TINT_TEXTURE

UNIFORM_LIGHT_DIR
UNIFORM_SIMPLE_SHADOW_CATCH
UNIFORM_TINT_PALETTE

VARYING_REL_POS
VARYING_SHADOW
varying vec3 concat_bone1;
varying vec3 concat_bone2;

void main()
{    
    // Reconstruct third bone axis
    vec3 concat_bone3 = cross(concat_bone1, concat_bone2);

    // Get world space normal
    vec4 normalmap = texture2D(normal_tex,gl_TexCoord[0].xy);
    vec3 unrigged_normal = UnpackObjNormal(normalmap);
    vec3 ws_normal = normalize(concat_bone1 * unrigged_normal.x +
                               concat_bone2 * unrigged_normal.y +
                               concat_bone3 * unrigged_normal.z);

    CALC_DYNAMIC_SHADOWED_BLUR
    shadow_tex.g = 1.0;
    CALC_BLOOD_AMOUNT
    CALC_DIFFUSE_LIGHTING
    CALC_BLOODY_CHARACTER_SPEC
    CALC_MORPHED_AND_TINTED_COLOR_MAP
    CALC_BLOOD_ON_COLOR_MAP
    CALC_COMBINED_COLOR
    CALC_BALANCE_AMBIENT
    CALC_EXPOSURE
    CALC_RIM_HIGHLIGHT
    CALC_HAZE
    float alpha = texture2D(fur_tex,gl_TexCoord[1].xy).a;
    CALC_FINAL_UNIVERSAL(alpha)
}