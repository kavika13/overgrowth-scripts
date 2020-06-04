#version 150
#extension GL_ARB_shading_language_420pack : enable

uniform mat4 model_mat;
uniform mat4 mvp_mat;

in vec3 vert_coord;
in vec2 tex_coord;

out vec3 rel_pos;
out vec2 var_uv;

void main() {    
    rel_pos = vec3(model_mat * vec4(vert_coord, 1.0));    
    gl_Position = mvp_mat * vec4(vert_coord,1.0);
    var_uv = tex_coord;
} 
