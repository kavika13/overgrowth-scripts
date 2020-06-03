uniform sampler2D tex0;
uniform sampler2D tex1;
uniform samplerCube tex2;
uniform samplerCube tex3;
uniform sampler2D tex4;
uniform vec3 cam_pos;
uniform float in_light;

varying vec3 vertex_pos;
varying vec3 light_pos;
varying vec3 rel_pos;
varying mat3 obj2worldmat3;

#include "lighting.glsl"
#include "texturepack.glsl"

void main()
{	
	vec3 color;
	
	vec3 shadow_tex = texture2D(tex4,tc1).rgb;
	
	vec4 normalmap = texture2D(tex1,tc0);
	vec3 normal = UnpackObjNormal(normalmap);

	float NdotL = GetDirectContrib(light_pos, normal, shadow_tex.r);
	vec3 diffuse_color = GetDirectColor(NdotL);
	diffuse_color += LookupCubemap(obj2worldmat3, normal, tex3) *
					 GetAmbientContrib(shadow_tex.g);
	
	float spec = GetSpecContrib(light_pos, normal, vertex_pos, shadow_tex.r);
	vec3 spec_color = gl_LightSource[0].diffuse.xyz * vec3(spec);
	
	vec3 spec_map_vec = reflect(vertex_pos,normal);
	spec_color += LookupCubemap(obj2worldmat3, spec_map_vec, tex2) * 0.5 *
				  GetAmbientContrib(shadow_tex.g);
	
	vec4 colormap = texture2D(tex0,gl_TexCoord[0].xy);
	
	color = diffuse_color * colormap.xyz + spec_color * GammaCorrectFloat(colormap.a);
	
	color *= BalanceAmbient(NdotL);
	
	AddHaze(color, rel_pos, tex3);

	color *= Exposure();

	gl_FragColor = vec4(color,1.0);
}