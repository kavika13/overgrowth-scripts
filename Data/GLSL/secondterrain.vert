uniform vec3 light_pos;
uniform sampler2D tex;
uniform sampler2D tex2;
uniform samplerCube tex4;
uniform sampler2D tex5;
varying vec3 normal;

void main()
{	
	normal = normalize(gl_Normal);
	gl_Position = ftransform();
	gl_TexCoord[0] = gl_MultiTexCoord0;
} 
