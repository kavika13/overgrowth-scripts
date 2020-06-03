#pragma transparent
#include "object_shared.glsl"
#include "object_frag.glsl"

#define base_normal_tex tex5

UNIFORM_COMMON_TEXTURES
uniform sampler2D base_normal_tex;
UNIFORM_LIGHT_DIR
UNIFORM_EXTRA_AO
UNIFORM_COLOR_TINT
uniform float wetness;

VARYING_REL_POS
VARYING_SHADOW
varying vec3 tangent;
varying vec3 normal;

#define shadow_tex_coords gl_TexCoord[1].xy

void main()
{    
    vec4 colormap = texture2D(tex0,gl_TexCoord[0].st);
    if(gl_TexCoord[0].x<0.0 || gl_TexCoord[0].x>1.0 ||
       gl_TexCoord[0].y<0.0 || gl_TexCoord[0].y>1.0 ||
       gl_TexCoord[0].z<-0.1 || gl_TexCoord[0].z>0.1 ||
        colormap.a <= 0.01) {
        discard;
    }
    // Calculate normal
    vec3 base_normal_tex = texture2D(base_normal_tex,gl_TexCoord[0].st).rgb;
    vec3 base_normal = normal;
    vec3 base_tangent = tangent;
    vec3 base_bitangent = normalize(cross(base_tangent,base_normal));
    base_tangent = normalize(cross(base_normal,base_bitangent));

    vec4 normalmap = texture2D(tex1,gl_TexCoord[0].st);
    vec3 ws_normal = vec3(base_normal * normalmap.b +
                          base_tangent * (normalmap.r*2.0-1.0) +
                          base_bitangent * (normalmap.g*2.0-1.0));
    ws_normal = normalize(ws_normal);
    
    CALC_SHADOWED
    CALC_DIFFUSE_LIGHTING

    vec3 H = normalize(normalize(ws_vertex*-1.0) + normalize(ws_light));
    float spec = min(1.0, pow(max(0.0,dot(ws_normal,H)),850.0)*pow(20.0,wetness)*0.5 * shadow_tex.r * gl_LightSource[0].diffuse.a);
    vec3 spec_color = vec3(spec);
    
    vec3 spec_map_vec = reflect(ws_vertex,ws_normal);
    spec_map_vec = reflect(ws_vertex,ws_normal);
    //spec_color += textureCube(tex2,spec_map_vec).xyz * 0.1;

    colormap.xyz *= mix(0.2, 0.4, max(0.0, min(1.0, wetness * 1.4 - 0.4)));

    CALC_COMBINED_COLOR_WITH_TINT
    CALC_COLOR_ADJUST
    CALC_HAZE
    CALC_EXPOSURE
    CALC_FINAL_ALPHA
}