uniform vec3 ws_light;
uniform sampler2D tex5;

#include "texturepack.glsl"

void main()
{    
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
    tc0 = gl_MultiTexCoord0.xy+vec2(0.0005)+ws_light.xz*0.0005;    
} 

