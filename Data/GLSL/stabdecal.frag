#version 150
uniform sampler2D tex0;

void main()
{    
    if(gl_TexCoord[0].x > 1.0 || gl_TexCoord[0].x < 0.0 ||
       gl_TexCoord[0].y > 1.0 || gl_TexCoord[0].y < 0.0)
    {
        discard;
    }
    vec4 color = texture2D(tex0, gl_TexCoord[0].xy);
    gl_FragColor = vec4(gl_Color.x * color.r, gl_Color.y, gl_Color.z, min(1.0,gl_Color.a * color.r * 10.0));
}
