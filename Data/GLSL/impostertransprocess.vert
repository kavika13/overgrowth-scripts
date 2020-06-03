uniform sampler2D tex0;
uniform float iter;

void main()
{	
	gl_Position = ftransform();
	gl_TexCoord[0] = gl_MultiTexCoord0;
} 
