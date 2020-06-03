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
	// Sample normalmap color and convert it to a world-space vector
	vec4 normalmap = texture2D(tex2,gl_TexCoord[1].xy);
	vec3 normal = normalize(vec3((normalmap.z-0.5)*-2.0, (normalmap.x-0.5)*2.0, (normalmap.y-0.5)*-2.0));

	// Calculate direct lighting (from sun)
	float NdotL = max(0.0,dot(light_pos, normal));
	vec3 diffuse_color = vec3(NdotL);
	
	// Calculate ambient lighting
	vec3 diffuse_map_vec = normal;
	diffuse_map_vec.y *= -1.0;
	diffuse_color += textureCube(tex4,diffuse_map_vec).xyz;
	
	// Sample color texture and detail texture
	vec4 terrain_color = texture2D(tex5,gl_TexCoord[1].xy);
	vec4 detail = texture2D(tex,gl_TexCoord[0].xy);
	vec4 detail2 = texture2D(tex,gl_TexCoord[0].xy*0.25);

	// Multiply diffuse color by color texture and detail texture
	diffuse_color *= terrain_color.xyz;
	diffuse_color *= (0.5 + detail.x + detail2.x);
	
	// Add haze
	float near = 0.1;
	float far = 1000.0;
	vec3 color = mix(diffuse_color, textureCube(tex4,normalize(rel_pos)).xyz, length(rel_pos)/far);
	
	gl_FragColor = vec4(color,1.0);
}