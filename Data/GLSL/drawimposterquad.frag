uniform sampler2D tex0;
uniform sampler2D tex1;
uniform sampler2D tex2;
uniform sampler2D tex3;
uniform samplerCube tex4;
uniform sampler2D tex5;
uniform float radius;
uniform vec3 cam_pos;
uniform vec3 ws_light;
uniform float extra_ao;
uniform float num_angles;

varying vec3 ws_vertex;
varying mat3 normal_mat;
varying vec2 fade;


#include "pseudoinstance.glsl"
#include "lighting.glsl"
#include "relativeskypos.glsl"

float rand(vec2 co){
    return fract(sin(dot(vec2(floor(co.x),floor(co.y)) ,vec2(12.9898,78.233))) * 43758.5453);
}

void main()
{        
    float rand_val = rand(gl_FragCoord.xy);
    if(rand_val > fade.x){
        discard;
    };

    vec2 tex_coord = gl_TexCoord[0].xy;
    vec2 shadow_tex_coord = gl_TexCoord[1].xy;
    if(rand_val > fade.y){
        tex_coord = gl_TexCoord[0].zw;
        shadow_tex_coord = gl_TexCoord[1].zw;
    }

    vec4 colormap = texture2D(tex0,tex_coord);
    colormap.xyz /= (colormap.a+0.001);
    colormap.xyz = pow(colormap.xyz,vec3(1.2));
    vec4 shadow_tex = texture2D(tex5,shadow_tex_coord);
    shadow_tex /= (shadow_tex.a+0.001);
    shadow_tex.xyz = pow(shadow_tex.xyz,vec3(1.4));
    vec4 normal_tex = texture2D(tex1,tex_coord);
    normal_tex /= (normal_tex.a+0.001);
    vec3 os_normal = UnpackObjNormal(normal_tex);
    vec3 ws_normal = normal_mat * os_normal;
    ws_normal = normalize(ws_normal);
    float NdotL = GetDirectContrib(ws_light, ws_normal, shadow_tex.r);
    vec3 diffuse_color = GetDirectColor(NdotL);
    vec3 ambient = LookupCubemapSimple(ws_normal, tex4) *
                     GetAmbientContrib(shadow_tex.g);
    diffuse_color += ambient;

    vec3 color = diffuse_color * colormap.xyz;

    vec4 translucent_tex = texture2D(tex2, tex_coord);
    translucent_tex /= (translucent_tex.a+0.001);
    vec3 translucent_lighting = shadow_tex.r *
                                vec3(gl_LightSource[0].diffuse.a);
    translucent_lighting += ambient;
    translucent_lighting *= GammaCorrectFloat(0.6);
    color += translucent_lighting * translucent_tex.xyz;
        
    color *= BalanceAmbient(NdotL);
    
    color *= vec3(min(1.0,shadow_tex.g*2.0)*extra_ao + (1.0-extra_ao));
    AddHaze(color, TransformRelPosForSky(ws_vertex), tex4);

    color *= Exposure();

    gl_FragColor = vec4(color, colormap.a);
}