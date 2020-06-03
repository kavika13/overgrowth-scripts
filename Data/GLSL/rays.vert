uniform sampler2D tex;
uniform float time;

varying vec3 light_vertex;
varying vec3 vertex;

void main()
{	
	vertex = gl_Vertex.xyz;
	
	gl_Position = ftransform();
	light_vertex = gl_Position.xyz;
	
	gl_TexCoord[0] = gl_MultiTexCoord0;
	gl_FrontColor = gl_Color;
} 
