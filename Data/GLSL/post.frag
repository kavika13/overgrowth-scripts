#extension GL_ARB_texture_rectangle : enable

uniform sampler2DRect tex0;

void main() {    
    gl_FragColor = texture2DRect( tex0, gl_TexCoord[0].st ).rgba;
}