uniform sampler2D tex0;
uniform samplerCube tex3;
uniform mat4 obj2world;
uniform vec3 cam_pos;

varying vec3 rel_pos;

void main()
{	
	rel_pos = vec3(obj2world * gl_Vertex);// - cam_pos;
	rel_pos.y *= -1.0;
	
	gl_Position = ftransform();
	gl_TexCoord[0] = gl_MultiTexCoord0;
} 
