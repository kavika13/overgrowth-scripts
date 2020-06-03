uniform samplerCube tex2;

varying vec3 normal;
varying float opac;

void main()
{    
    normal = gl_Vertex.xyz;
    normal.y *= -1.0;
    opac = gl_Color.a;
    
    gl_Position = ftransform();
} 
