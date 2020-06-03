uniform sampler2D tex0;
uniform float tex_size;

void main()
{	
	float offset_size = 1.0/tex_size;
	float total_alpha = 0.0;
	vec4 color = vec4(0.0);
	vec4 contrib;
	contrib = texture2D(tex0,gl_TexCoord[0].xy);
	total_alpha += contrib.a*0.383;
	color += contrib*contrib.a*0.383;
	contrib = texture2D(tex0,gl_TexCoord[0].xy+vec2(offset_size,0.0));
	total_alpha += contrib.a*0.242;
	color += contrib*contrib.a*0.242;
	contrib = texture2D(tex0,gl_TexCoord[0].xy+vec2(-offset_size,0.0));
	total_alpha += contrib.a*0.242;
	color += contrib*contrib.a*0.242;
	contrib = texture2D(tex0,gl_TexCoord[0].xy+vec2(offset_size*2.0,0.0));
	total_alpha += contrib.a*0.061;
	color += contrib*contrib.a*0.061;
	contrib = texture2D(tex0,gl_TexCoord[0].xy+vec2(-offset_size*2.0,0.0));
	total_alpha += contrib.a*0.061;
	color += contrib*contrib.a*0.061;
	contrib = texture2D(tex0,gl_TexCoord[0].xy+vec2(offset_size*3.0,0.0));
	total_alpha += contrib.a*0.006;
	color += contrib*contrib.a*0.006;
	contrib = texture2D(tex0,gl_TexCoord[0].xy+vec2(-offset_size*3.0,0.0));
	total_alpha += contrib.a*0.006;
	color += contrib*contrib.a*0.006;
	
	color /= total_alpha;
	
	gl_FragColor = color;
}