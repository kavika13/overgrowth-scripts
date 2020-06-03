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
varying vec3 rel_pos;

void main()
{	
	vec3 color;
	
	vec3 shadow_tex = texture2D(tex5,gl_TexCoord[0].xy).rgb;
	
	vec4 normalmap = texture2D(tex2,gl_TexCoord[0].xy);
	vec3 normal = normalize(vec3((normalmap.x-0.5)*2.0, (normalmap.z-0.5)*2.0, (normalmap.y-0.5)*-2.0));

	float NdotL = max(0.0,dot(light_pos, normal))*shadow_tex.r;
	vec3 diffuse_color = vec3(NdotL * 1.0);
	
	vec3 diffuse_map_vec = normalize(mat3(obj2world[0].xyz, obj2world[1].xyz, obj2world[2].xyz) * normal);
	diffuse_map_vec.y *= -1.0;
	diffuse_color += textureCube(tex4,diffuse_map_vec).xyz * min(1.0,max(shadow_tex.g * 1.5, 0.5));
	
	vec3 H = normalize(normalize(vertex_pos*-1.0) + normalize(light_pos));
	float spec = min(1.0, max(0.0,pow(dot(normal,H),10.0)*1.0 * NdotL)) ;
	vec3 spec_color = vec3(spec);
	
	vec3 spec_map_vec = reflect(vertex_pos,normal);
	spec_map_vec = normalize(mat3(obj2world[0].xyz, obj2world[1].xyz, obj2world[2].xyz) * spec_map_vec);
	spec_map_vec.y *= -1.0;
	spec_color += textureCube(tex3,spec_map_vec).xyz * 0.5 * min(1.0,max(shadow_tex.g * 1.5, 0.5));
	
	vec4 colormap = texture2D(tex,gl_TexCoord[0].xy);
	
	color = diffuse_color * colormap.xyz + spec_color * colormap.a;
	
	float near = 0.1;
	float far = 1000.0;
	
	color *= (1.0-NdotL*0.2);
	
	color = mix(color, textureCube(tex4,normalize(rel_pos)).xyz, min(1.0,length(rel_pos)/far));
	
	//color *= texture2D(tex5,gl_TexCoord[1].xy).g;
	
	//color = min(1.0,max(shadow_tex.g * 2.0, 0.5));
	
	
	//color = texture2D(tex5,gl_TexCoord[0].xy).g;// * (0.5+texture2D(tex5,gl_TexCoord[0].xy).r*0.5);
	
	gl_FragColor = vec4(color,1.0);
}