#version 150
#extension GL_ARB_shading_language_420pack : enable

#pragma transparent

uniform sampler2D tex4;

void main()
{    
    vec3 shadow_tex = texture2D(tex4,gl_TexCoord[1].xy).rgb;
    
    gl_FragColor = vec4(shadow_tex.xyz,1.0);
}
