uniform sampler2D tex0;
uniform sampler2D tex1;
uniform samplerCube tex2;
uniform samplerCube tex3;
uniform sampler2D tex4;
uniform sampler2D tex5;
uniform vec3 cam_pos;
uniform float in_light;
uniform float time;

varying vec3 light_pos; // light position in tangent space
varying mat3 tangent_to_world;
varying vec3 rel_pos;
varying float backlit;

#include "transposemat3.glsl"
#include "relativeskypos.glsl"
#include "pseudoinstance.glsl"
#include "texturepack.glsl"
#include "shadowpack.glsl"

void main()
{	
	mat4 obj2world = GetPseudoInstanceMat4();
	mat3 obj2worldmat3 = GetPseudoInstanceMat3();

	vec4 world_pos = obj2world*gl_Vertex;
	vec4 vertex_offset = vec4(0.0);
	float wind_shake_amount = 0.02*gl_MultiTexCoord4.r;
	float wind_time_scale = 8.0;
	float wind_shake_detail = 6.0;
	float wind_shake_offset = (world_pos.x+world_pos.y)*wind_shake_detail;
	
	wind_shake_amount *= max(0.0,sin((world_pos.x+world_pos.y)+time*0.3));
	wind_shake_amount *= sin((world_pos.x*0.1+world_pos.z)*0.3+time*0.6)+1.0;
	wind_shake_amount = max(0.002,wind_shake_amount);

	vertex_offset.x += sin(time*wind_time_scale+wind_shake_offset)*wind_shake_amount;
	vertex_offset.z += cos(time*wind_time_scale*1.2+wind_shake_offset)*wind_shake_amount;
	vertex_offset.y += cos(time*wind_time_scale*1.4+wind_shake_offset)*wind_shake_amount;
		
	vec3 normal = normalize(gl_Normal)+vertex_offset.xyz*5.0;
	vec3 temp_tangent = normalize(gl_MultiTexCoord1.xyz)+vertex_offset.yzx*5.0;
	vec3 bitangent = normalize(gl_MultiTexCoord2.xyz)+vertex_offset.zxy*5.0;
	
	tangent_to_world = obj2worldmat3 * mat3(temp_tangent, bitangent, normal);
	
	vec3 eyeSpaceVert = (gl_ModelViewMatrix * obj2world * gl_Vertex).xyz;
	vec3 vertex_pos = transposeMat3(gl_NormalMatrix * tangent_to_world) * eyeSpaceVert;
		
	mat3 light_to_world = mat3(obj2world[0].xyz,obj2world[1].xyz,obj2world[2].xyz) * transposeMat3(gl_NormalMatrix*obj2worldmat3);
	
	vec3 world_light = normalize(light_to_world * gl_LightSource[0].position.xyz);

	light_pos = normalize(transposeMat3(gl_NormalMatrix * tangent_to_world) * gl_LightSource[0].position.xyz);
 
	rel_pos = CalcRelativePositionForSky(obj2world, cam_pos);
	
	vec3 fixed_world_light = world_light;
	fixed_world_light.x *= -1.0;
	fixed_world_light.y *= -1.0;
	backlit = max(0.0,dot(fixed_world_light,normalize(rel_pos)));
	
	gl_Position = gl_ProjectionMatrix * gl_ModelViewMatrix * obj2world* (gl_Vertex + vertex_offset);
	
	//gl_Position = vec4((gl_MultiTexCoord0.st - vec2(0.5)) * vec2(2.0),0.0,1.0);
	
	vec2 tex_coords = gl_MultiTexCoord0.xy;
	
	tc0 = tex_coords;
	tc1 = GetShadowCoords();
//	gl_TexCoord[2] = gl_MultiTexCoord4;
} 
