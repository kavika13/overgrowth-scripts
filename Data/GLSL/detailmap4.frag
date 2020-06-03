#define base_color_tex tex0
#define base_normal_tex tex1
#define spec_cubemap tex2
#define diffuse_cubemap tex3
#define shadow_tex tex4
#define weight_tex tex5
#define detail_color_0 tex6
#define detail_normal_0 tex7
#define detail_color_1 tex8
#define detail_normal_1 tex9
#define detail_color_2 tex10
#define detail_normal_2 tex11
#define detail_color_3 tex12
#define detail_normal_3 tex13

uniform sampler2D base_color_tex;
uniform sampler2D base_normal_tex;
uniform samplerCube spec_cubemap;
uniform samplerCube diffuse_cubemap;
#ifdef BAKED_SHADOWS
    uniform sampler2D shadow_tex;
#else
    uniform sampler2DShadow shadow_tex;
#endif
uniform sampler2D weight_tex;
uniform sampler2D detail_color_0;
uniform sampler2D detail_normal_0;
uniform sampler2D detail_color_1;
uniform sampler2D detail_normal_1;
uniform sampler2D detail_color_2;
uniform sampler2D detail_normal_2;
uniform sampler2D detail_color_3;
uniform sampler2D detail_normal_3;

uniform vec3 avg_color0;
uniform vec3 avg_color1;
uniform vec3 avg_color2;
uniform vec3 avg_color3;
uniform vec3 ws_light;
uniform float extra_ao;
uniform float detail_scale;
uniform vec3 color_tint;

varying vec3 tangent;
varying vec3 bitangent;
varying vec3 ws_vertex;
#ifndef BAKED_SHADOWS
    varying vec4 shadow_coords[4];
#endif

#include "lighting.glsl"
#include "texturepack.glsl"
#include "relativeskypos.glsl"
#include "pseudoinstance.glsl"

void main()
{        
    // Get normalized weight map
    vec4 weight_map;
    {
        weight_map = texture2D(weight_tex, tc0);
        weight_map[3] = max(0.0, 1.0 - (weight_map[0]+weight_map[1]+weight_map[2]));
        
        float total = weight_map[0] + weight_map[1] + weight_map[2] + weight_map[3];
        weight_map /= total;
    }

    // Get fade
    const float detail_fade_distance = 200.0;
    float detail_fade = min(1.0,max(0.0,length(ws_vertex)/detail_fade_distance));

    // Get normal
    float color_tint_alpha;
    mat3 ws_from_ns;
    {
        vec4 base_normalmap = texture2D(tex1,tc0);
        color_tint_alpha = base_normalmap.a;

        vec3 base_normal = UnpackObjNormalV3(base_normalmap.xyz);
                
        vec3 base_bitangent = normalize(cross(base_normal,tangent));
        vec3 base_tangent = normalize(cross(base_bitangent,base_normal));
        base_bitangent *= 1.0 - step(dot(base_bitangent, bitangent),0.0) * 2.0;

        ws_from_ns = mat3(base_tangent,
                          base_bitangent,
                          base_normal);
    }

    vec2 tc2 = tc0 * detail_scale;
    vec3 ws_normal;
    {
        vec4 normalmap = (texture2D(detail_normal_0,tc2) * weight_map[0] +
                          texture2D(detail_normal_1,tc2) * weight_map[1] +
                          texture2D(detail_normal_2,tc2) * weight_map[2] +
                          texture2D(detail_normal_3,tc2) * weight_map[3]);
        normalmap.xyz = UnpackTanNormal(normalmap);
        normalmap.xyz = mix(normalmap.xyz,vec3(0.0,0.0,1.0),detail_fade);

        ws_normal = normalize(normalMatrix * ws_from_ns * normalmap.xyz);
    }

    // Get color
    vec3 base_color = texture2D(base_color_tex,tc0).xyz;
    vec3 tint;
    {
        vec3 average_color = avg_color0 * weight_map[0] +
                             avg_color1 * weight_map[1] +
                             avg_color2 * weight_map[2] +
                             avg_color3 * weight_map[3];
        average_color = max(average_color, vec3(0.01));
        tint = base_color / average_color;
    }

    vec4 colormap = texture2D(detail_color_0,tc2) * weight_map[0] +
                    texture2D(detail_color_1,tc2) * weight_map[1] +
                    texture2D(detail_color_2,tc2) * weight_map[2] +
                    texture2D(detail_color_3,tc2) * weight_map[3];
    colormap.xyz = mix(colormap.xyz * tint, base_color, detail_fade);
    colormap.xyz = mix(colormap.xyz,colormap.xyz*color_tint,color_tint_alpha);
    colormap.a = max(0.0,colormap.a); 

    // Get diffuse lighting
#ifdef BAKED_SHADOWS
    vec3 shadow_val = texture2D(shadow_tex,tc1).rgb;
#else
    vec3 shadow_val = vec3(1.0);
    shadow_val.r = GetCascadeShadow(shadow_tex, shadow_coords, length(ws_vertex));
#endif
    float NdotL = GetDirectContrib(ws_light, ws_normal, shadow_val.r);
    vec3 diffuse_color = GetDirectColor(NdotL);
    
    diffuse_color += LookupCubemapSimple(ws_normal, diffuse_cubemap) *
                     GetAmbientContrib(shadow_val.g);
    
    // Get spec lighting
    vec3 spec_color;
    {
        vec3 ws_H = normalize(normalize(ws_vertex*-1.0) + ws_light);
        float spec = min(1.0, pow(max(0.0,dot(ws_normal,ws_H)),10.0) * shadow_val.r);
        spec_color = gl_LightSource[0].diffuse.xyz * vec3(spec);
        
        vec3 spec_map_vec = reflect(ws_vertex,ws_normal);
        spec_color += LookupCubemapSimple(spec_map_vec, spec_cubemap) *
                      GetAmbientContrib(shadow_val.g);
    }   
    
    // Put it all together
    vec3 color = diffuse_color * colormap.xyz + spec_color * GammaCorrectFloat(colormap.a);
    color *= BalanceAmbient(NdotL);
    color *= vec3(min(1.0,shadow_val.g*2.0)*extra_ao + (1.0-extra_ao));
    AddHaze(color, TransformRelPosForSky(ws_vertex), diffuse_cubemap);
    color *= Exposure();

    gl_FragColor = vec4(color,1.0);
}
