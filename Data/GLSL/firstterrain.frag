uniform vec3 light_pos;
varying vec3 normal;
varying vec3 shadows;

void main()
{	
	// Encode direct lighting in red channel
	float NdotL = max(0.0,dot(light_pos, normal)) * max(0.0,shadows.x);
	vec3 color = vec3(0);
	color.r = NdotL;
	
	// Encode ambient occlusion in green channel
	color.g = shadows.y;
	
	color.b = shadows.z;
	
	gl_FragColor = vec4(color,1.0);
}