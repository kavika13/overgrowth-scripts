#include "object_vert.glsl"
#include "object_shared.glsl"

UNIFORM_REL_POS

VARYING_REL_POS
VARYING_TAN_TO_WORLD
VARYING_SHADOW

void main()
{    
    CALC_TRANSFORMED_VERTEX
    CALC_REL_POS
    CALC_TEX_COORDS
} 