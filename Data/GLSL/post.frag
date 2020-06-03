#version 150

uniform sampler2D tex0;
uniform sampler2D tex1;
uniform sampler2D tex2;

in vec2 tex;

out vec4 color;

// From http://rastergrid.com/blog/2010/09/efficient-gaussian-blur-with-linear-sampling/
uniform float offset[3] = float[]( 0.0, 1.3846153846, 3.2307692308 );
uniform float weight[3] = float[]( 0.2270270270, 0.3162162162, 0.0702702703 );

uniform int screen_height;
uniform int screen_width;
uniform float black_point;
uniform float white_point;
uniform float bloom_mult;

void main(void)
{
#if defined(BLUR_VERT)
    vec4 FragmentColor;
    float pixel_height = 1.0 / float(screen_height);
    FragmentColor = texture( tex0, tex ) * weight[0];
    for (int i=1; i<3; i++) {
        FragmentColor +=
            texture( tex0, tex+vec2(0.0, offset[i]*pixel_height) )
                * weight[i];
        FragmentColor +=
            texture( tex0, tex-vec2(0.0, offset[i]*pixel_height) )
                * weight[i];
    }
    color = FragmentColor;
#elif defined(BLUR_HORZ)
    vec4 FragmentColor;
    float pixel_width = 1.0 / float(screen_width);
    FragmentColor = texture( tex0, tex ) * weight[0];
    for (int i=1; i<3; i++) {
        FragmentColor +=
            texture( tex0, tex+vec2(offset[i]*pixel_width, 0.0) )
                * weight[i];
        FragmentColor +=
            texture( tex0, tex-vec2(offset[i]*pixel_width, 0.0) )
                * weight[i];
    }
    color = FragmentColor;
#elif defined(OVERBRIGHT)
    color = max(vec4(0.0), texture( tex0, tex ) - vec4(1.0)) * bloom_mult;
#elif defined(DOWNSAMPLE)
    float pixel_width = 1.0 / float(screen_width);
    float pixel_height = 1.0 / float(screen_height);
    color = texture( tex0, tex + vec2( pixel_width,  pixel_height)) +
                   texture( tex0, tex + vec2( pixel_width, -pixel_height)) +
                   texture( tex0, tex + vec2(-pixel_width,  pixel_height)) +
                   texture( tex0, tex + vec2(-pixel_width, -pixel_height));
   color *= 0.25;
#elif defined(TONE_MAP)
    //float temp_wp = 0.3;
    //float temp_bp = 0.002;
    float temp_wp = white_point;
    float temp_bp = black_point;
    float contrast = 1.0 / (temp_wp - temp_bp);
    vec4 src_color = texture(tex0, tex);
    for(int i=0; i<3; ++i){
        src_color[i] = pow(src_color[i], 1.0/2.2);
    }
    color.xyz = max(vec3(0.0), (src_color.xyz - vec3(temp_bp)) * contrast);  
    for(int i=0; i<3; ++i){
        color[i] = pow(color[i], 2.2);
    }
    color.a = src_color.a;   
#elif defined(ADD)
    color = texture(tex1, tex) + mix(texture(tex0, tex) , texture(tex2, tex), 0.75);
    vec3 overbright = max(vec3(0.0), color.xyz - vec3(1.0));
    float avg = (overbright[0] + overbright[1] + overbright[2]) / 3.0;
    color.xyz = mix(color.xyz, vec3(1.0), min(1.0,avg*0.3));
#else
    color = texture( tex0, tex );
#endif
}