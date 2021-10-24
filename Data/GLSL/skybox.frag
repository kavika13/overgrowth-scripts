#version 150
uniform samplerCube tex0;
in vec3 normal;
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

void main() {    
    vec3 color;
#ifdef YCOCG_SRGB
    color = YCOCGtoRGB(texture(tex0,normal));
    color = pow(color,vec3(2.2));
#else
    color = texture(tex0,normal).xyz;
#endif
    out_color = vec4(color,1.0);
}