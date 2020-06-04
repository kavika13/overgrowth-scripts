#version 150
#extension GL_ARB_shading_language_420pack : enable

uniform mat4 view_mat;
uniform mat4 proj_mat;
uniform vec3 cam_pos;
uniform mat4 model_mat;

in vec3 vertex;

flat out int instance_id;
out vec3 world_vert;
out vec3 normal;

void main()
{    
    world_vert = (model_mat * vec4(vertex, 1.0)).xyz;
    normal = (model_mat * vec4(vertex, 0.0)).xyz;
    gl_Position = proj_mat * view_mat * model_mat * vec4(vertex, 1.0);
} 
