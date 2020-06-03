//#pragma-transparent
uniform vec3 light_pos;

uniform sampler2D tex0;

uniform mat4 obj2world;

const float texture_offset = 0.001;

void main()
{	
	mat3 obj2world3 = mat3(obj2world[0].xyz, obj2world[1].xyz, obj2world[2].xyz);
	
	vec3 normalmap = texture2D(tex0,gl_TexCoord[1].xy+vec2(light_pos.x * texture_offset, light_pos.z * texture_offset)).rgb;
	
	vec3 normal = normalize((normalmap.xyz*vec3(2.0))-vec3(1.0));
	
	gl_FragColor = vec4((normal+vec3(1.0))*0.5,1.0);
}