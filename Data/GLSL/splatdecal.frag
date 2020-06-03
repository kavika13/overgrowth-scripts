uniform sampler2D tex0;
uniform sampler2D tex1;
uniform samplerCube tex2;
uniform samplerCube tex3;

varying mat3 tangent_to_world;
varying vec3 vertex_pos;
varying vec3 light_pos;

void main()
{    
    vec3 color;
    
    vec4 normalmap = texture2D(tex1,gl_TexCoord[0].xy);
    vec3 normal = normalize(vec3((normalmap.x-0.5)*2.0, (normalmap.y-0.5)*-2.0, normalmap.z));

    float NdotL = max(0.0,dot(light_pos, normal));
    vec3 diffuse_color = vec3(NdotL * 0.5);
    
    vec3 diffuse_map_vec = normal;
    diffuse_map_vec = tangent_to_world * diffuse_map_vec;
    diffuse_map_vec.y *= -1.0;
    diffuse_color += textureCube(tex3,diffuse_map_vec).xyz * 0.5;
    
    vec3 H = normalize(normalize(vertex_pos*-1.0) + normalize(light_pos));
    float spec = min(1.0, pow(max(0.0,dot(normal,H)),800.0)*10.0 * NdotL) ;
    vec3 spec_color = vec3(spec);
    
    vec3 spec_map_vec = reflect(vertex_pos,normal);
    spec_map_vec = tangent_to_world * spec_map_vec;
    spec_map_vec.y *= -1.0;
    spec_color += textureCube(tex2,spec_map_vec).xyz * 0.1;
    
    vec4 colormap = texture2D(tex0,gl_TexCoord[0].xy);
    
    float fresnel = 1.0;// - dot(normalize(vertex_pos), vec3(0,0,-1))*0.8;
    color = diffuse_color * colormap.xyz + spec_color * fresnel;
    
    //color = colormap.xyz;
    
    gl_FragColor = vec4(color,colormap.a);
}