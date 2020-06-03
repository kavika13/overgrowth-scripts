uniform sampler2D tex0;
uniform samplerCube tex3;
uniform float shadowed;

#include "lighting.glsl"

void main()
{	
	vec2 coord = vec2((1.0-gl_TexCoord[0].x),(1.0-gl_TexCoord[0].y));
	vec4 colormap = texture2D(tex0,coord);
	
	float fore = colormap.r;
	float back = colormap.g;
	colormap.a = max(0.0,fore-back-0.1);

	colormap.xyz = mix(colormap.xyz*vec3(1.0,0.0,0.0),colormap.xyz,colormap.a);
	colormap.xyz *= vec3(0.4,0.2,0.2);

	gl_FragColor = colormap;
}