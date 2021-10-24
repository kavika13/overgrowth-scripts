#version 150
uniform mat4 mvp;
in vec3 vert;
#ifdef ALPHA
in vec2 tex;
out vec2 frag_tex;
#endif
void main() {    
    gl_Position = mvp * vec4(vert, 1.0);
#ifdef ALPHA
    frag_tex = tex;
#endif
}