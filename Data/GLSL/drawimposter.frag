uniform sampler2D tex0;
uniform sampler2D tex1;
uniform sampler2D tex2;
uniform sampler2D tex3;
uniform samplerCube tex4;
uniform sampler2D tex5;
uniform sampler2D tex6;
uniform sampler2D tex7;
uniform float rotation;
uniform float rotation_total;
uniform float rotation_total2;
uniform float radius;
uniform vec3 cam_pos;
uniform vec3 ws_light;
uniform float extra_ao;
uniform float fade;

varying vec3 ws_vertex;

#include "pseudoinstance.glsl"
#include "lighting.glsl"
#include "relativeskypos.glsl"

void main()
{        
    if((rand(gl_FragCoord.xy)) >= fade){
        discard;
    };
        

    vec4 color_tex = texture2D(tex0,gl_TexCoord[0].xy);
    vec4 color_tex2 = texture2D(tex2,gl_TexCoord[1].xy);

    float scaled_rotation = min(1.0, max(0.0,rotation + (color_tex2.a - color_tex.a)*0.4));
    scaled_rotation -= 0.5;
    scaled_rotation *= 3.0;
    scaled_rotation += 0.5;
    scaled_rotation = min(1.0,max(0.0,scaled_rotation));

    vec4 colormap = mix(color_tex, color_tex2, scaled_rotation);

    /*colormap.xyz /= colormap.a;
    colormap.a -= 0.2;
    if(colormap.a <= 0.0){
        discard;
    }
    colormap.a = min(1.0, colormap.a*10.0);
*/
    
    vec4 shadow_coord1 = texture2D(tex5,gl_TexCoord[0].xy);
    vec4 shadow_coord2 = texture2D(tex6,gl_TexCoord[1].xy);

    vec3 shadow_tex1 = texture2D(tex7,shadow_coord1.xy).xyz;
    vec3 shadow_tex2 = texture2D(tex7,shadow_coord2.xy).xyz;

    vec3 shadow_tex = mix(shadow_tex1, shadow_tex2, scaled_rotation);

    vec4 normal_tex = texture2D(tex1,gl_TexCoord[0].xy);
    vec4 normal_tex2 = texture2D(tex3,gl_TexCoord[1].xy);
    vec3 os_normal1 = UnpackObjNormal(normal_tex);
    vec3 os_normal2 = UnpackObjNormal(normal_tex2);
    vec3 os_normal = mix(os_normal1, os_normal2, min(1.0,max(0.0,scaled_rotation+color_tex2.a-color_tex.a)));
    vec3 ws_normal = normalMatrix * os_normal;
    ws_normal = normalize(ws_normal);
    float NdotL = GetDirectContrib(ws_light, ws_normal, shadow_tex.r);
    vec3 diffuse_color = GetDirectColor(NdotL);
    diffuse_color += LookupCubemapSimple(ws_normal, tex4) *
                     GetAmbientContrib(shadow_tex.g);

    vec3 color = diffuse_color * colormap.xyz;
    
    color *= BalanceAmbient(NdotL);
    
    color *= vec3(min(1.0,shadow_tex.g*2.0)*extra_ao + (1.0-extra_ao));
    AddHaze(color, ws_vertex, tex4);

    color *= Exposure();

    gl_FragColor = vec4(vec3(1.0,0.0,0.0),colormap.a);
}