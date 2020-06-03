uniform sampler2D tex0;
uniform sampler2D tex1;
uniform sampler2DShadow tex2;

varying vec3 light_pos;
varying vec3 light2_pos;
varying vec3 vertex_pos;
varying vec4 ProjShadow;

void main()
{	
	float NdotL;
	vec3 color;
	
	vec3 H = normalize(normalize(vertex_pos*-1.0) + normalize(light_pos));
	
	float faded = max(abs(gl_TexCoord[0].z)-0.5,0.0)*2.0;
	float alpha = texture2D(tex0,gl_TexCoord[0].xy).a;
	float depth=max(0.3-faded,0.0);
	
	vec2 tex_offset;
	float height;
	vec4 normalmap = texture2D(tex1,gl_TexCoord[0].xy);
	
	height = -normalmap.a*depth+depth;
	tex_offset = height * normalize(vertex_pos).xy * normalmap.z;
	
	normalmap = texture2D(tex1,gl_TexCoord[0].xy+tex_offset);
	
	height = (height+(-normalmap.a*depth+depth))/2.0;
	tex_offset = height * normalize(vertex_pos).xy * normalmap.z;
	
	float spec;
	vec3 normal;
	vec4 color_tex;
	
	normalmap = texture2D(tex1,gl_TexCoord[0].xy+tex_offset);
	normal = normalize(vec3((normalmap.x-0.5)*2.0, (normalmap.y-0.5)*-2.0, normalmap.z));
	//normal = vec3(0,0,1);
	
	float offset = 1.0/4096.0/2.0;
	float shadowed = shadow2DProj(tex3, ProjShadow).r*.2;
	shadowed += shadow2DProj(tex3, ProjShadow + vec4(-offset*2.0,offset,0.0,0.0)).r*.2;
	shadowed += shadow2DProj(tex3, ProjShadow - vec4(offset*2.0,-offset,0.0,0.0)).r*.2;
	shadowed += shadow2DProj(tex3, ProjShadow + vec4(-offset,offset*2.0,0.0,0.0)).r*.2;
	shadowed += shadow2DProj(tex3, ProjShadow + vec4(offset,-offset*2.0,0.0,0.0)).r*.2;
	
	NdotL = max(dot(normal,normalize(light_pos)),0.0);
	spec = max(pow(dot(normal,H),40.0),0.0)*2.0 * NdotL ;
	
	color_tex = texture2D(tex0,gl_TexCoord[0].xy+tex_offset);
	
	color = gl_LightSource[0].diffuse.xyz * NdotL *(0.4+shadowed*0.6) * color_tex.xyz;
	color += spec * gl_LightSource[0].diffuse.xyz * normalmap.a * shadowed * 0.4;
	
	NdotL = max(dot(normal,normalize(light2_pos)),0.0);
	H = normalize(normalize(vertex_pos*-1.0) + normalize(light2_pos));
	spec = max(pow(dot(normal,H),4.0),0.0);
	
	color += gl_LightSource[1].diffuse.xyz * NdotL * color_tex.xyz;
	color += spec * gl_LightSource[1].diffuse.xyz * normalmap.a * 0.2;

	gl_FragColor = vec4(color,max(alpha-faded,0.0));
}