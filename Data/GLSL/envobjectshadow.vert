uniform sampler2D tex4;

#include "pseudoinstance.glsl"
#include "shadowpack.glsl"
#include "texturepack.glsl"

void main()
{    
    mat4 obj2world = GetPseudoInstanceMat4();
    vec4 transformed_vertex = obj2world * gl_Vertex;
    gl_Position = gl_ModelViewProjectionMatrix * transformed_vertex;
    
    tc1 = GetShadowCoords();
} 
