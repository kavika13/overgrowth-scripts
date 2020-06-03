uniform sampler2D tex0;

void main()
{	
	gl_FragColor = vec4(0.0,0.0,0.0,texture2D(tex0,gl_TexCoord[0].xy).a*gl_Color.a*0.1);
}