uniform vec3 light_pos;
uniform sampler2D tex0;
uniform sampler2D tex1;
uniform samplerCube tex3;
uniform sampler2D tex4;
varying vec3 normal;

const float texture_offset = 0.001;
const float border_fade_size = 0.1;

#include "lighting.glsl"

void main()
{	
	vec4 normal_map = texture2D(tex4,gl_TexCoord[0].xy+vec2(light_pos.x * texture_offset, light_pos.z * texture_offset));
	vec3 normal_vec = normalize((normal_map.xyz*vec3(2.0))-vec3(1.0));
	
	vec3 shadow_tex = texture2D(tex1,gl_TexCoord[0].xy).rgb;

	float NdotL = GetDirectContrib(light_pos, normal_vec, shadow_tex.r);

	vec3 color = GetDirectColor(NdotL);
	
	// Add ambient lighting to baked texture
	color += LookupCubemapSimple(normal_vec, tex3) * GetAmbientContrib(shadow_tex.g);

	// Combine diffuse color with baked texture
	color *= texture2D(tex0,gl_TexCoord[0].xy).xyz;
	
	color *= BalanceAmbient(NdotL);

	float alpha = 1.0;
	if(gl_TexCoord[0].x<border_fade_size) {
		alpha *= gl_TexCoord[0].x/border_fade_size;
	}
	if(gl_TexCoord[0].x>1.0-border_fade_size) {
		alpha *= (1.0-gl_TexCoord[0].x)/border_fade_size;
	}
	if(gl_TexCoord[0].y<border_fade_size) {
		alpha *= gl_TexCoord[0].y/border_fade_size;
	}
	if(gl_TexCoord[0].y>1.0-border_fade_size) {
		alpha *= (1.0-gl_TexCoord[0].y)/border_fade_size;
	}
		
	gl_FragColor = vec4(color,alpha);
}