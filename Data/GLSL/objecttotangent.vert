uniform sampler2D tex;
uniform sampler2D tex2;
uniform sampler2DShadow tex3;

varying vec4 ProjShadow;
varying vec3 normal;
varying vec3 tangent;
varying vec3 bitangent;

void main()
{	

	normal = normalize(gl_NormalMatrix * gl_Normal);
	tangent = normalize(gl_NormalMatrix *gl_MultiTexCoord1.xyz);
	bitangent = normalize(cross(normal,tangent));
	
	//gl_Position = ftransform();
	
	gl_TexCoord[0] = gl_MultiTexCoord0;
	
	gl_Position = gl_MultiTexCoord0;
	
	ProjShadow = gl_TextureMatrix[0] * gl_ModelViewMatrix * gl_Vertex;
} 
