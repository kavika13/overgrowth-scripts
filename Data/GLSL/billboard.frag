#version 150

uniform sampler2D tex;
uniform vec4 color;

#pragma bind_out_color
out vec4 out_color;

in vec2 uv;

void main() {	
	vec4 colormap = texture(tex, uv);
    colormap *= color;
#ifndef ALPHA_TO_COVERAGE
    if(colormap.a < 0.5){
        discard;
    }
#endif
	out_color = colormap;
}
