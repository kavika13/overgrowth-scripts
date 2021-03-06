#version 150
#extension GL_ARB_shading_language_420pack : enable
uniform sampler2D tex0;
uniform float tex_size;

void main()
{    
    gl_Position = vec4((gl_MultiTexCoord0.st - vec2(0.5)) * vec2(2.0),0.0,1.0);
    
    gl_TexCoord[0] = gl_MultiTexCoord0;
    
    gl_FrontColor = gl_Color;
} 
