#version 150
#extension GL_ARB_shading_language_420pack : enable

uniform vec4 color;

#pragma bind_out_color
out vec4 out_color;

void main() {    
    if(mod(gl_FragCoord.x + gl_FragCoord.y, 2.0) == 0.0){
        discard;
    } else {
        out_color = color;            
    }
}
