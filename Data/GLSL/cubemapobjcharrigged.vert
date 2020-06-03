uniform sampler2D tex0;
uniform sampler2D tex1;
uniform samplerCube tex2;
uniform samplerCube tex3;
uniform sampler2D tex4;
uniform mat4 obj2world;
uniform vec3 cam_pos;
uniform float in_light;
//uniform mat4 bones[64];

varying vec3 vertex_pos;
varying vec3 light_pos;
varying vec3 rel_pos;
varying vec3 world_light;
varying vec3 concat_bone1;
varying vec3 concat_bone2;
varying vec3 concat_bone3;

#include "transposemat3.glsl"
#include "relativeskypos.glsl"

void main()
{	
	mat3 transpose_normal_matrix = transposeMat3(gl_NormalMatrix);

	mat4 concat_bone;
	/*concat_bone = bones[int(gl_MultiTexCoord6.x)]*gl_MultiTexCoord5.x;
	concat_bone += bones[int(gl_MultiTexCoord6.y)]*gl_MultiTexCoord5.y;
	concat_bone += bones[int(gl_MultiTexCoord6.z)]*gl_MultiTexCoord5.z;
	concat_bone += bones[int(gl_MultiTexCoord6.a)]*gl_MultiTexCoord5.a;
*/
	concat_bone[0] = vec4(gl_MultiTexCoord1[0],gl_MultiTexCoord2[0],gl_MultiTexCoord4[0],0.0);
	concat_bone[1] = vec4(gl_MultiTexCoord1[1],gl_MultiTexCoord2[1],gl_MultiTexCoord4[1],0.0);
	concat_bone[2] = vec4(gl_MultiTexCoord1[2],gl_MultiTexCoord2[2],gl_MultiTexCoord4[2],0.0);
	concat_bone[3] = vec4(gl_MultiTexCoord1[3],gl_MultiTexCoord2[3],gl_MultiTexCoord4[3],1.0);
	
	/*concat_bone[0] = vec4(1.0,0.0,0.0,0.0);
	concat_bone[1] = vec4(0.0,1.0,0.0,0.0);
	concat_bone[2] = vec4(0.0,0.0,1.0,0.0);
	concat_bone[3] = vec4(0.0,0.0,0.0,1.0);
*/
	concat_bone1 = concat_bone[0].xyz;
	concat_bone2 = concat_bone[1].xyz;
	concat_bone3 = concat_bone[2].xyz;
/*
	concat_bone1 = vec3(1.0,0.0,0.0);
	concat_bone2 = vec3(0.0,1.0,0.0);
	concat_bone3 = vec3(0.0,0.0,1.0);*/

	vec3 eyeSpaceVert = (gl_ModelViewMatrix * concat_bone * gl_Vertex).xyz;
	vertex_pos = normalize(transpose_normal_matrix * eyeSpaceVert);
	
	mat3 light_to_world = mat3(obj2world[0].xyz,obj2world[1].xyz,obj2world[2].xyz) * transposeMat3(gl_NormalMatrix);	

	world_light = normalize(light_to_world * gl_LightSource[0].position.xyz);
	world_light.x *= -1.0;
	world_light.y *= -1.0;

	light_pos = normalize(transpose_normal_matrix * gl_LightSource[0].position.xyz);

	rel_pos = CalcRelativePositionForSky(obj2world, cam_pos);
 
	gl_Position = gl_ModelViewProjectionMatrix * concat_bone * gl_Vertex;
	gl_TexCoord[0] = gl_MultiTexCoord0;
	gl_TexCoord[1] = gl_MultiTexCoord3;
} 
