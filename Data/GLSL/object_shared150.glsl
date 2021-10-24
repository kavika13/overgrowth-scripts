void object_shared(){} // This is just here to make sure it gets added to include paths
#include "lighting150.glsl"

#ifndef BAKED_SHADOWS
    #define VARYING_SHADOW \
        varying vec4 shadow_coords[4];
    #define CALC_CASCADE_TEX_COORDS SetCascadeShadowCoords(transformed_vertex, shadow_coords);
#else
    #define VARYING_SHADOW
    #define CALC_CASCADE_TEX_COORDS
#endif 

#define VARYING_REL_POS \
varying vec3 ws_vertex;

#define VARYING_TAN_TO_WORLD \
varying mat3 tangent_to_world;

#define UNIFORM_LIGHT_DIR \
uniform vec3 ws_light;