uniform sampler2D tex0;
uniform sampler2D tex1;
uniform samplerCube tex2;
uniform samplerCube tex3;
uniform sampler2D tex4;
uniform vec3 cam_pos;
uniform mat3 test;
uniform vec3 ws_light;

varying vec3 ws_vertex;
varying vec3 tangent;

#include "transposemat3.glsl"
#include "pseudoinstance.glsl"

void main()
{    
    tangent = gl_MultiTexCoord1.xyz;

    mat4 obj2world = GetPseudoInstanceMat4();
    
    vec4 transformed_vertex = obj2world * gl_Vertex;

    ws_vertex = transformed_vertex.xyz - cam_pos;
    
    gl_Position = gl_ModelViewProjectionMatrix * transformed_vertex;
    
    gl_TexCoord[0] = gl_MultiTexCoord0;
} 
