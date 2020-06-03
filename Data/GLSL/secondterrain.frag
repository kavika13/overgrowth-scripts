uniform vec3 light_pos;
uniform sampler2D tex;
uniform sampler2D tex2;
uniform samplerCube tex4;
uniform sampler2D tex5;
varying vec3 normal;

const float texture_offset = 0.001;
const float border_fade_size = 0.1;

void main()
{	
	vec4 normal_map = texture2D(tex5,gl_TexCoord[0].xy+vec2(light_pos.x * texture_offset, light_pos.z * texture_offset));
	
	vec3 normal_vec = normalize((normal_map.xyz*vec3(2.0))-vec3(1.0));
	
	float NdotL = max(0.0,dot(light_pos, normal_vec));

	NdotL = NdotL * texture2D(tex2,gl_TexCoord[0].xy).x;
	
	vec3 color = vec3(NdotL);
	
	// Add ambient lighting to baked texture
	vec3 diffuse_map_vec = normal_vec;
	diffuse_map_vec.y *= -1.0;
	color += textureCube(tex4,diffuse_map_vec).xyz * (1.0-NdotL);

	// Combine diffuse color with baked texture
	color *= texture2D(tex,gl_TexCoord[0].xy).xyz;
	
	float alpha = 1.0;
	if(gl_TexCoord[0].x<border_fade_size) {
		alpha *= gl_TexCoord[0].x/border_fade_size;
	}
	if(gl_TexCoord[0].x>1.0-border_fade_size) {
		alpha *= (1.0-gl_TexCoord[0].x)/border_fade_size;
	}
	if(gl_TexCoord[0].y<border_fade_size) {
		alpha *= gl_TexCoord[0].y/border_fade_size;
	}
	if(gl_TexCoord[0].y>1.0-border_fade_size) {
		alpha *= (1.0-gl_TexCoord[0].y)/border_fade_size;
	}
	
	gl_FragColor = vec4(color,alpha);
}