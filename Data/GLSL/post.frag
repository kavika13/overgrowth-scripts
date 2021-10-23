#extension GL_ARB_texture_rectangle : enable

uniform sampler2DRect tex0;

void main() {    
    vec3 color_map = texture2DRect( tex0, gl_TexCoord[0].st ).rgb;
    gl_FragColor = vec4(color_map,1.0);
}