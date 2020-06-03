uniform vec3 ws_light;
uniform sampler2D tex5;

#include "texturepack.glsl"

void main()
{	
	vec3 shadow_tex = texture2D(tex5,tc0).rgb;
	gl_FragColor = vec4(shadow_tex,1.0);
}
