uniform sampler2D tex;

void main()
{	
	if(texture2D(tex,gl_TexCoord[0].xy).a < 0.1) {
		discard;
	}
	gl_FragColor = vec4(0.0,0.0,0.0,1.0);
}