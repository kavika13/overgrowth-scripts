uniform sampler2D tex;

void main()
{	
	gl_FragColor = vec4(0.0,0.0,0.0,texture2D(tex,gl_TexCoord[0].xy).a*gl_Color.a*0.1);
}