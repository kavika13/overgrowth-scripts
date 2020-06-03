#extension GL_ARB_texture_rectangle : enable

uniform sampler2D tex0;
uniform sampler2D tex1;
uniform samplerCube tex3;
uniform sampler2DRect tex5;
uniform float size;
uniform float shadowed;
uniform vec3 ws_light;
uniform vec3 cam_pos;

varying vec3 tangent_to_world1;
varying vec3 tangent_to_world2;
varying vec3 tangent_to_world3;
varying vec3 ws_vertex;

void main()
{    
    tangent_to_world3 = normalize(gl_Normal * -1.0);
    tangent_to_world1 = normalize(gl_MultiTexCoord1.xyz);
    tangent_to_world2 = normalize(cross(tangent_to_world1,tangent_to_world3));
    ws_vertex = gl_Vertex.xyz - cam_pos;

    gl_Position = ftransform();
    
    gl_TexCoord[0] = gl_MultiTexCoord0;
    
    gl_FrontColor = gl_Color;
} 
