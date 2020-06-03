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
uniform sampler2D tex6;
uniform sampler2D tex7;
uniform vec3 cam_pos;
uniform float time;
uniform vec3 ws_light;
uniform float extra_ao;
uniform vec3 avg_color;
uniform mat4 transforms[40];
uniform vec4 texcoords2[40];
uniform float height;
uniform float max_distance;

varying mat3 tangent_to_world;
varying vec3 ws_vertex;
#ifndef BAKED_SHADOWS
    varying vec4 shadow_coords[4];
#endif

attribute float index;

#include "pseudoinstance.glsl"
#include "shadowpack.glsl"
#include "texturepack.glsl"
#include "lighting.glsl"

void main()
{    
    mat4 obj2world = transforms[int(index)];//GetPseudoInstanceMat4();

    vec4 transformed_vertex = obj2world*gl_Vertex;
   
    vec3 vertex_offset = CalcVertexOffset(transformed_vertex, gl_Vertex.y*2.0, time);
    vertex_offset.y *= 0.2;

    mat3 obj2worldmat3 = GetPseudoInstanceMat3Normalized();

    mat3 tan_to_obj = mat3(gl_MultiTexCoord1.xyz, gl_MultiTexCoord2.xyz, normalize(gl_Normal));
    tangent_to_world = obj2worldmat3 * tan_to_obj;

    ws_vertex = transformed_vertex.xyz - cam_pos;
     
    transformed_vertex.y -= length(ws_vertex)*height/max_distance;
    //transformed_vertex.y -= max(0.0,(1.0-length(ws_vertex)*2.0))*height;

    transformed_vertex += obj2world * vec4(vertex_offset,0.0);

    gl_Position = gl_ModelViewProjectionMatrix * transformed_vertex;

    tc0 = gl_MultiTexCoord0.xy;
    tc1 = texcoords2[int(index)].xy+vec2(0.0005)+ws_light.xz*0.0005;
    gl_FrontColor = gl_Color;
#ifndef BAKED_SHADOWS
    SetCascadeShadowCoords(transformed_vertex, shadow_coords);
#endif
} 
