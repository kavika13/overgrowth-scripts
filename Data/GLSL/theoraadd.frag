#version 150
#pragma blendmode_add

uniform sampler2D tex0;
uniform samplerCube tex3;
uniform float shadowed;

#include "lighting.glsl"

void main() {    
    vec2 coord = vec2((1.0-gl_TexCoord[0].x),(1.0-gl_TexCoord[0].y));
    vec4 colormap = texture2D(tex0,coord);
    float avg_color = (colormap[0]+colormap[1]+colormap[2])/3.0;
    colormap.xyz = colormap.xyz + (colormap.xyz - vec3(avg_color))*0.5;

    gl_FragColor = colormap;
}
