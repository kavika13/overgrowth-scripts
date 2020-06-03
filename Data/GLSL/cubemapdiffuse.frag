uniform sampler2D tex;
uniform samplerCube tex3;
uniform samplerCube tex4;
uniform vec4 emission;
uniform mat4 obj2world;
uniform vec3 cam_pos;

varying vec3 normal;
varying vec3 world_normal;
varying vec3 rel_pos;

//#include "lighting.glsl"

void main()
{	
	float NdotL = GetDirectContrib(gl_LightSource[0].position.xyz, normal, 1.0);
	
	vec3 color = GetDirectColor(NdotL);

	color += textureCube(tex4,world_normal).xyz	* GetAmbientContrib(1.0);
	
	color *= BalanceAmbient(NdotL);
	
	color *= gl_Color.xyz;
	
	color += emission.xyz;
	
	AddHaze(color, rel_pos, tex4);

	gl_FragColor = vec4(color,1.0);
}