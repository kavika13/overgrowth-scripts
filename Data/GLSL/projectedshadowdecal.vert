uniform sampler2DShadow tex0;
uniform sampler2D tex4;
uniform sampler2D tex5;
uniform mat4 obj2world_normal;

varying vec3 light_pos;
varying vec3 normal;
varying vec4 ProjShadow;
#include "transposemat3.glsl"
#include "pseudoinstance.glsl"

void main()
{	
	mat4 obj2world = GetPseudoInstanceMat4();
	mat3 obj2worldmat3 = GetPseudoInstanceMat3();
	
	mat3 transpose_normal_matrix = transposeMat3(gl_NormalMatrix*obj2worldmat3);
	light_pos = normalize(transpose_normal_matrix * gl_LightSource[0].position.xyz);

	light_pos = normalize((obj2world_normal*vec4(light_pos,0.0)).xyz);
	//light_pos = (obj2world_normal*vec4(1.0,0.0,0.0,0.0)).xyz;

	normal = normalize(gl_NormalMatrix*obj2worldmat3 * gl_Normal);
	
	ProjShadow = gl_TextureMatrix[0] * gl_ModelViewMatrix * obj2world * gl_Vertex;
	
	gl_Position = gl_ProjectionMatrix * gl_ModelViewMatrix * obj2world * gl_Vertex;;
	
	gl_TexCoord[0] = gl_MultiTexCoord0;
	gl_TexCoord[1] = gl_MultiTexCoord3;
	
	gl_FrontColor = gl_Color;
} 
