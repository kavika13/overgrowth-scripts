uniform sampler2D tex0;
uniform sampler2D tex1;

varying vec3 light_pos;
varying vec3 vertex_pos;

void main()
{	
	float NdotL;
	vec4 color;
	vec4 totalcolor;
	
	vec3 H = normalize(normalize(vertex_pos*-1.0) + normalize(light_pos));
	
	vec2 old_texcoord = gl_TexCoord[0].xy;
	vec2 texcoord = old_texcoord;
	
	vec4 normalmap;
	vec3 normal;
	vec4 color_tex;
	float spec;
	
	normalmap = texture2D(tex1,texcoord);
	normal = vec3((normalmap.x-0.5)*-2.0, (normalmap.y-0.5)*2.0, normalmap.z);
	
	NdotL = max(dot(normal,light_pos),0.0);
	spec = pow(dot(normal,H),20.0);
	
	color_tex = texture2D(tex0,texcoord);
	
	color = min((gl_LightSource[0].diffuse * NdotL * gl_Color  + gl_LightModel.ambient * gl_Color ),1.0)* vec4(color_tex.xyz,1.0);
	color += spec * gl_Color * color_tex.a;
	
	totalcolor = color;
	/*
	float oblique=length(normalize(vertex_pos).xy);
	float where;
	
	float steps=1+20.0/length(vertex_pos);
	
	for(int i=1;i<steps;i++){
		where = i;//mix(i,steps,oblique/2);
		texcoord=old_texcoord-normalize(vertex_pos).xy*0.02/steps*where;
		normalmap = texture2D(tex2,texcoord);
		normal = vec3((normalmap.x-0.5)*-2.0, (normalmap.y-0.5)*2.0, normalmap.z);
		
		NdotL = max(dot(normal,light_pos),0.0);
		spec = pow(dot(normal,H),20.0);
		
		color_tex = texture2D(tex,texcoord);
		
		color = min((gl_LightSource[0].diffuse * NdotL * gl_Color  + gl_LightModel.ambient * gl_Color ),1.0)* vec4(color_tex.xyz,1.0);
		color += spec * gl_Color * color_tex.a;
		
		totalcolor = mix(totalcolor,color,min(max(color.a-(where/steps),0.0)*10.0,1.0));
	}
	*/
	gl_FragColor = totalcolor;
}