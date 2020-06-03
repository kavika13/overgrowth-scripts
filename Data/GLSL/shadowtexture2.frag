uniform sampler2D tex0;
uniform float tex_size;

void main()
{    
    vec4 color = texture2D(tex0,gl_TexCoord[0].xy);
    if(color.a<1.0) {
        float offset_size = 1.0/tex_size;
        float total_alpha = 0.0;
        color = vec4(0.0);
        vec4 contrib;
        contrib+= texture2D(tex0,gl_TexCoord[0].xy+vec2(offset_size,0.0));
        total_alpha += contrib.a;
        color += contrib*contrib.a;
        contrib = texture2D(tex0,gl_TexCoord[0].xy+vec2(-offset_size,0.0));
        total_alpha += contrib.a;
        color += contrib*contrib.a;
        contrib = texture2D(tex0,gl_TexCoord[0].xy+vec2(0.0,offset_size));
        total_alpha += contrib.a;
        color += contrib*contrib.a;
        contrib = texture2D(tex0,gl_TexCoord[0].xy+vec2(0.0,-offset_size));
        
        contrib = texture2D(tex0,gl_TexCoord[0].xy+vec2(offset_size,offset_size));
        total_alpha += contrib.a;
        color += contrib*contrib.a;
        contrib = texture2D(tex0,gl_TexCoord[0].xy+vec2(-offset_size,offset_size));
        total_alpha += contrib.a;
        color += contrib*contrib.a;
        contrib = texture2D(tex0,gl_TexCoord[0].xy+vec2(offset_size,-offset_size));
        total_alpha += contrib.a;
        color += contrib*contrib.a;
        contrib = texture2D(tex0,gl_TexCoord[0].xy+vec2(-offset_size,-offset_size));
        
        if(total_alpha>0.01) {
            color /= total_alpha;
            //color.a = 1.0;
        }
    }
    
    //color = 1.0;
    
    //color = texture2D(tex,gl_TexCoord[0].xy);
    

    gl_FragColor = color;
}