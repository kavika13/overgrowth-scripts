uniform sampler2D tex;
uniform sampler2D tex2;

varying vec3 light_pos;
varying vec3 light2_pos;
varying vec3 vertex_pos;

void main()
{	
	float NdotL;
	vec4 color;
	float depth=0.03;
	
	vec2 offset;
	
	float height;
	vec4 normal_tex = texture2D(tex2,gl_TexCoord[0].xy);
	
	height = normal_tex.a*depth-depth/2.0;
	offset = height * normalize(vertex_pos).xy/* * normal_tex.z*/;
	offset.x *= -1.0;
	
	normal_tex = texture2D(tex2,gl_TexCoord[0].xy+offset);
	
	height = (height+normal_tex.a*depth-depth/2.0)/2.0;
	offset = height * normalize(vertex_pos).xy/* * texture2D(tex2,gl_TexCoord[0].xy+offset).z*/ * 1.0;
	offset.x *= -1.0;
		
	vec3 normalmap = texture2D(tex2,gl_TexCoord[0].xy+offset).xyz;
	vec3 normal = normalize(vec3((normalmap.x-0.5)*2.0, (normalmap.y-0.5)*2.0, normalmap.z));
	
	vec4 color_tex = texture2D(tex,gl_TexCoord[0].xy+offset);
	//color_tex.xyz = vec3(1);
	
	NdotL = max(dot(normal,normalize(light_pos)),0.0);
	vec3 H = normalize(normalize(vertex_pos*-1.0) + normalize(light_pos));
	float spec = min(1.0, pow(max(0.0,dot(normal,H)),10.0)*1.0 * NdotL) ;
	
	color = min((gl_LightSource[0].diffuse * NdotL * gl_Color),1.0);//* vec4(color_tex.xyz,1.0);
	color += NdotL * spec * gl_Color * color_tex.a * gl_LightSource[0].diffuse;
	
	NdotL = max(dot(normal,light2_pos),0.0);
	H = normalize(normalize(vertex_pos*-1.0) + normalize(light2_pos));
	spec = max(0.0,min(1.0,pow(dot(normal,H),4.0)));
	
	color += min((gl_LightSource[1].diffuse * NdotL * gl_Color),1.0);//* vec4(color_tex.xyz,1.0);
	color += NdotL * spec * gl_Color * color_tex.a * gl_LightSource[1].diffuse;
	
	color.xyz *= normal_tex.a*0.2 + 0.8;
	
	//color.xyz = light_pos;
	
	gl_FragColor = color;
}