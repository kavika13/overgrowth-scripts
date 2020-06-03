#version 150
uniform mat4 mvp;
#ifdef COLOR_UNIFORM
	uniform vec4 color_uniform;
#endif
uniform vec3 cam_pos;

in vec3 vert_attrib;
#ifdef COLOR_ATTRIB
	in vec4 color_attrib;
#endif

out vec4 color;
out vec3 world_vert;

void main() {    
    world_vert = vert_attrib;
#ifdef FIRE
    world_vert += normalize(cam_pos - world_vert) * 0.1;
#endif
    gl_Position = mvp * vec4(world_vert, 1.0);
#ifdef COLOR_ATTRIB
    color = color_attrib;
#endif
#ifdef COLOR_UNIFORM
    color = color_uniform;
#endif
} 
