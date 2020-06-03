uniform sampler2D tex0;
uniform sampler2D tex1;
uniform sampler2D tex2;
uniform sampler2D tex3;
uniform samplerCube tex4;
uniform sampler2D tex5;
uniform sampler2D tex6;
uniform sampler2D tex7;
uniform float rotation;
uniform float rotation_total;
uniform float rotation_total2;
uniform float radius;
uniform vec3 cam_pos;
uniform vec3 ws_light;
uniform float extra_ao;
uniform float fade;

varying vec3 ws_vertex;

#include "pseudoinstance.glsl"

void main()
{    
    mat4 obj2world = GetPseudoInstanceMat4();
    vec4 transformed_vertex = obj2world * gl_Vertex;
    ws_vertex = transformed_vertex.xyz - cam_pos;
    gl_Position = gl_ModelViewProjectionMatrix * transformed_vertex;

    float rot = rotation_total / 180.0 * -3.1417;
    vec3 rotated_vert;
    rotated_vert.z = gl_Vertex.z*cos(rot)-gl_Vertex.x*sin(rot);
    rotated_vert.x = gl_Vertex.z*sin(rot)+gl_Vertex.x*cos(rot);
    rotated_vert.y = gl_Vertex.y;
    gl_TexCoord[0].xy = (rotated_vert.xy/radius+1.0)*0.5;

    rot = rotation_total2 / 180.0 * -3.1417;
    rotated_vert.z = gl_Vertex.z*cos(rot)-gl_Vertex.x*sin(rot);
    rotated_vert.x = gl_Vertex.z*sin(rot)+gl_Vertex.x*cos(rot);
    rotated_vert.y = gl_Vertex.y;
    gl_TexCoord[1].xy = (rotated_vert.xy/radius+1.0)*0.5;
} 
