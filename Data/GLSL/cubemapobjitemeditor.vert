#version 150
#pragma use_tangent

#include "lighting150.glsl"

in vec3 vertex_attrib;
in vec2 tex_coords_attrib;

uniform mat4 projection_view_mat;
uniform mat4 model_mat;
uniform vec3 cam_pos;
uniform mat4 shadow_matrix[4];

out vec3 ws_vertex;
out vec2 frag_tex_coords;
out vec4 shadow_coords[4];

void main() {    
    vec4 transformed_vertex = model_mat * vec4(vertex_attrib, 1.0);
    gl_Position = projection_view_mat * transformed_vertex;

    ws_vertex = transformed_vertex.xyz - cam_pos;
	frag_tex_coords = tex_coords_attrib;
    
    shadow_coords[0] = shadow_matrix[0] * vec4(transformed_vertex, 1.0);
    shadow_coords[1] = shadow_matrix[1] * vec4(transformed_vertex, 1.0);
    shadow_coords[2] = shadow_matrix[2] * vec4(transformed_vertex, 1.0);
    shadow_coords[3] = shadow_matrix[3] * vec4(transformed_vertex, 1.0);
} 
