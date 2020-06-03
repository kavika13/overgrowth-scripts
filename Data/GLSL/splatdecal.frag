uniform sampler2D tex0;
uniform sampler2D tex1;
uniform samplerCube tex2;
uniform samplerCube tex3;
uniform sampler2D tex4;
uniform float wetness;

varying mat3 tangent_to_world;
varying vec3 vertex_pos;
varying vec3 light_pos;
varying vec3 ws_vertex;

#include "lighting.glsl"
#include "relativeskypos.glsl"

void main()
{    
    vec3 color;
    
    if(gl_TexCoord[0].x<0.0 || gl_TexCoord[0].x>1.0 ||
        gl_TexCoord[0].y<0.0 || gl_TexCoord[0].y>1.0 ||
        gl_TexCoord[0].z<-1.0 || gl_TexCoord[0].z>1.0) {
        discard;
    }
    

    float shadowed = texture2D(tex4,gl_TexCoord[1].xy).x;
    vec4 normalmap = texture2D(tex1,gl_TexCoord[0].xy);
    vec3 normal = normalize(vec3((normalmap.x-0.5)*2.0, (normalmap.y-0.5)*-2.0, normalmap.z));

    float NdotL = max(0.0,dot(light_pos, normal))*shadowed;
    vec3 diffuse_color = vec3(NdotL * 0.5);
    
    vec3 diffuse_map_vec = normal;
    diffuse_map_vec = tangent_to_world * diffuse_map_vec;
    diffuse_map_vec.y *= -1.0;
    diffuse_color += textureCube(tex3,diffuse_map_vec).xyz * 0.5;
    
    vec3 H = normalize(normalize(vertex_pos*-1.0) + normalize(light_pos));
    float spec = min(1.0, pow(max(0.0,dot(normal,H)),850.0)*pow(20.0,wetness)*0.5 * NdotL) ;
    vec3 spec_color = vec3(spec);
    
    vec3 spec_map_vec = reflect(vertex_pos,normal);
    spec_map_vec = tangent_to_world * spec_map_vec;
    spec_map_vec.y *= -1.0;
    spec_color += textureCube(tex2,spec_map_vec).xyz * 0.01;
    
    vec4 colormap = texture2D(tex0,gl_TexCoord[0].xy);
    colormap.xyz *= (wetness*0.5+0.75);
    
    float fresnel = 1.0;// - dot(normalize(vertex_pos), vec3(0,0,-1))*0.8;
    color = diffuse_color * colormap.xyz + spec_color * fresnel;
    
    AddHaze(color, TransformRelPosForSky(ws_vertex), tex3);

    //    colormap.a = 1.0;
    //color = colormap.xyz;

    gl_FragColor = vec4(color,colormap.a);
}