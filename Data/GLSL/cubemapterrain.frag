uniform sampler2D tex;
uniform sampler2D tex2;
uniform samplerCube tex3;
uniform samplerCube tex4;
uniform sampler2D tex5;
uniform mat4 obj2world;
uniform vec3 cam_pos;

varying vec3 vertex_pos;
varying vec3 light_pos;
varying mat3 tangent_to_world;
varying vec3 rel_pos;

void main()
{	
	vec4 normalmap = texture2D(tex2,gl_TexCoord[1].xy);
	vec3 normal = normalize(vec3((normalmap.z-0.5)*-2.0, (normalmap.x-0.5)*2.0, (normalmap.y-0.5)*-2.0));

	float NdotL = max(0.0,dot(light_pos, normal));
	vec3 diffuse_color = vec3(NdotL);
	
	
	vec3 diffuse_map_vec = normal;
	diffuse_map_vec.y *= -1.0;
	diffuse_color += textureCube(tex4,diffuse_map_vec).xyz;
	
	
	vec4 terrain_color = texture2D(tex5,gl_TexCoord[1].xy);
	vec4 detail = texture2D(tex,gl_TexCoord[0].xy);
	vec4 detail2 = texture2D(tex,gl_TexCoord[0].xy*0.25);

	diffuse_color *= terrain_color.xyz;
	diffuse_color *= (0.5 + detail.x + detail2.x);
	
	vec3 color = diffuse_color;
	
	float near = 0.1;
	float far = 1000.0;
	
	color = mix(color, textureCube(tex4,normalize(rel_pos)).xyz, length(rel_pos)/far);
	
	gl_FragColor = vec4(color,1.0);
}