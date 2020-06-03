uniform sampler2D tex;
uniform sampler2D tex2;

varying vec3 light_pos;
varying vec3 light2_pos;
varying vec3 vertex_pos;

void main()
{	
	float NdotL;
	vec3 color;
	
	vec3 H = normalize(normalize(vertex_pos*-1.0) + normalize(light_pos));
	
	float faded = max(abs(gl_TexCoord[0].z)-0.5,0.0)*2.0;
	float alpha = texture2D(tex,gl_TexCoord[0].xy).a;
	float depth=max(0.3-faded,0.0);
	
	vec2 tex_offset;
	float height;
	vec4 normalmap = texture2D(tex2,gl_TexCoord[0].xy);
	
	height = -normalmap.a*depth+depth;
	tex_offset = height * normalize(vertex_pos).xy * normalmap.z;
	
	normalmap = texture2D(tex2,gl_TexCoord[0].xy+tex_offset);
	
	height = (height+(-normalmap.a*depth+depth))/2.0;
	tex_offset = height * normalize(vertex_pos).xy * normalmap.z;
	
	float spec;
	vec3 normal;
	vec4 color_tex;
	
	normalmap = texture2D(tex2,gl_TexCoord[0].xy+tex_offset);
	normal = normalize(vec3((normalmap.x-0.5)*2.0, (normalmap.y-0.5)*-2.0, normalmap.z));
	//normal = vec3(0,0,1);
	
	NdotL = max(dot(normal,normalize(light_pos)),0.0);
	spec = max(pow(dot(normal,H),40.0),0.0)*2.0 * NdotL ;
	
	color_tex = texture2D(tex,gl_TexCoord[0].xy+tex_offset);
	
	color = gl_LightSource[0].diffuse.xyz * NdotL * color_tex.xyz;
	color += spec * gl_LightSource[0].diffuse.xyz * normalmap.a * 0.4;
	
	NdotL = max(dot(normal,normalize(light2_pos)),0.0);
	H = normalize(normalize(vertex_pos*-1.0) + normalize(light2_pos));
	spec = max(pow(dot(normal,H),4.0),0.0);
	
	color += gl_LightSource[1].diffuse.xyz * NdotL * color_tex.xyz;
	color += spec * gl_LightSource[1].diffuse.xyz * normalmap.a * 0.2;

	gl_FragColor = vec4(color,max(alpha-faded,0.0));
}