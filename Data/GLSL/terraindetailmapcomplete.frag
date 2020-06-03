#include "object_shared.glsl"
#include "object_frag.glsl"

#define warp_tex tex14
uniform sampler2D tex14;
UNIFORM_COMMON_TEXTURES
UNIFORM_DETAIL4_TEXTURES

UNIFORM_AVG_COLOR4
UNIFORM_LIGHT_DIR
UNIFORM_EXTRA_AO

VARYING_REL_POS
varying vec3 tangent;
varying float alpha;

#ifndef BAKED_SHADOWS
    varying vec4 shadow_coords[4];
#endif

void main()
{        

    vec2 test_offset = (texture2D(warp_tex,tc0*200.0).xy-0.5)*0.001;
    
    vec4 weight_map = GetWeightMap(weight_tex,tc0+test_offset);

    CALC_DETAIL_FADE

    // Get normal
    vec3 base_normalmap = texture2D(normal_tex,tc0).xyz;
    vec3 base_normal = normalize((base_normalmap*vec3(2.0))-vec3(1.0));
    vec3 base_bitangent = normalize(cross(tangent,base_normal));
    vec3 base_tangent = normalize(cross(base_normal,base_bitangent));

    mat3 ws_from_ns = mat3(base_tangent,
                           base_bitangent,
                           base_normal);

    vec4 normalmap = (texture2D(tex7 ,tc1) * weight_map[0] +
                      texture2D(tex9 ,tc1) * weight_map[1] +
                      texture2D(tex11,tc1) * weight_map[2] +
                      texture2D(tex13,tc1) * weight_map[3]);
    normalmap.xyz = UnpackTanNormal(normalmap);
    normalmap.xyz = mix(normalmap.xyz,vec3(0.0,0.0,1.0),detail_fade);
    
    vec3 ws_normal = ws_from_ns * normalmap.xyz;

    #define shadow_tex_coords tc0
    CALC_SHADOWED
    CALC_DIFFUSE_LIGHTING
    CALC_SPECULAR_LIGHTING(1.0)
    
    // Get tint
    vec3 average_color = avg_color0 * weight_map[0] +
                         avg_color1 * weight_map[1] +
                         avg_color2 * weight_map[2] +
                         avg_color3 * weight_map[3];
    vec3 terrain_color = texture2D(color_tex,tc0+test_offset).xyz;
    average_color = max(average_color, vec3(0.01));
    vec3 tint = terrain_color / average_color;

    // Get colormap
    vec4 colormap = texture2D(tex6,tc1) * weight_map[0] +
                    texture2D(tex8,tc1) * weight_map[1] +
                    texture2D(tex10,tc1) * weight_map[2] +
                    texture2D(tex12,tc1) * weight_map[3];
    colormap.xyz = mix(colormap.xyz,average_color,detail_fade) * tint;
    colormap.a = max(0.0,colormap.a);

    // Put it all together
    CALC_COMBINED_COLOR
    CALC_COLOR_ADJUST
    CALC_HAZE
    CALC_EXPOSURE
    CALC_FINAL_UNIVERSAL(alpha)
}
