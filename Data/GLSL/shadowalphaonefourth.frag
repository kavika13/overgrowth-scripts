uniform sampler2D tex0;

void main()
{    
    if(texture2D(tex0,gl_TexCoord[0].xy).a < 0.1) {
        discard;
    }
    if(int(mod(gl_FragCoord.x,2.0))!=0||int(mod(gl_FragCoord.y,2.0))!=0){
        discard;
    }
    gl_FragColor = vec4(0.0,0.0,0.0,1.0);
}