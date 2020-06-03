uniform sampler2D tex0;
uniform sampler2D tex1;

void main()
{    
    vec3 color;
    
    vec4 normalmap;
    vec4 color_tex;
    
    normalmap = texture2D(tex1,gl_TexCoord[1].xy);
    color_tex = texture2D(tex0,gl_TexCoord[0].xy);
    
    //color = color_tex.xyz + vec3(normalmap.a);
        
    gl_FragColor = vec4((normalmap.a + color_tex.a)*0.5);
}