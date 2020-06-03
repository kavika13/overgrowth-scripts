uniform sampler2D tex;
uniform sampler2D tex2;
uniform samplerCube tex3;
uniform samplerCube tex4;
uniform sampler2D tex5;
uniform mat4 obj2world;
uniform vec3 cam_pos;

varying vec3 normal;
varying vec3 temp_tangent;
varying vec3 vertex_pos;
varying vec3 light_pos;
varying mat3 tangent_to_world;
varying vec3 rel_pos;

//#include "lighting.glsl"
 
void main()
{	
	vec4 terrain_color = texture2D(tex5,gl_TexCoord[0].xy);// + vec2(0.0,0.002));
	vec3 diffuse_color = terrain_color.xyz;
	
	//vec4 terrain_color = texture2D(tex5,gl_TexCoord[0].xy);
	vec4 detail = texture2D(tex,gl_TexCoord[1].xy);
	vec4 detail2 = texture2D(tex,gl_TexCoord[1].xy*0.25);
	vec4 detail3 = texture2D(tex,gl_TexCoord[1].xy*0.25*0.25);

	//diffuse_color *= (0.5 + detail.z + detail2.z);
	//diffuse_color *= 0.7;
	
	vec3 normal = normalize(vec3((detail.x-0.5)*2.0, (detail.y-0.5)*-2.0, detail.z - 0.5) + 
							vec3((detail2.x-0.5)*2.0, (detail2.y-0.5)*-2.0, detail2.z - 0.5) + 
							vec3((detail3.x-0.5)*2.0, (detail3.y-0.5)*-2.0, detail3.z - 0.5));	
	float NdotL = dot(normal,normalize(light_pos)) / light_pos.z;
	
	diffuse_color = diffuse_color * mix(1.0, NdotL, light_pos.z * 0.5);
	
	vec3 color = diffuse_color;
	
	AddHaze(color, rel_pos, tex4);

	color *= Exposure();

	gl_FragColor = vec4(color,terrain_color.a);
}