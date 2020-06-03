vec3 CalcRelativePositionForSky(const mat4 obj2world, const vec3 cam_pos) {
	vec3 position = (obj2world * gl_Vertex).xyz - cam_pos;
	position.xy *= -1.0;
	return position;
}