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

    CALC_TAN_TO_WORLD
    CALC_REL_POS
        
    vec4 aux = texcoords2[int(index)];

    float embed = aux.z;
    float height_scale = aux.a;
    transformed_vertex.y -= max(embed,length(ws_vertex)/max_distance)*height*height_scale;
    gl_Position = gl_ModelViewProjectionMatrix * transformed_vertex;

    tc0 = gl_MultiTexCoord0.xy;
    tc1 = aux.xy+TERRAIN_LIGHT_OFFSET;
    CALC_CASCADE_TEX_COORDS
} 
