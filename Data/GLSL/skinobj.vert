uniform sampler2D tex;
uniform sampler2D tex2;
uniform sampler2DShadow tex3;

varying vec3 light_pos;
varying vec3 light2_pos;
varying vec3 half_vector;
varying vec3 half_vector2;
varying vec4 ProjShadow;

void main()
{	
	light_pos = normalize(gl_LightSource[0].position.xyz);
	light2_pos = normalize(gl_LightSource[1].position.xyz);
	
	half_vector = normalize(gl_LightSource[0].halfVector.xyz);
	half_vector2 = normalize(gl_LightSource[1].halfVector.xyz);
	
	gl_Position = ftransform();
	
	gl_TexCoord[0] = gl_MultiTexCoord0;
	
	ProjShadow = gl_TextureMatrix[0] * gl_ModelViewMatrix * gl_Vertex;
} 
