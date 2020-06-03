uniform sampler2D tex0;

void main()
{	
	gl_FragColor = vec4(gl_TexCoord[1].xy,1.0,texture2D(tex0,gl_TexCoord[0].xy).a);
}