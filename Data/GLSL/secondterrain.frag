#version 150

uniform vec3 light_pos;
uniform sampler2D tex0; // diffuse color
uniform samplerCube tex3; // skybox
uniform sampler2D tex4; // normal map

in vec2 var_uv;

out vec4 out_color;

const float texture_offset = 0.001;
const float border_fade_size = 0.1;

#include "lighting150.glsl"

void main()
{    
    // Get lighting
    vec4 normal_map = texture(tex4, var_uv + light_pos.xz * texture_offset);
    vec3 normal_vec = normalize((normal_map.xyz*vec3(2.0))-vec3(1.0));
    float NdotL = GetDirectContrib(light_pos, normal_vec, 1.0);
    vec3 color = GetDirectColor(NdotL) + LookupCubemapSimpleLod(normal_vec, tex3, 5.0) * GetAmbientContrib(1.0);

    // Combine diffuse lighting with color
    color *= texture(tex0,var_uv).xyz;    
    color *= BalanceAmbient(NdotL);

    // Fade borders
    float alpha = 1.0;
    if(var_uv.x<border_fade_size) {
        alpha *= var_uv.x/border_fade_size;
    }
    if(var_uv.x>1.0-border_fade_size) {
        alpha *= (1.0-var_uv.x)/border_fade_size;
    }
    if(var_uv.y<border_fade_size) {
        alpha *= var_uv.y/border_fade_size;
    }
    if(var_uv.y>1.0-border_fade_size) {
        alpha *= (1.0-var_uv.y)/border_fade_size;
    }
        
    out_color = vec4(color,alpha);
}