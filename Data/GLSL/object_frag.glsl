#include "lighting.glsl"
#include "texturepack.glsl"
#include "relativeskypos.glsl"

#ifdef BAKED_SHADOWS
#define UNIFORM_SHADOW_TEXTURE \
    uniform sampler2D shadow_sampler;
#define CALC_SHADOWED \
    vec3 shadow_tex = texture2D(shadow_sampler,tc1).rgb;
#else
#define UNIFORM_SHADOW_TEXTURE \
    uniform sampler2DShadow shadow_sampler;
#define CALC_SHADOWED \
    vec3 shadow_tex = vec3(1.0);\
    shadow_tex.r = GetCascadeShadow(shadow_sampler, shadow_coords, length(ws_vertex));
#endif

#define color_tex tex0
#define normal_tex tex1
#define spec_cubemap tex2
#define diffuse_cubemap tex3
#define shadow_sampler tex4

#define UNIFORM_COMMON_TEXTURES \
uniform sampler2D color_tex; \
uniform sampler2D normal_tex; \
uniform samplerCube spec_cubemap; \
uniform samplerCube diffuse_cubemap; \
UNIFORM_SHADOW_TEXTURE

#define UNIFORM_LIGHT_DIR \
uniform vec3 ws_light;

#define UNIFORM_EXTRA_AO \
uniform float extra_ao;

#define UNIFORM_STIPPLE_FADE \
uniform float fade;

#define UNIFORM_COLOR_TINT \
uniform vec3 color_tint;

#define CALC_STIPPLE_FADE \
if((rand(gl_FragCoord.xy)) < fade){\
    discard;\
};\

#define CALC_TAN_NORMAL \
vec3 ws_normal;\
vec4 normalmap = texture2D(normal_tex,tc0);\
{\
    vec3 unpacked_normal = UnpackTanNormal(normalmap);\
    ws_normal = tangent_to_world1 * unpacked_normal.x +\
                tangent_to_world2 * unpacked_normal.y +\
                tangent_to_world3 * unpacked_normal.z;\
}

#define CALC_DIFFUSE_LIGHTING \
float NdotL = GetDirectContrib(ws_light, ws_normal,shadow_tex.r);\
vec3 diffuse_color = GetDirectColor(NdotL);\
diffuse_color += LookupCubemapSimple(ws_normal, diffuse_cubemap) *\
                 GetAmbientContrib(shadow_tex.g);

#define CALC_SPECULAR_LIGHTING \
vec3 spec_color;\
{\
    vec3 H = normalize(normalize(ws_vertex*-1.0) + normalize(ws_light));\
    float spec = GetSpecContrib(ws_light, ws_normal, ws_vertex, shadow_tex.r);\
    vec3 spec_color = gl_LightSource[0].diffuse.xyz * vec3(spec);\
    vec3 spec_map_vec = reflect(ws_vertex,ws_normal);\
    spec_color += LookupCubemapSimple(spec_map_vec, spec_cubemap) * 0.5 *\
                  GetAmbientContrib(shadow_tex.g);\
}

#define CALC_COLOR_MAP \
vec4 colormap = texture2D(tex0,gl_TexCoord[0].xy);

#define CALC_COMBINED_COLOR \
vec3 color = diffuse_color * colormap.xyz  * mix(vec3(1.0),color_tint,normalmap.a)+ \
             spec_color * GammaCorrectFloat(colormap.a);

#define CALC_COLOR_ADJUST \
color *= BalanceAmbient(NdotL); \
color *= vec3(min(1.0,shadow_tex.g*2.0)*extra_ao + (1.0-extra_ao));

#define CALC_HAZE \
AddHaze(color, TransformRelPosForSky(ws_vertex), diffuse_cubemap);

#define CALC_EXPOSURE \
color *= Exposure();

#define CALC_FINAL \
gl_FragColor = vec4(color,1.0);