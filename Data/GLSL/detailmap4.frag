#include "object_shared.glsl"
#include "object_frag.glsl"

UNIFORM_DETAIL4_TEXTURES
UNIFORM_COMMON_TEXTURES

UNIFORM_LIGHT_DIR
UNIFORM_EXTRA_AO
UNIFORM_COLOR_TINT
UNIFORM_AVG_COLOR4
uniform vec4 detail_scale;

VARYING_REL_POS
VARYING_SHADOW
varying vec3 tangent;
varying vec3 bitangent;

void main()
{        
    vec4 weight_map = GetWeightMap(weight_tex, tc0);
    float total = weight_map[0] + weight_map[1] + weight_map[2] + weight_map[3];
    weight_map /= total;
    CALC_DETAIL_FADE

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

    vec3 ws_normal;
    {
        vec4 normalmap = (texture2D(detail_normal_0,tc0*detail_scale[0]) * weight_map[0] +
                          texture2D(detail_normal_1,tc0*detail_scale[1]) * weight_map[1] +
                          texture2D(detail_normal_2,tc0*detail_scale[2]) * weight_map[2] +
                          texture2D(detail_normal_3,tc0*detail_scale[3]) * weight_map[3]);
        normalmap.xyz = UnpackTanNormal(normalmap);
        normalmap.xyz = mix(normalmap.xyz,vec3(0.0,0.0,1.0),detail_fade);

        ws_normal = normalize(normalMatrix * ws_from_ns * normalmap.xyz);
    }

    // Get color
    vec3 base_color = texture2D(color_tex,tc0).xyz;
    vec3 tint;
    {
        vec3 average_color = avg_color0 * weight_map[0] +
                             avg_color1 * weight_map[1] +
                             avg_color2 * weight_map[2] +
                             avg_color3 * weight_map[3];
        average_color = max(average_color, vec3(0.01));
        tint = base_color / average_color;
    }

    vec4 colormap = texture2D(detail_color_0,tc0*detail_scale[0]) * weight_map[0] +
                    texture2D(detail_color_1,tc0*detail_scale[1]) * weight_map[1] +
                    texture2D(detail_color_2,tc0*detail_scale[2]) * weight_map[2] +
                    texture2D(detail_color_3,tc0*detail_scale[3]) * weight_map[3];
    colormap.xyz = mix(colormap.xyz * tint, base_color, detail_fade);
    colormap.xyz = mix(colormap.xyz,colormap.xyz*color_tint,color_tint_alpha);
    colormap.a = max(0.0,colormap.a); 

    #define shadow_tex_coords tc1
    CALC_SHADOWED
    CALC_DIFFUSE_LIGHTING
    CALC_SPECULAR_LIGHTING(1.0)
    CALC_COMBINED_COLOR
    CALC_COLOR_ADJUST
    CALC_HAZE
    CALC_EXPOSURE
    CALC_FINAL
    //gl_FragColor.xyz = texture2D(shadow_sampler,shadow_tex_coords).rgb;
    //gl_FragColor.xyz = vec3(0.0);
}
