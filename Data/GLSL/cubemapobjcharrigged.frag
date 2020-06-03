uniform sampler2D tex0;
uniform sampler2D tex1;
uniform samplerCube tex2;
uniform samplerCube tex3;
uniform sampler2D tex4;
uniform sampler2DShadow tex5;
uniform mat4 obj2world;
uniform vec3 cam_pos;
uniform float in_light;
uniform mat4 shadowmat;
//uniform mat4 bones[64];

varying vec3 vertex_pos;
varying vec3 light_pos;
varying vec3 rel_pos;
varying vec3 world_light;
varying vec3 concat_bone1;
varying vec3 concat_bone2;
varying vec3 concat_bone3;

#include "lighting.glsl"

void main()
{	
	vec3 color;
	
	vec3 shadow_tex = vec3(1.0);
	shadow_tex.x = shadow2DProj(tex5,gl_TexCoord[2]+vec4(0.0,0.0,-0.00001,0.0)).r;
;
	
	vec4 normalmap = texture2D(tex1,gl_TexCoord[0].xy);
	
	mat3 concat_bone;
	concat_bone[0] = concat_bone1;
	concat_bone[1] = concat_bone2;
	concat_bone[2] = concat_bone3;
	vec3 normal = normalize(concat_bone * UnpackObjNormal(normalmap));

	//vec4 temp_normal = vec4(normal,0.0);
	//temp_normal = concat_bone * temp_normal;
	//normal = normalize(temp_normal.xyz);

	float NdotL = GetDirectContrib(light_pos, normal, shadow_tex.r);
	
	vec3 diffuse_color = GetDirectColor(NdotL);
	diffuse_color += LookupCubemapMat4(obj2world, normal, tex3) *
					 GetAmbientContrib(shadow_tex.g);
	
	float spec = GetSpecContrib(light_pos, normal, vertex_pos, shadow_tex.r);
	vec3 spec_color = gl_LightSource[0].diffuse.xyz * vec3(spec);
	
	vec3 spec_map_vec = reflect(vertex_pos,normal);
	spec_color += LookupCubemapMat4(obj2world, spec_map_vec, tex2) * 0.5 *
				  GetAmbientContrib(shadow_tex.g);
	
	vec4 colormap = texture2D(tex0,gl_TexCoord[0].xy);
	
	color = diffuse_color * colormap.xyz + spec_color * GammaCorrectFloat(colormap.a);
	
	color *= BalanceAmbient(NdotL);
	
	AddHaze(color, rel_pos, tex3);

	color *= Exposure();

	vec3 view = normalize(vertex_pos*-1.0);
	float back_lit = max(0.0,dot(normalize(rel_pos),world_light)); 
	//float back_lit = (dot(normalize(rel_pos),world_light)+1.0)*0.5; 
	float rim_lit = max(0.0,(1.0-dot(view,normal)));
	//rim_lit = pow(rim_lit,0.8);
	//rim_lit *= min(1.0,max(0.0,(obj2world*vec4(normal,0.0)).y+0.5));
	rim_lit *= pow((dot(light_pos,normal)+1.0)*0.5,0.5);
	color += vec3(back_lit*rim_lit) * GammaCorrectFloat(normalmap.a) * gl_LightSource[0].diffuse.xyz * gl_LightSource[0].diffuse.a * shadow_tex.r;
	
	//color = diffuse_color;

	//color = back_lit;

	//color = spec_color;

	//color = vec3(dot(light_pos,normal));

	//color = vec3(NdotL*0.6);

	//color = gl_TexCoord[1].xyz;

	gl_FragColor = vec4(color,1.0);
}