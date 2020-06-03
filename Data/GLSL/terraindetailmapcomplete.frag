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
uniform vec3 ws_light;

varying vec3 tangent;
varying vec3 ws_vertex;
varying float alpha;

#include "lighting.glsl"
#include "texturepack.glsl"
#include "relativeskyposfrag.glsl"

void main()
{	
	// Get weights
	vec4 weight_map = texture2D(tex0,tc0);
	weight_map[3] = 1.0 - (weight_map[0]+weight_map[1]+weight_map[2]);

	// Get fade
	float detail_fade_distance = 200.0;
	float detail_fade = min(1.0,max(0.0,length(ws_vertex)/detail_fade_distance));

	// Get normal
	vec3 base_normalmap = texture2D(tex4,tc0).xyz;
	vec3 base_normal = normalize((base_normalmap*vec3(2.0))-vec3(1.0));
	vec3 base_bitangent = normalize(cross(tangent,base_normal));
	vec3 base_tangent = normalize(cross(base_normal,base_bitangent));

	mat3 ws_from_ns = mat3(base_tangent,
						   base_bitangent,
						   base_normal);

	vec4 normalmap = (texture2D(tex7 ,tc1) * weight_map[0] +
					  texture2D(tex9 ,tc1) * weight_map[1] +
					  texture2D(tex11,tc1) * weight_map[2] +
					  texture2D(tex13,tc1) * weight_map[3]);
	normalmap.xyz = UnpackTanNormal(normalmap);
	normalmap.xyz = mix(normalmap.xyz,vec3(0.0,0.0,1.0),detail_fade);
	
	vec3 ws_normal = ws_from_ns * normalmap.xyz;

	// Get diffuse lighting
	vec3 shadow_tex = texture2D(tex5,tc0).rgb;
	float NdotL = GetDirectContrib(ws_light, ws_normal, shadow_tex.r);
	vec3 diffuse_color = GetDirectColor(NdotL);
	
	diffuse_color += LookupCubemapSimple(ws_normal, tex3) *
					 GetAmbientContrib(shadow_tex.g);
	
	// Get spec lighting
	vec3 ws_H = normalize(normalize(ws_vertex*-1.0) + ws_light);
	float spec = min(1.0, pow(max(0.0,dot(ws_normal,ws_H)),10.0) * shadow_tex.r);
	vec3 spec_color = gl_LightSource[0].diffuse.xyz * vec3(spec);
	
	vec3 spec_map_vec = reflect(ws_vertex,ws_normal);
	spec_color += LookupCubemapSimple(spec_map_vec, tex2) *
				  GetAmbientContrib(shadow_tex.g);
	
	// Get tint
	vec3 average_color = avg_color0 * weight_map[0] +
					     avg_color1 * weight_map[1] +
						 avg_color2 * weight_map[2] +
						 avg_color3 * weight_map[3];
	vec3 terrain_color = texture2D(tex1,tc0).xyz;
	vec3 tint = terrain_color / average_color;

	// Get colormap
	vec4 colormap = texture2D(tex6,tc1) * weight_map[0] +
				    texture2D(tex8,tc1) * weight_map[1] +
				    texture2D(tex10,tc1) * weight_map[2] +
				    texture2D(tex12,tc1) * weight_map[3];
	colormap.xyz = mix(colormap.xyz,average_color,detail_fade);

	// Put it all together
	vec3 color = diffuse_color * colormap.xyz * tint + spec_color * GammaCorrectFloat(colormap.a);
	color *= BalanceAmbient(NdotL);
	AddHaze(color, TransformRelPosForSky(ws_vertex), tex3);
	color *= Exposure();
	
	gl_FragColor = vec4(color,alpha);
}
