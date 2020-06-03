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
	
	b = max(0.0,min(1.0,b));

	return vec3(r,g,b);
}

void main()
{	
	vec4 color;
	
	color = vec4(YCOCGtoRGB(textureCube(tex2,normal)),1.0);
	//color = textureCube(tex2,normal);
	//color = textureCube(tex3,normal).xyz;

	color.x = pow(color.x,2.2);
	color.y = pow(color.y,2.2);
	color.z = pow(color.z,2.2);

	color *= Exposure();

	gl_FragColor = vec4(color.xyz,opac);
}