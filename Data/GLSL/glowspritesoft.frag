#extension GL_ARB_texture_rectangle : enable

uniform sampler2D tex0;
uniform sampler2DRect tex3;

void main()
{	
	vec3 color;
	
	vec4 color_tex = texture2D(tex0,gl_TexCoord[0].xy);
	
	color = gl_Color.xyz * color_tex.xyz;

	gl_FragColor = vec4(color,color_tex.a*gl_Color.a);

	float depth = texture2DRect(tex3,gl_FragCoord.xy).r-gl_FragCoord.z;
	float depth_blend = depth * 50.0f;
	depth_blend = max(0.0f,min(1.0f,depth_blend));

	gl_FragColor = vec4(color,color_tex.a*gl_Color.a*depth_blend);
}