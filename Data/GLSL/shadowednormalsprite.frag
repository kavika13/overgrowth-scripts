uniform sampler2D tex0;
uniform sampler2D tex1;
uniform sampler2DShadow tex2;

varying vec3 light_pos;
varying vec3 light2_pos;
varying vec3 vertex_pos;
varying vec4 ProjShadow;

void main()
{    
    float NdotL;
    vec3 color;
    
    vec4 normalmap;
    vec3 normal;
    vec4 color_tex;
    
    normalmap = texture2D(tex1,gl_TexCoord[0].xy);
    normal = normalize(vec3((normalmap.x-0.5)*2.0, (normalmap.y-0.5)*-2.0, normalmap.z));
    //normal = vec3(0,0,1);
    
    float offset = 1.0/4096.0/2.0;
    float shadowed = shadow2DProj(tex2, ProjShadow).r*.2;
    shadowed += shadow2DProj(tex2, ProjShadow + vec4(-offset*2.0,offset,0.0,0.0)).r*.2;
    shadowed += shadow2DProj(tex2, ProjShadow + vec4(offset*2.0,-offset,0.0,0.0)).r*.2;
    shadowed += shadow2DProj(tex2, ProjShadow + vec4(-offset,offset*2.0,0.0,0.0)).r*.2;
    shadowed += shadow2DProj(tex2, ProjShadow + vec4(offset,-offset*2.0,0.0,0.0)).r*.2;
    
    
    NdotL = (dot(normal,normalize(light_pos))+1.0)/2.0*(0.2+shadowed*0.8);
    
    color_tex = texture2D(tex0,gl_TexCoord[0].xy);
    
    color = gl_LightSource[0].diffuse.xyz * NdotL * color_tex.xyz;
    
    NdotL = (dot(normal,normalize(light2_pos))+1.0)/2.0*(0.8+shadowed*0.2);
    color += gl_LightSource[1].diffuse.xyz * NdotL * color_tex.xyz;

    color *= gl_Color.xyz;

    gl_FragColor = vec4(color,color_tex.a*gl_Color.a);
}