uniform sampler2D tex0;
uniform sampler2D tex1;
uniform samplerCube tex2;
uniform samplerCube tex3;
uniform sampler2D tex4;
uniform sampler2DShadow tex5;
uniform vec3 cam_pos;
uniform vec3 ws_light;
uniform float extra_ao;
uniform float fade;
uniform mat4 shadowmat;
uniform int x_stipple_offset;
uniform int y_stipple_offset;
uniform int stipple_val;

varying vec3 ws_vertex;

#include "pseudoinstance.glsl"
#include "lighting.glsl"
#include "texturepack.glsl"
#include "relativeskypos.glsl"

float rand(vec2 co){
    return fract(sin(dot(vec2(floor(co.x),floor(co.y)) ,vec2(12.9898,78.233))) * 43758.5453);
}

void main()
{            
    if(stipple_val != 1 &&
       int(gl_FragCoord.x + x_stipple_offset) % 2 * int(gl_FragCoord.y + y_stipple_offset) % 2 == 0){
        discard;
    }
    if((rand(gl_FragCoord.xy)) < fade){
        discard;
    };
    // Get normal
    vec4 normalmap = texture2D(tex1,tc0);
    vec3 os_normal = UnpackObjNormal(normalmap);
    vec3 ws_normal = normalMatrix * os_normal;
    ws_normal = normalize(ws_normal);

    // Get diffuse lighting
    vec3 shadow_tex = texture2D(tex4,gl_TexCoord[2].xy).rgb;
    shadow_tex.r *= shadow2DProj(tex5,gl_TexCoord[2]+vec4(0.0,0.0,-0.00001,0.0)).r;
    float NdotL = GetDirectContrib(ws_light, ws_normal, shadow_tex.r);
    vec3 diffuse_color = GetDirectColor(NdotL);
    diffuse_color += LookupCubemapSimple(ws_normal, tex3) *
                     GetAmbientContrib(shadow_tex.g);
    
    // Get specular lighting
    float spec = GetSpecContrib(ws_light, ws_normal, ws_vertex, shadow_tex.r,100.0);
    spec *= 5.0;
    vec3 spec_color = gl_LightSource[0].diffuse.xyz * vec3(spec);
    
    vec3 spec_map_vec = reflect(ws_vertex,ws_normal);
    spec_color += LookupCubemapSimple(spec_map_vec, tex2) * 0.5 *
                  GetAmbientContrib(shadow_tex.g);
    
    // Put it all together
    vec4 colormap = texture2D(tex0,gl_TexCoord[0].xy);
    vec3 color = diffuse_color * colormap.xyz + spec_color * GammaCorrectFloat(colormap.a);
    
    color *= BalanceAmbient(NdotL);
    
    color *= vec3(min(1.0,shadow_tex.g*2.0)*extra_ao + (1.0-extra_ao));
    AddHaze(color, TransformRelPosForSky(ws_vertex), tex3);

    color *= Exposure();

    //color = vec3(gl_Color.r);

    gl_FragColor = vec4(color,1.0);
}