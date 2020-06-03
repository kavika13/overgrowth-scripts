uniform sampler2D tex;
uniform sampler2D tex2;
uniform sampler2DShadow tex3;

varying vec3 light_pos;
varying vec3 light2_pos;
varying vec3 half_vector;
varying vec3 half_vector2;
varying vec4 ProjShadow;

void main()
{	
	float NdotL;
	vec3 color;
	
	vec4 normalmap;
	vec3 normal;
	vec4 color_tex;
	float spec;
	
	color_tex = texture2D(tex,gl_TexCoord[0].xy);
	normalmap = texture2D(tex2,gl_TexCoord[0].xy);
	normal = normalize(gl_NormalMatrix*(vec3(normalmap.x, normalmap.z, normalmap.y)*2.0-1.0));
	
	float offset = 1.0/4096.0;
	float shadowed = shadow2DProj(tex3, ProjShadow).r*.2;
	shadowed += shadow2DProj(tex3, ProjShadow + vec4(-offset*2.0,offset,0.0,0.0)).r*.2;
	shadowed += shadow2DProj(tex3, ProjShadow - vec4(offset*2.0,-offset,0.0,0.0)).r*.2;
	shadowed += shadow2DProj(tex3, ProjShadow + vec4(-offset,offset*2.0,0.0,0.0)).r*.2;
	shadowed += shadow2DProj(tex3, ProjShadow + vec4(offset,-offset*2.0,0.0,0.0)).r*.2;
	
	vec3 diffusion = vec3(0.4,0.2,0.0);
	
	NdotL = dot(normal,light_pos);
	color.x = /*gl_LightSource[0].diffuse.x * */max((NdotL+diffusion.x)/(1.0+diffusion.x),0.0) * color_tex.x;
	color.y = /*gl_LightSource[0].diffuse.y * */max((NdotL+diffusion.y)/(1.0+diffusion.y),0.0) * color_tex.y;
	color.z = /*gl_LightSource[0].diffuse.z * */max((NdotL+diffusion.z)/(1.0+diffusion.z),0.0) * color_tex.z;
	
	spec = max(pow(dot(normal,normalize(half_vector)),40.0),0.0)*2.0 * NdotL ;
	color += spec * normalmap.a;
	
	/*
	NdotL = max((dot(normal,light2_pos)+0.5)*0.66,0.0);
	spec = max(pow(dot(normal,normalize(half_vector2)),4.0),0.0);
	color += gl_LightSource[1].diffuse.xyz * NdotL * color_tex.xyz;
	color += spec * normalmap.a * 0.5;
*/
	//color = shadowed;

	gl_FragColor = vec4(color,1.0);
}