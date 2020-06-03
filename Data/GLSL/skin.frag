uniform sampler2D tex;
uniform sampler2D tex2;
uniform sampler2DShadow tex3;

varying vec3 light_pos;
varying vec3 light2_pos;
varying vec3 vertex_pos;
varying vec4 ProjShadow;

void main()
{	
	float NdotL;
	vec3 color;
	
	vec3 H = normalize(normalize(vertex_pos*-1.0) + normalize(light_pos));
	vec3 view = normalize(vertex_pos*-1.0);
	
	vec4 normalmap;
	vec3 normal;
	vec4 color_tex;
	float spec;
	
	normalmap = texture2D(tex2,gl_TexCoord[0].xy);
	normal = normalize(vec3((normalmap.x-0.5)*2.0, (normalmap.y-0.5)*-2.0, normalmap.z));
	
	
	float offset = 1.0/4096.0;
	float shadowed = shadow2DProj(tex3, ProjShadow).r*.2;
	shadowed += shadow2DProj(tex3, ProjShadow + vec4(-offset*2.0,offset,0.0,0.0)).r*.2;
	shadowed += shadow2DProj(tex3, ProjShadow - vec4(offset*2.0,-offset,0.0,0.0)).r*.2;
	shadowed += shadow2DProj(tex3, ProjShadow + vec4(-offset,offset*2.0,0.0,0.0)).r*.2;
	shadowed += shadow2DProj(tex3, ProjShadow + vec4(offset,-offset*2.0,0.0,0.0)).r*.2;
	
	color_tex = texture2D(tex,gl_TexCoord[0].xy);

	vec3 diffusion = vec3(0.3,0.15,0.0);
	
	NdotL = dot(normal,light_pos);
	NdotL += pow(max(1.0-dot(view,normal),0.0)*(dot(view*-1.0,light_pos)+1.0)/2.0*(NdotL+1.0)/2.0,1.5);
	NdotL -= 0.3;
	color.x = gl_LightSource[0].diffuse.x * max((NdotL+diffusion.x)/(1.0+diffusion.x),0.0) * color_tex.x;
	color.y = gl_LightSource[0].diffuse.y * max((NdotL+diffusion.y)/(1.0+diffusion.y),0.0) * color_tex.y;
	color.z = gl_LightSource[0].diffuse.z * max((NdotL+diffusion.z)/(1.0+diffusion.z),0.0) * color_tex.z;
	
	spec = max(pow(dot(normal,H),40.0),0.0)*2.0 * NdotL ;
	color += spec * mix(gl_LightSource[0].diffuse,vec4(1.0),0.4) * vec3(0.7,0.7,1.0) * normalmap.a;

	NdotL = max(dot(normal,normalize(light2_pos)),0.0);
	NdotL += pow(max(1.0-dot(view,normal),0.0)*(dot(view*-1.0,light2_pos)+1.0)/2.0*(NdotL+1.0)/2.0,1.0);
	NdotL -= 0.3;
	color.x += gl_LightSource[1].diffuse.x * max((NdotL+diffusion.x)/(1.0+diffusion.x),0.0) * color_tex.x;
	color.y += gl_LightSource[1].diffuse.y * max((NdotL+diffusion.y)/(1.0+diffusion.y),0.0) * color_tex.y;
	color.z += gl_LightSource[1].diffuse.z * max((NdotL+diffusion.z)/(1.0+diffusion.z),0.0) * color_tex.z;
	
	H = normalize(normalize(vertex_pos*-1.0) + normalize(light2_pos));
	spec = max(pow(dot(normal,H),4.0),0.0) * NdotL ;
	color += spec * mix(gl_LightSource[1].diffuse,vec4(1.0),0.4) * vec3(0.7,0.7,1.0) * normalmap.a;

	//color = NdotL;
	
	//color = shadowed;

	gl_FragColor = vec4(color,1.0);
}