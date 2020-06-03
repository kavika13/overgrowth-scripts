#include "object_shared.glsl"
#include "object_vert.glsl"

UNIFORM_REL_POS

VARYING_REL_POS
VARYING_SHADOW
varying vec3 tangent;

void main()
{    
    tangent = gl_MultiTexCoord1.xyz;
    CALC_TRANSFORMED_VERTEX
    CALC_REL_POS
    
    gl_TexCoord[0] = gl_MultiTexCoord0;
    CALC_CASCADE_TEX_COORDS
} 
