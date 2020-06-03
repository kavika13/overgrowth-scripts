uniform sampler2D tex;

void main()
{	
	vec3 color;
	
	float offset=1.0/256.0;
	vec4 color_tex = texture2D(tex,gl_TexCoord[0].xy)*0.2;
	color_tex += texture2D(tex,gl_TexCoord[0].xy+vec2(offset,0.0))*0.15;
	color_tex += texture2D(tex,gl_TexCoord[0].xy+vec2(-offset,0.0))*0.15;
	color_tex += texture2D(tex,gl_TexCoord[0].xy+vec2(offset*2.0,0.0))*0.13;
	color_tex += texture2D(tex,gl_TexCoord[0].xy+vec2(-offset*2.0,0.0))*0.13;
	color_tex += texture2D(tex,gl_TexCoord[0].xy+vec2(offset*3.0,0.0))*0.12;
	color_tex += texture2D(tex,gl_TexCoord[0].xy+vec2(-offset*3.0,0.0))*0.12;
	
	color = gl_Color.xyz * color_tex.xyz;

	gl_FragColor = vec4(color,1.0);
}