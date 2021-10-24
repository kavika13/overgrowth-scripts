#version 150
#extension GL_ARB_shading_language_420pack : enable

in vec3 vert_attrib;

void main() {    
    gl_Position = vec4(vert_attrib, 1.0);
} 
