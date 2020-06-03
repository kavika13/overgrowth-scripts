//#pragma-transparent

uniform sampler2D tex;
uniform sampler2D tex2;
uniform samplerCube tex3;
uniform samplerCube tex4;
uniform sampler2D tex5;
uniform sampler2D tex6;
uniform mat4 obj2world;
uniform vec3 cam_pos;
uniform float in_light;
uniform float time;

varying vec3 vertex_pos;
varying vec3 light_pos;
varying mat3 tangent_to_world;
varying vec3 rel_pos;
varying vec3 world_light;

//#include "lighting.glsl"

void main()
{	
	mat3 obj2world3 = mat3(obj2world[0].xyz, obj2world[1].xyz, obj2world[2].xyz);
	vec3 color;
	
	float shade_mult;
	vec4 normalmap = texture2D(tex2,gl_TexCoord[0].xy);
	vec3 normal = UnpackTanNormal(normalmap);
	
	vec3 shadow_tex = texture2D(tex5,gl_TexCoord[1].xy).rgb;
	
	float NdotL = GetDirectContrib(light_pos, normal,shadow_tex.r);
	float back_NdotL = 0.5-dot(light_pos, vec3(0.0,0.0,1.0))*0.5;

	vec3 diffuse_color = GetDirectColor(NdotL);
	
	vec3 diffuse_map_vec = tangent_to_world*normal;
	diffuse_color += LookupCubemap(obj2world, diffuse_map_vec, tex4) *
					 GetAmbientContrib(shadow_tex.g);
	
	float spec = GetSpecContrib(light_pos, normal, vertex_pos, shadow_tex.r);
	vec3 spec_color = gl_LightSource[0].diffuse.xyz * vec3(spec);
	
	vec3 spec_map_vec = tangent_to_world * reflect(vertex_pos,normal);
	spec_color += LookupCubemap(obj2world, spec_map_vec, tex3) * 0.2 *
				  GetAmbientContrib(shadow_tex.g);

	vec4 colormap = texture2D(tex,gl_TexCoord[0].xy);

	color = diffuse_color * colormap.xyz + spec_color * normalmap.a;
	
	color *= BalanceAmbient(NdotL);
	
	vec3 fixed_world_light = world_light;
	fixed_world_light.x *= -1.0;
	fixed_world_light.y *= -1.0;
	float backlit = max(0.0,dot(fixed_world_light,normalize(rel_pos)));
	color += back_NdotL * gl_LightSource[0].diffuse.xyz * gl_LightSource[0].diffuse.a * 0.6 * texture2D(tex6,gl_TexCoord[0].xy).xyz * shadow_tex.r;

	AddHaze(color, rel_pos, tex4);
	
	//color = vec3(gl_TexCoord[1]);
	//color = vec3(shadow_tex.g);

	color *= Exposure();
	
	gl_FragColor = vec4(color,colormap.a);
}