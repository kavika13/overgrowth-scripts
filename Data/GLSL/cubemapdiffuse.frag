#version 150
#extension GL_ARB_shading_language_420pack : enable

#include "object_shared150.glsl"
#include "object_frag150.glsl"
#include "lighting150.glsl"

uniform samplerCube spec_cubemap;
uniform vec4 emission;
uniform vec3 cam_pos;
uniform vec3 ws_light;
uniform vec3 color_tint;

in vec3 ws_vertex;
in vec4 shadow_coords[4];
in vec3 normal;

#pragma bind_out_color
out vec4 out_color;

void main()
{    
    float NdotL = GetDirectContrib(ws_light, normal, 1.0);
    vec3 color = GetDirectColor(NdotL);

    color += textureLod(spec_cubemap, normal, 5.0).xyz * GetAmbientContrib(1.0);
    
    color *= BalanceAmbient(NdotL);
    color *= color_tint;
    color += emission.xyz;

    CALC_HAZE
    CALC_FINAL
}
