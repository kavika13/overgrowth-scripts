uniform sampler2DShadow tex0;
uniform sampler2D tex4;
uniform sampler2D tex5;
uniform vec3 ws_light;

varying vec4 ProjShadow;

const float _shadow_depth = 20.0;
const float _half_shadow_depth = _shadow_depth * 0.5;
const float _fade_to_blur = 0.0004;
const float _base_blur = 0.002;
const float _shadow_blur_fudge = -2.3;

#include "lighting.glsl"

void main()
{
	// Get amount to fade shadow based on distance
	float projected_how_far = (gl_TexCoord[0].z + _half_shadow_depth + _shadow_blur_fudge);
	float distance_fade = max(0.0, projected_how_far / _shadow_depth);
		
	// Get amount to blur shadow based on distance
	float how_ambient = GetAmbientMultiplierScaled();
	float ambient_blur_mult = (1.0+how_ambient*how_ambient*400.0);
	float blur_offset = distance_fade*_fade_to_blur*ambient_blur_mult+_base_blur;
	
	// Clip decal to texture edges
	float edge_buffer = 0.01;
	if(gl_TexCoord[0].x <= blur_offset+edge_buffer || gl_TexCoord[0].x >= 1.0-blur_offset-edge_buffer ||
	   gl_TexCoord[0].y <= blur_offset+edge_buffer || gl_TexCoord[0].y >= 1.0-blur_offset-edge_buffer ||
	   gl_TexCoord[0].z < -10.0){
		discard;
	}

	// Accumulate shadow samples
	vec4 color = vec4(0.0,0.0,0.0,1.0);

	color.a -= (shadow2DProj(tex0,ProjShadow).r)*0.2;
	color.a -= (shadow2DProj(tex0,ProjShadow+vec4(blur_offset,0.0,0.0,0.0)).r)*0.2;
	color.a -= (shadow2DProj(tex0,ProjShadow+vec4(-blur_offset,0.0,0.0,0.0)).r)*0.2;
	color.a -= (shadow2DProj(tex0,ProjShadow+vec4(0.0,blur_offset,0.0,0.0)).r)*0.2;
	color.a -= (shadow2DProj(tex0,ProjShadow+vec4(0.0,-blur_offset,0.0,0.0)).r)*0.2;

	// Fade shadow based on distance
	color.a *= pow(texture2D(tex4,gl_TexCoord[1].xy).r,0.25);
	color.a *= (1.0-GetAmbientMultiplierScaled())*1.1;
	color.a *=max(0.0,(1.0 - distance_fade));

	gl_FragColor = color;
}