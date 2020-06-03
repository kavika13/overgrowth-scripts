uniform sampler2D tex0;

void main()
{	
	vec4 color = vec4(texture2D(tex0,gl_TexCoord[0].xy));
#ifdef GAMMA_CORRECT
	color.rgb *= 2.0;
	color.a *= 1.5;
#else
	color.rgb *= 0.8;
	color.a *= 0.8;
#endif
	gl_FragColor = color*gl_Color;
}