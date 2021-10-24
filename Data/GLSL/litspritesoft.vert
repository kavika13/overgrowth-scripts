#version 150
#extension GL_ARB_shading_language_420pack : enable

uniform mat4 mvp;

in vec3 vertex_attrib;
in vec2 tex_coord_attrib;

out vec2 tex_coord;

void main() {    
    gl_Position = mvp * vec4(vertex_attrib, 1.0);    
    tex_coord = tex_coord_attrib;    
} 
