#version 150

in vec3 vert_attrib;

void main() {    
    gl_Position = vec4(vert_attrib, 1.0);
} 
