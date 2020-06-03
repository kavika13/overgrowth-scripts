#pragma use_tangent

uniform sampler2D tex0;
uniform sampler2D tex1;
uniform samplerCube tex2;
uniform samplerCube tex3;
uniform sampler2D tex4;
uniform sampler2D tex5;
uniform sampler2D tex6;
uniform sampler2D tex7;
uniform vec3 cam_pos;
uniform float time;
uniform vec3 ws_light;
uniform float fade;
uniform vec3 color_tint;
uniform vec3 avg_color;

varying mat3 tangent_to_world;
varying vec3 ws_vertex;

#include "pseudoinstance.glsl"
#include "shadowpack.glsl"
#include "texturepack.glsl"

void main()
{    
    mat4 obj2world = GetPseudoInstanceMat4();

    vec4 transformed_vertex = obj2world*gl_Vertex;
    
    mat3 obj2worldmat3 = GetPseudoInstanceMat3Normalized();

    mat3 tan_to_obj = mat3(gl_MultiTexCoord1.xyz, gl_MultiTexCoord2.xyz, normalize(gl_Normal));
    tangent_to_world = obj2worldmat3 * tan_to_obj;

    ws_vertex = transformed_vertex.xyz - cam_pos;
    //transformed_vertex.y -= length(ws_vertex)*0.02;
    
    gl_Position = gl_ModelViewProjectionMatrix * transformed_vertex;

    tc0 = gl_MultiTexCoord0.xy;
    tc1 = gl_MultiTexCoord3.xy;
    gl_FrontColor = gl_Color;
} 
