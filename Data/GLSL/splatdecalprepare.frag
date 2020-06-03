uniform sampler2D tex0;
uniform sampler2D tex1;

varying vec3 gravity;

void main()
{    
    vec3 color;
    
    color = gravity*0.5 + vec3(0.5);
    
    gl_FragColor = vec4(color,1.0);
}