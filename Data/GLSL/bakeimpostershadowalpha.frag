uniform sampler2D tex0;
uniform sampler2D tex1;

void main()
{    
    gl_FragColor = vec4(texture2D(tex0,gl_TexCoord[1].xy).xyz,
                        texture2D(tex1,gl_TexCoord[0].xy).a);
    //gl_FragColor = vec4(1.0,0.0,0.0,1.0);
}