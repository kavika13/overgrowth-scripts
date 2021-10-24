#version 150
#extension GL_ARB_shading_language_420pack : enable
uniform sampler2D tex0;
uniform mat4 mvp;
uniform int num_buckets;

in vec2 lines;

void main() {    
    vec4 color = texture2DLod(tex0, vec2(lines[0]/float(num_buckets),0.5), 0.0);
    gl_Position = mvp * vec4(lines[0], lines[1] * (1.0 + color.r), 0.0, 1.0);
}
