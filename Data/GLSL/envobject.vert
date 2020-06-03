#version 150
#include "lighting150.glsl"

#ifdef TERRAIN
    in vec3 vertex;
    in vec3 tangent;
    in vec2 terrain_tex_coord;
    in vec2 detail_tex_coord;
#else
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
#endif

#ifdef TERRAIN
    uniform vec3 cam_pos;
    uniform mat4 mvp;
    uniform vec3 ws_light;
    uniform mat4 shadow_matrix[4];
#else
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

    #if defined(SCROLL_FAST) || defined(SCROLL_SLOW) || defined(SCROLL_VERY_SLOW) || defined(SCROLL_MEDIUM)
    uniform float time;
    #endif
#endif

#ifdef TERRAIN
    out vec3 world_vert;
    out vec3 frag_tangent;
    out float alpha;
    out vec4 frag_tex_coords;

    const float terrain_size = 500.0;
    const float fade_distance = 50.0;
    const float fade_mult = 1.0 / fade_distance;

    #define TERRAIN_LIGHT_OFFSET vec2(0.0005)+ws_light.xz*0.0005
#else
    #ifdef TANGENT
    out mat3 tan_to_obj;
    #endif
    out vec3 world_vert;
    out vec2 frag_tex_coords;
    #ifndef NO_INSTANCE_ID
    flat out int instance_id;
    #endif
#endif

void main() {    
    #ifdef TERRAIN
        frag_tangent = tangent;    
        world_vert = vertex;      
        alpha = min(1.0,(terrain_size-vertex.x)*fade_mult)*
                min(1.0,(vertex.x+500.0)*fade_mult)*
                min(1.0,(terrain_size-vertex.z)*fade_mult)*
                min(1.0,(vertex.z+500.0)*fade_mult);
        alpha = max(0.0,alpha);
        frag_tex_coords.xy = terrain_tex_coord+TERRAIN_LIGHT_OFFSET;    
        frag_tex_coords.zw = detail_tex_coord*0.1;

        gl_Position = mvp * vec4(vertex, 1.0);
    #else
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
        #ifdef SCROLL_MEDIUM
        frag_tex_coords.y -= time;
        #endif
        #ifdef SCROLL_FAST
        frag_tex_coords.y -= time * 3.0;
        #endif
        #ifdef SCROLL_SLOW
        frag_tex_coords.y -= time * 0.3;
        #endif
        #ifdef SCROLL_VERY_SLOW
        frag_tex_coords.y -= time * 0.2;
        #endif
        #ifndef DEPTH_ONLY
            world_vert = transformed_vertex.xyz;
        #endif
    #endif
} 