//#pragma-transparent

uniform sampler2D tex;
uniform sampler2D tex2;
uniform samplerCube tex3;
uniform samplerCube tex4;
uniform sampler2D tex5;
uniform sampler2D tex6;
uniform vec3 cam_pos;
uniform float in_light;
uniform float time;

varying vec3 light_pos;
varying mat3 tangent_to_world;
varying vec3 rel_pos;
varying float backlit;

//#include "lighting.glsl"

void main()
{	
	vec3 color;
	
	float shade_mult;
	vec4 normalmap = texture2D(tex2,gl_TexCoord[0].xy);
	vec3 normal = UnpackTanNormal(normalmap);
	
	vec3 shadow_tex = texture2D(tex5,gl_TexCoord[1].xy).rgb;
	
	float NdotL = GetDirectContrib(light_pos, normal,shadow_tex.r);
	float back_NdotL = 0.5-dot(light_pos, vec3(0.0,0.0,1.0))*0.5;

	NdotL = GetDirectContrib((normal+light_pos)*0.5, light_pos,shadow_tex.r);
	
	vec3 diffuse_color = GetDirectColor(NdotL);

	vec4 colormap = texture2D(tex,gl_TexCoord[0].xy);

	color = diffuse_color * colormap.xyz;
	
	color *= BalanceAmbient(NdotL);
	
	vec3 backlit_color = back_NdotL * max(0.0,(1.0-NdotL)) * gl_LightSource[0].diffuse.xyz * gl_LightSource[0].diffuse.a * 0.6 * texture2D(tex6,gl_TexCoord[0].xy).xyz * shadow_tex.r;

	color += backlit*backlit_color;

	vec3 diffuse_map_vec = tangent_to_world*normal;
	color += colormap.xyz * LookupCubemapSimple(diffuse_map_vec, tex4) *
					 GetAmbientContrib(shadow_tex.g);

	AddHaze(color, rel_pos, tex4);
	
	color *= Exposure();

	//color = vec3(backlit);

	gl_FragColor = vec4(color,colormap.a);
}