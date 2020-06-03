uniform sampler2D tex0;
uniform samplerCube tex3;
uniform mat4 obj2world;
uniform vec3 cam_pos;

varying vec3 rel_pos;

void main()
{	
	gl_FragColor = vec4(textureCube(tex3,normalize(rel_pos)).xyz,texture2D(tex0,gl_TexCoord[0].xy).a);
	//gl_FragColor = vec4(textureCube(tex3,vec3(0.0,0.0,-1.0)).xyz,1.0);
}