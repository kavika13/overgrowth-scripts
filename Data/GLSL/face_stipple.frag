#version 150

uniform vec4 color;

out vec4 out_color;

void main() {    
    if(mod(gl_FragCoord.x + gl_FragCoord.y, 2.0) == 0.0){
        discard;
    } else {
        out_color = color;            
    }
}
