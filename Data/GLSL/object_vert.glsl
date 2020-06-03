#include "pseudoinstance.glsl"
#include "shadowpack.glsl"
#include "texturepack.glsl"
#include "lighting.glsl"

#define UNIFORM_REL_POS \
uniform vec3 cam_pos;

#define CALC_REL_POS \
ws_vertex = transformed_vertex.xyz - cam_pos;

#define CALC_TAN_TO_WORLD \
mat3 obj2worldmat3 = GetPseudoInstanceMat3(); \
mat3 tan_to_obj = mat3(gl_MultiTexCoord1.xyz, gl_MultiTexCoord2.xyz, gl_Normal); \
mat3 tangent_to_world = obj2worldmat3 * tan_to_obj; \
tangent_to_world1 = normalize(tangent_to_world[0]); \
tangent_to_world2 = normalize(tangent_to_world[1]); \
tangent_to_world3 = normalize(tangent_to_world[2]);

#define CALC_TRANSFORMED_VERTEX \
mat4 obj2world = GetPseudoInstanceMat4(); \
vec4 transformed_vertex = obj2world * gl_Vertex; \
gl_Position = gl_ModelViewProjectionMatrix * transformed_vertex; \

#define CALC_TEX_COORDS \
tc0 = gl_MultiTexCoord0.xy;\
tc1 = GetShadowCoords();\
CALC_CASCADE_TEX_COORDS