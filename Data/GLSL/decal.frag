//#pragma-transparent

uniform sampler2D tex;
uniform sampler2D tex2;
uniform samplerCube tex3;
uniform samplerCube tex4;
uniform sampler2D tex5;
uniform sampler2D tex6;
uniform vec3 cam_pos;

varying vec3 vertex_pos;
varying vec3 light_pos;
varying mat3 tangent_to_world;
varying vec3 rel_pos;

void main()
{	
	vec3 color;
	
	vec3 shadow_tex = texture2D(tex5,gl_TexCoord[0].st).rgb;
	vec3 base_normal_tex = texture2D(tex6,gl_TexCoord[0].st).rgb;
	vec3 base_normal = (base_normal_tex-vec3(0.5))*2.0;

	float shade_mult;
	vec4 normalmap = texture2D(tex2,gl_TexCoord[0].st);
	vec3 normal = base_normal;//normalize(vec3((normalmap.x-0.5)*2.0, (normalmap.y-0.5)*-2.0, normalmap.z));
	vec3 tangent = gl_TexCoord[2].xyz;
	vec3 bitangent = normalize(cross(tangent,normal));
	tangent = normalize(cross(normal,bitangent));

	normal = normalize(base_normal * (normalmap.b*2.0) +
		    tangent * ((normalmap.x-0.5)*2.0) +
		    bitangent * ((normalmap.y-0.5)*2.0));
	
	float NdotL = max(0.0,dot(light_pos, normal))*shadow_tex.r;
	vec3 diffuse_color = vec3(NdotL);

	
	vec3 diffuse_map_vec = normal;
	diffuse_map_vec = diffuse_map_vec;
	diffuse_map_vec.y *= -1.0;
	diffuse_color += textureCube(tex4,diffuse_map_vec).xyz  * min(1.0,max(shadow_tex.g * 1.5, 0.5));
	
	vec3 H = normalize(normalize(vertex_pos*-1.0) + normalize(light_pos));
	float spec = min(1.0, max(0.0,pow(dot(normal,H),40.0)*2.0 * NdotL)) ;
	vec3 spec_color = vec3(spec);
	
	vec3 spec_map_vec = reflect(vertex_pos,normal);
	spec_map_vec = normalize(spec_map_vec);
	spec_map_vec.y *= -1.0;
	shade_mult = min(1.0,1.0-spec_map_vec.y+1.25) * (1.0*0.3+0.7);
	spec_color += textureCube(tex3,spec_map_vec).xyz * 0.5 * min(1.0,max(shadow_tex.g * 1.5, 0.5));
	
	vec4 colormap = texture2D(tex,gl_TexCoord[0].st);
	
	color = diffuse_color * colormap.xyz + spec_color * normalmap.a;
	
	float near = 0.1;
	float far = 1000.0;

	color = mix(color, textureCube(tex4,normalize(rel_pos)).xyz, length(rel_pos)/far);

	//color = colormap.xyz;

	//color = normal.rgb;

	//color = vec3(NdotL);

	/*if(gl_TexCoord[0].s>0.9||gl_TexCoord[0].s<0.1||
		gl_TexCoord[0].t>0.9||gl_TexCoord[0].t<0.1) {
		discard;
	}*/

	gl_FragColor = vec4(color,colormap.a);
}