varying vec3 vec;
varying vec3 face_vec;

void main() {    
	face_vec = gl_Vertex.xyz;
    vec = vec3(gl_Vertex.x, gl_Vertex.y, -1.0);
    gl_Position = gl_Vertex;
} 
