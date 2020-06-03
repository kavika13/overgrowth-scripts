uniform sampler2D tex0;
uniform sampler2D tex1;
uniform samplerCube tex2;
uniform samplerCube tex3;
uniform sampler2D tex4;
uniform float wetness;

varying mat3 tangent_to_world;
varying vec3 vertex_pos;
varying vec3 light_pos;

#include "transposemat3.glsl"

void main()
{    
    vec3 normal = normalize(gl_Normal);
    vec3 temp_tangent = normalize(gl_MultiTexCoord1.xyz);
    vec3 bitangent = normalize(gl_MultiTexCoord2.xyz);
    
    tangent_to_world = mat3(temp_tangent, bitangent, normal);
    
    vec3 eyeSpaceVert = (gl_ModelViewMatrix * gl_Vertex).xyz;
    vertex_pos = transposeMat3(gl_NormalMatrix * tangent_to_world) * eyeSpaceVert;
    
    light_pos = transposeMat3(gl_NormalMatrix * tangent_to_world) * gl_LightSource[0].position.xyz;
  
    gl_Position = ftransform();
    gl_TexCoord[0] = gl_MultiTexCoord0;
    gl_TexCoord[1] = gl_MultiTexCoord3;
} 
