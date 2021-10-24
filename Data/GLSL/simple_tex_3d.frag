#version 150
#extension GL_ARB_shading_language_420pack : enable

uniform sampler2D tex0;
uniform vec4 color;

in vec2 var_tex_coord; 

#pragma bind_out_color
out vec4 out_color;

void main() {    
	#ifdef VR_DISPLAY
    	out_color = color * vec4(textureLod(tex0,var_tex_coord.xy,0.0)) * vec4(textureLod(tex0,var_tex_coord.xy,0.0));
	#else    
		out_color = color * vec4(texture(tex0,var_tex_coord.xy));
	#endif
}
