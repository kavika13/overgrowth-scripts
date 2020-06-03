uniform sampler2D tex;
uniform samplerCube tex3;
uniform samplerCube tex4;
uniform vec4 emission;
uniform mat4 obj2world;

varying vec3 normal;
varying vec3 world_normal;

//#include "transposemat3.glsl"

void main()
{	
	normal = normalize(gl_NormalMatrix * gl_Normal);
	
	world_normal = normalize(gl_Normal);
	world_normal = mat3(obj2world[0].xyz, obj2world[1].xyz, obj2world[2].xyz)*world_normal;
	world_normal.xy *= -1.0;
	
	gl_Position = ftransform();
	
	gl_TexCoord[0] = gl_MultiTexCoord0;
	
	gl_FrontColor = gl_Color;
} 
