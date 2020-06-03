uniform vec3 light_pos;
uniform sampler2D tex;
uniform samplerCube tex4;
uniform sampler2D tex5;
varying vec3 normal;

const float texture_offset = 0.002;

void main()
{	
	// Add direct lighting to baked texture
	vec4 shadow_texture = texture2D(tex5,gl_TexCoord[0].xy);
	vec4 shadow_texture_offset = texture2D(tex5,gl_TexCoord[0].xy + vec2(light_pos.x * texture_offset, light_pos.z * texture_offset));
	
	vec3 color = vec3(shadow_texture_offset.r * shadow_texture_offset.a * shadow_texture.b);
	
	// Add ambient lighting to baked texture
	vec3 diffuse_map_vec = normal;
	diffuse_map_vec.y *= -1.0;
	color += textureCube(tex4,diffuse_map_vec).xyz * shadow_texture.g;

	// Combine diffuse color with baked texture
	color *= texture2D(tex,gl_TexCoord[0].xy).xyz;
	
	gl_FragColor = vec4(color,1.0);
}