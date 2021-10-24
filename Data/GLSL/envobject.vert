#version 150
#include "lighting150.glsl"

in vec3 vertex_attrib;
in vec2 tex_coord_attrib;
#ifdef PARTICLE
    in vec3 normal_attrib;
    in vec3 tangent_attrib;
#elif defined(DETAIL_OBJECT)
    in float index;
    in vec3 tangent_attrib;
    in vec3 bitangent_attrib;
    in vec3 normal_attrib;
#elif defined(TERRAIN)
    in vec3 tangent_attrib;
    in vec2 detail_tex_coord;
#elif defined(ITEM)
#elif defined(CHARACTER)
    in vec2 morph_tex_offset_attrib;
    in vec2 fur_tex_coord_attrib;
    in vec4 transform_mat_column_a;
    in vec4 transform_mat_column_b;
    in vec4 transform_mat_column_c;
    in vec3 vel_attrib;
#else // static object
    #ifdef TANGENT
        in vec3 tangent_attrib;
        in vec3 bitangent_attrib;
        in vec3 normal_attrib;
    #endif
    #ifdef PLANT
        in vec3 plant_stability_attrib;
    #endif
#endif

#ifdef PARTICLE
    uniform mat4 mvp;
#elif defined(DETAIL_OBJECT)
    uniform vec3 cam_pos;
    uniform vec3 ws_light;
    uniform float time;
    uniform mat4 transforms[40];
    uniform vec4 texcoords2[40];
    uniform float height;
    uniform float max_distance;
    uniform float plant_shake;
    uniform mat4 shadow_matrix[4];
    uniform mat4 projection_view_mat;
#elif defined(ITEM)    
    uniform mat4 projection_view_mat;
    uniform mat4 model_mat;
    uniform mat4 old_vel_mat;
    uniform mat4 new_vel_mat;
    uniform vec3 cam_pos;
    uniform mat4 shadow_matrix[4];
#elif defined(TERRAIN)
    uniform vec3 cam_pos;
    uniform mat4 mvp;
    uniform vec3 ws_light;
    uniform mat4 shadow_matrix[4];
#elif defined(CHARACTER)
    #ifndef DEPTH_ONLY
    uniform vec3 cam_pos;
    uniform mat4 shadow_matrix[4];
    #endif
    uniform mat4 mvp;
#else // static object
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

#ifdef PARTICLE
    out vec2 tex_coord;
    out vec3 world_vert;
    out vec3 tangent_to_world1;
    out vec3 tangent_to_world2;
    out vec3 tangent_to_world3;
#elif defined(DETAIL_OBJECT)
    out vec2 frag_tex_coords;
    out vec2 base_tex_coord;
    out mat3 tangent_to_world;
    out vec3 ws_vertex;
    out vec4 shadow_coords[4];
    out vec3 world_vert;
    #define TERRAIN_LIGHT_OFFSET vec2(0.0);//vec2(0.0005)+ws_light.xz*0.0005
#elif defined(ITEM)    
    #ifndef DEPTH_ONLY
    out vec3 ws_vertex;
    out vec3 world_vert;
    out vec3 vel;
    #endif
    out vec2 frag_tex_coords;
#elif defined(TERRAIN)
    out vec3 world_vert;
    out vec3 frag_tangent;
    out float alpha;
    out vec4 frag_tex_coords;

    const float terrain_size = 500.0;
    const float fade_distance = 50.0;
    const float fade_mult = 1.0 / fade_distance;

    #define TERRAIN_LIGHT_OFFSET vec2(0.0);//vec2(0.0005)+ws_light.xz*0.0005
#elif defined(CHARACTER)
    out vec2 fur_tex_coord;
    #ifndef DEPTH_ONLY
    out vec3 concat_bone1;
    out vec3 concat_bone2;
    out vec2 tex_coord;
    out vec2 morphed_tex_coord;
    out vec3 world_vert;
    out vec3 orig_vert;
    out vec3 vel;
    #endif
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

const float water_height = 26.0;
const float refract_amount = 0.6;

void ApplyWaterRefraction(inout vec3 vert){
    /*if(vert.y < water_height){
        vert.y = water_height + (vert.y - water_height) * refract_amount;
    }*/
/*
    if(vert.y > water_height){
        vert.y = water_height + (vert.y - water_height) / refract_amount;
    }*/
}

