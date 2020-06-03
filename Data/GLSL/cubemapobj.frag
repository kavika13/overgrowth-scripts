uniform sampler2D tex;
uniform sampler2D tex2;
uniform samplerCube tex3;
uniform samplerCube tex4;
uniform sampler2D tex5;
uniform mat4 obj2world;
uniform vec3 cam_pos;
uniform float in_light;

varying vec3 vertex_pos;
varying vec3 light_pos;
varying vec3 rel_pos;

//#include "lighting.glsl"

void main()
{	
	vec3 color;
	
	vec3 shadow_tex = texture2D(tex5,gl_TexCoord[1].xy).rgb;
	
	vec4 normalmap = texture2D(tex2,gl_TexCoord[0].xy);
	vec3 normal = UnpackObjNormal(normalmap);

	float NdotL = GetDirectContrib(light_pos, normal, shadow_tex.r);
	vec3 diffuse_color = GetDirectColor(NdotL);
	diffuse_color += LookupCubemap(obj2world, normal, tex4) *
					 GetAmbientContrib(shadow_tex.g);
	
	float spec = GetSpecContrib(light_pos, normal, vertex_pos, shadow_tex.r);
	vec3 spec_color = gl_LightSource[0].diffuse.xyz * vec3(spec);
	
	vec3 spec_map_vec = reflect(vertex_pos,normal);
	spec_color += LookupCubemap(obj2world, spec_map_vec, tex3) * 0.5 *
				  GetAmbientContrib(shadow_tex.g);
	
	vec4 colormap = texture2D(tex,gl_TexCoord[0].xy);
	
	color = diffuse_color * colormap.xyz + spec_color * colormap.a;
	
	color *= BalanceAmbient(NdotL);
	
	AddHaze(color, rel_pos, tex4);

	color *= Exposure();

	gl_FragColor = vec4(color,1.0);
}