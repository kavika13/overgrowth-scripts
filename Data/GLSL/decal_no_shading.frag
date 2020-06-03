//#pragma-transparent

uniform sampler2D tex;
uniform sampler2D tex2;
uniform samplerCube tex3;
uniform samplerCube tex4;
uniform sampler2D tex5;
uniform vec3 cam_pos;

varying vec3 vertex_pos;
varying vec3 light_pos;
varying mat3 tangent_to_world;
varying vec3 rel_pos;

void main()
{	
	if(gl_TexCoord[0].x<0.0 || gl_TexCoord[0].x>1.0 ||
		gl_TexCoord[0].y<0.0 || gl_TexCoord[0].y>1.0) {
		discard;
	}
	vec3 color;
	
	vec3 shadow_tex = texture2D(tex5,gl_TexCoord[1].xy).rgb;
	
	float shade_mult;
	vec4 normalmap = texture2D(tex2,gl_TexCoord[0].xy);
	vec3 normal = normalize(vec3((normalmap.x-0.5)*2.0, (normalmap.y-0.5)*-2.0, normalmap.z));

	float NdotL = max(0.0,dot(light_pos, normal))*shadow_tex.r;
	vec3 diffuse_color = vec3(NdotL);

	
	vec3 diffuse_map_vec = normal;
	diffuse_map_vec = tangent_to_world * diffuse_map_vec;
	diffuse_map_vec.y *= -1.0;
	diffuse_color += textureCube(tex4,diffuse_map_vec).xyz  * min(1.0,max(shadow_tex.g * 1.5, 0.5));
	
	vec3 H = normalize(normalize(vertex_pos*-1.0) + normalize(light_pos));
	float spec = min(1.0, max(0.0,pow(dot(normal,H),40.0)*2.0 * NdotL)) ;
	vec3 spec_color = vec3(spec);
	
	vec3 spec_map_vec = reflect(vertex_pos,normal);
	spec_map_vec = normalize(tangent_to_world * spec_map_vec);
	spec_map_vec.y *= -1.0;
	shade_mult = min(1.0,1.0-spec_map_vec.y+1.25) * (1.0*0.3+0.7);
	spec_color += textureCube(tex3,spec_map_vec).xyz * 0.5 * shadow_tex.g;
	
	vec4 colormap = texture2D(tex,gl_TexCoord[0].xy);
	
	color = colormap.xyz;//diffuse_color * colormap.xyz + spec_color * normalmap.a;
	
	float near = 0.1;
	float far = 1000.0;

	color = mix(color, textureCube(tex4,normalize(rel_pos)).xyz, length(rel_pos)/far);

	gl_FragColor = vec4(color,colormap.a);//colormap.a);
}