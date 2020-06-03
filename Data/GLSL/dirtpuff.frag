#extension GL_ARB_texture_rectangle : enable

uniform sampler2D tex0;
uniform sampler2D tex1;
uniform samplerCube tex3;
uniform sampler2DRect tex5;
uniform float size;
uniform float shadowed;
uniform vec3 ws_light;
uniform vec3 cam_pos;

varying vec3 tangent_to_world1;
varying vec3 tangent_to_world2;
varying vec3 tangent_to_world3;
varying vec3 ws_vertex;

#include "lighting.glsl"

void main()
{    
    vec3 up = vec3(0.0,1.0,0.0);
    
    vec4 colormap = texture2D(tex0,gl_TexCoord[0].xy);
    vec4 normalmap = texture2D(tex1,gl_TexCoord[0].xy);

    float alpha = min(1.0,pow(colormap.a*gl_Color.a,2.0)*2.0);

    vec3 ws_normal = vec3(tangent_to_world3 * normalmap.b +
                          tangent_to_world1 * (normalmap.r*2.0-1.0) +
                          tangent_to_world2 * (normalmap.g*2.0-1.0));
    
    float NdotL = GetDirectContrib(ws_light, ws_normal, 1.0);
    NdotL = max(NdotL, max(0.0,(1.0-alpha*0.5)));
    NdotL *= (1.0-shadowed);
    vec3 diffuse_color = GetDirectColor(NdotL);
    diffuse_color += LookupCubemapSimple(ws_normal, tex3) *
                     GetAmbientContrib(1.0);
    vec3 color = diffuse_color * colormap.xyz * gl_Color.xyz;
    
    color *= BalanceAmbient(NdotL);
    
    //color *= vec3(min(1.0,shadow_tex.g*2.0)*extra_ao + (1.0-extra_ao));

    //color = vec3(NdotL);
    gl_FragColor = vec4(color,alpha);
}