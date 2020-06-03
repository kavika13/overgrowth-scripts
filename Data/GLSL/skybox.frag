#version 150
uniform samplerCube tex0;
uniform samplerCube tex1;
uniform float time;
uniform vec3 tint;
uniform float fog_amount;
in vec3 normal;

#pragma bind_out_color
out vec4 out_color;

#ifdef YCOCG_SRGB
vec3 YCOCGtoRGB(in vec4 YCoCg) {
    float Co = YCoCg.r - 0.5;
    float Cg = YCoCg.g - 0.5;
    float Y  = YCoCg.a;
    
    float t = Y - Cg * 0.5;
    float g = Cg + t;
    float b = t - Co * 0.5;
    float r = b + Co;
    
    r = max(0.0,min(1.0,r));
    g = max(0.0,min(1.0,g));
    b = max(0.0,min(1.0,b));

    return vec3(r,g,b);
}
#endif

float hash( vec2 p )
{
    float h = dot(p,vec2(127.1,311.7));
    
    return -1.0 + 2.0*fract(sin(h)*43758.5453123);
}

float noise( in vec2 p )
{
    vec2 i = floor( p );
    vec2 f = fract( p );
    
    vec2 u = f*f*(3.0-2.0*f);

    return mix( mix( hash( i + vec2(0.0,0.0) ), 
                     hash( i + vec2(1.0,0.0) ), u.x),
                mix( hash( i + vec2(0.0,1.0) ), 
                     hash( i + vec2(1.0,1.0) ), u.x), u.y);
}

float fractal( in vec2 uv){
    float f = 0.0;
    mat2 m = mat2( 1.6,  1.2, -1.2,  1.6 );
    f  = 0.5000*noise( uv ); uv = m*uv;
    f += 0.2500*noise( uv ); uv = m*uv;
    f += 0.1250*noise( uv ); uv = m*uv;
    f += 0.0625*noise( uv ); uv = m*uv;
    f += 0.03125*noise( uv ); uv = m*uv;
    f += 0.016625*noise( uv ); uv = m*uv;
    return f;
}

void main() {    
    vec3 color;
#ifdef YCOCG_SRGB
    color = YCOCGtoRGB(texture(tex0,normal));
    color = pow(color,vec3(2.2));
#else
    color = texture(tex0,normal).xyz;
#endif
    float foggy = max(0.0, min(1.0, (fog_amount - 1.0) / 2.0));
    float fogness = mix(-1.0, 1.0, foggy);
    if(normal.y < 0.0){
        fogness = mix(fogness, 1.0, -normal.y * fog_amount / 5.0);
    }
    float blur = max(0.0, min(1.0, (1.0-abs(normalize(normal).y)+fogness)));
    color = mix(color, textureLod(tex1,normal, mix(pow(blur, 2.0), 1.0, fogness*0.5+0.5) * 5.0).xyz, min(1.0, blur * 4.0));
    color.xyz *= tint;
    //vec3 tint = vec3(1.0, 0.0, 0.0);
    //color *= tint;
    out_color = vec4(color,1.0);

    #ifdef TEST_CLOUDS
    vec3 normalized = normalize(normal);
    vec3 plane_intersect = normalized / (normalized.y+0.2);
    vec2 uv = plane_intersect.xz * 4.0;
    //uv *= (2.0 - normalized.y) * 0.5;
    uv.x += time * 0.1;
    float f = (fractal(uv + vec2(time*0.2, 0.0))+fractal(uv + vec2(0.0, time*0.14)));
    f = min(1.0, f*0.5 + 0.5) * 0.9;

    float min_threshold = sin(time)*0.5+0.5;
    f = min(1.0, max(0.0, f - min_threshold)/(1.0-min_threshold));

    f *= max(0.0, pow(normalized.y, 0.2));

    out_color.xyz = mix(out_color.xyz, vec3(1.0), f);
    #endif
}
