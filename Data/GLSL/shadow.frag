#version 150
#ifdef ALPHA
uniform sampler2D tex0;
in vec2 frag_tex;
#endif
out vec4 out_color;

void main() {    
#ifdef ALPHA
    if(texture(tex0, frag_tex).a < 0.1) {
        discard;
    }
#endif
#ifdef ONE_FOURTH_STIPPLE
    if(int(mod(gl_FragCoord.x,2.0))!=0||int(mod(gl_FragCoord.y,2.0))!=0){
        discard;
    }
#endif
#ifdef ONE_HALF_STIPPLE
    if(int(mod(gl_FragCoord.x+gl_FragCoord.y,2.0))==0){
        discard;
    }
#endif
#ifdef THREE_FOURTH_STIPPLE
    if(int(mod(gl_FragCoord.x,2.0))!=0&&int(mod(gl_FragCoord.y,2.0))==0){
        discard;
    }
#endif
#ifdef TRI_COLOR
    out_color.x = (gl_PrimitiveID%256)/255.0;
    out_color.y = ((gl_PrimitiveID/256)%256)/255.0;
    out_color.z = ((gl_PrimitiveID/256)/256)/255.0;
    out_color.a = 0.0;
#else
    out_color = vec4(0.0,0.0,0.0,1.0);
#endif
}