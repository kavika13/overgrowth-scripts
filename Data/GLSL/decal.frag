//#pragma-transparent

uniform sampler2D tex0;
uniform sampler2D tex1;
uniform samplerCube tex2;
uniform samplerCube tex3;
uniform sampler2D tex4;
uniform sampler2D tex5;
uniform vec3 cam_pos;
uniform mat3 test;
uniform vec3 ws_light;

varying vec3 ws_vertex;
varying vec3 tangent;

#include "lighting.glsl"
#include "relativeskyposfrag.glsl"

void main()
{	
	if(gl_TexCoord[0].x<0.0 || gl_TexCoord[0].x>1.0 ||
		gl_TexCoord[0].y<0.0 || gl_TexCoord[0].y>1.0) {
		discard;
	}
	
	// Calculate normal
	vec3 base_normal_tex = texture2D(tex5,gl_TexCoord[0].st).rgb;
	vec3 base_normal = base_normal_tex*2.0-vec3(1.0);
	vec3 base_tangent = tangent;
	vec3 base_bitangent = normalize(cross(base_tangent,base_normal));
	base_tangent = normalize(cross(base_normal,base_bitangent));

	vec4 normalmap = texture2D(tex1,gl_TexCoord[0].st);
	vec3 ws_normal = vec3(base_normal * normalmap.b +
						  base_tangent * (normalmap.x*2.0-1.0) +
					      base_bitangent * (normalmap.y*2.0-1.0));
	
	// Calculate diffuse lighting
	vec3 shadow_tex = texture2D(tex4,gl_TexCoord[0].st).rgb;
	float NdotL = GetDirectContrib(ws_light, ws_normal, shadow_tex.r);
	vec3 diffuse_color = GetDirectColor(NdotL);

	diffuse_color += LookupCubemapSimple(ws_normal, tex3) *
					 GetAmbientContrib(shadow_tex.g);

	// Calculate specular lighting
	float spec = GetSpecContrib(ws_light, ws_normal, ws_vertex, shadow_tex.r);
	vec3 spec_color = gl_LightSource[0].diffuse.xyz * vec3(spec);
	
	vec3 spec_map_vec = reflect(ws_vertex,ws_normal);
	spec_color += LookupCubemapSimple(spec_map_vec, tex2) * 0.5 *
				  GetAmbientContrib(shadow_tex.g);

	// Put it all together
	vec4 colormap = texture2D(tex0,gl_TexCoord[0].st);
	vec3 color = diffuse_color * colormap.xyz + spec_color * GammaCorrectFloat(normalmap.a);
	
	color *= BalanceAmbient(NdotL);
	
	AddHaze(color, TransformRelPosForSky(ws_vertex), tex3);
	
	color *= Exposure();

	gl_FragColor = vec4(color,colormap.a);
}