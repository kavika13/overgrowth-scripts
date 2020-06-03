uniform sampler2D tex0;

varying vec3 normal;
varying vec3 shadows;

void main()
{	
	// Encode direct lighting in red channel
	vec3 color = vec3(0);
	color.r = max(0.0,shadows.x*shadows.z);
	
	// Encode ambient occlusion in green channel
	color.g = shadows.y;
	
	color.b = texture2D(tex0,gl_TexCoord[0].xy).r;
	
	gl_FragColor = vec4(color,1.0);
}