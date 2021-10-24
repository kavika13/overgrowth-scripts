#version 150

uniform sampler2D tex0;
uniform vec4 color;

in vec2 frag_texcoord;

out vec4 out_color;

void main() {    
    out_color = texture(tex0,frag_texcoord);
    #ifdef GAMMA_CORRECT
        out_color.rgb *= 2.0;
        out_color.a *= 1.5;
    #else
        out_color.rgb *= 0.8;
        out_color.a *= 0.8;
    #endif
    out_color *= color;
}