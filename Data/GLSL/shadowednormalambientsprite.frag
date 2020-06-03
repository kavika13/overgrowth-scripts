uniform sampler2D tex0;
uniform sampler2D tex1;
uniform sampler2DShadow tex2;

varying vec3 light_pos;
varying vec3 light2_pos;
varying vec3 vertex_pos;
varying vec4 ProjShadow;
varying vec4 ProjShadow2;
varying vec4 ProjShadow3;
varying vec4 ProjShadow4;
varying vec4 ProjShadow5;
varying vec4 ProjShadow6;

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
    
    float offset = 1.0/4096.0/2.0*4.0;
    float frac = 1.0/6.0;
    float shadowed = shadow2DProj(tex2, ProjShadow).r*frac;
    shadowed += shadow2DProj(tex2, ProjShadow2).r*frac;
    shadowed += shadow2DProj(tex2, ProjShadow3).r*frac;
    shadowed += shadow2DProj(tex2, ProjShadow4).r*frac;
    shadowed += shadow2DProj(tex2, ProjShadow5).r*frac;
    shadowed += shadow2DProj(tex2, ProjShadow6).r*frac;
    
    
    NdotL = (dot(normal*-1.0,normalize(light_pos))+1.0)/2.0*shadowed;
    
    color_tex = texture2D(tex0,gl_TexCoord[0].xy);
    
    color = gl_LightSource[0].diffuse.xyz * NdotL * color_tex.xyz;
    
    NdotL = (dot(normal*-1.0,normalize(light2_pos))+1.0)/2.0*shadowed;
    color += gl_LightSource[1].diffuse.xyz * NdotL * color_tex.xyz;

    color *= gl_Color.xyz;

    gl_FragColor = vec4(color,color_tex.a*gl_Color.a);
}