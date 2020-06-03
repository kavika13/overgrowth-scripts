uniform sampler2D tex;
uniform sampler2D tex2;
uniform samplerCube tex3;
uniform samplerCube tex4;
uniform sampler2D tex5;
uniform vec3 cam_pos;
uniform mat3 test;

varying vec3 vertex_pos;
varying vec3 light_pos;
varying mat3 tangent_to_world;
varying vec3 rel_pos;

//#include "transposemat3.glsl"
//#include "relativeskypos.glsl"
//#include "pseudoinstance.glsl"

void main()
{	
	mat4 obj2world = GetPseudoInstanceMat4();
	mat3 obj2worldmat3 = GetPseudoInstanceMat3();
	
	mat3 transpose_normal_matrix = transposeMat3(gl_NormalMatrix*obj2worldmat3);
	vec3 eyeSpaceVert = (gl_ModelViewMatrix * obj2world * gl_Vertex).xyz;
	vertex_pos = normalize(test * transpose_normal_matrix * eyeSpaceVert);
	
	light_pos = normalize(test * transpose_normal_matrix * gl_LightSource[0].position.xyz);
	
	rel_pos = CalcRelativePositionForSky(obj2world, cam_pos);
	
	gl_Position = gl_ProjectionMatrix * gl_ModelViewMatrix * obj2world * gl_Vertex;;
	
	gl_TexCoord[0] = gl_MultiTexCoord0;
	//gl_TexCoord[1] = gl_MultiTexCoord3;
	gl_TexCoord[2] = gl_MultiTexCoord1;
} 
