#version 150

#include "object_shared150.glsl"
#include "object_frag150.glsl"

UNIFORM_COMMON_TEXTURES
UNIFORM_LIGHT_DIR
UNIFORM_EXTRA_AO
UNIFORM_COLOR_TINT
uniform mat3 model_rotation_mat;

in vec3 ws_vertex;
in vec2 frag_tex_coords;
in vec4 shadow_coords[4];

#pragma bind_out_color
out vec4 out_color;

#define shadow_tex_coords tc1
#define tc0 frag_tex_coords

void main()
{    
    CALC_OBJ_NORMAL
    CALC_SHADOWED
    CALC_DIFFUSE_LIGHTING
    CALC_SPECULAR_LIGHTING(0.5)
    CALC_COLOR_MAP
    CALC_COMBINED_COLOR_WITH_NORMALMAP_TINT
    CALC_COLOR_ADJUST
    CALC_HAZE
    CALC_FINAL
}
