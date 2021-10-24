#version 150
#include "lighting150.glsl"

in vec3 vertex_attrib;
in vec2 tex_coords_attrib;
#ifdef TANGENT
in vec3 tangent_attrib;
in vec3 bitangent_attrib;
in vec3 normal_attrib;
#endif
#ifdef PLANT
in vec3 plant_stability_attrib;
#endif

const int kMaxInstances = 100;

uniform InstanceInfo {
    mat4 model_mat[kMaxInstances];
    mat3 model_rotation_mat[kMaxInstances];
    vec4 color_tint[kMaxInstances];
    vec4 detail_scale[kMaxInstances];
};

uniform mat4 projection_view_mat;
uniform vec3 cam_pos;
uniform mat4 shadow_matrix[4];

#ifdef PLANT
uniform float plant_shake;
uniform float time;
#endif

#ifdef TANGENT
out mat3 tan_to_obj;
#endif
out vec3 world_vert;
out vec2 frag_tex_coords;
#ifndef NO_INSTANCE_ID
flat out int instance_id;
#endif

void main() {    
    #ifdef NO_INSTANCE_ID
        int instance_id;
    #endif
    instance_id = gl_InstanceID;
    #if defined(TANGENT) && !defined(DEPTH_ONLY)
        tan_to_obj = mat3(tangent_attrib, bitangent_attrib, normal_attrib);
    #endif
    vec4 transformed_vertex = model_mat[instance_id] * vec4(vertex_attrib, 1.0);
    #ifdef PLANT
        vec3 vertex_offset = CalcVertexOffset(transformed_vertex, plant_stability_attrib.r, time, plant_shake);
        transformed_vertex.xyz += model_rotation_mat[instance_id] * vertex_offset;
    #endif
    gl_Position = projection_view_mat * transformed_vertex;    
    frag_tex_coords = tex_coords_attrib;
    #ifndef DEPTH_ONLY
        world_vert = transformed_vertex.xyz;
    #endif
} 