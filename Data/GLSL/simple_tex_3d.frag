#version 150

uniform sampler2D tex0;
uniform vec4 color;

in vec2 var_tex_coord; 

#pragma bind_out_color
out vec4 out_color;

void main() {    
    out_color = color * vec4(texture(tex0,var_tex_coord.xy));
}
