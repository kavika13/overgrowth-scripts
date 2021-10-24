#version 150

in vec2 uv;

out vec2 var_uv;

void main() {    
    gl_Position = vec4(uv*2.0-vec2(1.0), 0.0, 1.0);
    var_uv = uv;
} 
