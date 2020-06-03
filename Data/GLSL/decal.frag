#pragma transparent
#include "object_shared.glsl"
#include "object_frag.glsl"

#define base_normal_tex tex5

UNIFORM_COMMON_TEXTURES
uniform sampler2D base_normal_tex;
UNIFORM_LIGHT_DIR
UNIFORM_EXTRA_AO
UNIFORM_COLOR_TINT

VARYING_REL_POS
VARYING_SHADOW
varying vec3 tangent;

#define shadow_tex_coords gl_TexCoord[0].xy

void main()
{    
    vec4 colormap = texture2D(tex0,gl_TexCoord[0].st);
    if(gl_TexCoord[0].x<0.0 || gl_TexCoord[0].x>1.0 ||
       gl_TexCoord[0].y<0.0 || gl_TexCoord[0].y>1.0 ||
        colormap.a <= 0.05) {
        discard;
    }
    // Calculate normal
    vec3 base_normal_tex = texture2D(base_normal_tex,gl_TexCoord[0].st).rgb;
    vec3 base_normal = base_normal_tex*2.0-vec3(1.0);
    vec3 base_tangent = tangent;
    vec3 base_bitangent = normalize(cross(base_tangent,base_normal));
    base_tangent = normalize(cross(base_normal,base_bitangent));

    vec4 normalmap = texture2D(tex1,gl_TexCoord[0].st);
    vec3 ws_normal = vec3(base_normal * normalmap.b +
                          base_tangent * (normalmap.r*2.0-1.0) +
                          base_bitangent * (normalmap.g*2.0-1.0));
    
    CALC_SHADOWED
    CALC_DIFFUSE_LIGHTING
    CALC_SPECULAR_LIGHTING(0.5)
    CALC_COMBINED_COLOR_WITH_TINT
    CALC_COLOR_ADJUST
    CALC_HAZE
    CALC_EXPOSURE
    CALC_FINAL_ALPHA
}