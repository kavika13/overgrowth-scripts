#version 150
#include "ambient_tet_mesh.glsl"

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
#ifdef STIPPLE
    if(mod(gl_FragCoord.x + gl_FragCoord.y, 2.0) == 0.0){
        discard;
    }
#endif

    vec3 acc[6];
    acc[0] = ambient_cube_color[instance_id * 6 + 0].xyz;
    acc[1] = ambient_cube_color[instance_id * 6 + 1].xyz;
    acc[2] = ambient_cube_color[instance_id * 6 + 2].xyz;
    acc[3] = ambient_cube_color[instance_id * 6 + 3].xyz;
    acc[4] = ambient_cube_color[instance_id * 6 + 4].xyz;
    acc[5] = ambient_cube_color[instance_id * 6 + 5].xyz;

    vec3 total = SampleAmbientCube(acc, normalize(vert));
    out_color.xyz = total;
    out_color.a = 1.0;
}