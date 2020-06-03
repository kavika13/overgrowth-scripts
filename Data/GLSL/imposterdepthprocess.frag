uniform sampler2D tex0;

void main()
{	
	vec3 color;
	
	float offset=1.0/256.0;
	float depth = texture2D(tex0,gl_TexCoord[0].xy).r;
	float min_surround_depth = depth;
	min_surround_depth = min(min_surround_depth, texture2D(tex0,gl_TexCoord[0].xy+vec2(offset,0.0)).r);
	min_surround_depth = min(min_surround_depth, texture2D(tex0,gl_TexCoord[0].xy+vec2(-offset,0.0)).r);
	min_surround_depth = min(min_surround_depth, texture2D(tex0,gl_TexCoord[0].xy+vec2(0.0,offset)).r);
	min_surround_depth = min(min_surround_depth, texture2D(tex0,gl_TexCoord[0].xy+vec2(0.0,-offset)).r);
	if(depth >= 0.999){
		depth = min_surround_depth;
	}
	gl_FragDepth = depth;
	gl_FragColor = vec4(1.0,0.0f,0.0f,1.0f);
}