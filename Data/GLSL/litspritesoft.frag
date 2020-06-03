#extension GL_ARB_texture_rectangle : enable

uniform sampler2D tex0;
uniform samplerCube tex3;
uniform sampler2DRect tex5;
uniform float size;
uniform float shadowed;

#include "lighting.glsl"

float LinearizeDepth(float z)
{
  float n = 0.1; // camera z near
  float f = 1000.0; // camera z far
  float depth = (2.0 * n) / (f + n - z * (f - n));
  return (f-n)*depth + n;
}

void main()
{    
    vec3 up = vec3(0.0,1.0,0.0);
    float NdotL = GetDirectContribSimple((1.0-shadowed)*0.8);
    vec3 diffuse_color = GetDirectColor(NdotL);
    
    diffuse_color += LookupCubemapSimple(vec3(0.0,1.0,0.0), tex3);
    
    vec4 colormap = texture2D(tex0,gl_TexCoord[0].xy);
    vec3 color = diffuse_color * colormap.xyz;
    
    color *= BalanceAmbient(NdotL);
    
    //color *= vec3(min(1.0,shadow_tex.g*2.0)*extra_ao + (1.0-extra_ao));

    float env_depth = LinearizeDepth(texture2DRect(tex5,gl_FragCoord.xy).r);
    float particle_depth = LinearizeDepth(gl_FragCoord.z);
    float depth = env_depth - particle_depth;
    float depth_blend = depth / size * 0.5;
    depth_blend = max(0.0,min(1.0,depth_blend));
    depth_blend *= max(0.0,min(1.0, particle_depth*0.5-0.1));
    
    gl_FragColor = vec4(diffuse_color*gl_Color.xyz,colormap.a*gl_Color.a*depth_blend);
}