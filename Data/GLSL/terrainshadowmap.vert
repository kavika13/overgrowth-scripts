uniform vec3 ws_light;
uniform sampler2D tex5;

#include "object_vert.glsl"

void main()
{    
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
    tc0 = gl_MultiTexCoord0.xy+TERRAIN_LIGHT_OFFSET;    
} 

