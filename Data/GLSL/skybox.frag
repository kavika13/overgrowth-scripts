uniform samplerCube tex3;

varying vec3 normal;
varying float opac;

void main()
{	
	vec3 color;

	color = textureCube(tex3,normal).xyz;

	gl_FragColor = vec4(color,opac);
}