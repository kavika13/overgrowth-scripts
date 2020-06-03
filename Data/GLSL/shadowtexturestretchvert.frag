uniform sampler2D tex0;
uniform float tex_size;

void main()
{	
	float offset_size = 1.0/tex_size;

	float shadow = texture2D(tex0,gl_TexCoord[0].xy).r;
	float float_i = 0.0;
	for(int i=0; i<8; i++){
		float_i += 1.0;
		vec2 new_uv = gl_TexCoord[0].xy+vec2(0.0,-offset_size)*float_i*1.0;
		new_uv.y = max(0.01,new_uv.y);
		shadow = max(shadow,texture2D(tex0,new_uv).r);
	}

	gl_FragColor = vec4(vec3(shadow),1.0);
}