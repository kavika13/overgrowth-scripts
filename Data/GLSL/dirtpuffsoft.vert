#version 150
#extension GL_ARB_shading_language_420pack : enable

uniform vec3 cam_pos;
uniform mat4 mvp;

in vec3 vertex_attrib;
in vec2 tex_coord_attrib;
in vec3 normal_attrib;
in vec3 tangent_attrib;

out vec3 ws_vertex;
out vec2 tex_coord;
out vec3 tangent_to_world1;
out vec3 tangent_to_world2;
out vec3 tangent_to_world3;

void main() {    
    tangent_to_world3 = normalize(normal_attrib * -1.0);
    tangent_to_world1 = normalize(tangent_attrib);
    tangent_to_world2 = normalize(cross(tangent_to_world1,tangent_to_world3));

    ws_vertex = vertex_attrib - cam_pos;
    gl_Position = mvp * vec4(vertex_attrib, 1.0);    
    tex_coord = tex_coord_attrib;
} 
