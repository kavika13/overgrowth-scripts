#version 150
#extension GL_ARB_shading_language_420pack : enable
uniform sampler2D tex;

void main()
{    
    gl_FragColor = texture2D(tex,gl_TexCoord[0].xy);
}
