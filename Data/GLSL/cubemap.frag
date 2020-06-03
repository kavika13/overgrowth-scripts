uniform sampler2D tex;
uniform sampler2D tex2;
uniform samplerCube tex3;
uniform samplerCube tex4;
uniform sampler2D tex5;
uniform mat4 obj2world;
uniform vec3 cam_pos;
uniform float in_light;

varying vec3 vertex_pos;
varying vec3 light_pos;
varying mat3 tangent_to_world;
varying vec3 rel_pos;

void main()
{	
	mat3 obj2world3 = mat3(obj2world[0].xyz, obj2world[1].xyz, obj2world[2].xyz);
	vec3 color;
	
	vec3 shadow_tex = texture2D(tex5,gl_TexCoord[1].xy).rgb;
	
	vec4 normalmap = texture2D(tex2,gl_TexCoord[0].xy);
	vec3 normal = normalize(vec3((normalmap.x-0.5)*2.0, (normalmap.y-0.5)*-2.0, normalmap.z));
	
	float NdotL = max(0.0,dot(light_pos, normal))*shadow_tex.r*gl_LightSource[0].diffuse.a;
	vec3 diffuse_color = gl_LightSource[0].diffuse.xyz * vec3(NdotL);
	
	vec3 diffuse_map_vec = normal;
	diffuse_map_vec = normalize(obj2world3 * tangent_to_world * diffuse_map_vec);
	diffuse_map_vec.y *= -1.0;
	diffuse_color += textureCube(tex4,diffuse_map_vec).xyz * min(1.0,max(shadow_tex.g * 1.5, 0.5)) * (1.5-gl_LightSource[0].diffuse.a*0.5);
	
	vec3 H = normalize(normalize(vertex_pos*-1.0) + normalize(light_pos));
	float spec = min(1.0, pow(max(0.0,dot(normal,H)),10.0)*1.0 * NdotL) ;
	vec3 spec_color = gl_LightSource[0].diffuse.xyz * vec3(spec);
	
	vec3 spec_map_vec = reflect(vertex_pos,normal);
	spec_map_vec = normalize(obj2world3 * tangent_to_world * spec_map_vec);
	spec_map_vec.y *= -1.0;
	spec_color += textureCube(tex3,spec_map_vec).xyz * 0.5 * min(1.0,max(shadow_tex.g * 1.5, 0.5));
	 
	vec4 colormap = texture2D(tex,gl_TexCoord[0].xy);
	
	color = diffuse_color * colormap.xyz + spec_color * colormap.a;
	
	float near = 0.1;
	float far = 1000.0;
	
	color *= (1.0-NdotL*0.2);
	
	color = mix(color, textureCube(tex4,normalize(rel_pos)).xyz, length(rel_pos)/far);
	
	//color = min(1.0,max(shadow_tex.g * 2.0, 0.5));
	
	//color = texture2D(tex5,gl_TexCoord[1].xy).g;// * (0.5+texture2D(tex5,gl_TexCoord[1].xy).r*0.5);
	
	gl_FragColor = vec4(color,1.0);
}