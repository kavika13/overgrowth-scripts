uniform vec3 light_pos;
uniform sampler2D tex0;
uniform sampler2D tex1;
uniform samplerCube tex3;
uniform sampler2D tex4;
varying vec3 normal;

void main()
{	
	normal = normalize(gl_Normal);
	gl_Position = ftransform();
	gl_TexCoord[0] = gl_MultiTexCoord0;
} 
