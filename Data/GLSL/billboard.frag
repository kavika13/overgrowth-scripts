uniform sampler2D tex;

void main()
{	
	vec4 color_tex = texture2D(tex,gl_TexCoord[0].xy);
		
	gl_FragColor = color_tex;
}