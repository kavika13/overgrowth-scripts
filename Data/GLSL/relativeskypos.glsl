vec3 CalcRelativePositionForSky(const mat4 obj2world, const vec3 cam_pos) {
	vec3 position = (obj2world * gl_Vertex).xyz - cam_pos;
	position.xy *= -1.0;
	return position;
}

vec3 CalcRelativePositionForSkySimple(const vec3 cam_pos) {
	vec3 position = gl_Vertex.xyz - cam_pos;
	position.xy *= -1.0;
	return position;
}

vec3 CalcRelativePositionForSkySimple2(const vec3 pos, const vec3 cam_pos) {
	vec3 position = pos - cam_pos;
	position.xy *= -1.0;
	return position;
}

vec3 TransformRelPosForSky(const vec3 pos) {
	return vec3(pos.x * -1.0, pos.y * -1.0, pos.z);
}
