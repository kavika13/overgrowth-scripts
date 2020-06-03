uniform sampler2D tex;
uniform samplerCube tex4;
uniform sampler2D tex5;
varying vec3 normal;

void main()
{	
	// Add direct lighting to baked texture
	vec4 shadow_texture = texture2D(tex5,gl_TexCoord[0].xy);
	vec3 color = vec3(shadow_texture.r);
	
	// Add ambient lighting to baked texture
	vec3 diffuse_map_vec = normal;
	diffuse_map_vec.y *= -1.0;
	color += textureCube(tex4,diffuse_map_vec).xyz * shadow_texture.g;

	// Combine diffuse color with baked texture
	color *= texture2D(tex,gl_TexCoord[0].xy).xyz;
	
	gl_FragColor = vec4(color,1.0);
}