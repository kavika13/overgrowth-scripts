#version 150

#pragma transparent
uniform vec3 light_pos;

uniform sampler2D tex0;

uniform mat4 obj2world;

const float texture_offset = 0.001;

void main()
{    
    mat3 obj2world3 = mat3(obj2world[0].xyz, obj2world[1].xyz, obj2world[2].xyz);
    
    vec3 normalmap = texture2D(tex0,gl_TexCoord[1].xy).rgb;
    
    vec3 normal = normalize(vec3((normalmap.x-0.5)*2.0, (normalmap.z-0.5)*2.0, (normalmap.y-0.5)*-2.0));

    normal = normalize(mat3(obj2world[0].xyz, obj2world[1].xyz, obj2world[2].xyz) * normal);

    gl_FragColor = vec4((normal+vec3(1.0))*0.5,1.0);
}
