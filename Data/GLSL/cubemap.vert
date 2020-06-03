uniform sampler2D tex0;
uniform sampler2D tex1;
uniform samplerCube tex2;
uniform samplerCube tex3;
uniform sampler2D tex4;
uniform vec3 cam_pos;
uniform vec3 ws_light;
uniform float fade;

varying vec3 ws_vertex;
varying vec3 tangent_to_world1;
varying vec3 tangent_to_world2;
varying vec3 tangent_to_world3;

#include "pseudoinstance.glsl"
#include "shadowpack.glsl"
#include "texturepack.glsl"

void main()
{	
	mat3 obj2worldmat3 = GetPseudoInstanceMat3();
	mat3 tan_to_obj = mat3(gl_MultiTexCoord1.xyz, gl_MultiTexCoord2.xyz, gl_Normal);
	mat3 tangent_to_world = obj2worldmat3 * tan_to_obj;
	tangent_to_world1 = normalize(tangent_to_world[0]);
	tangent_to_world2 = normalize(tangent_to_world[1]);
	tangent_to_world3 = normalize(tangent_to_world[2]);

	mat4 obj2world = GetPseudoInstanceMat4();
	vec4 transformed_vertex = obj2world * gl_Vertex;
	ws_vertex = transformed_vertex.xyz - cam_pos;
	
	gl_Position = gl_ModelViewProjectionMatrix * transformed_vertex;
	
	tc0 = gl_MultiTexCoord0.xy;
	tc1 = GetShadowCoords();
} 
