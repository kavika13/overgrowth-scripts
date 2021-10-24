#version 150
#extension GL_ARB_shading_language_420pack : enable

uniform mat4 model_mat;
uniform mat4 projection_view_mat;
uniform vec3 cam_pos;
uniform mat4 shadow_matrix[4];

in vec3 vertex_attrib;
in vec3 normal_attrib;
in vec3 tangent_attrib;
in vec3 tex_coords_attrib;
in vec3 base_tex_coord_attrib;

out vec4 shadow_coords[4];
out vec3 tangent;
out vec3 normal;
out vec3 ws_vertex;
out vec3 tex_coord;
out vec3 base_tex_coord;

void main() {    
    tangent = tangent_attrib;
    normal = normal_attrib;
    vec4 transformed_vertex = model_mat * vec4(vertex_attrib, 1.0);
    gl_Position = projection_view_mat * transformed_vertex;
    ws_vertex = transformed_vertex.xyz - cam_pos;
    
    tex_coord = tex_coords_attrib;
    base_tex_coord = base_tex_coord_attrib;
    
    shadow_coords[0] = shadow_matrix[0] * transformed_vertex;
    shadow_coords[1] = shadow_matrix[1] * transformed_vertex;
    shadow_coords[2] = shadow_matrix[2] * transformed_vertex;
    shadow_coords[3] = shadow_matrix[3] * transformed_vertex;
} 
