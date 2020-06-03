#version 150

layout(triangles) in;
layout (triangle_strip, max_vertices=3) out;

in vec3 world_position[3];

out vec3 normal_frag;
out vec3 position_frag;

void main()
{
    vec3 n = cross(world_position[1].xyz-world_position[0].xyz, world_position[2].xyz-world_position[0].xyz);
    normal_frag = normalize(n);

    position_frag = world_position[0];
    gl_Position = gl_in[0].gl_Position;
    EmitVertex();

    position_frag = world_position[1];
    gl_Position = gl_in[1].gl_Position;
    EmitVertex();

    position_frag = world_position[2];
    gl_Position = gl_in[2].gl_Position;
    EmitVertex();

}



