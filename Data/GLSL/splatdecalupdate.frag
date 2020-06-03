uniform sampler2D tex;
uniform sampler2D tex2;

const float _flow_speed = 0.001;
const float _pixel_size = 1.0 / 512.0;

void main()
{	
	vec3 color;
	
	vec4 normalmap;
	vec4 color_tex = vec4(0.0);
	
	normalmap = texture2D(tex2,gl_TexCoord[0].xy);
	normalmap *= 2.0;
	normalmap -= 1.0;
	color_tex = texture2D(tex,gl_TexCoord[0].xy + normalmap.xy*_flow_speed);
	
	gl_FragColor = vec4(color,color_tex.a);
}