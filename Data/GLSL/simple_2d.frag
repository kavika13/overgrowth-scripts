#version 150

#ifdef TEXTURE
uniform sampler2D tex0;
#endif

#ifndef COLOREDVERTICES
uniform vec4 color;
#else
in vec4 color;
#endif


#ifdef TEXTURE
in vec2 var_tex_coord; 
#endif

out vec4 out_color;

void main() {    
#if defined TEXTURE
    #if defined(STAB)
        vec4 tex_color = texture(tex0,var_tex_coord.xy);
        out_color = vec4(color[0] * tex_color[0], color[2], color[3], min(1.0,color[3] * tex_color[0] * 10.0));
    #else
        out_color = color * vec4(texture(tex0,var_tex_coord.xy));
    #endif
#else
    //out_color = vec4(1.0,0.0,0.0,1.0); //color;
    out_color = color;
#endif
}