#version 400
#extension GL_ARB_viewport_array : enable


#ifndef SHADOW_CASCADE
#error Geometry shader only when shadow cascade
#endif  // SHADOW_CASCADE

#define NUM_SHADOW_CASCADES 4


// FIXME: this is nasty
#ifdef PARTICLE

#elif defined(DETAIL_OBJECT)

#define FRAG_TEX_COORDS 2

#elif defined(ITEM)

#define FRAG_TEX_COORDS 2

#elif defined(TERRAIN)

#define FRAG_TEX_COORDS 4

#elif defined(CHARACTER)

#else

#define FRAG_TEX_COORDS 2

#endif


layout(invocations = NUM_SHADOW_CASCADES) in;


layout(triangles) in;
layout(triangle_strip) out;
layout(max_vertices = 12) out;


layout (std140) uniform ShadowCascades {
    mat4 proj_view_matrices[NUM_SHADOW_CASCADES];
    vec4 frustum_planes[NUM_SHADOW_CASCADES * 6];
    uvec4 viewports[NUM_SHADOW_CASCADES];
};


#if (FRAG_TEX_COORDS == 2)

in vec2 geom_tex_coords[];

#elif (FRAG_TEX_COORDS == 4)  // FRAG_TEX_COORDS

in vec4 geom_tex_coords[];

#else  // FRAG_TEX_COORDS

#endif  // FRAG_TEX_COORDS

#ifdef CHARACTER
in vec2 geom_fur_tex_coord[];
#endif  // CHARACTER

in vec3 geom_world_vert[];


#if (FRAG_TEX_COORDS == 2)

out vec2 frag_tex_coords;

#elif (FRAG_TEX_COORDS == 4)  // FRAG_TEX_COORDS

out vec4 frag_tex_coords;

#else  // FRAG_TEX_COORDS

#endif  // FRAG_TEX_COORDS

#ifdef CHARACTER
out vec2 fur_tex_coord;
#endif  // CHARACTER

out vec3 world_vert;


void main()
{
    mat4 proj_view_matrix = proj_view_matrices[gl_InvocationID];
    vec4 v0 = proj_view_matrix * vec4(geom_world_vert[0], 1.0);
    vec4 v1 = proj_view_matrix * vec4(geom_world_vert[1], 1.0);
    vec4 v2 = proj_view_matrix * vec4(geom_world_vert[2], 1.0);

    vec3 v0p = v0.xyz / v0.w;
    vec3 v1p = v1.xyz / v1.w;
    vec3 v2p = v2.xyz / v2.w;

    // cull back-facing triangles
    vec3 c = cross(v1p - v0p, v2p - v0p);
    if (c.z > 0.0f) {
        for (int j = 0; j < 6; j++) {
            // if all three points of the triangle are behind this plane, we can cull it
            // if any are in front we would have to clip and so can't cull
            vec4 plane = frustum_planes[gl_InvocationID * 6 + j];
            bvec3 behind = bvec3(dot(plane, vec4(geom_world_vert[0], 1.0)) < 0.0
                               , dot(plane, vec4(geom_world_vert[1], 1.0)) < 0.0
                               , dot(plane, vec4(geom_world_vert[2], 1.0)) < 0.0);

            if (all(behind)) {
                return;
            }
        }

    for (int j = 0; j < 3; j++) {
        gl_ViewportIndex = gl_InvocationID;
        gl_Position     = proj_view_matrix * vec4(geom_world_vert[j], 1.0);
#ifdef FRAG_TEX_COORDS
        frag_tex_coords = geom_tex_coords[j];
#endif  // FRAG_TEX_COORDS
        world_vert      = geom_world_vert[j];
#ifdef CHARACTER
        fur_tex_coord   = geom_fur_tex_coord[j];
#endif  // CHARACTER
        EmitVertex();
    }
    EndPrimitive();
    }
}
