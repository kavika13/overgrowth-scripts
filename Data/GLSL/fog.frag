uniform sampler2D tex;
uniform samplerCube tex4;
uniform mat4 obj2world;
uniform vec3 cam_pos;

varying vec3 rel_pos;

void main()
{	
	gl_FragColor = vec4(textureCube(tex4,normalize(rel_pos)).xyz,texture2D(tex,gl_TexCoord[0].xy).a);
}