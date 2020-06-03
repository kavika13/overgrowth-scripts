uniform sampler2D tex0;
uniform samplerCube tex3;
uniform float shadowed;

#include "lighting.glsl"

void main()
{	
	float NdotL = GetDirectContribSimple((1.0-shadowed)*0.8);
	vec3 diffuse_color = GetDirectColor(NdotL);
	
	diffuse_color += LookupCubemapSimple(vec3(0.0,1.0,0.0), tex3);
	
	vec4 colormap = texture2D(tex0,gl_TexCoord[0].xy);
	vec3 color = diffuse_color * colormap.xyz;
	
	color *= BalanceAmbient(NdotL);
	
	gl_FragColor = vec4(color,colormap.a*gl_Color.a);
}