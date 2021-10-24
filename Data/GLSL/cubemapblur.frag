uniform samplerCube tex0;
uniform mat4 rotate;
uniform float max_angle;
uniform float src_mip;
#ifdef HEMISPHERE
	uniform vec3 hemisphere_dir;
#endif

varying vec3 vec;
varying vec3 face_vec;

#define M_PI 3.1415926535897932384626433832795

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void main() {    
	vec3 accum;
	vec3 front = normalize((rotate * vec4(vec,0.0)).xyz);
	vec3 right = normalize(cross(front, vec3(0.0, 1.0, 0.0)));
	vec3 up = cross(front, right);
	float rand_val = rand(face_vec.xy);
	float total = 0.0;
	int num_samples = 3;
	for(int i=-num_samples; i<num_samples; ++i){
		float spin_angle = (float(i)+rand_val) * 2.0 * M_PI / (float(num_samples*2) + 1.0);
		vec3 spin_vec = up * cos(spin_angle) + right * sin(spin_angle);
		for(int j=-num_samples; j<num_samples; ++j){
			float j_val = float(j)+rand_val;
			float angle = sign(j_val) * pow(abs(j_val/(float(num_samples)+0.5)), 0.5) * max_angle;
			vec3 sample_dir = front * cos(angle) + spin_vec * sin(angle);
			float opac = cos(angle);
			#ifdef HEMISPHERE
				opac *= step(0.0, dot(hemisphere_dir, sample_dir));
			#endif
			total += opac;
			accum += textureCubeLod(tex0, sample_dir, src_mip).xyz * opac;
		}
	}
	gl_FragColor.xyz = accum / total;
    gl_FragColor.a = 1.0;
}