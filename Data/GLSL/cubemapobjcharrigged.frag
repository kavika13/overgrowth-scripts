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
uniform sampler2D tex7;
uniform vec3 cam_pos;
uniform mat4 shadowmat;
uniform vec3 ws_light;

varying vec3 ws_vertex;
varying vec3 concat_bone1;
varying vec3 concat_bone2;
#ifndef BAKED_SHADOWS
    varying vec4 shadow_coords[4];
#endif

#include "lighting.glsl"
#include "relativeskypos.glsl"

void main()
{    
    // Reconstruct third bone axis
    vec3 concat_bone3 = cross(concat_bone1, concat_bone2);

    // Get world space normal
    vec4 normalmap = texture2D(tex1,gl_TexCoord[0].xy);
    vec3 unrigged_normal = UnpackObjNormal(normalmap);
    vec3 ws_normal = normalize(concat_bone1 * unrigged_normal.x +
                               concat_bone2 * unrigged_normal.y +
                               concat_bone3 * unrigged_normal.z);

    // Get shadowed amount
#ifdef BAKED_SHADOWS
    vec3 shadow_tex = texture2D(tex4,gl_TexCoord[2].xy).xyz;
    float offset = 2.0/512.0;
    float shadow_amount = 0.0;
    float z_bias = -0.00002;
    //shadow_amount += shadow2DProj(tex5,gl_TexCoord[2]+vec4(0.0,0.0,z_bias,0.0)).r;
    shadow_amount += shadow2DProj(tex5,gl_TexCoord[2]+vec4(0.0,0.0,z_bias,0.0)).r * 0.2;
    shadow_amount += shadow2DProj(tex5,gl_TexCoord[2]+vec4(offset,offset*0.2,z_bias,0.0)).r * 0.2;
    shadow_amount += shadow2DProj(tex5,gl_TexCoord[2]+vec4(-offset,offset*-0.2,z_bias,0.0)).r * 0.2;
    shadow_amount += shadow2DProj(tex5,gl_TexCoord[2]+vec4(offset*0.2,offset,z_bias,0.0)).r * 0.2;
    shadow_amount += shadow2DProj(tex5,gl_TexCoord[2]+vec4(-offset*0.2,-offset,z_bias,0.0)).r * 0.2;
    shadow_tex.r *= shadow_amount;
#else
    vec3 shadow_tex = vec3(1.0);
    shadow_tex.r = GetCascadeShadow(tex4, shadow_coords, length(ws_vertex));
#endif
    shadow_tex.g = 1.0;

    float blood_amount, wetblood;
    ReadBloodTex(tex6, gl_TexCoord[1].xy, blood_amount, wetblood);

    // Get diffuse lighting
    float NdotL = GetDirectContrib(ws_light, ws_normal, shadow_tex.r);
    
    vec3 diffuse_color = GetDirectColor(NdotL);
    diffuse_color += LookupCubemapSimple(ws_normal, tex3) *
                     GetAmbientContrib(shadow_tex.g);
    
    // Get specular lighting
    //float spec = GetSpecContrib(ws_light, ws_normal, ws_vertex, shadow_tex.r);
    float spec = GetSpecContrib(ws_light, ws_normal, ws_vertex, shadow_tex.r,mix(200.0,50.0,(1.0-wetblood)*blood_amount));
    spec *= 5.0;
    vec3 spec_color = gl_LightSource[0].diffuse.xyz * vec3(spec) * 0.3;
    
    vec3 spec_map_vec = reflect(ws_vertex, ws_normal);
    spec_color += LookupCubemapSimple(spec_map_vec, tex2) * 0.25 *
                  GetAmbientContrib(shadow_tex.g) * max(0.0,(1.0 - blood_amount * 2.0));

    // Put it all together
    vec4 colormap = texture2D(tex0,gl_TexCoord[1].xy);
    ApplyBloodToColorMap(colormap, blood_amount, wetblood);

    //colormap = vec4(0.1,0.0,0.0,1.0);
    //colormap.xyz *= 1.0-blood_amount*0.3;
    //colormap.a = mix(colormap.a, 1.0, blood_amount);
    vec3 color = diffuse_color * colormap.xyz + spec_color * GammaCorrectFloat(colormap.a);
    
    color *= BalanceAmbient(NdotL);
    color *= Exposure();

    // Add rim lighting
    vec3 view = normalize(ws_vertex*-1.0);
    float back_lit = max(0.0,dot(normalize(ws_vertex),ws_light)); 
    float rim_lit = max(0.0,(1.0-dot(view,ws_normal)));
    rim_lit *= pow((dot(ws_light,ws_normal)+1.0)*0.5,0.5);
    color += vec3(back_lit*rim_lit) * (1.0 - blood_amount) * GammaCorrectFloat(normalmap.a) * gl_LightSource[0].diffuse.xyz * gl_LightSource[0].diffuse.a * shadow_tex.r;
    
    // Add haze
    AddHaze(color, TransformRelPosForSky(ws_vertex), tex3);

    //color = texture2D(tex6,gl_TexCoord[1].xy).xyz;
    float alpha = texture2D(tex7,gl_TexCoord[3].xy).a;//vec3(frac(gl_TexCoord[3].x));
    gl_FragColor = vec4(color,alpha);
}