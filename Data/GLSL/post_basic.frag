#extension GL_ARB_texture_rectangle : enable

uniform sampler2DRect tex0;
uniform sampler2DRect tex1;

void main()
{	
	vec3 color;
	
	vec3 color_map = texture2DRect( tex0, gl_TexCoord[0].st ).rgb;
	float depth = texture2DRect( tex1, gl_TexCoord[0].st ).r;
	
	vec3 accum = texture2DRect( tex0, gl_TexCoord[0].st ).rgb +
				 texture2DRect( tex0, gl_TexCoord[0].st + vec2(1,0) ).rgb * -0.25 +
				 texture2DRect( tex0, gl_TexCoord[0].st + vec2(-1,0) ).rgb * -0.25 +
				 texture2DRect( tex0, gl_TexCoord[0].st + vec2(0,1) ).rgb * -0.25 +
				 texture2DRect( tex0, gl_TexCoord[0].st + vec2(0,-1) ).rgb * -0.25;

	accum *= 100.0;

	gl_FragColor = vec4(accum,1.0);
}