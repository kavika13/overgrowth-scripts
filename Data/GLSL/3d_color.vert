#version 150
uniform mat4 mvp;
#ifdef COLOR_UNIFORM
	uniform vec4 color_uniform;
#endif

in vec3 vert_attrib;
#ifdef COLOR_ATTRIB
	in vec4 color_attrib;
#endif

out vec4 color;

void main() {    
    gl_Position = mvp * vec4(vert_attrib, 1.0);
#ifdef COLOR_ATTRIB
    color = color_attrib;
#endif
#ifdef COLOR_UNIFORM
    color = color_uniform;
#endif
} 
