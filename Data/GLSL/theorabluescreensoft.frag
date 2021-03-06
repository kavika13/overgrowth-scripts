#extension GL_ARB_texture_rectangle : enable

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
	vec2 coord = vec2((1.0-gl_TexCoord[0].x),(1.0-gl_TexCoord[0].y));
	vec4 colormap = texture2D(tex0,coord);
	float avg_color = (colormap[0]+colormap[1]+colormap[2])/3.0;
	colormap.xyz = colormap.xyz + (colormap.xyz - vec3(avg_color))*0.5;
	
	
	float fore = colormap.r;
	float back = colormap.b;

	colormap.a *= max(0.0,min(1.0,((fore+0.1)-back)*50.0));	

	if(back>fore+0.1){
		colormap.a = 0.0;
	}

	//colormap.xyz = mix(colormap.xyz*vec3(1.0,1.0,0.0),colormap.xyz,colormap.a);
	//colormap.xyz *= vec3(0.8,0.5,0.5);

	float scale_down = 10.0;

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