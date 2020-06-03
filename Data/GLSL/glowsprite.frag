uniform sampler2D tex;

void main()
{	
	vec3 color;
	
	vec4 color_tex = texture2D(tex,gl_TexCoord[0].xy);
	
	color = gl_Color.xyz * color_tex.xyz;

	gl_FragColor = vec4(color,color_tex.a*gl_Color.a);
}