uniform sampler2D tex0;
uniform sampler2D tex1;
uniform samplerCube tex2;
uniform samplerCube tex3;
uniform sampler2D tex4;
uniform vec3 cam_pos;
uniform vec3 ws_light;

varying vec3 obj2world1;
varying vec3 obj2world2;
varying vec3 ws_vertex;

#include "pseudoinstance.glsl"
#include "shadowpack.glsl"
#include "texturepack.glsl"

void main()
{	
	mat4 obj2world = GetPseudoInstanceMat4();
	mat3 obj2worldmat3 = GetPseudoInstanceMat3();
	obj2world1 = normalize(obj2worldmat3[0]);
	obj2world2 = normalize(obj2worldmat3[1]);

	vec4 transformed_vertex = obj2world * gl_Vertex;

	ws_vertex = transformed_vertex.xyz - cam_pos;
	gl_Position = gl_ModelViewProjectionMatrix * transformed_vertex;
	
	tc0 = gl_MultiTexCoord0.xy;
	tc1 = GetShadowCoords();
} 