void main() {    
    #ifdef PARTICLE
        vec3 transformed_vertex = vertex_attrib;
        ApplyWaterRefraction(transformed_vertex);
        gl_Position = mvp * vec4(transformed_vertex, 1.0);    
        world_vert = transformed_vertex;
        tex_coord = tex_coord_attrib;    
        tangent_to_world3 = normalize(normal_attrib * -1.0);
        tangent_to_world1 = normalize(tangent_attrib);
        tangent_to_world2 = normalize(cross(tangent_to_world1,tangent_to_world3));
    #elif defined(DETAIL_OBJECT)
        mat4 obj2world = transforms[int(index)];
        vec4 transformed_vertex = obj2world*vec4(vertex_attrib, 1.0);
        #ifdef PLANT
            vec3 vertex_offset = CalcVertexOffset(transformed_vertex, vertex_attrib.y*2.0, time, plant_shake);
            vertex_offset.y *= 0.2;
        #endif

        mat3 obj2worldmat3 = mat3(normalize(obj2world[0].xyz), 
                                  normalize(obj2world[1].xyz), 
                                  normalize(obj2world[2].xyz));
        mat3 tan_to_obj = mat3(tangent_attrib, bitangent_attrib, normal_attrib);
        tangent_to_world = obj2worldmat3 * tan_to_obj;

         
        vec4 aux = texcoords2[int(index)];

        float embed = aux.z;
        float height_scale = aux.a;
        transformed_vertex.y -= max(embed,length(transformed_vertex.xyz - cam_pos)/max_distance)*height*height_scale;
        #ifdef PLANT
            transformed_vertex += obj2world * vec4(vertex_offset,0.0);
        #endif
        vec3 temp = transformed_vertex.xyz;
        ApplyWaterRefraction(temp);
        transformed_vertex.xyz = temp;
        world_vert = transformed_vertex.xyz;
        ws_vertex = transformed_vertex.xyz - cam_pos;
        gl_Position = projection_view_mat * transformed_vertex;

        frag_tex_coords = tex_coord_attrib;
        base_tex_coord = aux.xy+TERRAIN_LIGHT_OFFSET;
        
        shadow_coords[0] = shadow_matrix[0] * vec4(transformed_vertex);
        shadow_coords[1] = shadow_matrix[1] * vec4(transformed_vertex);
        shadow_coords[2] = shadow_matrix[2] * vec4(transformed_vertex);
        shadow_coords[3] = shadow_matrix[3] * vec4(transformed_vertex);
    #elif defined(ITEM)
        vec4 transformed_vertex = model_mat * vec4(vertex_attrib, 1.0);
        gl_Position = projection_view_mat * transformed_vertex;
        
        frag_tex_coords = tex_coord_attrib;
        #ifndef DEPTH_ONLY
            ws_vertex = transformed_vertex.xyz - cam_pos;
            world_vert = transformed_vertex.xyz;

            vec4 old_vel = old_vel_mat * vec4(vertex_attrib, 1.0);
            vec4 new_vel = new_vel_mat * vec4(vertex_attrib, 1.0);
            vel = (new_vel - old_vel).xyz;
        #endif
    #elif defined(TERRAIN)
        vec3 transformed_vertex = vertex_attrib;
        ApplyWaterRefraction(transformed_vertex);

        frag_tangent = tangent_attrib;    
        world_vert = transformed_vertex;      
        alpha = min(1.0,(terrain_size-vertex_attrib.x)*fade_mult)*
                min(1.0,(vertex_attrib.x+500.0)*fade_mult)*
                min(1.0,(terrain_size-vertex_attrib.z)*fade_mult)*
                min(1.0,(vertex_attrib.z+500.0)*fade_mult);
        alpha = max(0.0,alpha);
        frag_tex_coords.xy = tex_coord_attrib+TERRAIN_LIGHT_OFFSET;    
        frag_tex_coords.zw = detail_tex_coord*0.1;

        gl_Position = mvp * vec4(transformed_vertex, 1.0);
    #elif defined(CHARACTER)    
        mat4 concat_bone;
        concat_bone[0] = vec4(transform_mat_column_a[0], transform_mat_column_b[0], transform_mat_column_c[0], 0.0);
        concat_bone[1] = vec4(transform_mat_column_a[1], transform_mat_column_b[1], transform_mat_column_c[1], 0.0);
        concat_bone[2] = vec4(transform_mat_column_a[2], transform_mat_column_b[2], transform_mat_column_c[2], 0.0);
        concat_bone[3] = vec4(transform_mat_column_a[3], transform_mat_column_b[3], transform_mat_column_c[3], 1.0);
        // Set up varyings to pass bone matrix to fragment shader
        vec3 transformed_vertex = (concat_bone * vec4(vertex_attrib, 1.0)).xyz;
        ApplyWaterRefraction(transformed_vertex);

        gl_Position = mvp * vec4(transformed_vertex, 1.0);

        #ifndef DEPTH_ONLY
            orig_vert = vertex_attrib;
            world_vert = transformed_vertex;
            concat_bone1 = concat_bone[0].xyz;
            concat_bone2 = concat_bone[1].xyz;

            tex_coord = tex_coord_attrib;
            morphed_tex_coord = tex_coord_attrib + morph_tex_offset_attrib;
            vel = vel_attrib;
        #endif
        fur_tex_coord = fur_tex_coord_attrib;
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
        vec3 temp = transformed_vertex.xyz;
        ApplyWaterRefraction(temp);
        transformed_vertex.xyz = temp;
        gl_Position = projection_view_mat * transformed_vertex;    
        frag_tex_coords = tex_coord_attrib;
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