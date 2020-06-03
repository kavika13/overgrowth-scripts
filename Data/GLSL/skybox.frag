uniform samplerCube tex3;

varying vec3 normal;
varying float opac;

//#include "lighting.glsl"

void main()
{	
	vec3 color;
	
	color = textureCube(tex3,normal).xyz;

	color *= Exposure();

	gl_FragColor = vec4(color,opac);
}