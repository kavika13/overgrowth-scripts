#version 150
#extension GL_ARB_shading_language_420pack : enable
uniform sampler2D tex0;

void main()
{
    gl_Position = gl_ModelViewProjectionMatrix * gl_Vertex;
    gl_TexCoord[0] = gl_MultiTexCoord0;
    gl_FrontColor = gl_Color;
} 
