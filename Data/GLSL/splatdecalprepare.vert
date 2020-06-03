uniform sampler2D tex0;
uniform sampler2D tex1;

varying vec3 gravity;

void main()
{	
	vec3 normal = normalize(gl_Normal);
	vec3 temp_tangent = normalize(gl_MultiTexCoord1.xyz);
	vec3 bitangent = normalize(gl_MultiTexCoord2.xyz);
	
	gravity = vec3(temp_tangent.y, bitangent.y, normal.y);
	
	gl_Position = ftransform();
} 
