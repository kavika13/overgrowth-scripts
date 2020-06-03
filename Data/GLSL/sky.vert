uniform sampler2D tex0;
uniform float time;

varying vec3 light_vertex;
varying vec3 vertex;

void main()
{	
	vertex = gl_Vertex.xyz;
	light_vertex = gl_NormalMatrix * gl_Vertex.xyz;

	gl_Position = ftransform();
	gl_TexCoord[0] = gl_MultiTexCoord0;
	gl_FrontColor = gl_Color;
} 
