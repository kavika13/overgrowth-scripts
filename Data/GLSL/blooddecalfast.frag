#pragma transparent

uniform sampler2D tex0;
uniform sampler2D tex1;
uniform samplerCube tex2;
uniform sampler2D tex4;
uniform sampler2D tex5;
uniform vec3 cam_pos;
uniform mat3 test;
uniform vec3 ws_light;
uniform float extra_ao;

varying vec3 ws_vertex;
varying vec3 tangent_to_world1;
varying vec3 tangent_to_world2;
varying vec3 tangent_to_world3;

#include "lighting.glsl"
#include "relativeskypos.glsl"

void main()
{    
    vec4 colormap = texture2D(tex0,gl_TexCoord[0].st);
    if(gl_TexCoord[0].x<0.0 || gl_TexCoord[0].x>1.0 ||
        gl_TexCoord[0].y<0.0 || gl_TexCoord[0].y>1.0 ||
        colormap.a <= 0.05) {
        discard;
    } else {
        // Calculate normal
        vec4 normalmap = texture2D(tex1,gl_TexCoord[0].st);
        vec3 ws_normal = vec3(tangent_to_world3 * normalmap.b +
                              tangent_to_world1 * (normalmap.r*2.0-1.0) +
                              tangent_to_world2 * (normalmap.g*2.0-1.0));
        
        // Calculate diffuse lighting
        vec3 shadow_tex = vec3(1.0);//texture2D(tex4,gl_TexCoord[0].st).rgb;
        float NdotL = GetDirectContrib(ws_light, ws_normal, shadow_tex.r);
        vec3 diffuse_color = GetDirectColor(NdotL);

        diffuse_color += LookupCubemapSimpleLod(ws_normal, tex2, 5.0) *
                         GetAmbientContrib(shadow_tex.g);

        // Calculate specular lighting
        float spec = GetSpecContrib(ws_light, ws_normal, ws_vertex, shadow_tex.r);
        vec3 spec_color = gl_LightSource[0].diffuse.xyz * vec3(spec);
        
        vec3 spec_map_vec = reflect(ws_vertex,ws_normal);
        spec_color += LookupCubemapSimple(spec_map_vec, tex2) * 0.5 *
                      GetAmbientContrib(shadow_tex.g);

        // Put it all together
        vec3 blood_spec = vec3(GetSpecContrib(ws_light, ws_normal, ws_vertex, shadow_tex.r, 450.0));
        vec3 color = diffuse_color * colormap.xyz;// + spec_color * GammaCorrectFloat(normalmap.a);
        color += blood_spec;

        color *= BalanceAmbient(NdotL);
        
        color *= vec3(min(1.0,shadow_tex.g*2.0)*extra_ao + (1.0-extra_ao));
        AddHaze(color, ws_vertex, tex2);
        
        color *= Exposure();

        //color = ws_normal;

        gl_FragColor = vec4(colormap.xyz,colormap.a);
    }
}