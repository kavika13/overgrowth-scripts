#version 150
#extension GL_ARB_shading_language_420pack : enable
in vec3 normal_frag;
in vec3 position_frag;

uniform vec3 camera_position;
uniform vec3 camera_forward;

#ifdef STIPPLING
uniform vec3 close_stipple_color;
uniform vec3 far_stipple_color;
#endif

#pragma bind_out_color
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

    out_color = vec4(mix(close_stipple_color, far_stipple_color, min(distance_frag, 1)), 1.0);
#elif defined(NAV_COLLISION_MESH)
	float vec_front = dot(-camera_forward, normal_frag);
	vec3 light_front = mix(vec3(0.14, 0.12, 0.105), vec3(0.31, 0.27, 0.24), vec_front);
	vec3 norm_color = vec3(normal_frag.x*0.5+0.5, normal_frag.y*0.5+0.5, normal_frag.z*0.5+0.5);
	norm_color.xz *= 0.5;
	norm_color.xz += norm_color.y*0.5;
	float mult = 1.0;
	if((int(position_frag.x)+int(position_frag.z))%2==0){
		mult = 0.8;
	}
	if(int(position_frag.y)%2==0){
		mult *= 0.8;
	}
    out_color = vec4(norm_color*mult, 1.0);
#else
	out_color = vec4(1.0,0,0,1.0);
#endif
}
