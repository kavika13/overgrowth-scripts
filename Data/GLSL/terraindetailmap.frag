uniform sampler2D tex0;
uniform sampler2D tex1;
uniform samplerCube tex2;
uniform samplerCube tex3;
uniform sampler2D tex4;
uniform sampler2D tex5;
uniform sampler2D tex6;
uniform vec3 cam_pos;
uniform int weight_component;

varying vec3 tangent;
varying vec3 vertex_pos;
varying vec3 light_pos;
varying vec3 rel_pos;

#include "lighting.glsl"
#include "texturepack.glsl"

void main()
{	
	vec4 weight_map = texture2D(tex0,gl_TexCoord[0].xy);
	if(weight_map[weight_component]<0.0){
		discard;
	}

	vec3 color;
	vec3 shadow_tex = vec3(1.0);//texture2D(tex5,tc1).rgb;
	
	vec3 tint = texture2D(tex1,gl_TexCoord[0].xy).xyz;
	vec3 base_normalmap = texture2D(tex6,gl_TexCoord[0].xy).xyz;
	vec3 base_normal = normalize((base_normalmap*vec3(2.0))-vec3(1.0));
	vec3 bitangent = normalize(cross(tangent,base_normal));
	vec3 new_tangent = normalize(cross(base_normal,bitangent));

	vec4 normalmap = texture2D(tex5,gl_TexCoord[1].xy);
	vec3 normal = UnpackTanNormal(normalmap);

	normal = normal.x * new_tangent +
			 normal.y * bitangent +
			 normal.z * base_normal;

	

	float NdotL = GetDirectContrib(light_pos, normal,shadow_tex.r);
	vec3 diffuse_color = GetDirectColor(NdotL);
	
	vec3 diffuse_map_vec = normal;
	diffuse_color += LookupCubemapSimple(diffuse_map_vec, tex3) *
					 GetAmbientContrib(shadow_tex.g);
	
	vec3 H = normalize(normalize(vertex_pos*-1.0) + normalize(light_pos));
	float spec = min(1.0, pow(max(0.0,dot(normal,H)),10.0)*1.0 * NdotL) ;
	vec3 spec_color = gl_LightSource[0].diffuse.xyz * vec3(spec);
	
	vec3 spec_map_vec = reflect(vertex_pos,normal);
	spec_color += LookupCubemapSimple(spec_map_vec, tex2) * 0.5 *
				  GetAmbientContrib(shadow_tex.g);
	 
	vec4 colormap = texture2D(tex4,gl_TexCoord[1].xy);
	
	/*vec4 colormap_alt = texture2D(tex5,gl_TexCoord[1].xy*0.4);
	float blend = max(0.0,min(1.0,(length(rel_pos)-30.0)*0.1));
	colormap = mix(colormap,colormap_alt,blend);
*/
	color = diffuse_color * colormap.xyz * tint * 2.0;// + spec_color * colormap.a;

	color *= BalanceAmbient(NdotL);
	
	AddHaze(color, rel_pos, tex3);

	color *= Exposure();


	gl_FragColor = vec4(color,weight_map[weight_component]);
}