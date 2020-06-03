float GetDirectContrib( const vec3 light_pos,
					    const vec3 normal, 
					    const float unshadowed ) {
	float direct_contrib;
	direct_contrib = max(0.0,dot(light_pos, normal));
	direct_contrib *= unshadowed;
	direct_contrib *= gl_LightSource[0].diffuse.a;
	return direct_contrib;
}

vec3 UnpackObjNormal(const vec4 normalmap) {
	return normalize(vec3((normalmap.x-0.5)*2.0, 
						  (normalmap.z-0.5)*2.0, 
						  (normalmap.y-0.5)*-2.0));
}

vec3 UnpackTanNormal(const vec4 normalmap) {
	return normalize(vec3((normalmap.x-0.5)*2.0,
						  (normalmap.y-0.5)*-2.0, 
						   normalmap.z));
}

vec3 GetDirectColor(const float intensity) {
	return gl_LightSource[0].diffuse.xyz * vec3(intensity);
}

vec3 LookupCubemap(const mat4 obj2world, 
				   const vec3 vec, 
				   const samplerCube cube_map) {
	mat3 obj2world_mat3 = mat3(obj2world[0].xyz,
							   obj2world[1].xyz,
							   obj2world[2].xyz);
	vec3 world_space_vec = normalize(obj2world_mat3 * vec);
	world_space_vec.xy *= -1.0;
	return textureCube(cube_map,world_space_vec).xyz;
}

vec3 LookupCubemapSimple(const vec3 vec, 
				   const samplerCube cube_map) {
	vec3 world_space_vec = normalize(vec);
	world_space_vec.xy *= -1.0;
	return textureCube(cube_map,world_space_vec).xyz;
}

float GetAmbientContrib (const float unshadowed) {
	float contrib = min(1.0,max(unshadowed * 1.5, 0.5));
	contrib *= (1.5-gl_LightSource[0].diffuse.a*0.5);
	return contrib;
}

float GetSpecContrib ( const vec3 light_pos,
					   const vec3 normal,
					   const vec3 vertex_pos,
					   const float unshadowed ) {
	vec3 H = normalize(normalize(vertex_pos*-1.0) + normalize(light_pos));
	return min(1.0, pow(max(0.0,dot(normal,H)),10.0)*1.0)*unshadowed;
}

float BalanceAmbient ( const float direct_contrib ) {
	return 1.0-direct_contrib*0.2;
}

void AddHaze( inout vec3 color, 
			  in vec3 relative_position,
			  in samplerCube fog_cube ) { 
	float near = 0.1;
	float far = 1000.0;
	vec3 fog_color = textureCube(fog_cube,normalize(relative_position)).xyz;
	float fog_opac = min(1.0,length(relative_position)/far);
	color = mix(color, fog_color, fog_opac);
}

float Exposure() {
	return gl_LightSource[0].ambient.a;
}