uniform sampler2D tex;
uniform sampler2D tex2;
varying vec3 normal;

void main()
{	
	normal = gl_Normal.xyz;
	
	gl_Position = ftransform();
	
	gl_TexCoord[0] = gl_MultiTexCoord0;
	
	gl_FrontColor = gl_Color;
} 