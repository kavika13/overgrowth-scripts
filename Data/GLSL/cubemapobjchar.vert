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
varying vec3 world_light;
varying mat3 obj2worldmat3;
//varying vec3 normal_var;

#include "transposemat3.glsl"
#include "relativeskypos.glsl"
#include "pseudoinstance.glsl"

void main()
{	
	mat4 obj2world = GetPseudoInstanceMat4();
	obj2worldmat3 = GetPseudoInstanceMat3();

	//normal_var = normalize(gl_Normal);//(obj2world * vec4(normalize(gl_NormalMatrix * gl_Normal),0.0)).xyz;
	
	mat3 transpose_normal_matrix = transposeMat3(gl_NormalMatrix*obj2worldmat3);

	vec3 eyeSpaceVert = (gl_ModelViewMatrix * obj2world * gl_Vertex).xyz;
	vertex_pos = normalize(transpose_normal_matrix * eyeSpaceVert);
	
	mat3 light_to_world = mat3(obj2world[0].xyz,obj2world[1].xyz,obj2world[2].xyz) * transpose_normal_matrix;	

	world_light = normalize(light_to_world * gl_LightSource[0].position.xyz);
	world_light.x *= -1.0;
	world_light.y *= -1.0;

	light_pos = normalize(transpose_normal_matrix * gl_LightSource[0].position.xyz);

	rel_pos = CalcRelativePositionForSky(obj2world, cam_pos);
  
	gl_Position = gl_ProjectionMatrix * gl_ModelViewMatrix * obj2world * gl_Vertex;;
	
	gl_TexCoord[0] = gl_MultiTexCoord0;
	gl_TexCoord[1] = gl_MultiTexCoord3;
	gl_FrontColor = gl_Color;
} 
