#extension GL_ARB_texture_rectangle : enable

void main()
{    
    gl_Position = ftransform();  
    gl_TexCoord[0] = gl_MultiTexCoord0;
}