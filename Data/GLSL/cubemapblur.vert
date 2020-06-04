#version 150
#extension GL_ARB_shading_language_420pack : enable

out vec3 vec;
out vec3 face_vec;

in vec3 vertex;

void main() {    
	face_vec = vertex;
    vec = vec3(vertex.x, vertex.y, -1.0);
    gl_Position = vec4(vertex, 1.0);
} 
