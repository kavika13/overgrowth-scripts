#include "object_vert.glsl"
#include "object_shared.glsl"

UNIFORM_REL_POS
uniform mat4 shadowmat;
#ifdef GPU_SKINNING
uniform mat4 bone_mats[128];
#endif

VARYING_REL_POS
VARYING_SHADOW
varying vec3 concat_bone1;
varying vec3 concat_bone2;

void main()
{    
    // Reconstruct bone matrix from tex_coords
    vec4 index = gl_MultiTexCoord1;
    vec4 weight = gl_MultiTexCoord2;
    #ifdef GPU_SKINNING
        mat4 concat_bone = 
            bone_mats[int(index[0])]*weight[0] +
            bone_mats[int(index[1])]*weight[1] +
            bone_mats[int(index[2])]*weight[2] +
            bone_mats[int(index[3])]*weight[3];
    #else
        mat4 concat_bone;
        concat_bone[0] = vec4(gl_MultiTexCoord1[0],gl_MultiTexCoord2[0],gl_MultiTexCoord4[0],0.0);
        concat_bone[1] = vec4(gl_MultiTexCoord1[1],gl_MultiTexCoord2[1],gl_MultiTexCoord4[1],0.0);
        concat_bone[2] = vec4(gl_MultiTexCoord1[2],gl_MultiTexCoord2[2],gl_MultiTexCoord4[2],0.0);
        concat_bone[3] = vec4(gl_MultiTexCoord1[3],gl_MultiTexCoord2[3],gl_MultiTexCoord4[3],1.0);
    #endif
    // Set up varyings to pass bone matrix to fragment shader
    concat_bone1 = concat_bone[0].xyz;
    concat_bone2 = concat_bone[1].xyz;

    #ifdef GPU_SKINNING
        vec4 transformed_vertex = concat_bone * (gl_Vertex + vec4(gl_MultiTexCoord4[0],gl_MultiTexCoord4[1],gl_MultiTexCoord4[2],0.0));
    #else
        vec4 transformed_vertex = concat_bone * gl_Vertex;
    #endif
    CALC_REL_POS
 
    gl_Position = gl_ModelViewProjectionMatrix * transformed_vertex;

    gl_TexCoord[0].xy = gl_MultiTexCoord0.xy;
    gl_TexCoord[0].zw = gl_MultiTexCoord0.xy + gl_MultiTexCoord5.xy;
    gl_TexCoord[1] = gl_MultiTexCoord6;
    gl_TexCoord[2] = shadowmat *gl_ModelViewMatrix * transformed_vertex;
    CALC_CASCADE_TEX_COORDS
} 