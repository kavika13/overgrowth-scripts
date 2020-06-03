uniform sampler2D tex0;
uniform sampler2DShadow tex2;

varying vec3 normal;
varying vec4 ProjShadow;

void main()
{    
    vec3 color;
    
    float offset = 1.0/4096.0;
    float shadowed = shadow2DProj(tex2, ProjShadow).r*.2;
    shadowed += shadow2DProj(tex2, ProjShadow + vec4(-offset*2.0,offset,0.0,0.0)).r*.2;
    shadowed += shadow2DProj(tex2, ProjShadow + vec4(offset*2.0,-offset,0.0,0.0)).r*.2;
    shadowed += shadow2DProj(tex2, ProjShadow + vec4(-offset,offset*2.0,0.0,0.0)).r*.2;
    shadowed += shadow2DProj(tex2, ProjShadow + vec4(offset,-offset*2.0,0.0,0.0)).r*.2;
    
    vec4 color_tex = texture2D(tex0,gl_TexCoord[0].xy);
    
    color = gl_Color.xyz * color_tex.xyz * (shadowed*0.7+0.3);

    gl_FragColor = vec4(color,color_tex.a*gl_Color.a);
}