uniform sampler2D tex0;
uniform sampler2D tex1;
uniform sampler2DShadow tex2;

varying vec4 ProjShadow;
varying vec3 normal;
varying vec3 tangent;
varying vec3 bitangent;

void main()
{    
    float NdotL;
    vec3 color;
    
    vec4 normalmap;
    vec3 map_normal;
    vec4 color_tex;
    float spec;
    
    color_tex = texture2D(tex0,gl_TexCoord[0].xy);
    normalmap = texture2D(tex1,gl_TexCoord[0].xy);
    map_normal = normalize((vec3(normalmap.x, normalmap.z, normalmap.y)*2.0-1.0));
    
    vec3 object_normal;
    object_normal.x = tangent.x*map_normal.x+bitangent.x*normalmap.y+normal.x*normalmap.z;
    object_normal.y = tangent.y*map_normal.x+bitangent.y*normalmap.y+normal.y*normalmap.z;
    object_normal.z = tangent.z*map_normal.x+bitangent.z*normalmap.y+normal.z*normalmap.z;
    
    object_normal=normalize(object_normal);
    object_normal.x = object_normal.x*0.5+0.5;
    object_normal.y = object_normal.y*0.5+0.5;
    object_normal.z = object_normal.z*0.5+0.5;

    color = object_normal;

    gl_FragColor = vec4(color,1.0);
}