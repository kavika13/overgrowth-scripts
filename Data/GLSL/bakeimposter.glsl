#include "pseudoinstance.glsl"

#define BAKE_IMPOSTER_MAIN_START \
void main()\
{

#define BAKE_IMPOSTER_MAIN_TRANSFORM \
    mat4 obj2world = GetPseudoInstanceMat4();\
    vec4 transformed_vertex = obj2world * gl_Vertex;\
    gl_Position = gl_ModelViewProjectionMatrix * transformed_vertex;
    
    
#define BAKE_IMPOSTER_MAIN_ONE_TEXCOORD \
    gl_TexCoord[0].xy = gl_MultiTexCoord0.xy;
    
#define BAKE_IMPOSTER_MAIN_TWO_TEXCOORD \
    gl_TexCoord[0].xy = gl_MultiTexCoord0.xy;\
    gl_TexCoord[1].xy = gl_MultiTexCoord3.xy;
    
#define BAKE_IMPOSTER_MAIN_END\
}

#define BAKE_IMPOSTER_TAN_VARYING_DECL \
varying vec3 tangent_to_obj1;\
varying vec3 tangent_to_obj2;\
varying vec3 tangent_to_obj3;


#define BAKE_IMPOSTER_TAN_VARYING_ASSIGN \
    mat3 tan_to_obj = mat3(gl_MultiTexCoord1.xyz, \
                           gl_MultiTexCoord2.xyz, \
                           gl_Normal);\
    tangent_to_obj1 = normalize(tan_to_obj[0]);\
    tangent_to_obj2 = normalize(tan_to_obj[1]);\
    tangent_to_obj3 = normalize(tan_to_obj[2]);

#define BAKE_IMPOSTER_MAIN \
BAKE_IMPOSTER_MAIN_START \
BAKE_IMPOSTER_MAIN_TRANSFORM \
BAKE_IMPOSTER_MAIN_ONE_TEXCOORD \
BAKE_IMPOSTER_MAIN_END

#define BAKE_IMPOSTER_TWO_TC_MAIN \
BAKE_IMPOSTER_MAIN_START \
BAKE_IMPOSTER_MAIN_TRANSFORM \
BAKE_IMPOSTER_MAIN_TWO_TEXCOORD \
BAKE_IMPOSTER_MAIN_END

#define BAKE_IMPOSTER_TAN_MAIN \
BAKE_IMPOSTER_TAN_VARYING_DECL \
BAKE_IMPOSTER_MAIN_START \
BAKE_IMPOSTER_TAN_VARYING_ASSIGN \
BAKE_IMPOSTER_MAIN_TRANSFORM \
BAKE_IMPOSTER_MAIN_ONE_TEXCOORD \
BAKE_IMPOSTER_MAIN_END