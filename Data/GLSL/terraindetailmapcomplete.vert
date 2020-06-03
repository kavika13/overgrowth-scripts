#include "object_vert.glsl"
#include "object_shared.glsl"

#pragma use_tangent

UNIFORM_REL_POS
UNIFORM_LIGHT_DIR

VARYING_REL_POS
varying vec3 tangent;
varying float alpha;
VARYING_SHADOW

const float terrain_size = 500.0;
const float fade_distance = 50.0;
const float fade_mult = 1.0 / fade_distance;

void main()
{    
    tangent = gl_MultiTexCoord1.xyz;
    
    ws_vertex = gl_Vertex.xyz - cam_pos;
    
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
    
    alpha = min(1.0,(terrain_size-gl_Vertex.x)*fade_mult)*
            min(1.0,(gl_Vertex.x+500.0)*fade_mult)*
            min(1.0,(terrain_size-gl_Vertex.z)*fade_mult)*
            min(1.0,(gl_Vertex.z+500.0)*fade_mult);

    alpha = max(0.0,alpha);

    tc0 = gl_MultiTexCoord0.xy+TERRAIN_LIGHT_OFFSET;    
    tc1 = gl_MultiTexCoord3.xy*0.1;

    vec4 transformed_vertex = gl_Vertex;
    CALC_CASCADE_TEX_COORDS
} 
