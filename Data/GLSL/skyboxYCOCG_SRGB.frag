uniform samplerCube tex2;

varying vec3 normal;
varying float opac;

#include "lighting.glsl"

vec3 YCOCGtoRGB(in vec4 YCoCg) {
	float Co = YCoCg.r - 0.5;
	float Cg = YCoCg.g - 0.5;
	float Y  = YCoCg.a;
	
	float t = Y - Cg * 0.5;
	float g = Cg + t;
	float b = t - Co * 0.5;
	float r = b + Co;
	
	return vec3(r,g,b);
}

void main()
{	
	vec3 color;
	
	color = YCOCGtoRGB(textureCube(tex2,normal));
	//color = textureCube(tex3,normal).xyz;
	
	color.x = pow(color.x,2.2);
	color.y = pow(color.y,2.2);
	color.z = pow(color.z,2.2);

	color *= Exposure();

	gl_FragColor = vec4(color,opac);
}