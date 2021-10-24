#version 150
#extension GL_ARB_shading_language_420pack : enable

uniform mat4 proj_mat;
uniform mat4 modelview_mat;

in vec2 vert_attrib;
in vec2 tex_attrib;

out vec2 frag_texcoord;

void main() {    
    gl_Position = proj_mat * modelview_mat * vec4(vert_attrib, 0.0, 1.0);
    frag_texcoord = tex_attrib;
} 
