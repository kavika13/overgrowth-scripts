uniform sampler2D tex0;
uniform sampler2D tex1;
uniform samplerCube tex2;
uniform samplerCube tex3;
#ifdef BAKED_SHADOWS
    #ifdef SHADOW_CATCHER
        uniform sampler2D tex4;
    #endif
#else
    uniform sampler2DShadow tex4;
#endif
uniform sampler2DShadow tex5;
uniform sampler2D tex6;
uniform vec3 cam_pos;
uniform vec3 ws_light;
uniform float fade;
uniform mat4 shadowmat;
uniform int x_stipple_offset;
uniform int y_stipple_offset;
uniform int stipple_val;
#ifndef SHADOW_CATCHER
    uniform float in_light;
#endif


varying vec3 ws_vertex;
#ifndef BAKED_SHADOWS
    varying vec4 shadow_coords[4];
    #include "lighting.glsl"
#endif

#include "pseudoinstance.glsl"
#include "shadowpack.glsl"
#include "texturepack.glsl"

void main()
{    
    mat4 obj2world = GetPseudoInstanceMat4();

    vec4 transformed_vertex = obj2world * gl_Vertex;

    ws_vertex = transformed_vertex.xyz - cam_pos;
    gl_Position = gl_ModelViewProjectionMatrix * transformed_vertex;

    tc0 = gl_MultiTexCoord0.xy;
    tc1 = GetShadowCoords();
    //gl_FrontColor = gl_Color;
    gl_TexCoord[2] = shadowmat *gl_ModelViewMatrix * transformed_vertex;
#ifndef BAKED_SHADOWS
    SetCascadeShadowCoords(transformed_vertex, shadow_coords);
#endif
} 
