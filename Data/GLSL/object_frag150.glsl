void object_frag(){} // This is just here to make sure it gets added to include paths


layout (std140) uniform ClusterInfo {
    uvec3 grid_size;
    uint num_decals;
    uint num_lights;
    uint light_cluster_data_offset;
    uint light_data_offset;
    uint pad2;
    mat4 inv_proj_mat;
    vec4 viewport;
    float z_near;
    float z_mult;
    float pad3;
    float pad4;
};


// this MUST match the one in source or bad things happen
struct PointLightData {
	vec3 pos;
	float radius;
	vec3 color;
	float padding;
};

#define POINT_LIGHT_SIZE_VEC4 2u


#define NUM_GRID_COMPONENTS 2u
#define ZCLUSTERFUNC(val) (log(-1.0 * (val) - z_near + 1.0) * z_mult)


#define light_decal_data_buffer tex15
#define cluster_buffer tex13


uniform samplerBuffer light_decal_data_buffer;
uniform usamplerBuffer cluster_buffer;


PointLightData FetchPointLight(uint light_index) {
	PointLightData l;

	vec4 temp = texelFetch(light_decal_data_buffer, int(light_data_offset + POINT_LIGHT_SIZE_VEC4 * light_index + 0u));
	l.pos = temp.xyz;
	l.radius = temp.w;

	temp = texelFetch(light_decal_data_buffer, int(light_data_offset + POINT_LIGHT_SIZE_VEC4 * light_index + 1u));
	l.color = temp.xyz;
	l.padding = temp.w;

	return l;
}


void CalculateLightContrib(inout vec3 out_color, vec3 world_vert, vec3 ws_normal) {
	uint num_lights_ = uint(num_lights);

	uint num_z_clusters = grid_size.z;

	vec4 ndcPos;
	ndcPos.xy = ((2.0 * gl_FragCoord.xy) - (2.0 * viewport.xy)) / (viewport.zw) - 1;
	ndcPos.z = 2.0 * gl_FragCoord.z - 1; // this assumes gl_DepthRange is not changed
	ndcPos.w = 1.0;

	vec4 clipPos = ndcPos / gl_FragCoord.w;
	vec4 eyePos = inv_proj_mat * clipPos;

	float zVal = ZCLUSTERFUNC(eyePos.z);

	zVal = max(0u, min(zVal, num_z_clusters - 1u));

	uvec3 g = uvec3(gl_FragCoord.xy / 32.0, zVal);

	// index of cluster we're in
	uint light_cluster_index = NUM_GRID_COMPONENTS * ((g.y * grid_size.x + g.x) * num_z_clusters + g.z) + 1u;
	uint val = texelFetch(cluster_buffer, int(light_cluster_index)).x;

	// number of lights in current cluster
	uint light_count = (val >> 16) & 0xFFFFU;

	// index into cluster_lights
	uint first_light_index = val & 0xFFFFU;

	// light list data is immediately after cluster lookup data
	uint num_clusters = grid_size.x * grid_size.y * grid_size.z;
	first_light_index = first_light_index + uint(light_cluster_data_offset);

	// debug option, uncomment to visualize clusters
	//out_color = vec3(min(light_count, 63u) / 63.0);
	//out_color = vec3(g.z / num_z_clusters);

	for (uint i = 0u; i < light_count; i++) {
		uint light_index = texelFetch(cluster_buffer, int(first_light_index + i)).x;

		PointLightData l = FetchPointLight(light_index);

		vec3 to_light = l.pos - world_vert;
		// TODO: inverse square falloff
		// TODO: real light equation
		float dist = length(to_light);
		float falloff = max(0.0, (1.0 / dist / dist) * (1.0 - dist / l.radius));

		vec3 n = normalize(to_light);
		float d = max(0.0, dot(to_light, ws_normal));

		out_color += falloff * d * l.color;
	}
}


#include "lighting150.glsl"
#include "relativeskypos.glsl"

#ifndef ARB_sample_shading_available
#define CALC_MOTION_BLUR \
    if(stipple_val != 1 && \
       (int(mod(gl_FragCoord.x + float(x_stipple_offset),float(stipple_val))) != 0 ||  \
        int(mod(gl_FragCoord.y + float(y_stipple_offset),float(stipple_val))) != 0)){  \
        discard;  \
    }
#else
#define CALC_MOTION_BLUR \
    if(stipple_val != 1 && \
       (int(mod(gl_FragCoord.x + mod(float(gl_SampleID), float(stipple_val)) + float(x_stipple_offset),float(stipple_val))) != 0 || \
        int(mod(gl_FragCoord.y + float(gl_SampleID) / float(stipple_val) + float(y_stipple_offset),float(stipple_val))) != 0)){ \
        discard; \
    }
