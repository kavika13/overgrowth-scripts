uniform sampler2D tex;
uniform sampler2D tex2;
uniform samplerCube tex3;
uniform samplerCube tex4;
uniform sampler2D tex5;
uniform mat4 obj2world;
uniform vec3 cam_pos;

varying vec3 normal;
varying vec3 temp_tangent;
varying vec3 vertex_pos;
varying vec3 light_pos;
varying mat3 tangent_to_world;
varying vec3 rel_pos;

mat3 transposeMat3(const mat3 matrix) {
	mat3 temp;
	temp[0][0] = matrix[0][0];
	temp[0][1] = matrix[1][0];
	temp[0][2] = matrix[2][0];
	temp[1][0] = matrix[0][1];
	temp[1][1] = matrix[1][1];
	temp[1][2] = matrix[2][1];
	temp[2][0] = matrix[0][2];
	temp[2][1] = matrix[1][2];
	temp[2][2] = matrix[2][2];
	return temp;
}

void main()
{	
	normal = normalize(gl_Normal);
	temp_tangent = normalize(gl_MultiTexCoord1.xyz);
	vec3 bitangent = normalize(gl_MultiTexCoord2.xyz);
	
	tangent_to_world = mat3(temp_tangent, bitangent, normal);
	
	vec3 eyeSpaceVert = (gl_ModelViewMatrix * gl_Vertex).xyz;
	vertex_pos = transposeMat3(gl_NormalMatrix * tangent_to_world) * eyeSpaceVert;
	
	light_pos = transposeMat3(gl_NormalMatrix * tangent_to_world) * gl_LightSource[0].position.xyz;
 
	rel_pos = vec3(obj2world * gl_Vertex) - cam_pos;
	rel_pos.y *= -1.0;
	
	gl_Position = ftransform();
	gl_TexCoord[0] = gl_MultiTexCoord0;
	gl_TexCoord[1] = gl_MultiTexCoord3;
} 
