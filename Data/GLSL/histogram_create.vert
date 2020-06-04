#version 150
#extension GL_ARB_shading_language_420pack : enable
uniform sampler2D tex0;

in vec2 pixel_uv;

void main() {    
    vec4 color = texture2DLod(tex0, pixel_uv, 0.0);
    float avg = (color[0] + color[1] + color[2]) / 3.0;
    float bucket = avg;
    gl_Position = vec4(max(-0.99999, min(0.99999, bucket*2.0-1.0)), 0.5, 0.0, 1.0);
}
