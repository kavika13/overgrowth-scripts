//#pragma-transparent

uniform sampler2D tex0;
uniform sampler2D tex1;
uniform samplerCube tex2;
uniform samplerCube tex3;
uniform sampler2D tex4;
uniform vec3 cam_pos;
uniform vec3 ws_light;

varying vec3 ws_vertex;
varying vec3 tangent_to_world1;
varying vec3 tangent_to_world2;
varying vec3 tangent_to_world3;

#include "lighting.glsl"
#include "texturepack.glsl"
#include "relativeskyposfrag.glsl"

void main()
{	
	// Get normal
	vec4 normalmap = texture2D(tex1,tc0);
	vec3 unpacked_normal = UnpackTanNormal(normalmap);
	vec3 ws_normal = tangent_to_world1 * unpacked_normal.x +
					 tangent_to_world2 * unpacked_normal.y +
					 tangent_to_world3 * unpacked_normal.z;
	
	// Get diffuse lighting
	vec3 shadow_tex = texture2D(tex4,tc1).rgb;
	float NdotL = GetDirectContrib(ws_light, ws_normal,shadow_tex.r);
	vec3 diffuse_color = GetDirectColor(NdotL);
	
	diffuse_color += LookupCubemapSimple(ws_normal, tex3) *
					 GetAmbientContrib(shadow_tex.g);
	
	// Get specular lighting
	vec3 H = normalize(normalize(ws_vertex*-1.0) + normalize(ws_light));
	float spec = GetSpecContrib(ws_light, ws_normal, ws_vertex, shadow_tex.r);
	vec3 spec_color = gl_LightSource[0].diffuse.xyz * vec3(spec);
	
	vec3 spec_map_vec = reflect(ws_vertex,ws_normal);
	spec_color += LookupCubemapSimple(spec_map_vec, tex2) * 0.5 *
				  GetAmbientContrib(shadow_tex.g);
	 
	// Put it all together
	vec4 colormap = texture2D(tex0,gl_TexCoord[0].xy);
	
	vec3 color = diffuse_color * colormap.xyz + spec_color * GammaCorrectFloat(normalmap.a);
	
	color *= BalanceAmbient(NdotL);
	
	AddHaze(color, TransformRelPosForSky(ws_vertex), tex3);

	color *= Exposure();

	gl_FragColor = vec4(color,colormap.a);
}