#pragma use_tangent

uniform sampler2D tex0;
uniform sampler2D tex1;
uniform samplerCube tex2;
uniform samplerCube tex3;
#ifdef BAKED_SHADOWS
    uniform sampler2D tex4;
#else
    uniform sampler2DShadow tex4;
#endif
uniform sampler2D tex5;
uniform vec3 cam_pos;
uniform float time;
uniform vec3 ws_light;
uniform float fade;
uniform vec3 color_tint;

varying mat3 tangent_to_world;
varying vec3 ws_vertex;
#ifndef BAKED_SHADOWS
    varying vec4 shadow_coords[4];
#endif

#include "pseudoinstance.glsl"
#include "shadowpack.glsl"
#include "texturepack.glsl"
#include "lighting.glsl"

void main()
{    
    mat4 obj2world = GetPseudoInstanceMat4();

    vec4 transformed_vertex = obj2world*gl_Vertex;
    vec3 vertex_offset = CalcVertexOffset(transformed_vertex, gl_Color.r, time);
    
    mat3 obj2worldmat3 = GetPseudoInstanceMat3Normalized();
    transformed_vertex.xyz += obj2worldmat3 * vertex_offset;

    mat3 tan_to_obj = mat3(gl_MultiTexCoord1.xyz, gl_MultiTexCoord2.xyz, normalize(gl_Normal));
    tangent_to_world = obj2worldmat3 * tan_to_obj;

    ws_vertex = transformed_vertex.xyz - cam_pos;
    
    gl_Position = gl_ModelViewProjectionMatrix * transformed_vertex;

    tc0 = gl_MultiTexCoord0.xy;
    tc1 = GetShadowCoords();
    gl_FrontColor = gl_Color;
#ifndef BAKED_SHADOWS
    SetCascadeShadowCoords(transformed_vertex, shadow_coords);
#endif
} 
