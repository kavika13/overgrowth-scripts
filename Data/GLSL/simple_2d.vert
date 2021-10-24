#version 150

uniform mat4 mvp_mat;

in vec2 vert_coord;

#ifdef TEXTURE
in vec2 tex_coord;
out vec2 var_tex_coord; 
#endif

#ifdef COLOREDVERTICES
in vec4 vert_color;
out vec4 color;
#endif

void main() {    
    gl_Position = mvp_mat * vec4(vert_coord,0.0,1.0);
#ifdef TEXTURE
	var_tex_coord = tex_coord;
#endif 

 #ifdef COLOREDVERTICES
	color = vert_color;
#endif

} 
