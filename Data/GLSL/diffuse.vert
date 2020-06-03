uniform sampler2D tex0;
uniform vec4 emission;
varying vec3 normal;

void main()
{	
	normal = normalize(gl_NormalMatrix * gl_Normal);
	
	gl_Position = ftransform();
	
	gl_TexCoord[0] = gl_MultiTexCoord0;
	
	gl_FrontColor = gl_Color;
} 
