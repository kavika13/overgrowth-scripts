uniform sampler2D tex0;
uniform sampler2D tex1;
uniform samplerCube tex2;
uniform samplerCube tex3;
#ifdef BAKED_SHADOWS
    uniform sampler2D tex4;
#else
    uniform sampler2DShadow tex4;
#endif
uniform vec3 cam_pos;
uniform mat3 test;
uniform vec3 ws_light;
uniform vec3 color_tint;

varying vec3 ws_vertex;
varying vec3 tangent;
#ifndef BAKED_SHADOWS
    varying vec4 shadow_coords[4];
    #include "lighting.glsl"
#endif


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
#ifndef BAKED_SHADOWS
    SetCascadeShadowCoords(transformed_vertex, shadow_coords);
#endif
} 
