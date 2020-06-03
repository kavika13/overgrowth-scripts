uniform sampler2DShadow tex0;
uniform sampler2D tex4;
uniform sampler2D tex5;
uniform mat4 obj2world_normal;

varying vec3 light_pos;
varying vec3 normal;
varying vec4 ProjShadow;

const float shadow_depth = 20.0;
const float half_shadow_depth = shadow_depth * 0.5;

#include "lighting.glsl"

void main()
{
	vec4 color = vec4(0.0);

	float sub_amt = abs( max(0.0, (gl_TexCoord[0].z+half_shadow_depth) / shadow_depth));
		
	float offset = sub_amt*0.0004*(1.0+GetAmbientMultiplierScaled()*1.0)+0.001;
	float edge_buffer = 0.01;

	if(gl_TexCoord[0].x <= offset+edge_buffer || gl_TexCoord[0].x >= 1.0-offset-edge_buffer ||
	   gl_TexCoord[0].y <= offset+edge_buffer || gl_TexCoord[0].y >= 1.0-offset-edge_buffer ||
	   gl_TexCoord[0].z < -10.0){
		discard;
	}

	color.a += (1.0-shadow2DProj(tex0,ProjShadow).r)*0.2;
	color.a += (1.0-shadow2DProj(tex0,ProjShadow+vec4(offset,0.0,0.0,0.0)).r)*0.2;
	color.a += (1.0-shadow2DProj(tex0,ProjShadow+vec4(-offset,0.0,0.0,0.0)).r)*0.2;
	color.a += (1.0-shadow2DProj(tex0,ProjShadow+vec4(0.0,offset,0.0,0.0)).r)*0.2;
	color.a += (1.0-shadow2DProj(tex0,ProjShadow+vec4(0.0,-offset,0.0,0.0)).r)*0.2;


	//color = texture2D(tex,vec2(gl_TexCoord[0].x,gl_TexCoord[0].y));


	//color.a = 1.0-shadow2DProj(tex, ProjShadow).r;

	float NdotL = max(dot(normal,gl_LightSource[0].position.xyz),0.0);
	NdotL = min(1.0,NdotL*5.0);

	/*shadow = baked + (1.0-baked)*dynamic;
	dynamic = (shadow-baked)/(1.0-baked)*/

	color.a *= pow(texture2D(tex4,gl_TexCoord[1].xy).r,0.25);
	color.a *= (1.0-GetAmbientMultiplierScaled())*1.1;
	color.a *=max(0.0,(1.0 - sub_amt));

	//color = vec4(vec3(sub_amt),1.0);
	//color.a *= NdotL;

	//color = vec4(vec3(NdotL),1.0);

	//color = texture2D(tex5,gl_TexCoord[1].xy);

	
	//color.a = max(0.0,color.a * (1.0 - sub_amt)); 
	
	//color = vec4(gl_TexCoord[1].x,gl_TexCoord[1].y,0.0,1.0);

	//color = vec4(1.0,1.0,1.0,1.0);

	//NdotL = max(dot(normal,normalize(gl_LightSource[0].position.xyz)),0.0);
	
	//color = vec4(1.0);

	gl_FragColor = color;
}