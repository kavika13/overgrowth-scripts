//#pragma-transparent

uniform sampler2D tex0;
uniform sampler2D tex1;
uniform samplerCube tex2;
uniform samplerCube tex3;
uniform sampler2D tex4;
uniform vec3 cam_pos;
uniform float in_light;

varying vec3 vertex_pos;
varying vec3 light_pos;
varying mat3 tangent_to_world;
varying vec3 rel_pos;

#include "lighting.glsl"
#include "texturepack.glsl"

void main()
{	
	vec3 color;
	
	vec3 shadow_tex = vec3(1.0);
	//vec3 shadow_tex = texture2D(tex4,tc1).rgb;
	
	vec4 normalmap = texture2D(tex1,tc0);
	vec3 normal = UnpackTanNormal(normalmap);
	
	float NdotL = GetDirectContrib(light_pos, normal,shadow_tex.r);
	vec3 diffuse_color = GetDirectColor(NdotL);
	
	vec3 diffuse_map_vec = tangent_to_world*normal;
	diffuse_color += LookupCubemapSimple(diffuse_map_vec, tex3) *
					 GetAmbientContrib(shadow_tex.g);
	
	vec3 H = normalize(normalize(vertex_pos*-1.0) + normalize(light_pos));
	float spec = min(1.0, pow(max(0.0,dot(normal,H)),10.0)*1.0 * NdotL) ;
	vec3 spec_color = gl_LightSource[0].diffuse.xyz * vec3(spec);
	
	vec3 spec_map_vec = tangent_to_world * reflect(vertex_pos,normal);
	spec_color += LookupCubemapSimple(spec_map_vec, tex2) * 0.5 *
				  GetAmbientContrib(shadow_tex.g);
	 
	vec4 colormap = texture2D(tex0,tc0);
	
	color = diffuse_color * 0.5 + 2.0 * spec_color * normalmap.a;
	
	//color = diffuse_color * colormap.xyz + spec_color * normalmap.a;
	
	color *= BalanceAmbient(NdotL);
	
	AddHaze(color, rel_pos, tex3);

	color *= Exposure();

	gl_FragColor = vec4(color,colormap.a);
}
