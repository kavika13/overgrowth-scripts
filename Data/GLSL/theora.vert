#version 150
#extension GL_ARB_shading_language_420pack : enable
uniform sampler2D tex0;
uniform samplerCube tex3;
uniform float shadowed;

void main()
{    
    gl_Position = ftransform();
    
    gl_TexCoord[0] = gl_MultiTexCoord0;
    
    gl_FrontColor = gl_Color;
} 
