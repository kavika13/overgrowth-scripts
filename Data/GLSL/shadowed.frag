uniform sampler2D tex;
uniform sampler2DShadow tex3;
uniform vec4 emission;

varying vec3 normal;
varying vec4 ProjShadow;

void main()
{	
	float NdotL;
	vec3 color;
	
	float offset = 1.0/4096.0;
	float shadowed = shadow2DProj(tex3, ProjShadow).r*.2;
	shadowed += shadow2DProj(tex3, ProjShadow + vec4(-offset*2.0,offset,0.0,0.0)).r*.2;
	shadowed += shadow2DProj(tex3, ProjShadow + vec4(offset*2.0,-offset,0.0,0.0)).r*.2;
	shadowed += shadow2DProj(tex3, ProjShadow + vec4(-offset,offset*2.0,0.0,0.0)).r*.2;
	shadowed += shadow2DProj(tex3, ProjShadow + vec4(offset,-offset*2.0,0.0,0.0)).r*.2;
	
	NdotL = max(dot(normal,gl_LightSource[0].position.xyz),0.0);
	vec4 color_tex = texture2D(tex,gl_TexCoord[0].xy);
	
	color = gl_LightSource[0].diffuse.xyz * NdotL *(0.4+shadowed*0.6) * gl_Color.xyz;// * color_tex.xyz;
	
	NdotL = max(dot(normal,normalize(gl_LightSource[1].position.xyz)),0.0);
	
	color += gl_LightSource[1].diffuse.xyz * NdotL * gl_Color.xyz;// * color_tex.xyz;
	
	color += emission.xyz;
	
	gl_FragColor = vec4(color,1.0);
}