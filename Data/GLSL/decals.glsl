
const int grid_x = 8;
const int grid_y = 8;
const int grid_z = 8;
const int num_clusters = grid_x * grid_y * grid_z;
const vec3 grid_size = vec3(grid_x, grid_y, grid_z);


layout (std140) uniform DecalInfo {
    uniform vec3 decal_cluster_size;
    uniform int num_decals;
    uniform vec4 decal_grid_min;
    uniform vec4 decal_grid_max;
};


#define decal_normal_tex tex9
#define decal_color_tex tex10

#define decal_buffer tex15
#define decal_cluster_buffer tex13


//Disabled because we've run out of texture sampler.
#ifdef DECAL_NORMALS
uniform sampler2D decal_normal_tex; // decal normal texture
#endif  // DECAL_NORMALS
uniform sampler2D decal_color_tex; // decal color texture

uniform samplerBuffer decal_buffer;
uniform isamplerBuffer decal_cluster_buffer;


void CalculateDecals(inout vec4 colormap, inout vec3 ws_normal, in vec3 world_vert) {
	if (any(lessThan(world_vert, decal_grid_min.xyz))) {
	    return;
	}

	if (any(greaterThan(world_vert, decal_grid_max.xyz))) {
	    return;
	}

	ivec3 g = ivec3((world_vert - decal_grid_min.xyz) / decal_cluster_size);

	// index of cluster we're in
	int decal_cluster_index = (g.z * grid_y + g.y) * grid_x + g.x;

	// FIXME: testing hax to avoid gpu hang, remove
	decal_cluster_index = max(0, decal_cluster_index);
	decal_cluster_index = min(decal_cluster_index, num_clusters);


	int major = decal_cluster_index / 4;
	int minor = decal_cluster_index % 4;


	int val = texelFetch(decal_cluster_buffer, major)[minor];


	// number of decals in current cluster
	int decal_count = (val >> 16) & 0xFFFF;

	// FIXME: testing hax to avoid gpu hang, remove
	decal_count = max(0, decal_count);
	decal_count = min(decal_count, 30);

	// index into cluster_decals
	int first_decal_index = val & 0xFFFF;

	// FIXME: testing hax to avoid gpu hang, remove
	first_decal_index = max(0, first_decal_index);

	// decal list data is immediately after cluster lookup data
	first_decal_index = first_decal_index + num_clusters;

	vec3 world_dx = dFdx(world_vert);
	vec3 world_dy = dFdy(world_vert);
	for (int i = 0; i < decal_count; ++i) {
    	major = (first_decal_index + i) / 4;
    	minor = (first_decal_index + i) % 4;
		int decal_index = texelFetch(decal_cluster_buffer, major)[minor];

		mat4 decal_transform;
		decal_transform[0] = texelFetch(decal_buffer, 7 * decal_index + 0);
		decal_transform[1] = texelFetch(decal_buffer, 7 * decal_index + 1);
		decal_transform[2] = texelFetch(decal_buffer, 7 * decal_index + 2);
		decal_transform[3] = texelFetch(decal_buffer, 7 * decal_index + 3);

		mat4 test = inverse(decal_transform);

		vec4 decal_tint = texelFetch(decal_buffer, 7 * decal_index + 4);

		vec4 temp_uv = texelFetch(decal_buffer, 7 * decal_index + 5);
		vec2 start_uv = temp_uv.xy;
		vec2 size_uv = temp_uv.zw;

		vec4 temp_normal = texelFetch(decal_buffer, 7 * decal_index + 6);
		vec2 start_normal = temp_normal.xy;
		vec2 size_normal = temp_normal.zw;

		vec3 temp = (test * vec4(world_vert, 1.0)).xyz;
		if(temp[0] < -0.5 || temp[0] > 0.5 || temp[1] < -0.5 || temp[1] > 0.5 || temp[2] < -0.5 || temp[2] > 0.5){
            
		} else {
			// we must supply texture gradients here since we have non-uniform control flow
			vec2 color_tex_coord = start_uv + size_uv * (temp.xz + vec2(0.5));

			vec2 color_tex_dx = (test * vec4(world_dx, 0.0)).xz * size_uv;
			vec2 color_tex_dy = (test * vec4(world_dy, 0.0)).xz * size_uv;

			vec4 decal_color = textureGrad(decal_color_tex, color_tex_coord, color_tex_dx, color_tex_dy);
			colormap.xyz = mix(colormap.xyz, decal_color.xyz * decal_tint.xyz, decal_color.a);
#ifdef DECAL_NORMALS
			vec2 normal_tex_coord = start_normal + size_normal * (temp.xz + vec2(0.5));

			vec2 normal_tex_dx = (test * vec4(world_dx, 0.0)).xz * size_normal;
			vec2 normal_tex_dy = (test * vec4(world_dy, 0.0)).xz * size_normal;

			vec4 decal_normal = textureGrad(decal_normal_tex, normal_tex_coord, normal_tex_dx, normal_tex_dy);

			vec3 decal_tan = normalize(cross(ws_normal, (decal_transform * vec4(0.0, 0.0, 1.0, 0.0)).xyz));
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
