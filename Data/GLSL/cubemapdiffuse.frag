#extension GL_ARB_shader_texture_lod : require

#include "object_shared.glsl"
#include "object_frag.glsl"

uniform samplerCube spec_cubemap;
uniform vec4 emission;
uniform vec3 cam_pos;

varying vec3 normal;
varying vec3 world_normal;
VARYING_REL_POS

#include "lighting.glsl"

void main()
{    
    float NdotL = GetDirectContrib(gl_LightSource[0].position.xyz, normal, 1.0);
    vec3 color = GetDirectColor(NdotL);

    color += textureCubeLod(spec_cubemap,world_normal,5.0).xyz * GetAmbientContrib(1.0);
    
    color *= BalanceAmbient(NdotL);
    color *= gl_Color.xyz;
    color += emission.xyz;

    CALC_HAZE
    CALC_EXPOSURE
    CALC_FINAL
}