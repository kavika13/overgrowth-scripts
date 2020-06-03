uniform sampler2D tex0;
uniform sampler2D tex1;
uniform samplerCube tex2;
uniform samplerCube tex3;
uniform sampler2D tex4;
uniform sampler2D tex5;
uniform sampler2D tex6;
uniform sampler2D tex7;
uniform sampler2D tex8;
uniform sampler2D tex9;
uniform sampler2D tex10;
uniform sampler2D tex11;
uniform sampler2D tex12;
uniform sampler2D tex13;
uniform vec3 cam_pos;
uniform vec3 avg_color0;
uniform vec3 avg_color1;
uniform vec3 avg_color2;
uniform vec3 avg_color3;
uniform int weight_component;

varying vec3 tangent;
varying vec3 vertex_pos;
varying vec3 light_pos;
varying vec3 rel_pos;
varying float alpha;

#include "relativeskypos.glsl"
#include "pseudoinstance.glsl"
#include "transposemat3.glsl"

const float terrain_size = 500.0;
const float fade_distance = 50.0;
const float fade_mult = 1.0 / fade_distance;

void main()
{	
	mat4 obj2world = GetPseudoInstanceMat4();
	mat3 obj2worldmat3 = GetPseudoInstanceMat3();

	vec3 normal = normalize(gl_Normal);
	tangent = normalize(gl_MultiTexCoord1.xyz);
	vec3 bitangent = normalize(gl_MultiTexCoord2.xyz);
	
	mat3 tangent_to_world = obj2worldmat3*mat3(tangent, bitangent, normal);
	
	vec3 eyeSpaceVert = (gl_ModelViewMatrix * obj2world * gl_Vertex).xyz;
	vertex_pos = transposeMat3(gl_NormalMatrix) * eyeSpaceVert;
	
	light_pos = transposeMat3(gl_NormalMatrix) * gl_LightSource[0].position.xyz;
 
	gl_Position = gl_ProjectionMatrix * gl_ModelViewMatrix * obj2world * gl_Vertex;
	
	rel_pos = CalcRelativePositionForSky(obj2world, cam_pos);
	
	//alpha = min(1.0,(gl_Vertex.x+500.0)*0.01);
	alpha = min(1.0,(terrain_size-gl_Vertex.x)*fade_mult)*
			min(1.0,(gl_Vertex.x+500.0)*fade_mult)*
			min(1.0,(terrain_size-gl_Vertex.z)*fade_mult)*
			min(1.0,(gl_Vertex.z+500.0)*fade_mult);

	alpha = max(0.0,alpha);

	gl_TexCoord[0] = gl_MultiTexCoord0+vec4(0.0005)+vec4(light_pos.xz*0.0005,0.0,0.0);	
	gl_TexCoord[1] = gl_MultiTexCoord3*0.1;
} 
