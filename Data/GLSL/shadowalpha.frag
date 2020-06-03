uniform sampler2D tex0;

void main()
{	
	if(texture2D(tex0,gl_TexCoord[0].xy).a < 0.1) {
		discard;
	}
	gl_FragColor = vec4(0.0,0.0,0.0,1.0);
}