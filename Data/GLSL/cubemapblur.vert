#version 150

out vec3 vec;
out vec3 face_vec;

in vec3 vertex;

void main() {    
	face_vec = vertex;
    vec = vec3(vertex.x, vertex.y, -1.0);
    gl_Position = vec4(vertex, 1.0);
} 
