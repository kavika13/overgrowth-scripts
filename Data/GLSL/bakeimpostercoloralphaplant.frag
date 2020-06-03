uniform sampler2D tex0;

void main()
{    
    vec4 color = texture2D(tex0,gl_TexCoord[0].xy);
    color.a = pow(color.a,0.1);
    gl_FragColor = vec4(color);
}