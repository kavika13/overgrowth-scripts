uniform sampler2D tex0;
uniform sampler2D tex1;
uniform samplerCube tex2;
uniform samplerCube tex3;
#ifdef BAKED_SHADOWS
    uniform sampler2D tex4;
#else
    uniform sampler2DShadow tex4;
#endif
uniform sampler2DShadow tex5;
uniform sampler2D tex6;
uniform vec3 cam_pos;
uniform mat4 shadowmat;
uniform vec3 ws_light;
//uniform mat4 bones[64];

varying vec3 vertex_pos;
varying vec3 ws_vertex;
varying vec3 concat_bone1;
varying vec3 concat_bone2;
#ifndef BAKED_SHADOWS
    varying vec4 shadow_coords[4];
    #include "lighting.glsl"
#endif

void main()
{    
    // Reconstruct bone matrix from tex_coords
    mat4 concat_bone;
    concat_bone[0] = vec4(gl_MultiTexCoord1[0],gl_MultiTexCoord2[0],gl_MultiTexCoord4[0],0.0);
    concat_bone[1] = vec4(gl_MultiTexCoord1[1],gl_MultiTexCoord2[1],gl_MultiTexCoord4[1],0.0);
    concat_bone[2] = vec4(gl_MultiTexCoord1[2],gl_MultiTexCoord2[2],gl_MultiTexCoord4[2],0.0);
    concat_bone[3] = vec4(gl_MultiTexCoord1[3],gl_MultiTexCoord2[3],gl_MultiTexCoord4[3],1.0);
    
    // Set up varyings to pass bone matrix to fragment shader
    concat_bone1 = concat_bone[0].xyz;
    concat_bone2 = concat_bone[1].xyz;

    vec4 transformed_vertex = concat_bone * gl_Vertex;
    ws_vertex = transformed_vertex.xyz - cam_pos;
    vertex_pos = transformed_vertex.xyz;
 
    gl_Position = gl_ModelViewProjectionMatrix * transformed_vertex;
    gl_TexCoord[0] = gl_MultiTexCoord0;
    gl_TexCoord[1] = gl_MultiTexCoord0 + gl_MultiTexCoord5;
    gl_TexCoord[2] = shadowmat *gl_ModelViewMatrix * transformed_vertex;
#ifndef BAKED_SHADOWS
    SetCascadeShadowCoords(transformed_vertex, shadow_coords);
#endif
} 
