uniform sampler2D tex0;
uniform sampler2D tex1;

varying vec3 normal;

void main()
{    
    vec3 color;
    
    vec4 normalmap;
    vec4 color_tex;
    
    //normalmap = texture2D(tex2,gl_TexCoord[0].xy);
    color_tex = texture2D(tex0,gl_TexCoord[0].xy);
    
    //color = color_tex.xyz * vec3(1.0-color_tex.a*0.8,0,0);
    
    color = vec3(1.0-color_tex.a*0.6,0,0);
    
    gl_FragColor = vec4(color,color_tex.a * 2.0);
}