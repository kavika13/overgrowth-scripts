uniform sampler2D tex0;
uniform sampler2D tex1;

varying vec3 tangent_to_obj1;
varying vec3 tangent_to_obj2;
varying vec3 tangent_to_obj3;

#include "pseudoinstance.glsl"

void main()
{	
	mat3 tan_to_obj = mat3(gl_MultiTexCoord1.xyz, 
						   gl_MultiTexCoord2.xyz, 
						   gl_Normal);
	tangent_to_obj1 = normalize(tan_to_obj[0]);
	tangent_to_obj2 = normalize(tan_to_obj[1]);
	tangent_to_obj3 = normalize(tan_to_obj[2]);
	mat4 obj2world = GetPseudoInstanceMat4();
	vec4 transformed_vertex = obj2world * gl_Vertex;
	gl_Position = gl_ModelViewProjectionMatrix * transformed_vertex;
	gl_TexCoord[0] = gl_MultiTexCoord0;
} 
