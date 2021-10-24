#version 150
#extension GL_ARB_shading_language_420pack : enable
uniform mat4 mvp;
#ifdef COLOR_UNIFORM
	uniform vec4 color_uniform;
#endif

in vec3 vert_attrib;
#ifdef COLOR_ATTRIB
	in vec4 color_attrib;
#endif

out vec4 color;
out vec3 world_position;

void main() 
{
    world_position = vert_attrib;
    gl_Position = mvp * vec4(vert_attrib, 1.0);
#ifdef COLOR_ATTRIB
    color = color_attrib;
#endif
#ifdef COLOR_UNIFORM
    color = color_uniform;
#endif
} 
