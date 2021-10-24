#pragma use_tangent
#include "object_vert.glsl"
#include "object_shared.glsl"

UNIFORM_REL_POS

VARYING_REL_POS
VARYING_SHADOW
varying vec3 normal;
varying vec3 tangent;
varying vec3 bitangent;

void main()
{    
    normal = gl_Normal.xyz;
    tangent = gl_MultiTexCoord1.xyz;
    bitangent = gl_MultiTexCoord2.xyz;

    CALC_TRANSFORMED_VERTEX
    CALC_REL_POS
    CALC_TEX_COORDS
} 
