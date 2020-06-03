uniform sampler2D tex0;
uniform sampler2D tex1;
uniform samplerCube tex2;
uniform samplerCube tex3;
uniform sampler2D tex4;
uniform vec3 cam_pos;
uniform float in_light;

varying vec3 vertex_pos;
varying vec3 light_pos;
varying vec3 rel_pos;
varying mat3 obj2worldmat3;

#include "transposemat3.glsl"
#include "relativeskypos.glsl"
#include "pseudoinstance.glsl"
#include "shadowpack.glsl"
#include "texturepack.glsl"

void main()
{	
	mat4 obj2world = GetPseudoInstanceMat4();
	obj2worldmat3 = GetPseudoInstanceMat3();
	mat3 transpose_normal_matrix = transposeMat3(gl_NormalMatrix*obj2worldmat3);

	vec3 eyeSpaceVert = (gl_ModelViewMatrix * obj2world * gl_Vertex).xyz;
	vertex_pos = normalize(transpose_normal_matrix * eyeSpaceVert);
	
	light_pos = normalize(transpose_normal_matrix * gl_LightSource[0].position.xyz);

	rel_pos = CalcRelativePositionForSky(obj2world, cam_pos);
  
	gl_Position = gl_ProjectionMatrix * gl_ModelViewMatrix * obj2world * gl_Vertex;;
	
	tc0 = gl_MultiTexCoord0.xy;
	tc1 = GetShadowCoords();

	gl_FrontColor = gl_Color;
} 
