uniform sampler2D tex0;

void main()
{	
	vec3 color = vec3(0);
	
	vec2 uv = gl_TexCoord[0].xy;
	
	for(int i=0; i<15;i++){
		uv=(uv-vec2(0.5))*0.9+vec2(0.5);
		color.xyz += texture2D(tex0, uv).xyz*(0.03+float(i)*0.003)*1.5;
	}
	
	gl_FragColor = vec4(color,1.0);
}