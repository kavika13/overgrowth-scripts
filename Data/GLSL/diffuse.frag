#version 150
uniform sampler2D tex0;
uniform vec4 emission;
varying vec3 normal;

void main()
{    
    float NdotL;
    vec3 color;
    
    NdotL = max(dot(normal,gl_LightSourceDEPRECATED[0].position.xyz),0.0);
    vec4 color_tex = texture2D(tex0,gl_TexCoord[0].xy);
    
    color = gl_LightSourceDEPRECATED[0].diffuse.xyz * NdotL * gl_Color.xyz;// * color_tex.xyz;
    
    NdotL = max(dot(normal,normalize(gl_LightSourceDEPRECATED[1].position.xyz)),0.0);
    
    color += gl_LightSourceDEPRECATED[1].diffuse.xyz * NdotL * gl_Color.xyz;// * color_tex.xyz;

    color += emission.xyz;
            
    gl_FragColor = vec4(color,1.0);
}
