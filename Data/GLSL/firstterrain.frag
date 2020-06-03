uniform vec3 light_pos;
varying vec3 normal;
varying vec3 shadows;

void main()
{    
    // Encode direct lighting in red channel
    /*float NdotL = max(0.0,dot(light_pos, normal)) * max(0.0,shadows.x);
    vec3 color = vec3(0);
    color.r = NdotL;
    
    // Encode ambient occlusion in green channel
    color.g = shadows.y;
    
    color.b = shadows.z;*/
    
    vec3 color = (normal+vec3(1.0))*vec3(0.5);
    
    gl_FragColor = vec4(color,1.0);
}