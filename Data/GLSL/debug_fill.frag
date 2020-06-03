#version 150
in vec3 normal_frag;
in vec3 position_frag;

uniform vec3 camera_position;
uniform vec3 camera_forward;

out vec4 out_color;

void main() 
{
#ifdef STIPPLING
	float distance_frag = pow(length(camera_position - position_frag.rgb)/400, 0.5);

	if(distance_frag < 0.25){
		if(int(mod(gl_FragCoord.x,2.0))!=0||int(mod(gl_FragCoord.y,2.0))!=0){
		   	discard;
		}
	} else if(distance_frag < 0.5) {
		if(mod(gl_FragCoord.x + gl_FragCoord.y, 2.0) == 0.0){
	        discard;
	    }
	} else if(distance_frag < 0.75) {
		if(int(mod(gl_FragCoord.x,2.0))!=0&&int(mod(gl_FragCoord.y,2.0))==0){
	        discard;
	    }
	}
	//out_color = vec4(position_frag, 1);
	out_color = vec4(mix(vec3(0.1, 0.8, 1.0), vec3(0.25, 0.29, 0.3), min(distance_frag, 1)), 1.0);

#elif defined(CAMERA_FILL_LIGHT)
	float vec_front = dot(-camera_forward, normal_frag);
	vec3 light_front = mix(vec3(0.14, 0.12, 0.105), vec3(0.31, 0.27, 0.24), vec_front);
    out_color = vec4(light_front, 1.0);
#else
	out_color = vec4(1.0,0,0,1.0);
#endif
}
