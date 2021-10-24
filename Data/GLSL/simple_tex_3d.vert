#version 150

uniform mat4 mvp_mat;

in vec3 vert_coord;
in vec2 tex_coord;

out vec2 var_tex_coord; 

void main() {    
    gl_Position = mvp_mat * vec4(vert_coord,1.0);
    #ifdef FLIPPED
        var_tex_coord = vec2(tex_coord[0], 1.0 - tex_coord[1]);
    #else
        var_tex_coord = tex_coord;
    #endif 
} 
