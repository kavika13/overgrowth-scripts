uniform sampler2D tex4;

#include "texturepack.glsl"

void main()
{		
	vec3 shadow_tex = texture2D(tex4,tc1).rgb;
	gl_FragColor = vec4(shadow_tex,1.0);
}