#pragma use_tangent

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
uniform sampler2D tex14;
uniform vec3 cam_pos;
uniform vec3 avg_color0;
uniform vec3 avg_color1;
uniform vec3 avg_color2;
uniform vec3 avg_color3;
uniform int weight_component;
uniform vec3 ws_light;
uniform float fade;
uniform float detail_scale;
uniform vec3 color_tint;

varying vec3 tangent;
varying vec3 ws_vertex;
varying float alpha;

#include "relativeskypos.glsl"
#include "pseudoinstance.glsl"
#include "transposemat3.glsl"
#include "texturepack.glsl"
#include "shadowpack.glsl"

const float terrain_size = 500.0;
const float fade_distance = 50.0;
const float fade_mult = 1.0 / fade_distance;

void main()
{	
	mat4 obj2world = GetPseudoInstanceMat4();

	tangent = gl_MultiTexCoord1.xyz;
	
	vec4 transformed_vertex = obj2world * gl_Vertex;
	ws_vertex = transformed_vertex.xyz - cam_pos;
	
	gl_Position = gl_ModelViewProjectionMatrix * transformed_vertex;
	
	alpha = min(1.0,(terrain_size-gl_Vertex.x)*fade_mult)*
			min(1.0,(gl_Vertex.x+500.0)*fade_mult)*
			min(1.0,(terrain_size-gl_Vertex.z)*fade_mult)*
			min(1.0,(gl_Vertex.z+500.0)*fade_mult);

	alpha = max(0.0,alpha);

	tc0 = gl_MultiTexCoord0.xy;
	tc1 = GetShadowCoords();
} 
