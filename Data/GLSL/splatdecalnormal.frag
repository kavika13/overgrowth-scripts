uniform sampler2D tex;
uniform sampler2D tex2;

varying vec3 normal;

const float _pixel_size = 1.0 / 512.0;

void main()
{	
	vec3 color;
	
	vec4 normalmap;
	vec4 color_tex;
	vec4 color_tex_up;
	vec4 color_tex_left;
	
	//normalmap = texture2D(tex2,gl_TexCoord[0].xy);
	color_tex = texture2D(tex,gl_TexCoord[0].xy);
	color_tex_up = texture2D(tex,gl_TexCoord[0].xy - vec2(0,_pixel_size));
	color_tex_left = texture2D(tex,gl_TexCoord[0].xy - vec2(_pixel_size, 0));
	
	vec3 up = normalize(vec3(0.0,color_tex_up.a - color_tex.a,1.0));
	vec3 left = normalize(vec3(1.0,color_tex_left.a - color_tex.a,0.0));
	vec3 norm = (cross(up, left));
	norm.z *= 4.0;
	norm = normalize(norm);

	
	color.b = norm.y * 0.5 + 0.5;
	color.r = norm.x * -0.5 + 0.5;
	color.g = norm.z * 0.5 + 0.5;
	
	//color = 0.0;
	
	gl_FragColor = vec4(color,1.0);
}