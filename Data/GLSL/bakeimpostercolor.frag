uniform sampler2D tex0;

void main()
{    
    gl_FragColor = vec4(texture2D(tex0,gl_TexCoord[0].xy).xyz,1.0);
}