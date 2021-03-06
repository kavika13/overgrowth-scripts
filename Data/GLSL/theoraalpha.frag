#version 150
#extension GL_ARB_shading_language_420pack : enable
uniform sampler2D tex0;
uniform samplerCube tex3;
uniform float shadowed;

#include "lighting.glsl"

void main()
{    
    vec2 coord = vec2((1.0-gl_TexCoord[0].x)*0.5,(1.0-gl_TexCoord[0].y));
    vec4 colormap = texture2D(tex0,coord);
    coord.x += 0.5;
    colormap.a = texture2D(tex0,coord).r;
    float avg_color = (colormap[0]+colormap[1]+colormap[2])/3.0;
    colormap.xyz = colormap.xyz + (colormap.xyz - vec3(avg_color))*0.5;
    
    gl_FragColor = colormap;
}
