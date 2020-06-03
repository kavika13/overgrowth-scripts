//#pragma-transparent

uniform sampler2D tex;
uniform sampler2D tex2;
uniform samplerCube tex3;
uniform samplerCube tex4;
uniform sampler2D tex5;
uniform sampler2D tex6;
uniform vec3 cam_pos;
uniform mat3 test;
uniform mat4 obj2world;

varying vec3 vertex_pos;
varying vec3 light_pos;
varying mat3 tangent_to_world;
varying vec3 rel_pos;

//#include "lighting.glsl"

void main()
{	
	vec3 color;
	
	vec3 shadow_tex = texture2D(tex5,gl_TexCoord[0].st).rgb;
	vec3 base_normal_tex = texture2D(tex6,gl_TexCoord[0].st).rgb;
	vec3 base_normal = (base_normal_tex-vec3(0.5))*2.0;

	float shade_mult;
	vec4 normalmap = texture2D(tex2,gl_TexCoord[0].st);
	vec3 normal = base_normal;
	vec3 tangent = gl_TexCoord[2].xyz;
	vec3 bitangent = normalize(cross(tangent,normal));
	tangent = normalize(cross(normal,bitangent));

	normal = normalize(base_normal * (normalmap.b*2.0) +
					   tangent * ((normalmap.x-0.5)*2.0) +
					   bitangent * ((normalmap.y-0.5)*2.0));
	
	float NdotL = GetDirectContrib(light_pos, normal, shadow_tex.r);
	vec3 diffuse_color = GetDirectColor(NdotL);

	diffuse_color += LookupCubemapSimple(normal, tex4) *
					 GetAmbientContrib(shadow_tex.g);

	float spec = GetSpecContrib(light_pos, normal, vertex_pos, shadow_tex.r);
	vec3 spec_color = gl_LightSource[0].diffuse.xyz * vec3(spec);
	
	vec3 spec_map_vec = reflect(vertex_pos,normal);
	spec_color += LookupCubemapSimple(spec_map_vec, tex3) * 0.5 *
				  GetAmbientContrib(shadow_tex.g);

	vec4 colormap = texture2D(tex,gl_TexCoord[0].st);
	
	color = diffuse_color * colormap.xyz + spec_color * normalmap.a;
	
	color *= BalanceAmbient(NdotL);
	
	AddHaze(color, rel_pos, tex4);

	//color = shadow_tex.rgb;

	gl_FragColor = vec4(color,colormap.a);
}