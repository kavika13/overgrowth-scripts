uniform sampler2D tex;
uniform sampler2D tex2;

varying vec3 gravity;

void main()
{	
	vec3 color;
	
	color = gravity*0.5 + vec3(0.5);
	
	gl_FragColor = vec4(color,1.0);
}