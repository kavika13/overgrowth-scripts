//#pragma-transparent

uniform sampler2D tex0;
uniform sampler2D tex1;
uniform samplerCube tex2;
uniform samplerCube tex3;
uniform sampler2D tex4;
uniform sampler2D tex5;
uniform vec3 cam_pos;
uniform float in_light;
uniform float time;

varying vec3 light_pos; // light position in tangent space
varying mat3 tangent_to_world;
varying vec3 rel_pos;
varying float backlit;

#include "lighting.glsl"
#include "texturepack.glsl"

void main()
{	
	vec3 color;
	
	float shade_mult;
	vec4 normalmap = texture2D(tex1,tc0);
	vec3 normal = UnpackTanNormal(normalmap);
	
	vec3 shadow_tex = texture2D(tex4,tc1).rgb;
	
	float NdotL = GetDirectContrib(light_pos, normal,shadow_tex.r);
	float back_NdotL = 0.5-dot(light_pos, vec3(0.0,0.0,1.0))*0.5;

	vec3 diffuse_color = GetDirectColor(NdotL);
	
	vec3 diffuse_map_vec = tangent_to_world*normal;
	diffuse_color += LookupCubemapSimple(diffuse_map_vec, tex3) *
					 GetAmbientContrib(shadow_tex.g);
	
	/*float spec = GetSpecContrib(light_pos, normal, vertex_pos, shadow_tex.r);
	vec3 spec_color = gl_LightSource[0].diffuse.xyz * vec3(spec);
	
	vec3 spec_map_vec = tangent_to_world * reflect(vertex_pos,normal);
	spec_color += LookupCubemap(obj2worldmat3, spec_map_vec, tex3) * 0.2 *
				  GetAmbientContrib(shadow_tex.g);*/

	vec4 colormap = texture2D(tex0,tc0);

	color = diffuse_color * colormap.xyz;// + spec_color * GammaCorrectFloat(normalmap.a);
	
	color *= BalanceAmbient(NdotL);
	
	color += back_NdotL * gl_LightSource[0].diffuse.xyz * gl_LightSource[0].diffuse.a * 0.6 * texture2D(tex5,gl_TexCoord[0].xy).xyz * shadow_tex.r;

	AddHaze(color, rel_pos, tex3);
	
	//color = vec3(gl_TexCoord[1]);
	//color = vec3(shadow_tex.g);

	color *= Exposure();
	
	gl_FragColor = vec4(color,colormap.a);
}