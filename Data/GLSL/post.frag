uniform sampler2DRect tex;
uniform sampler2DRect tex2;

void main()
{	
	vec3 color;
	
	vec3 color_map = texture2DRect( tex, gl_TexCoord[0].st ).rgb;
	/*float depth = texture2DRect( tex2, gl_TexCoord[0].st ).r;
	
	float near = 0.1;
	float far = 1000.0;
	float distance = (near * far) / (far - depth * (far - near));*/
	color = color_map;
			
	gl_FragColor = vec4(color,1.0);
}