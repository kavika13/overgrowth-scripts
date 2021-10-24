#ifdef ARB_sample_shading_available
#extension GL_ARB_sample_shading: enable
#endif

#include "object_shared.glsl"
#include "object_frag.glsl"

UNIFORM_STIPPLE_BLUR

void main() {            
    CALC_MOTION_BLUR
    gl_FragColor = vec4(vec3(0.0),1.0);
}