uniform samplerCube tex2;

varying vec3 normal;
varying float opac;

void main()
{    
    vec3 color;

    color = textureCube(tex2,normal).xyz;

    color.x = pow(color.x,2.2);
    color.y = pow(color.y,2.2);
    color.z = pow(color.z,2.2);

    gl_FragColor = vec4(color,opac);
}