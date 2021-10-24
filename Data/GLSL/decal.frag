#version 150

#pragma transparent
#include "object_shared150.glsl"
#include "object_frag150.glsl"

#define base_normal_tex tex5

UNIFORM_COMMON_TEXTURES
uniform sampler2D base_normal_tex;
UNIFORM_LIGHT_DIR
UNIFORM_EXTRA_AO
UNIFORM_COLOR_TINT
uniform float wetness;

in vec4 shadow_coords[4];
in vec3 tangent;
in vec3 normal;
in vec3 ws_vertex;
in vec3 tex_coord;
in vec3 base_tex_coord;

#pragma bind_out_color
out vec4 out_color;

#define shadow_tex_coords gl_TexCoord[1].xy

void main()
{    
    vec4 colormap = texture(tex0, tex_coord.xy);
    if(tex_coord.x<0.0 || tex_coord.x>1.0 ||
       tex_coord.y<0.0 || tex_coord.y>1.0 ||
       colormap.a <= 0.01) 
    {
        discard;
    }
    // Calculate normal
    vec3 base_normal_tex = texture(base_normal_tex, base_tex_coord.xy).rgb;
    vec3 base_normal = base_normal_tex*2.0-vec3(1.0);
    vec3 base_tangent = tangent;
    vec3 base_bitangent = normalize(cross(base_tangent,base_normal));
    base_tangent = normalize(cross(base_normal,base_bitangent));

    vec4 normalmap = texture(tex1, tex_coord.xy);
    vec3 ws_normal = vec3(base_normal * normalmap.b +
                          base_tangent * (normalmap.r*2.0-1.0) +
                          base_bitangent * (normalmap.g*2.0-1.0));
    ws_normal = normalize(ws_normal);
    
    CALC_SHADOWED
    CALC_DIFFUSE_LIGHTING
    CALC_SPECULAR_LIGHTING(0.5)
    CALC_COMBINED_COLOR_WITH_TINT
    CALC_COLOR_ADJUST
    CALC_HAZE
    CALC_FINAL_ALPHA
}
