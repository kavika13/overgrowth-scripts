uniform sampler2D tex0;
uniform sampler2D tex1;

varying vec3 light_pos;
varying vec3 light2_pos;
varying vec3 vertex_pos;

void main()
{    
    float NdotL;
    vec3 color;
    
    vec3 H = normalize(normalize(vertex_pos*-1.0) + normalize(light_pos));
    
    vec4 normalmap;
    vec3 normal;
    vec4 color_tex;
    float spec;
    
    normalmap = texture2D(tex1,gl_TexCoord[0].xy);
    normal = normalize(vec3((normalmap.x-0.5)*2.0, (normalmap.y-0.5)*-2.0, normalmap.z));
    
    
    NdotL = max(dot(normal,normalize(light_pos)),0.0);
    spec = min(1.0, max(0.0,pow(dot(normal,H),40.0)*2.0 * NdotL)) ;
    
    color_tex = texture2D(tex0,gl_TexCoord[0].xy);
    
    color = gl_LightSource[0].diffuse.xyz * NdotL * color_tex.xyz;
    color += spec * gl_LightSource[0].diffuse.xyz * color_tex.a;
    
    NdotL = max(dot(normal,normalize(light2_pos)),0.0);
    H = normalize(normalize(vertex_pos*-1.0) + normalize(light2_pos));
    spec = min(1.0,max(pow(dot(normal,H),4.0),0.0));
    
    color += gl_LightSource[1].diffuse.xyz * NdotL * color_tex.xyz;
    color += spec * gl_LightSource[1].diffuse.xyz * color_tex.a * 0.5;

    //color = NdotL;

    gl_FragColor = vec4(color,1.0);
}