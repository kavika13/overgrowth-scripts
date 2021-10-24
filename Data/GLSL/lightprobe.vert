#version 150
#extension GL_ARB_shading_language_420pack : enable

const int kMaxInstances = 128;

uniform LightProbeInfo {
    vec4 center[kMaxInstances];
    mat4 view_mat;
    mat4 proj_mat;
    vec3 cam_pos;
    vec4 ambient_cube_color[6*kMaxInstances];
};

in vec3 vertex;

flat out int instance_id;
out vec3 vert;
//out vec3 world_vert;

void main()
{    
    vec4 scaled_vert = vec4(vertex * 0.3, 1.0);
    vert = scaled_vert.xyz;
    //world_vert = (model_mat * scaled_vert).xyz;
    instance_id = gl_InstanceID;
    gl_Position = proj_mat * view_mat * (scaled_vert + center[instance_id]);
} 
