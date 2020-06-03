uniform sampler2D tex;
uniform sampler2D tex2;
uniform samplerCube tex3;
uniform samplerCube tex4;
uniform sampler2D tex5;
uniform vec3 cam_pos;
uniform float in_light;

varying vec3 vertex_pos;
varying vec3 light_pos;
varying vec3 rel_pos;
varying vec3 world_light;
varying mat3 obj2worldmat3;
//varying vec3 normal_var;

//#include "lighting.glsl"

void main()
{	
	vec3 color;
	
	vec3 shadow_tex = vec3(1.0);//texture2D(tex5,gl_TexCoord[1].xy).rgb;
	
	vec4 normalmap = texture2D(tex2,gl_TexCoord[0].xy);
	vec3 normal = UnpackObjNormal(normalmap);

	float NdotL = GetDirectContrib(light_pos, normal, shadow_tex.r);
	
	vec3 diffuse_color = GetDirectColor(NdotL);
	diffuse_color += LookupCubemap(obj2worldmat3, normal, tex4) *
					 GetAmbientContrib(shadow_tex.g);
	
	float spec = GetSpecContrib(light_pos, normal, vertex_pos, shadow_tex.r);
	vec3 spec_color = gl_LightSource[0].diffuse.xyz * vec3(spec);
	
	vec3 spec_map_vec = reflect(vertex_pos,normal);
	spec_color += LookupCubemap(obj2worldmat3, spec_map_vec, tex3) * 0.5 *
				  GetAmbientContrib(shadow_tex.g);
	
	vec4 colormap = texture2D(tex,gl_TexCoord[0].xy);
	
	color = diffuse_color * colormap.xyz + spec_color * colormap.a;
	
	color *= BalanceAmbient(NdotL);
	
	AddHaze(color, rel_pos, tex4);

	color *= Exposure();

	vec3 view = normalize(vertex_pos*-1.0);
	float back_lit = max(0.0,dot(normalize(rel_pos),world_light)); 
	//float back_lit = (dot(normalize(rel_pos),world_light)+1.0)*0.5; 
	float rim_lit = max(0.0,(1.0-dot(view,normal)));
	//rim_lit = pow(rim_lit,0.8);
	//rim_lit *= min(1.0,max(0.0,(obj2world*vec4(normal,0.0)).y+0.5));
	rim_lit *= pow((dot(light_pos,normal)+1.0)*0.5,0.5);
	color += vec3(back_lit*rim_lit) * normalmap.a * gl_LightSource[0].diffuse.xyz * gl_LightSource[0].diffuse.a * shadow_tex.r;
	
	//color = spec_color;

	//color = vec3(dot(light_pos,normal));

	//color = vec3(NdotL*0.6);

	//color = gl_Color.xyz;

	gl_FragColor = vec4(color,1.0);
}