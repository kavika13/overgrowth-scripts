uniform sampler2D tex0;

void main()
{	
	gl_FragColor = vec4(texture2D(tex0,gl_TexCoord[1].xy).xyz,1.0);
	//gl_FragColor = vec4(1.0,0.0,0.0,1.0);
}