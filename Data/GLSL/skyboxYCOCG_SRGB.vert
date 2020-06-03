uniform samplerCube tex2;

varying vec3 normal;
varying float opac;

void main() {    
    normal = gl_Vertex.xyz;
    opac = gl_Color.a;
    gl_Position = ftransform();
} 
