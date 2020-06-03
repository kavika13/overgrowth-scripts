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
	float NdotL = max(dot(normal,normalize(light_pos)),0.0) / light_pos.z;
	
	diffuse_color = diffuse_color * mix(1.0, NdotL, light_pos.z);
	
	vec3 color = diffuse_color;
	
	float near = 0.1;
	float far = 1000.0;
	
	color = mix(color, textureCube(tex4,normalize(rel_pos)).xyz, length(rel_pos)/far);
	
	//color = terrain_color.xyz;

	
	gl_FragColor = vec4(color,1.0);
}