uniform sampler2D tex0;
uniform sampler2D tex1;
uniform samplerCube tex2;
uniform samplerCube tex3;
uniform sampler2D tex4;
uniform sampler2DShadow tex5;
uniform vec3 cam_pos;
uniform mat4 shadowmat;
uniform vec3 ws_light;

varying vec3 ws_vertex;
varying vec3 concat_bone1;
varying vec3 concat_bone2;

#include "lighting.glsl"
#include "relativeskypos.glsl"

float rand(vec2 co){
	return fract(sin(dot(vec2(floor(co.x),floor(co.y)) ,vec2(12.9898,78.233))) * 43758.5453);
}

void main()
{	
	// Reconstruct third bone axis
	vec3 concat_bone3 = cross(concat_bone1, concat_bone2);

	// Get world space normal
	vec4 normalmap = texture2D(tex1,gl_TexCoord[0].xy);
	vec3 unrigged_normal = UnpackObjNormal(normalmap);
	vec3 ws_normal = normalize(concat_bone1 * unrigged_normal.x +
							   concat_bone2 * unrigged_normal.y +
						       concat_bone3 * unrigged_normal.z);

	// Get shadowed amount
	vec3 shadow_tex = texture2D(tex4,gl_TexCoord[2].xy).xyz;
	/*float shadow_amount = 0.0;
	float offset = 40.0/2048.0;
	for(int i=0; i<100; i++){
		float random = (rand(gl_FragCoord.xy*i*3)-0.5)*offset;
		float random2 = (rand(gl_FragCoord.xy*(i*3+1))-0.5)*offset;
		float random3 = (rand(gl_FragCoord.xy*(i*3+2))-0.5)*offset*0.001;
		shadow_amount += shadow2DProj(tex5,gl_TexCoord[2]+vec4(random,random2,-0.00001+random3,0.0)).r/100.0;
	}
	shadow_tex.r *= shadow_amount;*/

	shadow_tex.r *= shadow2DProj(tex5,gl_TexCoord[2]+vec4(0.0,0.0,-0.00001,0.0)).r;

	shadow_tex.g = 1.0;

	// Get diffuse lighting
	float NdotL = GetDirectContrib(ws_light, ws_normal, shadow_tex.r);
	
	vec3 diffuse_color = GetDirectColor(NdotL);
	diffuse_color += LookupCubemapSimple(ws_normal, tex3) *
					 GetAmbientContrib(shadow_tex.g);
	
	// Get specular lighting
	float spec = GetSpecContrib(ws_light, ws_normal, ws_vertex, shadow_tex.r);
	vec3 spec_color = gl_LightSource[0].diffuse.xyz * vec3(spec) * 0.3;
	
	vec3 spec_map_vec = reflect(ws_vertex, ws_normal);
	spec_color += LookupCubemapSimple(spec_map_vec, tex2) * 0.5 *
				  GetAmbientContrib(shadow_tex.g);

	// Put it all together
	vec4 colormap = texture2D(tex0,gl_TexCoord[0].xy);
	vec3 color = diffuse_color * colormap.xyz + spec_color * GammaCorrectFloat(colormap.a);
	
	color *= BalanceAmbient(NdotL);
	color *= Exposure();

	// Add rim lighting
	vec3 view = normalize(ws_vertex*-1.0);
	float back_lit = max(0.0,dot(normalize(ws_vertex),ws_light)); 
	float rim_lit = max(0.0,(1.0-dot(view,ws_normal)));
	rim_lit *= pow((dot(ws_light,ws_normal)+1.0)*0.5,0.5);
	color += vec3(back_lit*rim_lit) * GammaCorrectFloat(normalmap.a) * gl_LightSource[0].diffuse.xyz * gl_LightSource[0].diffuse.a * shadow_tex.r;
	
	// Add haze
	AddHaze(color, TransformRelPosForSky(ws_vertex), tex3);

	//color = vec3(rand(gl_FragCoord.xy));

	gl_FragColor = vec4(color,1.0);
}