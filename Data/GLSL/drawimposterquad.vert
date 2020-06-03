uniform sampler2D tex0;
uniform sampler2D tex1;
uniform sampler2D tex2;
uniform sampler2D tex3;
uniform samplerCube tex4;
uniform sampler2D tex5;
uniform float radius;
uniform vec3 cam_pos;
uniform vec3 ws_light;
uniform float extra_ao;
uniform float num_angles;

varying vec3 ws_vertex;
varying mat3 normal_mat;
varying vec2 fade;

#include "pseudoinstance.glsl"

void main()
{	
	mat4 obj2world;
	obj2world[0] = vec4(gl_MultiTexCoord1.x, gl_MultiTexCoord2.x, gl_MultiTexCoord3.x, gl_MultiTexCoord4.x);
	obj2world[1] = vec4(gl_MultiTexCoord1.y, gl_MultiTexCoord2.y, gl_MultiTexCoord3.y, gl_MultiTexCoord4.y);
	obj2world[2] = vec4(gl_MultiTexCoord1.z, gl_MultiTexCoord2.z, gl_MultiTexCoord3.z, gl_MultiTexCoord4.z);
	obj2world[3] = vec4(gl_MultiTexCoord1.w, gl_MultiTexCoord2.w, gl_MultiTexCoord3.w, gl_MultiTexCoord4.w);
	
	normal_mat[0] = obj2world[0].xyz;
	normal_mat[1] = obj2world[1].xyz;
	normal_mat[2] = obj2world[2].xyz;

	vec4 translation = obj2world[3];

	vec3 obj_dir = normalize(normal_mat * vec3(0.0,0.0,1.0));
	vec3 obj_right = normal_mat * vec3(1.0,0.0,0.0);
	float right_scale = length(obj_right);
	obj_right = normalize(obj_right);

	vec3 dir = normalize(translation.xyz - cam_pos);
	vec3 up = normal_mat * vec3(0.0,1.0,0.0);
	vec3 right = normalize(cross(dir,up))*right_scale;

	vec2 angle_vec = normalize(vec2(dot(dir, obj_right), dot(dir, obj_dir)));
	float angle_f = atan(angle_vec[0], angle_vec[1]) * 180.0 / 3.1415 + 180.0;
	angle_f /= (360.0 / num_angles);
	angle_f += num_angles;
	angle_f += 1.5;

	//float angle = float(int(angle_f) % int(num_angles));
	float angle = mod(floor(angle_f), num_angles);
	float angle2 = mod(floor((angle_f)-1.0), num_angles);


	fade.x = gl_MultiTexCoord6.x;
	
	fade.y = angle_f - floor(angle_f);
	fade.y = min(1.0,max(0.0,fade.y * 3.0 - 1.5));
	
	vec3 fixed_vert = right*gl_Vertex.x + up * gl_Vertex.y + dir * gl_Vertex.z;
	vec4 transformed_vertex = vec4(fixed_vert.xyz * radius, 0.0) + translation;
	ws_vertex = transformed_vertex.xyz - cam_pos;
	
	gl_Position = (gl_ModelViewProjectionMatrix * transformed_vertex);

	vec2 tex_coord = gl_MultiTexCoord0.xy;
	vec2 tex_coord2 = gl_MultiTexCoord0.xy;
	tex_coord.x /= num_angles;
	tex_coord.x += angle/num_angles;
	tex_coord2.x /= num_angles;
	tex_coord2.x += angle2/num_angles;
	gl_TexCoord[0].xy = tex_coord;
	gl_TexCoord[0].zw = tex_coord2;
	tex_coord *= gl_MultiTexCoord5.zw;
	tex_coord += gl_MultiTexCoord5.xy;
	tex_coord2 *= gl_MultiTexCoord5.zw;
	tex_coord2 += gl_MultiTexCoord5.xy;
	gl_TexCoord[1].xy = tex_coord;
	gl_TexCoord[1].zw = tex_coord2;	
} 