#endif

#define CALC_HALFTONE_STIPPLE \
if(mod(gl_FragCoord.x + gl_FragCoord.y, 2.0) == 0.0){ \
    discard; \
}

#define UNIFORM_SHADOW_TEXTURE \
    uniform sampler2DShadow shadow_sampler;
#define CALC_SHADOWED \
    vec3 shadow_tex = vec3(1.0);\
    shadow_tex.r = GetCascadeShadow(tex4, shadow_coords, length(ws_vertex));
#define CALC_DYNAMIC_SHADOWED CALC_SHADOWED

#define color_tex tex0
#define normal_tex tex1
#define spec_cubemap tex2
#define shadow_sampler tex4
#define projected_shadow_sampler tex5
#define translucency_tex tex5
#define blood_tex tex6
#define fur_tex tex7
#define tint_map tex8
#define ambient_grid_data tex11
#define ambient_color_buffer tex12

#define UNIFORM_COMMON_TEXTURES \
uniform sampler2D color_tex; \
uniform sampler2D normal_tex; \
uniform samplerCube spec_cubemap; \
UNIFORM_SHADOW_TEXTURE

#define weight_tex tex5
#define detail_color tex6
#define detail_normal tex7

#define UNIFORM_DETAIL4_TEXTURES \
uniform sampler2D weight_tex; \
uniform sampler2DArray detail_color; \
uniform vec4 detail_color_indices; \
uniform sampler2DArray detail_normal; \
uniform vec4 detail_normal_indices; \

#define UNIFORM_AVG_COLOR4 \
uniform vec3 avg_color0; \
uniform vec3 avg_color1; \
uniform vec3 avg_color2; \
uniform vec3 avg_color3;

#define CALC_BLOOD_AMOUNT \
float blood_amount, wetblood; \
ReadBloodTex(blood_tex, tc0, blood_amount, wetblood);

#define UNIFORM_BLOOD_TEXTURE \
uniform sampler2D blood_tex; \
uniform vec3 blood_tint;

#define UNIFORM_FUR_TEXTURE \
uniform sampler2D fur_tex;

#define UNIFORM_TINT_TEXTURE \
uniform sampler2D tint_map;

#define UNIFORM_TRANSLUCENCY_TEXTURE \
uniform sampler2D translucency_tex;

#define UNIFORM_PROJECTED_SHADOW_TEXTURE \
uniform sampler2DShadow projected_shadow_sampler;

#define UNIFORM_EXTRA_AO \
uniform float extra_ao;

#define UNIFORM_STIPPLE_FADE \
uniform float fade;

#define UNIFORM_STIPPLE_BLUR \
uniform int x_stipple_offset; \
uniform int y_stipple_offset; \
uniform int stipple_val;

#ifndef SHADOW_CATCHER
#define UNIFORM_SIMPLE_SHADOW_CATCH uniform float in_light;
#else
#define UNIFORM_SIMPLE_SHADOW_CATCH
#endif

#define UNIFORM_COLOR_TINT \
uniform vec3 color_tint;

#define UNIFORM_TINT_PALETTE \
uniform vec3 tint_palette[5];

#define CALC_BLOODY_WEAPON_SPEC \
float spec = GetSpecContrib(ws_light, ws_normal, ws_vertex, shadow_tex.r,mix(100.0,50.0,(1.0-wetblood)*blood_amount)); \
spec *= 5.0; \
vec3 spec_color = primary_light_color.xyz * vec3(spec) * mix(1.0,0.3,blood_amount); \
vec3 spec_map_vec = reflect(ws_vertex,ws_normal); \
spec_color += LookupCubemapSimpleLod(spec_map_vec, tex2, 0.0) * 0.5 * \
              GetAmbientContrib(shadow_tex.g) * max(0.0,(1.0 - blood_amount * 2.0));

#define CALC_BLOODY_CHARACTER_SPEC \
float spec = GetSpecContrib(ws_light, ws_normal, ws_vertex, shadow_tex.r,mix(200.0,50.0,(1.0-wetblood)*blood_amount)); \
spec *= 5.0; \
vec3 spec_color = primary_light_color.xyz * vec3(spec) * 0.3; \
vec3 spec_map_vec = reflect(ws_vertex, ws_normal); \
spec_color += LookupCubemapSimpleLod(spec_map_vec, tex2, 0.0) * 0.2 * \
    GetAmbientContrib(shadow_tex.g) * max(0.0,(1.0 - blood_amount * 2.0));

#define CALC_STIPPLE_FADE \
if((rand(gl_FragCoord.xy)) < fade){\
    discard;\
};\

