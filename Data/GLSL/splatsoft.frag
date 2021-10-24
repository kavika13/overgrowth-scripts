#version 150

uniform sampler2D tex0;
uniform sampler2D tex1;
uniform samplerCube tex3;
uniform sampler2D tex5;
uniform float size;
uniform float shadowed;
uniform vec3 ws_light;
uniform vec3 cam_pos;
uniform vec2 viewport_dims;
uniform vec4 color_tint;

in vec3 ws_vertex;
in vec2 tex_coord;
in vec3 tangent_to_world1;
in vec3 tangent_to_world2;
in vec3 tangent_to_world3;

out vec4 out_color;

#include "object_shared150.glsl"
#include "object_frag150.glsl"

float LinearizeDepth(float z)
{
  float n = 0.1; // camera z near
  float f = 1000.0; // camera z far
  float depth = (2.0 * n) / (f + n - z * (f - n));
  return (f-n)*depth + n;
}

void main() {        
    vec4 colormap = texture(tex0, tex_coord);
    vec4 normalmap = texture(tex1, tex_coord);
    
    vec3 ws_normal = vec3(tangent_to_world3 * normalmap.b +
                          tangent_to_world1 * (normalmap.r*2.0-1.0) +
                          tangent_to_world2 * (normalmap.g*2.0-1.0));
    
    ws_normal = normalize(ws_normal);

    float NdotL = GetDirectContribSoft(ws_light, ws_normal, (1.0-shadowed));
    vec3 diffuse_color = GetDirectColor(NdotL);
    diffuse_color += LookupCubemapSimpleLod(ws_normal, tex3, 5.0) * GetAmbientContrib(1.0);
    vec3 color = diffuse_color * colormap.xyz * color_tint.xyz;
    
    vec3 blood_spec = vec3(GetSpecContrib(ws_light, ws_normal, ws_vertex, 1.0, 200.0)) * (1.0-shadowed);
    color += blood_spec;

    color *= BalanceAmbient(NdotL);

    float env_depth = LinearizeDepth(texture(tex5,gl_FragCoord.xy / viewport_dims).r);
    float particle_depth = LinearizeDepth(gl_FragCoord.z);
    float depth = env_depth - particle_depth;
    float depth_blend = depth / size * 1.0;
    depth_blend = max(0.0,min(1.0,depth_blend));
    depth_blend *= max(0.0,min(1.0, particle_depth*0.5-0.1));
    
    float alpha = min(1.0,pow(colormap.a*color_tint.a*depth_blend,5.0)*20.0);

    out_color = vec4(color,alpha);
}