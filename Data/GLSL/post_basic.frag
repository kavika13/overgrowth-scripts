#extension GL_ARB_texture_rectangle : enable

uniform sampler2DRect tex;
uniform sampler2DRect tex2;

void main()
{	
	vec3 color_map = texture2DRect( tex, gl_TexCoord[0].st ).rgb;
	/*float depth = texture2DRect( tex2, gl_TexCoord[0].st ).r;
	
	float near = 0.1;
	float far = 1000.0;
	float distance = (near) / (far - depth * (far - near));*/

	gl_FragColor = vec4(color_map,1.0);
}