#extension GL_ARB_texture_rectangle : enable

uniform sampler2D tex0;
uniform sampler2D tex1;
uniform samplerCube tex3;
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
    vec4 colormap = texture2D(tex0,gl_TexCoord[0].xy);
    vec4 normalmap = texture2D(tex1,gl_TexCoord[0].xy);
    
    vec3 ws_normal = vec3(tangent_to_world3 * normalmap.b +
                          tangent_to_world1 * (normalmap.r*2.0-1.0) +
                          tangent_to_world2 * (normalmap.g*2.0-1.0));
    
    ws_normal = normalize(ws_normal);

    float NdotL = GetDirectContribSoft(ws_light, ws_normal, 1.0);
    NdotL *= (1.0-shadowed);
    vec3 diffuse_color = GetDirectColor(NdotL);
    diffuse_color += LookupCubemapSimple(ws_normal, tex3) * 0.5;
    vec3 color = diffuse_color * colormap.xyz;
    
    vec3 blood_spec = vec3(GetSpecContrib(ws_light, ws_normal, ws_vertex, 1.0, 450.0)) * (1.0-shadowed);
    color += blood_spec;

    color *= BalanceAmbient(NdotL);

    float alpha = min(1.0,pow(colormap.a*gl_Color.a,5.0)*20.0);
    gl_FragColor = vec4(color*gl_Color.xyz,alpha);
}