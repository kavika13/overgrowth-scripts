vec3 TransformRelPosForSky(const vec3 pos) {
	return vec3(pos.x * -1.0, pos.y * -1.0, pos.z);
}