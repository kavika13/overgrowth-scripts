void object_vert(){} // This is just here to make sure it gets added to include paths

#include "pseudoinstance.glsl"
#include "lighting.glsl"

#define UNIFORM_REL_POS \
uniform vec3 cam_pos;

#define CALC_REL_POS \
ws_vertex = transformed_vertex.xyz - cam_pos;

#define TERRAIN_LIGHT_OFFSET vec2(0.0005)+ws_light.xz*0.0005