#define CALC_OBJ_NORMAL \
vec4 normalmap = texture(tex1,tc0); \
vec3 os_normal = UnpackObjNormal(normalmap); \
vec3 ws_normal = model_rotation_mat * os_normal; \
ws_normal = normalize(ws_normal);

#define CALC_DIRECT_DIFFUSE_COLOR \
float NdotL = GetDirectContrib(ws_light, ws_normal,shadow_tex.r);\
vec3 diffuse_color = GetDirectColor(NdotL);\
CalculateLightContrib(diffuse_color, world_vert, ws_normal);

#define CALC_DIFFUSE_LIGHTING \
CALC_DIRECT_DIFFUSE_COLOR \
diffuse_color += LookupCubemapSimpleLod(ws_normal, spec_cubemap, 5.0) *\
                 GetAmbientContrib(shadow_tex.g);

#define CALC_DIFFUSE_TRANSLUCENT_LIGHTING \
CALC_DIRECT_DIFFUSE_COLOR \
vec3 ambient = LookupCubemapSimpleLod(ws_normal, tex2, 5.0) * GetAmbientContrib(shadow_tex.g); \
diffuse_color += ambient; \
vec3 translucent_lighting = GetDirectColor(shadow_tex.r) * primary_light_color.a; \
translucent_lighting += ambient; \
translucent_lighting *= GammaCorrectFloat(0.6);

#define CALC_DETAIL_FADE \
float detail_fade_distance = 200.0; \
float detail_fade = min(1.0,max(0.0,length(ws_vertex)/detail_fade_distance));

#define CALC_SPECULAR_LIGHTING(amb_mult) \
vec3 spec_color;\
{\
    vec3 H = normalize(normalize(ws_vertex*-1.0) + normalize(ws_light));\
    float spec = GetSpecContrib(ws_light, ws_normal, ws_vertex, shadow_tex.r);\
    spec_color = primary_light_color.xyz * vec3(spec);\
    vec3 spec_map_vec = reflect(ws_vertex,ws_normal);\
    spec_color += LookupCubemapSimple(spec_map_vec, spec_cubemap) * amb_mult *\
                  GetAmbientContrib(shadow_tex.g);\
}

#define CALC_DISTANCE_ADJUSTED_ALPHA \
colormap.a = pow(colormap.a, max(0.1,min(1.0,4.0/length(ws_vertex))));

#define CALC_COLOR_MAP \
vec4 colormap = texture(color_tex, frag_tex_coords);

#define CALC_MORPHED_COLOR_MAP \
vec4 colormap = texture(color_tex,gl_TexCoord[0].zw);

#define CALC_BLOOD_ON_COLOR_MAP \
ApplyBloodToColorMap(colormap, blood_amount, wetblood, blood_tint);

#define CALC_RIM_HIGHLIGHT \
vec3 view = normalize(ws_vertex*-1.0); \
float back_lit = max(0.0,dot(normalize(ws_vertex),ws_light));  \
float rim_lit = max(0.0,(1.0-dot(view,ws_normal))); \
rim_lit *= pow((dot(ws_light,ws_normal)+1.0)*0.5,0.5); \
color += vec3(back_lit*rim_lit) * (1.0 - blood_amount) * GammaCorrectFloat(normalmap.a) * primary_light_color.xyz * primary_light_color.a * shadow_tex.r;
    
#define CALC_COMBINED_COLOR_WITH_NORMALMAP_TINT \
vec3 color = diffuse_color * colormap.xyz  * mix(vec3(1.0),color_tint,normalmap.a)+ \
             spec_color * GammaCorrectFloat(colormap.a);

#define CALC_COMBINED_COLOR_WITH_TINT \
vec3 color = diffuse_color * colormap.xyz * color_tint + spec_color * GammaCorrectFloat(normalmap.a);

#define CALC_COMBINED_COLOR \
vec3 color = diffuse_color * colormap.xyz + \
             spec_color * GammaCorrectFloat(colormap.a);

#define CALC_COLOR_ADJUST \
color *= BalanceAmbient(NdotL); \
color *= vec3(min(1.0,shadow_tex.g*2.0)*extra_ao + (1.0-extra_ao));

#define CALC_HAZE \
AddHaze(color, ws_vertex, spec_cubemap);

#define CALC_FINAL_UNIVERSAL(alpha) \
out_color = vec4(color,alpha);

#define CALC_FINAL \
CALC_FINAL_UNIVERSAL(1.0)

#define CALC_FINAL_ALPHA \
CALC_FINAL_UNIVERSAL(colormap.a)

vec4 GetWeightMap(sampler2D tex, vec2 coord){
    vec4 weight_map = texture(tex, coord);
    weight_map[3] = max(0.0, 1.0 - (weight_map[0]+weight_map[1]+weight_map[2]));
    return weight_map;
}