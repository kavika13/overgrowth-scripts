#version 150
#extension GL_ARB_texture_rectangle : enable
#extension GL_ARB_shading_language_420pack : enable

uniform sampler2D tex0;
uniform sampler2DRect tex5;
uniform float size;

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
    vec2 coord = vec2((1.0-gl_TexCoord[0].x)*0.5,(1.0-gl_TexCoord[0].y));
    vec4 colormap = texture2D(tex0,coord);
    coord.x += 0.5;
    colormap.a = texture2D(tex0,coord).r;
    float avg_color = (colormap[0]+colormap[1]+colormap[2])/3.0;
    colormap.xyz = colormap.xyz + (colormap.xyz - vec3(avg_color))*0.5;
    
    float scale_down = 3.0;

    float env_depth = LinearizeDepth(texture2DRect(tex5,gl_FragCoord.xy).r);
    float particle_depth = LinearizeDepth(gl_FragCoord.z);
    float depth = env_depth - particle_depth;
    float depth_blend = depth / size * 0.5;
    depth_blend = (depth_blend - 0.5) * scale_down + 0.5;
    depth_blend = max(0.0,min(1.0,depth_blend));
    depth_blend *= max(0.0,min(1.0, (particle_depth-0.4)*scale_down));
    
    colormap.a *= depth_blend;
    gl_FragColor = colormap;
}
