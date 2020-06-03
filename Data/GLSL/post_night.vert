#extension GL_ARB_texture_rectangle : enable

uniform sampler2DRect tex0;
uniform sampler2DRect tex1;
uniform sampler2D tex2;

uniform float time;

void main()
{	
	gl_Position = ftransform();
	
	gl_TexCoord[0] = gl_MultiTexCoord0;
} 
