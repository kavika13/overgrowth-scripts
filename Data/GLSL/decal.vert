uniform sampler2D tex;
uniform sampler2D tex2;
uniform samplerCube tex3;
uniform samplerCube tex4;
uniform sampler2D tex5;
uniform vec3 cam_pos;
uniform mat3 test;
uniform mat4 obj2world;

varying vec3 vertex_pos;
varying vec3 light_pos;
varying mat3 tangent_to_world;
varying vec3 rel_pos;

//#include "transposemat3.glsl"
//#include "relativeskypos.glsl"

void main()
{	
	mat3 transpose_normal_matrix = transposeMat3(gl_NormalMatrix);
	vec3 eyeSpaceVert = (gl_ModelViewMatrix * gl_Vertex).xyz;
	vertex_pos = normalize(test * transpose_normal_matrix * eyeSpaceVert);
	
	light_pos = normalize(test * transpose_normal_matrix * gl_LightSource[0].position.xyz);
	
	rel_pos = CalcRelativePositionForSky(obj2world, cam_pos);
	
	gl_Position = ftransform();
	
	gl_TexCoord[0] = gl_MultiTexCoord0;
	//gl_TexCoord[1] = gl_MultiTexCoord3;
	gl_TexCoord[2] = gl_MultiTexCoord1;
} 
