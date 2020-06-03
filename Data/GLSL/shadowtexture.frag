uniform sampler2D tex;
uniform sampler2DShadow tex3;
uniform vec4 emission;

varying vec3 normal;
varying vec4 ProjShadow;

void main()
{	
	if(ProjShadow.x>0.8)discard;
	if(ProjShadow.x<0.2)discard;
	if(ProjShadow.y>0.8)discard;
	if(ProjShadow.y<0.2)discard;
	if(ProjShadow.z>0.8)discard;
	if(ProjShadow.z<0.2)discard;
	
	//vec3 color = shadow2DProj(tex3, ProjShadow).r;
	
	float offset = 1.0/2048.0;
	float shadowed = shadow2DProj(tex3, ProjShadow).r*.4;
	shadowed += shadow2DProj(tex3, ProjShadow + vec4(-offset*2.0,offset,0.0,0.0)).r*.15;
	shadowed += shadow2DProj(tex3, ProjShadow + vec4(offset*2.0,-offset,0.0,0.0)).r*.15;
	shadowed += shadow2DProj(tex3, ProjShadow + vec4(-offset,offset*2.0,0.0,0.0)).r*.15;
	shadowed += shadow2DProj(tex3, ProjShadow + vec4(offset,-offset*2.0,0.0,0.0)).r*.15;
	
	vec3 color = vec3(shadowed);
	
	//color = -ProjShadow.z*0.004;
	
	gl_FragColor = vec4(color,1.0);
}