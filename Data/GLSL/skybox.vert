#version 150
uniform mat4 mvp;
in vec3 vert_attrib;
out vec3 normal;

void main() {    
    normal = vert_attrib.xyz;
    gl_Position = mvp * vec4(vert_attrib, 1.0);
} 
