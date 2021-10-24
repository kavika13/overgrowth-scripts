#ifndef RELATIVE_SKY_POS_GLSL
#define RELATIVE_SKY_POS_GLSL

#ifdef VERTEX_SHADER
vec3 CalcRelativePositionForSky(const mat4 obj2world, const vec3 cam_pos) {
    vec3 position = (obj2world * vec4(gl_Vertex.xyz,0.0)).xyz - cam_pos;
    return position;
}
#endif

#endif
