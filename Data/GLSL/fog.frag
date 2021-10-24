#version 150

uniform sampler2D tex0; // fog band
uniform samplerCube tex3; // skybox

in vec3 rel_pos;
in vec2 var_uv;

out vec4 out_color;

void main() {    
    out_color = vec4(textureLod(tex3,normalize(rel_pos), 5.0).xyz,
                     texture(tex0,var_uv).a);
}