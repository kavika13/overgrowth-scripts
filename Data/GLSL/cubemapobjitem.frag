#ifdef GL_ARB_sample_shading_available
#extension GL_ARB_sample_shading: enable
#endif

uniform sampler2D tex0;
uniform sampler2D tex1;
uniform samplerCube tex2;
uniform samplerCube tex3;
#ifdef BAKED_SHADOWS
    uniform sampler2D tex4;
#else
    uniform sampler2DShadow tex4;
#endif
uniform sampler2DShadow tex5;
uniform sampler2D tex6;
uniform vec3 cam_pos;
uniform vec3 ws_light;
uniform float extra_ao;
uniform float fade;
uniform mat4 shadowmat;
uniform int x_stipple_offset;
uniform int y_stipple_offset;
uniform int stipple_val;

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
#ifndef GL_ARB_sample_shading_available
    if(stipple_val != 1 &&
       (int(mod(gl_FragCoord.x + float(x_stipple_offset),float(stipple_val))) != 0 ||
        int(mod(gl_FragCoord.y + float(y_stipple_offset),float(stipple_val))) != 0)){
        discard;
    }
#else
    if(stipple_val != 1 &&
       (int(mod(gl_FragCoord.x + mod(float(gl_SampleID), float(stipple_val)) + float(x_stipple_offset),float(stipple_val))) != 0 ||
        int(mod(gl_FragCoord.y + float(gl_SampleID) / float(stipple_val) + float(y_stipple_offset),float(stipple_val))) != 0)){
        discard;
    }
#endif
    if((rand(gl_FragCoord.xy)) < fade){
        discard;
    };
    float blood_amount, wetblood;
    ReadBloodTex(tex6, tc0, blood_amount, wetblood);
    // Get normal
    vec4 normalmap = texture2D(tex1,tc0);
    vec3 os_normal = UnpackObjNormal(normalmap);
    vec3 ws_normal = normalMatrix * os_normal;
    ws_normal = normalize(ws_normal);

    // Get diffuse lighting
#ifdef BAKED_SHADOWS
    vec3 shadow_tex = texture2D(tex4,gl_TexCoord[2].xy).rgb;
    shadow_tex.r *= shadow2DProj(tex5,gl_TexCoord[2]+vec4(0.0,0.0,-0.00001,0.0)).r;
#else
    vec3 shadow_tex = vec3(1.0);
    shadow_tex.r = GetCascadeShadow(tex4, shadow_coords, length(ws_vertex));
#endif
    float NdotL = GetDirectContrib(ws_light, ws_normal, shadow_tex.r);
    vec3 diffuse_color = GetDirectColor(NdotL);
    diffuse_color += LookupCubemapSimple(ws_normal, tex3) *
                     GetAmbientContrib(shadow_tex.g);


    // Get specular lighting
    float spec = GetSpecContrib(ws_light, ws_normal, ws_vertex, shadow_tex.r,mix(100.0,50.0,(1.0-wetblood)*blood_amount));
    spec *= 5.0;
    vec3 spec_color = gl_LightSource[0].diffuse.xyz * vec3(spec) * mix(1.0,0.3,blood_amount);
    
    vec3 spec_map_vec = reflect(ws_vertex,ws_normal);
    spec_color += LookupCubemapSimple(spec_map_vec, tex2) * 0.5 *
                  GetAmbientContrib(shadow_tex.g) * max(0.0,(1.0 - blood_amount * 2.0));
    
    // Put it all together
    vec4 colormap = texture2D(tex0,gl_TexCoord[0].xy);
    ApplyBloodToColorMap(colormap, blood_amount, wetblood);
    vec3 color = diffuse_color * colormap.xyz + spec_color * GammaCorrectFloat(colormap.a);
    
    color *= BalanceAmbient(NdotL);
    
    color *= vec3(min(1.0,shadow_tex.g*2.0)*extra_ao + (1.0-extra_ao));
    AddHaze(color, TransformRelPosForSky(ws_vertex), tex3);

    color *= Exposure();

    //color = vec3(gl_Color.r);

    gl_FragColor = vec4(color,1.0);
}