uniform sampler2DShadow tex0;
uniform samplerCube tex3;
uniform sampler2D tex4;
uniform sampler2D tex5;
uniform vec3 ws_light;

varying vec4 ProjShadow;
varying vec3 normal;

#include "pseudoinstance.glsl"

void main()
{    
    mat4 obj2world = GetPseudoInstanceMat4();
    
    vec4 transformed_vertex = obj2world * gl_Vertex;
    ProjShadow = gl_TextureMatrix[0] * gl_ModelViewMatrix * transformed_vertex;

    gl_Position = gl_ModelViewProjectionMatrix * transformed_vertex;
    normal = gl_Normal;

    gl_TexCoord[0] = gl_MultiTexCoord0;
    gl_TexCoord[1] = gl_MultiTexCoord3;
} 
