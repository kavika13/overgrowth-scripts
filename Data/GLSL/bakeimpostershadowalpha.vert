uniform sampler2D tex0;
uniform sampler2D tex1;

#include "pseudoinstance.glsl"

void main()
{    
    mat4 obj2world = GetPseudoInstanceMat4();
    vec4 transformed_vertex = obj2world * gl_Vertex;
    gl_Position = gl_ModelViewProjectionMatrix * transformed_vertex;
    gl_TexCoord[0].xy = gl_MultiTexCoord0.xy;
    gl_TexCoord[1].xy = gl_MultiTexCoord3.xy;
} 