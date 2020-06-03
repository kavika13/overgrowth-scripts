uniform vec3 light_pos;

uniform sampler2D tex;
uniform sampler2D tex2;
uniform samplerCube tex3;
uniform samplerCube tex4;
uniform sampler2D tex5;

uniform mat4 obj2world;

varying vec3 normal;
varying vec3 tangent;
varying vec3 bitangent;

void main()
{	
	normal = normalize(gl_Normal);

	mat3 obj2world3 = mat3(obj2world[0].xyz, obj2world[1].xyz, obj2world[2].xyz);
	
	tangent = obj2world3*normalize(gl_MultiTexCoord1.xyz);
	bitangent = obj2world3*normalize(gl_MultiTexCoord2.xyz);
	
	gl_Position = ftransform();
	
	gl_TexCoord[0] = gl_MultiTexCoord0;
	gl_TexCoord[1] = gl_MultiTexCoord3;
} 
