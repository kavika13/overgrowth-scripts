#version 150
#include "lighting150.glsl"

in vec3 vertex_attrib;
in vec2 tex_coord_attrib;
#if defined(PARTICLE)
    #ifndef INSTANCED
        in vec3 normal_attrib;
        in vec3 tangent_attrib;
    #endif
#elif defined(DETAIL_OBJECT)
    in vec3 tangent_attrib;
    in vec3 bitangent_attrib;
    in vec3 normal_attrib;
#elif defined(TERRAIN)
    in vec3 tangent_attrib;
    in vec2 detail_tex_coord;
#elif defined(ITEM)
    in vec3 normal_attrib;
#elif defined(CHARACTER)
    in vec2 morph_tex_offset_attrib;
    in vec2 fur_tex_coord_attrib;

#if defined(GPU_SKINNING)

    in vec4 bone_weights;
    in vec4 bone_ids;
    in vec3 morph_offsets;

#else  // GPU_SKINNING

    in vec4 transform_mat_column_a;
    in vec4 transform_mat_column_b;
    in vec4 transform_mat_column_c;

#endif  // GPU_SKINNING

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
    const int kMaxInstances = 100;

    #ifdef INSTANCED
        uniform InstanceInfo {
            vec4 instance_color[kMaxInstances];
            mat4 instance_transform[kMaxInstances];
        };
    #endif
#elif defined(DETAIL_OBJECT)
    uniform vec3 cam_pos;
    uniform vec3 ws_light;
    uniform float time;

    const int kMaxInstances = 200; // 200 * 4 * 4 * 5 < 16384 , which is lowest possible support uniform block size

    uniform InstanceInfo {
        mat4 transforms[kMaxInstances];
        vec4 texcoords2[kMaxInstances];
    };

    uniform float height;
    uniform float max_distance;
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
    uniform mat4 projection_view_mat;
    uniform vec3 ws_light;
    uniform mat4 shadow_matrix[4];
#elif defined(CHARACTER)
    #ifndef DEPTH_ONLY
    uniform vec3 cam_pos;
    uniform mat4 shadow_matrix[4];
    #endif
    uniform mat4 mvp;

#if defined(GPU_SKINNING)

    const int kMaxBones = 200;

    uniform mat4 bone_mats[kMaxBones];

#endif  // GPU_SKINNING

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
    uniform float time;
    #endif

    #ifdef MEGASCAN_TEST
        uniform sampler2D tex0;
    #endif

    #if defined(SCROLL_FAST) || defined(SCROLL_SLOW) || defined(SCROLL_VERY_SLOW) || defined(SCROLL_MEDIUM)
    uniform float time;
    #endif
#endif


#ifdef SHADOW_CASCADE
#define frag_tex_coords geom_tex_coords
#define world_vert      geom_world_vert

#ifdef CHARACTER
#define fur_tex_coord   geom_fur_tex_coord
#endif  // CHARACTER

#endif  // SHADOW_CASCADE


out vec3 world_vert;


#ifdef PARTICLE
    out vec2 tex_coord;
    #if defined(NORMAL_MAP_TRANSLUCENT) || defined(WATER) || defined(SPLAT)
        out vec3 tangent_to_world1;
        out vec3 tangent_to_world2;
        out vec3 tangent_to_world3;
    #endif
    flat out int instance_id;
#elif defined(DETAIL_OBJECT)
    out vec2 frag_tex_coords;
    out vec2 base_tex_coord;
    out mat3 tangent_to_world;
    #define TERRAIN_LIGHT_OFFSET vec2(0.0);//vec2(0.0005)+ws_light.xz*0.0005
#elif defined(ITEM)    
    #ifndef DEPTH_ONLY
        #ifndef NO_VELOCITY_BUF
            out vec3 vel;
        #endif
    #ifdef TANGENT
        out vec3 frag_normal;
    #endif
    #endif
    out vec2 frag_tex_coords;
#elif defined(TERRAIN)
    #if defined(DETAILMAP4)
        out vec3 frag_tangent;
    #endif
    #if !defined(SIMPLE_SHADOW)
        //out float alpha;
    #endif
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
    out vec3 orig_vert;
    #ifndef NO_VELOCITY_BUF
        out vec3 vel;
    #endif
    #endif
#else
    #ifdef TANGENT
    out mat3 tan_to_obj;
    #endif
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

void GenerateNormal() {

}

