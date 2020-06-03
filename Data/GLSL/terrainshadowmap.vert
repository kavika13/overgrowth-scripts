uniform sampler2D tex;

varying vec3 normal;
varying vec3 shadows;

void main()
{	
	normal = normalize(gl_Normal);
	shadows = gl_MultiTexCoord1.xyz;
	gl_Position = ftransform();
	gl_TexCoord[0] = gl_MultiTexCoord0;
} 
