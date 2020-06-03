#version 150

uniform samplerCube tex1;
uniform vec3 cam_pos;

in vec3 world_vert;
in vec3 normal;
out vec4 out_color;

void main()
{    
    if(int(gl_FragCoord.x + gl_FragCoord.y)%2==0){
        discard;
    }
    //vec3 total = SampleAmbientCube(acc, normalize(vert));
    vec3 ws_normal = normalize(normal);
    vec3 spec_map_vec = reflect(world_vert - cam_pos, ws_normal);
    vec3 spec = textureLod(tex1, ws_normal, 0.0).xyz;
    vec3 diffuse = textureLod(tex1, ws_normal, 5.0).xyz;
    float fresnel = dot(normalize(world_vert - cam_pos), ws_normal);
    out_color.xyz = spec;//mix(diffuse, spec, 1.0 + fresnel);
    out_color.a = 1.0;
}