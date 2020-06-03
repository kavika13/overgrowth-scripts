#include "object_vert.glsl"
#include "object_shared.glsl"

UNIFORM_REL_POS

VARYING_REL_POS
varying vec3 normal;
varying vec3 world_normal;

void main()
{    
    normal = normalize(gl_NormalMatrix * gl_Normal);  
    mat3 obj2worldmat3 = GetPseudoInstanceMat3();
    world_normal = obj2worldmat3 * normal;
    world_normal.xy *= -1.0;
   
    mat4 obj2worldmat4 = GetPseudoInstanceMat4();
    vec3 transformed_vertex = (obj2worldmat4 * gl_ModelViewMatrix * gl_Vertex).xyz;
    ws_vertex = transformed_vertex - cam_pos;

    gl_Position = ftransform();
    gl_TexCoord[0] = gl_MultiTexCoord0;
    gl_FrontColor = gl_Color;
} 