uniform sampler2D tex;
uniform sampler2DShadow tex3;
uniform vec4 emission;

varying vec3 normal;
varying vec4 ProjShadow;

void main()
{	
	normal = normalize(gl_NormalMatrix * gl_Normal);
	
	gl_Position = ftransform();
	
	gl_TexCoord[0] = gl_MultiTexCoord0;
	
	ProjShadow = gl_TextureMatrix[0] * gl_ModelViewMatrix * gl_Vertex;
	
	//ProjShadow.z -= 0.001;
	
	gl_FrontColor = gl_Color;
} 
