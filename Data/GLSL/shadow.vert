#version 150
#extension GL_ARB_shading_language_420pack : enable

uniform mat4 projection_view_mat;

in vec3 vert;

#ifdef ALPHA
in vec2 tex;
out vec2 frag_tex;
#endif

void main() {
    gl_Position = projection_view_mat * vec4(vert, 1.0);
#ifdef ALPHA
    frag_tex = tex;
#endif
}