void main() {    
    #ifdef PARTICLE
        #ifdef INSTANCED
            vec3 transformed_vertex = (instance_transform[gl_InstanceID] * vec4(vertex_attrib, 1.0)).xyz;
            #if defined(NORMAL_MAP_TRANSLUCENT) || defined(WATER) || defined(SPLAT)
                tangent_to_world3 = normalize((instance_transform[gl_InstanceID] * vec4(0,0,-1,0)).xyz);
                tangent_to_world1 = normalize((instance_transform[gl_InstanceID] * vec4(1,0,0,0)).xyz);
                tangent_to_world2 = normalize(cross(tangent_to_world1,tangent_to_world3));
            #endif
        #else
            vec3 transformed_vertex = vertex_attrib;
            #if defined(NORMAL_MAP_TRANSLUCENT) || defined(WATER) || defined(SPLAT)
                tangent_to_world3 = normalize(normal_attrib * -1.0);
                tangent_to_world1 = normalize(tangent_attrib);
                tangent_to_world2 = normalize(cross(tangent_to_world1,tangent_to_world3));
            #endif
        #endif
        ApplyWaterRefraction(transformed_vertex);
        mat4 projection_view_mat = mvp;
        tex_coord = tex_coord_attrib;    
        tex_coord[1] = 1.0 - tex_coord[1];
        #ifdef INSTANCED
            instance_id = gl_InstanceID;
        #endif
    #elif defined(DETAIL_OBJECT)
        mat4 obj2world = transforms[gl_InstanceID];
        vec3 transformed_vertex = (obj2world*vec4(vertex_attrib, 1.0)).xyz;
        #ifdef PLANT
            float plant_shake = 0.0;
            vec3 vertex_offset = CalcVertexOffset(transformed_vertex, vertex_attrib.y*2.0, time, plant_shake);
            vertex_offset.y *= 0.2;
        #endif

        mat3 obj2worldmat3 = mat3(normalize(obj2world[0].xyz), 
                                  normalize(obj2world[1].xyz), 
                                  normalize(obj2world[2].xyz));
        mat3 tan_to_obj = mat3(tangent_attrib, bitangent_attrib, normal_attrib);
        tangent_to_world = obj2worldmat3 * tan_to_obj;

         
        vec4 aux = texcoords2[gl_InstanceID];

        float embed = aux.z;
        float height_scale = aux.a;
        transformed_vertex.y -= max(embed,length(transformed_vertex.xyz - cam_pos)/max_distance)*height*height_scale;
        #ifdef PLANT
            transformed_vertex += (obj2world * vec4(vertex_offset,0.0)).xyz;
        #endif
        vec3 temp = transformed_vertex.xyz;
        ApplyWaterRefraction(temp);
        transformed_vertex.xyz = temp;

        frag_tex_coords = tex_coord_attrib;
        base_tex_coord = aux.xy+TERRAIN_LIGHT_OFFSET;

        frag_tex_coords[1] = 1.0 - frag_tex_coords[1];
        base_tex_coord[1] = 1.0 - base_tex_coord[1];
        
    #elif defined(ITEM)
        vec3 transformed_vertex = (model_mat * vec4(vertex_attrib, 1.0)).xyz;
        
        frag_tex_coords = tex_coord_attrib; 
        frag_tex_coords[1] = 1.0 - frag_tex_coords[1];
        #ifndef DEPTH_ONLY
                #ifndef NO_VELOCITY_BUF
                    vec4 old_vel = old_vel_mat * vec4(vertex_attrib, 1.0);
                    vec4 new_vel = new_vel_mat * vec4(vertex_attrib, 1.0);
                    vel = (new_vel - old_vel).xyz;
                #endif
            #ifdef TANGENT
                frag_normal = normal_attrib;
            #endif
        #endif
    #elif defined(TERRAIN)
        vec3 transformed_vertex = vertex_attrib;
        ApplyWaterRefraction(transformed_vertex);

        #if defined(DETAILMAP4)
            frag_tangent = tangent_attrib;    
        #endif
        
        #if !defined(SIMPLE_SHADOW)
            //alpha = min(1.0,(terrain_size-vertex_attrib.x)*fade_mult)*
            //    min(1.0,(vertex_attrib.x+500.0)*fade_mult)*
            //    min(1.0,(terrain_size-vertex_attrib.z)*fade_mult)*
            //    min(1.0,(vertex_attrib.z+500.0)*fade_mult);
            //alpha = max(0.0,alpha);
        #endif
        frag_tex_coords.xy = tex_coord_attrib+TERRAIN_LIGHT_OFFSET;    
        frag_tex_coords.zw = detail_tex_coord*0.1;
        frag_tex_coords[1] = 1.0 - frag_tex_coords[1];
        frag_tex_coords[3] = 1.0 - frag_tex_coords[3];
    #elif defined(CHARACTER)    

#if defined(GPU_SKINNING)

        mat4 concat_bone = bone_mats[int(bone_ids[0])];
        concat_bone *= bone_weights[0];
        for (int i = 1; i < 4; i++) {
            concat_bone += bone_weights[i] * bone_mats[int(bone_ids[i])];
        }

        vec3 offset = (concat_bone * vec4(morph_offsets, 0.0)).xyz;
        concat_bone[3] += vec4(offset, 0.0);

#else  // GPU_SKINNING

        mat4 concat_bone;
        concat_bone[0] = vec4(transform_mat_column_a[0], transform_mat_column_b[0], transform_mat_column_c[0], 0.0);
        concat_bone[1] = vec4(transform_mat_column_a[1], transform_mat_column_b[1], transform_mat_column_c[1], 0.0);
        concat_bone[2] = vec4(transform_mat_column_a[2], transform_mat_column_b[2], transform_mat_column_c[2], 0.0);
        concat_bone[3] = vec4(transform_mat_column_a[3], transform_mat_column_b[3], transform_mat_column_c[3], 1.0);

#endif  // GPU_SKINNING

        vec3 transformed_vertex = (concat_bone * vec4(vertex_attrib, 1.0)).xyz;
        ApplyWaterRefraction(transformed_vertex);

        mat4 projection_view_mat = mvp;

        // Set up varyings to pass bone matrix to fragment shader
        #ifndef DEPTH_ONLY
            orig_vert = vertex_attrib;
            concat_bone1 = concat_bone[0].xyz;
            concat_bone2 = concat_bone[1].xyz;

            tex_coord = tex_coord_attrib;
            morphed_tex_coord = tex_coord_attrib + morph_tex_offset_attrib;
            #ifndef NO_VELOCITY_BUF
                vel = vel_attrib;
            #endif
            tex_coord[1] = 1.0 - tex_coord[1];
            morphed_tex_coord[1] = 1.0 - morphed_tex_coord[1];
        #endif
        fur_tex_coord = fur_tex_coord_attrib;
        fur_tex_coord[1] = 1.0 - fur_tex_coord[1];
    #else
        #ifdef NO_INSTANCE_ID
            int instance_id;
        #endif
        instance_id = gl_InstanceID;
        #if defined(TANGENT) && !defined(DEPTH_ONLY)
            tan_to_obj = mat3(tangent_attrib, bitangent_attrib, normal_attrib);
        #endif
        vec3 transformed_vertex = (model_mat[instance_id] * vec4(vertex_attrib, 1.0)).xyz;
        #ifdef PLANT
            float plant_shake = max(0.0, color_tint[instance_id][3]);
            vec3 vertex_offset = CalcVertexOffset(transformed_vertex, plant_stability_attrib.r, time, plant_shake);
            transformed_vertex.xyz += model_rotation_mat[instance_id] * vertex_offset;
        #endif
        #ifdef WATERFALL
            transformed_vertex.xyz += CalcVertexOffset(transformed_vertex, 0.1, time, 1.0);
        #endif


        #ifdef MEGASCAN_TEST
            vec3 temp_scale;
            {
                mat3 temp_mat = mat3(model_mat[instance_id][0].xyz, model_mat[instance_id][1].xyz, model_mat[instance_id][2].xyz);
                temp_mat = inverse(model_rotation_mat[instance_id]) * temp_mat;
                temp_scale = vec3(temp_mat[0][0], temp_mat[1][1], temp_mat[2][2]);
            }
            float tile_scale = 2.0;
            float displacement_scale = 0.25;
            vec2 temp_uv;
            #ifdef AXIS_UV
                temp_uv = tex_coord_attrib * tile_scale;
                temp_uv.x *= abs(dot(temp_scale, tangent_attrib));
                temp_uv.y *= abs(dot(temp_scale, bitangent_attrib));
            #else
                temp_uv = tex_coord_attrib;
            #endif
            #ifdef DISPLACE
                transformed_vertex.xyz += model_rotation_mat[instance_id] * normal_attrib * (texture(tex0, temp_uv).a - 0.5) * displacement_scale;//CalcVertexOffset(transformed_vertex, 0.1, 0.0, 1.0);
            #endif
        #endif

        vec3 temp = transformed_vertex.xyz;
        ApplyWaterRefraction(temp);
        transformed_vertex.xyz = temp;
        #ifdef MEGASCAN_TEST
            frag_tex_coords = temp_uv;
        #else
            frag_tex_coords = tex_coord_attrib;
        #endif
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
        frag_tex_coords[1] = 1.0 - frag_tex_coords[1];
    #endif

    world_vert = transformed_vertex;
#ifndef SHADOW_CASCADE
	gl_Position = projection_view_mat * vec4(transformed_vertex, 1.0);
#endif  // SHADOW_CASCADE
} 
