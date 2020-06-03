uniform sampler2D tex0;
uniform samplerCube tex2;
uniform samplerCube tex3;
uniform vec4 emission;
uniform mat4 obj2world;
uniform vec3 cam_pos;

varying vec3 normal;
varying vec3 world_normal;
varying vec3 rel_pos;

#include "transposemat3.glsl"
#include "relativeskypos.glsl"

void main()
{    
    normal = normalize(gl_NormalMatrix * gl_Normal);
    
    world_normal = normalize(gl_Normal);
    world_normal = mat3(obj2world[0].xyz, obj2world[1].xyz, obj2world[2].xyz)*world_normal;
    world_normal.xy *= -1.0;
    
    rel_pos = CalcRelativePositionForSkySimple(cam_pos);

    gl_Position = ftransform();
    
    gl_TexCoord[0] = gl_MultiTexCoord0;
    
    gl_FrontColor = gl_Color;
} 
