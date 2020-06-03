#pragma transparent

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
uniform float in_light;
uniform float time;
uniform vec3 ws_light;
uniform float extra_ao;
uniform float fade;
uniform vec3 color_tint;

varying mat3 tangent_to_world;
varying vec3 ws_vertex;
#ifndef BAKED_SHADOWS
    varying vec4 shadow_coords[4];
#endif

#include "lighting.glsl"
#include "texturepack.glsl"
#include "relativeskypos.glsl"

void main()
{    
    if((rand(gl_FragCoord.xy)) < fade
        ){
        discard;
    };

    // Calculate normal
    vec4 normalmap = texture2D(tex1,tc0);
    vec3 normal = UnpackTanNormal(normalmap);
    vec3 ws_normal = tangent_to_world * normal;

    // Calculate diffuse lighting
#ifdef BAKED_SHADOWS
    vec3 shadow_tex = texture2D(tex4,tc1).rgb;
#else
    vec3 shadow_tex = vec3(1.0);
    shadow_tex.r = GetCascadeShadow(tex4, shadow_coords, length(ws_vertex));
#endif
    float NdotL = GetDirectContrib(ws_light, ws_normal, shadow_tex.r);
    vec3 diffuse_color = GetDirectColor(NdotL);

    vec3 ambient = LookupCubemapSimple(ws_normal, tex3) *
                     GetAmbientContrib(shadow_tex.g);
    diffuse_color += ambient;

    
    // Calculate translucency

    vec3 translucent_lighting = GetDirectColor(shadow_tex.r) * 
                                gl_LightSource[0].diffuse.a;
    translucent_lighting += ambient;

    translucent_lighting *= GammaCorrectFloat(0.6);
    
    vec4 colormap = texture2D(tex0,tc0);
    vec3 translucent_map = texture2D(tex5,tc0).xyz;
    vec3 color = diffuse_color * colormap.xyz + translucent_lighting * translucent_map;
    color *= color_tint;

    color *= BalanceAmbient(NdotL);
    color *= vec3(min(1.0,shadow_tex.g*2.0)*extra_ao + (1.0-extra_ao));    
    AddHaze(color, TransformRelPosForSky(ws_vertex), tex3);
    color *= Exposure();

    colormap.a = pow(colormap.a, max(0.1,min(1.0,4.0/length(ws_vertex))));

    gl_FragColor = vec4(color,colormap.a);
}