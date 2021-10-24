#pragma use_tangent
#include "object_vert.glsl"
#include "object_shared.glsl"

UNIFORM_REL_POS
#ifdef ATTACHED
uniform mat4 shadowmat;
#endif

VARYING_REL_POS
VARYING_SHADOW
varying vec3 tangent;
varying vec3 bitangent;

void main()
{    
    tangent = gl_MultiTexCoord1.xyz;
    bitangent = gl_MultiTexCoord2.xyz;

    CALC_TRANSFORMED_VERTEX
    CALC_REL_POS
    CALC_TEX_COORDS
    #ifdef ATTACHED
    gl_TexCoord[2] = shadowmat * gl_ModelViewMatrix * transformed_vertex;
    #endif
} 
