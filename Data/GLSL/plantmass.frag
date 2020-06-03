#pragma transparent

uniform sampler2D tex0;
uniform sampler2D tex1;
uniform samplerCube tex2;
uniform samplerCube tex3;
uniform sampler2D tex4;
uniform sampler2D tex5;
uniform vec3 cam_pos;
uniform float in_light;
uniform float time;
uniform vec3 ws_light;

varying mat3 tangent_to_world;
varying vec3 ws_vertex;

#include "lighting.glsl"
#include "texturepack.glsl"
#include "relativeskypos.glsl"

void main()
{	
	
	// Calculate normal
	vec4 normalmap = texture2D(tex1,tc0);
	vec3 normal = UnpackTanNormal(normalmap);
	vec3 ws_normal = tangent_to_world * normal;

	// Calculate diffuse lighting
	vec3 shadow_tex = texture2D(tex4,tc1).rgb;
	float NdotL = GetDirectContrib(ws_light, ws_normal, shadow_tex.r);
	vec3 diffuse_color = GetDirectColor(NdotL);

	vec3 ambient = LookupCubemapSimple(ws_normal, tex3) *
					 GetAmbientContrib(shadow_tex.g);
	diffuse_color += ambient;

	
	// Calculate translucency

	vec3 translucent_lighting = GetDirectColor(shadow_tex.r) * 
								gl_LightSource[0].diffuse.a;
	translucent_lighting += ambient;

	translucent_lighting *= GammaCorrectFloat(0.6);
	
	vec4 colormap = texture2D(tex0,tc0);
	vec3 translucent_map = texture2D(tex5,tc0).xyz;
	vec3 color = diffuse_color * colormap.xyz + translucent_lighting * translucent_map;
	
	color *= BalanceAmbient(NdotL);
	color *= vec3(min(1.0,shadow_tex.g*2.0));
	AddHaze(color, TransformRelPosForSky(ws_vertex), tex3);
	color *= Exposure();

	gl_FragColor = vec4(color,colormap.a);
}