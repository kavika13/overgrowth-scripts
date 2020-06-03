#version 150
in vec4 color;
out vec4 out_color;
uniform float opacity;

void main() {    
	out_color = vec4(color.rgb, color.w * opacity);
}
