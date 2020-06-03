#version 150
#pragma use_tangent

in vec3 vertex;
in vec3 tangent;
in vec2 terrain_tex_coord;
in vec2 detail_tex_coord;

uniform vec3 cam_pos;
uniform mat4 mvp;
uniform vec3 ws_light;
uniform mat4 shadow_matrix[4];

out vec3 world_vert;
out vec3 frag_tangent;
out float alpha;
out vec3 ws_vertex;
out vec4 shadow_coords[4];
out vec4 frag_tex_coords;

const float terrain_size = 500.0;
const float fade_distance = 50.0;
const float fade_mult = 1.0 / fade_distance;

#define TERRAIN_LIGHT_OFFSET vec2(0.0005)+ws_light.xz*0.0005

void main()
{    
    frag_tangent = tangent;    
    world_vert = vertex;    
    ws_vertex = vertex - cam_pos;    
    alpha = min(1.0,(terrain_size-vertex.x)*fade_mult)*
            min(1.0,(vertex.x+500.0)*fade_mult)*
            min(1.0,(terrain_size-vertex.z)*fade_mult)*
            min(1.0,(vertex.z+500.0)*fade_mult);
    alpha = max(0.0,alpha);
    frag_tex_coords.xy = terrain_tex_coord+TERRAIN_LIGHT_OFFSET;    
    frag_tex_coords.zw = detail_tex_coord*0.1;

    shadow_coords[0] = shadow_matrix[0] * vec4(vertex, 1.0);
    shadow_coords[1] = shadow_matrix[1] * vec4(vertex, 1.0);
    shadow_coords[2] = shadow_matrix[2] * vec4(vertex, 1.0);
    shadow_coords[3] = shadow_matrix[3] * vec4(vertex, 1.0);

    gl_Position = mvp * vec4(vertex, 1.0);
} 
