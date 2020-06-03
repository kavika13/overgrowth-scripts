#extension GL_ARB_texture_rectangle : enable

uniform sampler2D tex0;
uniform sampler2DRect tex5;
uniform float size;

void main()
{    
    gl_Position = ftransform();
    
    gl_TexCoord[0] = gl_MultiTexCoord0;
    
    gl_FrontColor = gl_Color;
} 
