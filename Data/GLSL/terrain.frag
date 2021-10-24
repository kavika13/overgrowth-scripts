#version 150

#include "object_shared150.glsl"
#include "object_frag150.glsl"
#include "ambient_tet_mesh.glsl"
#include "decals.glsl"

uniform sampler2D tex14;
UNIFORM_COMMON_TEXTURES
UNIFORM_DETAIL4_TEXTURES
UNIFORM_AVG_COLOR4
UNIFORM_LIGHT_DIR
UNIFORM_EXTRA_AO
uniform usamplerBuffer tex31;
uniform int num_light_probes;
uniform int num_tetrahedra;
#define warp_tex tex14

in vec3 ws_vertex;
in vec3 frag_tangent;
in float alpha;
in vec4 frag_tex_coords;
in vec4 shadow_coords[4];
in vec3 world_vert;

out vec4 out_color;

void main() {     
    vec3 ambient_cube_color[6];
    bool use_amb_cube = GetAmbientCube(world_vert, num_light_probes, tex31, ambient_cube_color, 0u);

    vec2 tc0 = frag_tex_coords.xy;
    vec2 tc1 = frag_tex_coords.zw;   
    vec2 test_offset = (texture(warp_tex,tc0*200.0).xy-0.5)*0.001;
    
    vec4 weight_map = GetWeightMap(weight_tex,tc0+test_offset);

    CALC_DETAIL_FADE

    // Get normal
    vec3 base_normalmap = texture(normal_tex,tc0).xyz;
    vec3 base_normal = normalize((base_normalmap*vec3(2.0))-vec3(1.0));
    vec3 base_bitangent = normalize(cross(frag_tangent,base_normal));
    vec3 base_tangent = normalize(cross(base_normal,base_bitangent));

    mat3 ws_from_ns = mat3(base_tangent,
                           base_bitangent,
                           base_normal);

    vec4 normalmap = (texture(tex7 ,tc1) * weight_map[0] +
                      texture(tex9 ,tc1) * weight_map[1] +
                      texture(tex11,tc1) * weight_map[2] +
                      texture(tex13,tc1) * weight_map[3]);
    normalmap.xyz = UnpackTanNormal(normalmap);
    normalmap.xyz = mix(normalmap.xyz,vec3(0.0,0.0,1.0),detail_fade);
    
    vec3 ws_normal = ws_from_ns * normalmap.xyz;

    #define shadow_tex_coords tc0
    CALC_SHADOWED

    CALC_DIRECT_DIFFUSE_COLOR
    if(!use_amb_cube){
        diffuse_color += LookupCubemapSimpleLod(ws_normal, spec_cubemap, 5.0) *
                         GetAmbientContrib(shadow_tex.g);
    } else {
        diffuse_color += SampleAmbientCube(ambient_cube_color, ws_normal) *
                         GetAmbientContrib(shadow_tex.g);
    }

    vec3 spec_color = vec3(0.0);
    if(!use_amb_cube){
        CALC_SPECULAR_LIGHTING(1.0)
    } else {
        vec3 ambient_spec;
        {
            float amb_mult = 1.0;
            vec3 H = normalize(normalize(ws_vertex*-1.0) + normalize(ws_light));
            float spec = GetSpecContrib(ws_light, ws_normal, ws_vertex, shadow_tex.r);
            spec_color = primary_light_color.xyz * vec3(spec);
            vec3 spec_map_vec = reflect(ws_vertex,ws_normal);
            spec_color += SampleAmbientCube(ambient_cube_color, spec_map_vec) * amb_mult;
        }
    }
    
    // Get tint
    vec3 average_color = avg_color0 * weight_map[0] +
                         avg_color1 * weight_map[1] +
                         avg_color2 * weight_map[2] +
                         avg_color3 * weight_map[3];
    vec3 terrain_color = texture(color_tex,tc0+test_offset).xyz;
    average_color = max(average_color, vec3(0.01));
    vec3 tint = terrain_color / average_color;

    // Get colormap
    vec4 colormap = texture(tex6,tc1) * weight_map[0] +
                    texture(tex8,tc1) * weight_map[1] +
                    texture(tex10,tc1) * weight_map[2] +
                    texture(tex12,tc1) * weight_map[3];
    colormap.xyz = mix(colormap.xyz,average_color,detail_fade) * tint;
    colormap.a = max(0.0,colormap.a);

	CalculateDecals(colormap, ws_normal, world_vert);

    // Put it all together
    CALC_COMBINED_COLOR
    CALC_COLOR_ADJUST
    CALC_HAZE
    CALC_FINAL_UNIVERSAL(alpha)
}
