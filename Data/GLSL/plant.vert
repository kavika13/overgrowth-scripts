#pragma use_tangent
#include "object_vert.glsl"
#include "object_shared.glsl"

UNIFORM_REL_POS
uniform float time;
uniform float plant_shake;

VARYING_TAN_TO_WORLD
VARYING_REL_POS
VARYING_SHADOW
//varying float wind_color;

void main()
{    
    CALC_TAN_TO_WORLD

    mat4 obj2world = GetPseudoInstanceMat4();
    vec4 transformed_vertex = obj2world*gl_Vertex;
    vec3 vertex_offset = CalcVertexOffset(transformed_vertex, gl_Color.r, time, plant_shake);
    transformed_vertex.xyz += obj2worldmat3 * vertex_offset;
    gl_Position = gl_ModelViewProjectionMatrix * transformed_vertex;
    //wind_color = gl_Color.r;

    CALC_REL_POS
    //CALC_TEX_COORDS // This is expanded manually to fix some kind of Intel problem
	tc0 = gl_MultiTexCoord0.xy;
	tc1 = GetShadowCoords();
	CALC_CASCADE_TEX_COORDS
} 
