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
varying vec3 tangent_to_world1; \
varying vec3 tangent_to_world2; \
varying vec3 tangent_to_world3;
