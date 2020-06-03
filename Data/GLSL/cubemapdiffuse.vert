uniform sampler2D tex0;
uniform samplerCube tex2;
uniform samplerCube tex3;
uniform vec4 emission;
uniform vec3 cam_pos;

varying vec3 normal;
varying vec3 world_normal;
varying vec3 rel_pos;

#include "pseudoinstance.glsl"
#include "transposemat3.glsl"
#include "relativeskypos.glsl"

void main()
{    
    normal = normalize(gl_NormalMatrix * gl_Normal);
    
    mat3 obj2worldmat3 = GetPseudoInstanceMat3();
    world_normal = obj2worldmat3 * normal;
    world_normal.xy *= -1.0;
    //vec4 transformed_vertex = obj2world * gl_Vertex;
    vec4 transformed_vertex = gl_Vertex;
   
    rel_pos = CalcRelativePositionForSkySimple2(transformed_vertex.xyz, cam_pos);

    gl_Position = gl_ModelViewProjectionMatrix * transformed_vertex;
    
    gl_TexCoord[0] = gl_MultiTexCoord0;
    
    gl_FrontColor = gl_Color;
} 
