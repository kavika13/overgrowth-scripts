uniform sampler2D tex0;
uniform sampler2D tex1;
uniform sampler2D tex2;
uniform sampler2D tex3;
uniform samplerCube tex4;
uniform sampler2D tex5;
uniform sampler2D tex6;
uniform sampler2D tex7;
uniform float rotation;
uniform float rotation_total;
uniform float rotation_total2;
uniform float radius;
uniform vec3 cam_pos;
uniform vec3 ws_light;
uniform float extra_ao;
uniform float fade;

varying vec3 ws_vertex;

#include "pseudoinstance.glsl"

void main()
{	
	mat4 obj2world = GetPseudoInstanceMat4();
	vec4 transformed_vertex = obj2world * gl_Vertex;
	ws_vertex = transformed_vertex.xyz - cam_pos;
	gl_Position = ftransform();

	gl_TexCoord[0].xy = gl_MultiTexCoord0.xy;
	gl_TexCoord[1].xy = gl_MultiTexCoord0.xy;
} 
