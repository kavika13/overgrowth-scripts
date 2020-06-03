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
uniform vec3 ws_light;
uniform float extra_ao;
uniform float fade;
uniform vec3 color_tint;

varying vec3 ws_vertex;
#ifndef BAKED_SHADOWS
    varying vec4 shadow_coords[4];
#endif

#include "pseudoinstance.glsl"
#include "lighting.glsl"
#include "texturepack.glsl"
#include "relativeskypos.glsl"

void main()
{            
    if((rand(gl_FragCoord.xy)) < fade){
        discard;
    };
    // Get normal
    vec4 normalmap = texture2D(tex1,tc0);
    vec3 os_normal = UnpackObjNormal(normalmap);
    vec3 ws_normal = normalMatrix * os_normal;
    ws_normal = normalize(ws_normal);

    // Get diffuse lighting
#ifdef BAKED_SHADOWS
    vec3 shadow_tex = texture2D(tex4,tc1).rgb;
#else
    vec3 shadow_tex = vec3(1.0);
    shadow_tex.r = GetCascadeShadow(tex4, shadow_coords, length(ws_vertex));
#endif
    float NdotL = GetDirectContrib(ws_light, ws_normal, shadow_tex.r);
    vec3 diffuse_color = GetDirectColor(NdotL);
    diffuse_color += LookupCubemapSimple(ws_normal, tex3) *
                     GetAmbientContrib(shadow_tex.g);
    
    // Get specular lighting
    float spec = GetSpecContrib(ws_light, ws_normal, ws_vertex, shadow_tex.r);
    vec3 spec_color = gl_LightSource[0].diffuse.xyz * vec3(spec);
    
    vec3 spec_map_vec = reflect(ws_vertex,ws_normal);
    spec_color += LookupCubemapSimple(spec_map_vec, tex2) * 0.5 *
                  GetAmbientContrib(shadow_tex.g);
    
    // Put it all together
    vec4 colormap = texture2D(tex0,gl_TexCoord[0].xy);
    vec3 color = diffuse_color * colormap.xyz * mix(vec3(1.0),color_tint,normalmap.a) + spec_color * GammaCorrectFloat(colormap.a);
    
    color *= BalanceAmbient(NdotL);
    
    color *= vec3(min(1.0,shadow_tex.g*2.0)*extra_ao + (1.0-extra_ao));
    AddHaze(color, TransformRelPosForSky(ws_vertex), tex3);

    color *= Exposure();

    gl_FragColor = vec4(color,1.0);
}