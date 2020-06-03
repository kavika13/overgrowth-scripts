uniform sampler2D tex;

void main()
{	
	vec4 color;
		
	color = texture2D(tex,gl_TexCoord[0].xy);
	
	float sub_amt = abs( max(0.0, gl_TexCoord[0].z / 2.0) ) + abs(min(0.0,gl_TexCoord[0].z * 4.0));
	
	color.a = max(0.0,color.a * (1.0 - sub_amt)); 
	
	gl_FragColor = color;
}