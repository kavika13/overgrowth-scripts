uniform sampler2D tex0;
uniform sampler2D tex1;

#include "pseudoinstance.glsl"
#include "lighting.glsl"

void main()
{	
	vec4 normalmap = texture2D(tex1,gl_TexCoord[0].xy);
	vec3 os_normal = normalize(UnpackObjNormal(normalmap));
	vec3 ws_normal = normalize(normalMatrix * os_normal);
	gl_FragColor = vec4(PackObjNormal(ws_normal),texture2D(tex0,gl_TexCoord[0].xy).a);
}