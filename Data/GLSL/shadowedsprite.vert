uniform sampler2D tex0;
uniform sampler2DShadow tex2;

varying vec3 normal;
varying vec4 ProjShadow;

void main()
{	
	normal = normalize(gl_NormalMatrix * gl_Normal);
	
	gl_Position = ftransform();
	
	gl_TexCoord[0] = gl_MultiTexCoord0;
	
	ProjShadow = gl_TextureMatrix[0] * gl_ModelViewMatrix * gl_Vertex;
	
	gl_FrontColor = gl_Color;
} 
