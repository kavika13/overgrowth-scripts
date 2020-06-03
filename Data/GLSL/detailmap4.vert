#pragma use_tangent

uniform vec3 cam_pos;

varying vec3 tangent;
varying vec3 bitangent;
varying vec3 ws_vertex;
#ifndef BAKED_SHADOWS
    varying vec4 shadow_coords[4];
    #include "lighting.glsl"
#endif

#include "pseudoinstance.glsl"
#include "texturepack.glsl"
#include "shadowpack.glsl"

void main()
{    
    mat4 obj2world = GetPseudoInstanceMat4();

    tangent = gl_MultiTexCoord1.xyz;
    bitangent = gl_MultiTexCoord2.xyz;
    
    vec4 transformed_vertex = obj2world * gl_Vertex;
    ws_vertex = transformed_vertex.xyz - cam_pos;
    
    gl_Position = gl_ModelViewProjectionMatrix * transformed_vertex;
    
    tc0 = gl_MultiTexCoord0.xy;
    tc1 = GetShadowCoords();
#ifndef BAKED_SHADOWS
    SetCascadeShadowCoords(transformed_vertex, shadow_coords);
#endif
} 
