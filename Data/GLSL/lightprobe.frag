#version 150

const int kMaxInstances = 128;

uniform LightProbeInfo {
    vec4 center[kMaxInstances];
    mat4 view_mat;
    mat4 proj_mat;
    vec3 cam_pos;
    vec4 ambient_cube_color[6*kMaxInstances];
};

flat in int instance_id;
in vec3 vert;
//in vec3 world_vert;

out vec4 out_color;

void main()
{    
    float sum = abs(vert[0]) + abs(vert[1]) + abs(vert[2]);
    vec3 temp_vert = vert / vec3(sum);

    vec3 total = vec3(0.0);
    total += ambient_cube_color[0+int(temp_vert.x<0)+instance_id*6].xyz * vec3(abs(temp_vert.x));
    total += ambient_cube_color[2+int(temp_vert.y<0)+instance_id*6].xyz * vec3(abs(temp_vert.y));
    total += ambient_cube_color[4+int(temp_vert.z<0)+instance_id*6].xyz * vec3(abs(temp_vert.z));
    out_color.xyz = total;
    out_color.a = 1.0;
}