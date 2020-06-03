uniform sampler2D tex;
uniform sampler2D tex2;
uniform samplerCube tex3;
uniform samplerCube tex4;
uniform sampler2D tex5;
uniform sampler2D tex6;
uniform mat4 obj2world;
uniform vec3 cam_pos;
uniform float in_light;
uniform float time;

varying vec3 vertex_pos;
varying vec3 light_pos;
varying mat3 tangent_to_world;
varying vec3 rel_pos;
varying vec3 world_light;

//#include "transposemat3.glsl"
//#include "relativeskypos.glsl"

void main()
{	
	vec4 world_pos = obj2world*gl_Vertex;
	vec4 vertex_offset = vec4(0.0);
	float wind_shake_amount = 0.02*gl_MultiTexCoord4.r;
	float wind_time_scale = 8.0;
	float wind_shake_detail = 6.0;
	float wind_shake_offset = (world_pos.x+world_pos.y)*wind_shake_detail;
	vertex_offset.x += sin(time*wind_time_scale+wind_shake_offset)*wind_shake_amount;
	vertex_offset.z += cos(time*wind_time_scale*1.2+wind_shake_offset)*wind_shake_amount;
	vertex_offset.y += cos(time*wind_time_scale*1.4+wind_shake_offset)*wind_shake_amount;
		
	vec3 normal = normalize(gl_Normal)+vertex_offset.xyz*5.0;
	vec3 temp_tangent = normalize(gl_MultiTexCoord1.xyz)+vertex_offset.yzx*5.0;
	vec3 bitangent = normalize(gl_MultiTexCoord2.xyz)+vertex_offset.zxy*5.0;
	
	tangent_to_world = /*transposeMat3mat3(obj2world[0].xyz, obj2world[1].xyz, obj2world[2].xyz) * */mat3(temp_tangent, bitangent, normal);
	
	vec3 eyeSpaceVert = (gl_ModelViewMatrix * gl_Vertex).xyz;
	vertex_pos = transposeMat3(gl_NormalMatrix * tangent_to_world) * eyeSpaceVert;
	
	//world_light = normalize(transposeMat3(mat3(gl_ModelViewMatrix[0].xyz,gl_ModelViewMatrix[1].xyz,gl_ModelViewMatrix[2].xyz)) * gl_LightSource[0].position.xyz);
		
	mat3 light_to_world = mat3(obj2world[0].xyz,obj2world[1].xyz,obj2world[2].xyz) * transposeMat3(gl_NormalMatrix);
	
	world_light = normalize(light_to_world * gl_LightSource[0].position.xyz);

	light_pos = normalize(transposeMat3(gl_NormalMatrix * tangent_to_world) * gl_LightSource[0].position.xyz);
 
	rel_pos = CalcRelativePositionForSky(obj2world, cam_pos);
	
	gl_Position = gl_ProjectionMatrix * gl_ModelViewMatrix * (gl_Vertex + vertex_offset);
	
	//gl_Position = vec4((gl_MultiTexCoord0.st - vec2(0.5)) * vec2(2.0),0.0,1.0);
	
	gl_TexCoord[0] = gl_MultiTexCoord0;
	gl_TexCoord[1] = gl_MultiTexCoord3;//+vertex_offset;
//	gl_TexCoord[2] = gl_MultiTexCoord4;
} 
