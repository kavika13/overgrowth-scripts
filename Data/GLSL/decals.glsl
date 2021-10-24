
#define decal_normal_tex tex9
#define decal_color_tex tex10


//Disabled because we've run out of texture sampler.
#ifdef DECAL_NORMALS
uniform sampler2D decal_normal_tex; // decal normal texture
#endif  // DECAL_NORMALS
uniform sampler2D decal_color_tex; // decal color texture


// this MUST match the one in source or bad things happen
struct DecalData {
	mat4 transform;
	vec4 tint;
	vec4 uv;
	vec4 normal;
};

#define DECAL_SIZE_VEC4 7u


DecalData FetchDecal(uint decal_index) {
	DecalData decal;

	decal.transform[0] = texelFetch(light_decal_data_buffer, int(DECAL_SIZE_VEC4 * decal_index + 0u));
	decal.transform[1] = texelFetch(light_decal_data_buffer, int(DECAL_SIZE_VEC4 * decal_index + 1u));
	decal.transform[2] = texelFetch(light_decal_data_buffer, int(DECAL_SIZE_VEC4 * decal_index + 2u));
	decal.transform[3] = texelFetch(light_decal_data_buffer, int(DECAL_SIZE_VEC4 * decal_index + 3u));
	decal.tint = texelFetch(light_decal_data_buffer, int(DECAL_SIZE_VEC4 * decal_index + 4u));

	decal.uv = texelFetch(light_decal_data_buffer, int(DECAL_SIZE_VEC4 * decal_index + 5u));

	decal.normal = texelFetch(light_decal_data_buffer, int(DECAL_SIZE_VEC4 * decal_index + 6u));

	return decal;
}


void CalculateDecals(inout vec4 colormap, inout vec3 ws_normal, in vec3 world_vert) {
	uint num_z_clusters = grid_size.z;

	vec4 ndcPos;
	ndcPos.xy = ((2.0 * gl_FragCoord.xy) - (2.0 * viewport.xy)) / (viewport.zw) - 1;
	ndcPos.z = 2.0 * gl_FragCoord.z - 1; // this assumes gl_DepthRange is not changed
	ndcPos.w = 1.0;

	vec4 clipPos = ndcPos / gl_FragCoord.w;
	vec4 eyePos = inv_proj_mat * clipPos;

	float zVal = ZCLUSTERFUNC(eyePos.z);

	zVal = max(0u, min(zVal, num_z_clusters - 1u));

	uvec3 g = uvec3(gl_FragCoord.xy / 32.0, zVal);

	// index of cluster we're in
	uint decal_cluster_index = NUM_GRID_COMPONENTS * ((g.y * grid_size.x + g.x) * num_z_clusters + g.z);
	uint val = texelFetch(cluster_buffer, int(decal_cluster_index)).x;

	// number of decals in current cluster
	uint decal_count = (val >> 16) & 0xFFFFU;

	// debug option, uncomment to visualize clusters
	//colormap.xyz = vec3(min(decal_count, 63u) / 63.0);
	//colormap.xyz = vec3(g.z / num_z_clusters);

	// index into cluster_decals
	uint first_decal_index = val & 0xFFFFU;

	// decal list data is immediately after cluster lookup data
	uint num_clusters = grid_size.x * grid_size.y * grid_size.z;
	first_decal_index = first_decal_index + 2u * num_clusters;

	vec3 world_dx = dFdx(world_vert);
	vec3 world_dy = dFdy(world_vert);
	for (uint i = 0u; i < decal_count; ++i) {
		// texelFetch takes int
		uint decal_index = texelFetch(cluster_buffer, int(first_decal_index + i)).x;

		DecalData decal = FetchDecal(decal_index);

		mat4 test = inverse(decal.transform);

		vec2 start_uv = decal.uv.xy;
		vec2 size_uv = decal.uv.zw;

		vec2 start_normal = decal.normal.xy;
		vec2 size_normal = decal.normal.zw;

		vec3 temp = (test * vec4(world_vert, 1.0)).xyz;

		// we must supply texture gradients here since we have non-uniform control flow
		// non-uniformness happens when we have z cluster discontinuities

		vec2 color_tex_dx = (test * vec4(world_dx, 0.0)).xz * size_uv;
		vec2 color_tex_dy = (test * vec4(world_dy, 0.0)).xz * size_uv;

		vec2 color_tex_coord = start_uv + size_uv * (temp.xz + vec2(0.5));
		vec4 decal_color = textureGrad(decal_color_tex, color_tex_coord, color_tex_dx, color_tex_dy);

#ifdef DECAL_NORMALS

		vec2 normal_tex_coord = start_normal + size_normal * (temp.xz + vec2(0.5));

		vec2 normal_tex_dx = (test * vec4(world_dx, 0.0)).xz * size_normal;
		vec2 normal_tex_dy = (test * vec4(world_dy, 0.0)).xz * size_normal;

		vec4 decal_normal = textureGrad(decal_normal_tex, normal_tex_coord, normal_tex_dx, normal_tex_dy);

#endif  // DECAL_NORMALS

		if(temp[0] < -0.5 || temp[0] > 0.5 || temp[1] < -0.5 || temp[1] > 0.5 || temp[2] < -0.5 || temp[2] > 0.5){
            
		} else {
			colormap.xyz = mix(colormap.xyz, decal_color.xyz * decal.tint.xyz, decal_color.a);
#ifdef DECAL_NORMALS

			vec3 decal_tan = normalize(cross(ws_normal, (decal.transform * vec4(0.0, 0.0, 1.0, 0.0)).xyz));
			vec3 decal_bitan = cross(ws_normal, decal_tan);
			vec3 new_normal = vec3(0);
			new_normal += ws_normal * (decal_normal.b*2.0-1.0);
			new_normal += (decal_normal.r*2.0-1.0) * decal_tan;
			new_normal += (decal_normal.g*2.0-1.0) * decal_bitan;
			ws_normal = normalize(mix(ws_normal, new_normal, decal_color.a));
#endif  // DECAL_NORMALS
		}
	}
}
