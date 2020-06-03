uniform sampler2D tex;
uniform samplerCube tex3;
uniform samplerCube tex4;
uniform vec4 emission;
uniform mat4 obj2world;

varying vec3 normal;
varying vec3 world_normal;

void main()
{	
	float NdotL;
	vec3 color;
	
	NdotL = max(dot(normal,gl_LightSource[0].position.xyz),0.0)*gl_LightSource[0].diffuse.a;
	vec4 color_tex = texture2D(tex,gl_TexCoord[0].xy);
	
	color = gl_LightSource[0].diffuse.xyz * NdotL * gl_Color.xyz;
	
	color += emission.xyz;

	color += textureCube(tex4,world_normal).xyz	* (1.5-gl_LightSource[0].diffuse.a*0.5) * 0.8;
	
	color *= (1.0-NdotL*0.2);
	
	gl_FragColor = vec4(color,1.0);
}