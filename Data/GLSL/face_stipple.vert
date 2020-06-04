#version 150
#extension GL_ARB_shading_language_420pack : enable

uniform mat4 mvp_mat;

in vec3 vert_coord;

void main() {    
    gl_Position = mvp_mat * vec4(vert_coord,1.0);
} 
