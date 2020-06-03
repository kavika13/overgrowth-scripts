uniform sampler2D tex;
uniform sampler2D tex2;
uniform samplerCube tex3;
uniform samplerCube tex4;
uniform sampler2D tex5;
uniform vec3 cam_pos;
uniform float in_light;

varying vec3 vertex_pos;
varying vec3 light_pos;
varying vec3 rel_pos;
varying mat3 obj2worldmat3;

//#include "lighting.glsl"

void main()
{	
	mat3 tangent_to_world;

	vec3 color;
	
	vec3 shadow_tex = texture2D(tex5,gl_TexCoord[1].xy).rgb;
	
	vec4 normalmap = texture2D(tex2,gl_TexCoord[0].xy);
	vec3 normal = UnpackTanNormal(normalmap);
	
	normal = vec3(0,0,1);

	float NdotL = GetDirectContrib(light_pos, normal,shadow_tex.r);
	vec3 diffuse_color = GetDirectColor(NdotL);
	
	vec3 diffuse_map_vec = tangent_to_world*normal;
	diffuse_color += LookupCubemap(obj2worldmat3, diffuse_map_vec, tex4) *
					 GetAmbientContrib(shadow_tex.g);
	
	vec3 H = normalize(normalize(vertex_pos*-1.0) + normalize(light_pos));
	float spec = min(1.0, pow(max(0.0,dot(normal,H)),10.0)*1.0 * NdotL) ;
	vec3 spec_color = gl_LightSource[0].diffuse.xyz * vec3(spec);
	
	vec3 spec_map_vec = tangent_to_world * reflect(vertex_pos,normal);
	spec_color += LookupCubemap(obj2worldmat3, spec_map_vec, tex3) * 0.5 *
				  GetAmbientContrib(shadow_tex.g);
	 
	vec4 colormap = texture2D(tex,gl_TexCoord[0].xy);
	
	color = diffuse_color * colormap.xyz + spec_color * colormap.a;
	
	color *= BalanceAmbient(NdotL);
	
	AddHaze(color, rel_pos, tex4);

	color *= Exposure();

	//color = gl_Color.xyz;

	gl_FragColor = vec4(color,1.0);
}