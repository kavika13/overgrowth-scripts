#include "object_vert.glsl"
#include "object_shared.glsl"

UNIFORM_REL_POS
uniform mat4 shadowmat;

VARYING_REL_POS
VARYING_SHADOW

void main()
{    
    CALC_TRANSFORMED_VERTEX
    CALC_REL_POS
    CALC_TEX_COORDS

    gl_TexCoord[2] = shadowmat * gl_ModelViewMatrix * transformed_vertex;
} 

