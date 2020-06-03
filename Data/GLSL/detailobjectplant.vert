#include "object_shared.glsl"
#include "object_vert.glsl"

#pragma use_tangent

UNIFORM_REL_POS
UNIFORM_LIGHT_DIR
uniform float time;
uniform mat4 transforms[40];
uniform vec4 texcoords2[40];
uniform float height;
uniform float max_distance;
uniform float plant_shake;

varying mat3 tangent_to_world;
VARYING_REL_POS
VARYING_SHADOW

attribute float index;

void main()
{    
    mat4 obj2world = transforms[int(index)];
    vec4 transformed_vertex = obj2world*gl_Vertex;
    vec3 vertex_offset = CalcVertexOffset(transformed_vertex, gl_Vertex.y*2.0, time, plant_shake);
    vertex_offset.y *= 0.2;

    CALC_TAN_TO_WORLD
    CALC_REL_POS
     
    transformed_vertex.y -= length(ws_vertex)*height/max_distance;
    transformed_vertex += obj2world * vec4(vertex_offset,0.0);
    gl_Position = gl_ModelViewProjectionMatrix * transformed_vertex;

    tc0 = gl_MultiTexCoord0.xy;
    tc1 = texcoords2[int(index)].xy+TERRAIN_LIGHT_OFFSET;
    CALC_CASCADE_TEX_COORDS
} 
