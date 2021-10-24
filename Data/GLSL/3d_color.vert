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

#ifdef FIRE
    out vec3 world_vert;
#endif

void main() {
#ifdef FIRE
    world_vert = vert_attrib;
    world_vert = world_vert + normalize(cam_pos - world_vert) * 0.1;
    gl_Position = mvp * vec4(world_vert, 1.0);
#else
    gl_Position = mvp * vec4(vert_attrib, 1.0);
#endif

#ifdef COLOR_ATTRIB
    color = color_attrib;
#elif defined(COLOR_UNIFORM)
    color = color_uniform;
#else
    color = vec4(1.0);
#endif
} 
