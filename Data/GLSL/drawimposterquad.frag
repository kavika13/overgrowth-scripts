uniform sampler2D tex0;
uniform sampler2D tex1;
uniform sampler2D tex2;
uniform sampler2D tex3;
uniform samplerCube tex4;
uniform sampler2D tex5;
uniform sampler2D tex6;
uniform sampler2D tex7;
uniform float rotation;
uniform float rotation_total;
uniform float rotation_total2;
uniform float radius;
uniform vec3 cam_pos;
uniform vec3 ws_light;
uniform float extra_ao;
uniform float fade;

varying vec3 ws_vertex;

#include "pseudoinstance.glsl"
#include "lighting.glsl"
#include "relativeskypos.glsl"

float rand(vec2 co){
	return fract(sin(dot(vec2(floor(co.x),floor(co.y)) ,vec2(12.9898,78.233))) * 43758.5453);
}

void main()
{		
	if((rand(gl_FragCoord.xy)) > fade){
		discard;
	};

	vec4 colormap = texture2D(tex0,gl_TexCoord[0].xy);
	
	vec4 shadow_coord = texture2D(tex5,gl_TexCoord[0].xy);
	vec3 shadow_tex = texture2D(tex7,gl_TexCoord[0].xy).xyz;
	//vec3 shadow_tex = texture2D(tex7,shadow_coord.xy).xyz;
	vec4 normal_tex = texture2D(tex1,gl_TexCoord[0].xy);
	vec3 os_normal = UnpackObjNormal(normal_tex);
	vec3 ws_normal = normalMatrix * os_normal;
	ws_normal = normalize(ws_normal);
	float NdotL = GetDirectContrib(ws_light, ws_normal, shadow_tex.r);
	vec3 diffuse_color = GetDirectColor(NdotL);
	vec3 ambient = LookupCubemapSimple(ws_normal, tex4) *
					 GetAmbientContrib(shadow_tex.g);
	diffuse_color += ambient;

	vec3 color = diffuse_color * colormap.xyz;
	
	vec3 trans_tex = texture2D(tex2, gl_TexCoord[0].xy).xyz;
	vec3 translucent_lighting = shadow_tex.r *
								vec3(gl_LightSource[0].diffuse.a);
	translucent_lighting += ambient;
	translucent_lighting *= GammaCorrectFloat(0.6);
	color += translucent_lighting * trans_tex;
	
	color *= BalanceAmbient(NdotL);
	
	color *= vec3(min(1.0,shadow_tex.g*2.0)*extra_ao + (1.0-extra_ao));
	AddHaze(color, TransformRelPosForSky(ws_vertex), tex4);

	color *= Exposure();

	gl_FragColor = vec4(color,colormap.a);
}