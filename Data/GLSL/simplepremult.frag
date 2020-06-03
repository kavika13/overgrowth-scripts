uniform sampler2D tex0;

void main()
{    
    vec4 tex = texture2D(tex0,gl_TexCoord[0].xy);
    tex.xyz *= tex.a;
    gl_FragColor = vec4(tex);
}