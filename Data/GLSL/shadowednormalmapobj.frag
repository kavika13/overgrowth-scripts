uniform sampler2D tex0;
uniform sampler2D tex1;
uniform sampler2DShadow tex2;

varying vec3 light_pos;
varying vec3 light2_pos;
varying vec3 half_vector;
varying vec3 half_vector2;
varying vec4 ProjShadow;

void main()
{    
    float NdotL;
    vec3 color;
    
    vec4 normalmap;
    vec3 normal;
    vec4 color_tex;
    float spec;
    
    color_tex = texture2D(tex0,gl_TexCoord[0].xy);
    normalmap = texture2D(tex1,gl_TexCoord[0].xy);
    normal = normalize(gl_NormalMatrix*(vec3(normalmap.x, normalmap.z, normalmap.y)*2.0-1.0));
    
    float offset = 1.0/4096.0;
    float shadowed = shadow2DProj(tex2, ProjShadow).r*.2;
    shadowed += shadow2DProj(tex2, ProjShadow + vec4(-offset*2.0,offset,0.0,0.0)).r*.2;
    shadowed += shadow2DProj(tex2, ProjShadow + vec4(offset*2.0,-offset,0.0,0.0)).r*.2;
    shadowed += shadow2DProj(tex2, ProjShadow + vec4(-offset,offset*2.0,0.0,0.0)).r*.2;
    shadowed += shadow2DProj(tex2, ProjShadow + vec4(offset,-offset*2.0,0.0,0.0)).r*.2;
    
    NdotL = max(dot(normal,light_pos),0.0);
    spec = max(pow(dot(normal,normalize(half_vector)),40.0),0.0)*2.0 * NdotL ;
    color = gl_LightSource[0].diffuse.xyz * NdotL *(0.4+shadowed*0.6) * color_tex.xyz;
    color += spec * gl_LightSource[0].diffuse.xyz * normalmap.a * shadowed;
    
    NdotL = max(dot(normal,light2_pos),0.0);
    spec = max(pow(dot(normal,normalize(half_vector2)),4.0),0.0);
    color += gl_LightSource[1].diffuse.xyz * NdotL * color_tex.xyz;
    color += spec * gl_LightSource[1].diffuse.xyz * normalmap.a * 0.5;

    //color = shadowed;
    
    //color = vec3(0);

    gl_FragColor = vec4(color,1.0);
}