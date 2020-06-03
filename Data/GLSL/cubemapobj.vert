uniform sampler2D tex;
uniform sampler2D tex2;
uniform samplerCube tex3;
uniform samplerCube tex4;
uniform sampler2D tex5;
uniform mat4 obj2world;
uniform vec3 cam_pos;
uniform float in_light;

varying vec3 vertex_pos;
varying vec3 light_pos;
varying vec3 rel_pos;

//#include "transposemat3.glsl"
//#include "relativeskypos.glsl"

void main()
{	
	mat3 transpose_normal_matrix = transposeMat3(gl_NormalMatrix);

	vec3 eyeSpaceVert = (gl_ModelViewMatrix * gl_Vertex).xyz;
	vertex_pos = normalize(transpose_normal_matrix * eyeSpaceVert);
	
	light_pos = normalize(transpose_normal_matrix * gl_LightSource[0].position.xyz);

	rel_pos = CalcRelativePositionForSky(obj2world, cam_pos);
  
	gl_Position = ftransform();
	gl_TexCoord[0] = gl_MultiTexCoord0;
} 
