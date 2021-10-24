uniform sampler2D tex0;
uniform samplerCube tex3;
uniform mat4 obj2world;
uniform vec3 cam_pos;

varying vec3 rel_pos;

void main() {    
    gl_FragColor = vec4(textureCubeLod(tex3,normalize(rel_pos), 5.0).xyz,texture2D(tex0,gl_TexCoord[0].xy).a);
}