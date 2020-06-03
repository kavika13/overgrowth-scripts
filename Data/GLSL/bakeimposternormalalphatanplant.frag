uniform sampler2D tex0;
uniform sampler2D tex1;

varying vec3 tangent_to_obj1;
varying vec3 tangent_to_obj2;
varying vec3 tangent_to_obj3;

#include "pseudoinstance.glsl"
#include "lighting.glsl"

void main()
{	
	vec4 normalmap = texture2D(tex1,gl_TexCoord[0].xy);
	vec3 normal = UnpackTanNormal(normalmap);
	vec3 os_normal = normalize(tangent_to_obj1 * normal.x +
					 tangent_to_obj2 * normal.y +
					 tangent_to_obj3 * normal.z);
	vec3 ws_normal = normalize(normalMatrix * os_normal);
	gl_FragColor = vec4(PackObjNormal(ws_normal),pow(texture2D(tex0,gl_TexCoord[0].xy).a,0.1));
}