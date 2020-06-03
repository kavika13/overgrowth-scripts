uniform vec3 light_pos;

uniform sampler2D tex0;

uniform mat4 obj2world;

void main()
{	
	gl_Position = ftransform();
	
	gl_TexCoord[0] = gl_MultiTexCoord0;
	gl_TexCoord[1] = gl_MultiTexCoord3;
} 
