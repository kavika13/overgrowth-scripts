uniform sampler2D tex0;
uniform sampler2D tex1;
uniform samplerCube tex2;
uniform samplerCube tex3;
uniform sampler2D tex4;
uniform sampler2D tex5;
uniform sampler2D tex6;
uniform sampler2D tex7;
uniform sampler2D tex8;
uniform sampler2D tex9;
uniform sampler2D tex10;
uniform sampler2D tex11;
uniform sampler2D tex12;
uniform sampler2D tex13;
uniform vec3 avg_color0;
uniform vec3 avg_color1;
uniform vec3 avg_color2;
uniform vec3 avg_color3;
uniform vec3 cam_pos;
uniform int weight_component;

varying vec3 tangent;
varying vec3 vertex_pos;
varying vec3 light_pos;
varying vec3 rel_pos;
varying float alpha;

#include "lighting.glsl"
#include "texturepack.glsl"

void main()
{	
	vec4 weight_map = texture2D(tex0,gl_TexCoord[0].xy);

	vec3 color = vec3(0.0);

	vec3 terrain_color = texture2D(tex1,gl_TexCoord[0].xy).xyz;
	
	vec3 average_color = vec3(0.0);
	vec3 shadow_tex = texture2D(tex5,gl_TexCoord[0].xy).rgb;
	
	weight_map[3] = 1.0 - (weight_map[0]+weight_map[1]+weight_map[2]);
	float total_weight = weight_map[0] +
						 weight_map[1] +
						 weight_map[2] +
						 weight_map[3];

	float inv_total_weight = 1.0 / total_weight;

	average_color = avg_color0 * weight_map[0] +
					avg_color1 * weight_map[1] +
					avg_color2 * weight_map[2] +
					avg_color3 * weight_map[3];
	average_color *= inv_total_weight;
	
	vec3 tint = terrain_color / average_color;

	color = tint;

	vec3 base_normalmap = texture2D(tex4,gl_TexCoord[0].xy).xyz;
	vec3 base_normal = normalize((base_normalmap*vec3(2.0))-vec3(1.0));
	vec3 bitangent = normalize(cross(tangent,base_normal));
	vec3 new_tangent = normalize(cross(base_normal,bitangent));

	mat3 to_normal = mat3(new_tangent,
						  bitangent,
						  base_normal);

	float NdotL;
	vec3 diffuse_color;
	vec3 H;
	float spec;
	vec3 spec_color;
	vec3 spec_map_vec;

	float fade_distance = 100.0;
	float fade = min(1.0,max(0.0,length(rel_pos)/fade_distance));

	vec3 normalmap = (texture2D(tex7,gl_TexCoord[1].xy) * weight_map[0] +
					 texture2D(tex9,gl_TexCoord[1].xy) * weight_map[1] +
					 texture2D(tex11,gl_TexCoord[1].xy) * weight_map[2] +
					 texture2D(tex13,gl_TexCoord[1].xy) * weight_map[3]).xyz;
	normalmap *= inv_total_weight;
	normalmap = UnpackTanNormal(vec4(normalmap,1.0));
	normalmap.xyz = mix(normalmap.xyz,vec3(0.0,0.0,1.0),fade);
	
	vec3 normal = to_normal * normalmap;
	NdotL = GetDirectContrib(light_pos, normal,shadow_tex.r);
	diffuse_color = GetDirectColor(NdotL);
	
	diffuse_color += LookupCubemapSimple(normal, tex3) *
					 GetAmbientContrib(shadow_tex.g);
	
	H = normalize(normalize(vertex_pos*-1.0) + normalize(light_pos));
	spec = min(1.0, pow(max(0.0,dot(normal,H)),10.0)*1.0 * NdotL) ;
	spec_color = gl_LightSource[0].diffuse.xyz * vec3(spec);
	
	spec_map_vec = reflect(vertex_pos,normal);
	spec_color += LookupCubemapSimple(spec_map_vec, tex2) * 0.5 *
				  GetAmbientContrib(shadow_tex.g);
	 
	vec4 colormap = texture2D(tex6,gl_TexCoord[1].xy) * weight_map[0] +
				    texture2D(tex8,gl_TexCoord[1].xy) * weight_map[1] +
				    texture2D(tex10,gl_TexCoord[1].xy) * weight_map[2] +
				    texture2D(tex12,gl_TexCoord[1].xy) * weight_map[3];
	colormap *= inv_total_weight;

	colormap.xyz = mix(colormap.xyz,average_color,fade);
	
	color = diffuse_color * colormap.xyz * tint + spec_color * colormap.a;
	color *= BalanceAmbient(NdotL);
	
	AddHaze(color, rel_pos, tex3);

	color *= Exposure();

	//color = weight_map.xyz;

	gl_FragColor = vec4(color,alpha);
}