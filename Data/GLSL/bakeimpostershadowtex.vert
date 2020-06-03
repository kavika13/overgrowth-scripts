
#include "pseudoinstance.glsl"

void main()
{    
    mat4 obj2world = GetPseudoInstanceMat4();
    vec4 transformed_vertex = obj2world * gl_Vertex;
    gl_Position = gl_ModelViewProjectionMatrix * transformed_vertex;
    gl_TexCoord[0] = gl_MultiTexCoord0;
    gl_TexCoord[1] = gl_MultiTexCoord3;
} 
