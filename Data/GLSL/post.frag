#version 150

uniform sampler2D tex0;
uniform sampler2D tex1;
uniform sampler2D tex2;
uniform sampler2D tex3;
uniform sampler2D tex4;

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
uniform float time_offset;

uniform mat4 proj_mat;
uniform mat4 view_mat;
uniform mat4 prev_view_mat;

const float near = 0.1;
const float far = 1000.0;

float DistFromDepth(float depth) {   
    return (near) / (far - depth * (far - near)) * far;
}

vec4 ScreenCoordFromDepth(vec2 tex_uv, vec2 offset, out float distance) {
    float depth = texture( tex1, tex_uv + offset ).r;
    distance = DistFromDepth( depth );
    return vec4((tex_uv[0] + offset[0]) * 2.0 - 1.0, 
                (tex_uv[1] + offset[1]) * 2.0 - 1.0, 
                depth * 2.0- 1.0, 
                1.0);
}

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
    vec4 bloom = mix(texture(tex0, tex) , texture(tex3, tex), 0.5);
    color = texture(tex2, tex) + bloom;
    vec3 overbright = max(vec3(0.0), color.xyz - vec3(1.0));
    float avg = (overbright[0] + overbright[1] + overbright[2]) / 3.0;
    color = 1.0 - max(vec4(0.0), (vec4(1.0) - texture(tex2, tex))) * max(vec4(0.0), (vec4(1.0) - bloom));
    color.xyz = mix(color.xyz, vec3(1.0), min(1.0,avg*0.3));
#elif defined(CALC_MOTION_BLUR)
    vec3 vel = texture( tex2, tex).rgb;
    float depth = texture( tex1, tex).r;
    vec4 noise = texture( tex3, gl_FragCoord.xy / 256.0 );
    float dist;
    vec4 screen_coord = ScreenCoordFromDepth(tex, vec2(0,0), dist);
    vec4 world_pos = inverse(proj_mat * view_mat) * screen_coord;
    vec4 world_pos2 = inverse(proj_mat * prev_view_mat) * screen_coord;
    color = texture( tex0, tex );
    vec3 vel_3d = (view_mat * world_pos - view_mat * world_pos2).xyz;
    vel_3d /= time_offset;
    vel_3d -= (view_mat * vec4(vel,0.0)).xyz*0.5;
    vel_3d.x += vel_3d.z * screen_coord.x;
    vel_3d.y += vel_3d.z * screen_coord.y;
    vel_3d.z = 0.0;
    vel_3d *= 0.002;
    color.xyz = vel_3d;
#elif defined(APPLY_MOTION_BLUR)
/*
    vec3 vel = texture( tex2, tex).rgb;
    float depth = texture( tex1, tex).r;
    vec4 noise = texture( tex3, gl_FragCoord.xy / 256.0 );
    float dist;
    color = vec4(0.0);
    float total = 0.0;
    vec3 dominant_dir = texture( tex4, tex).rgb;
    const int num_samples = 5;
    for(int i=0; i<num_samples; ++i){
        vec2 coord = tex + vel.xy * float(i-(num_samples / 2.0)+noise.r);
        if(coord[0] >= 0.0 && coord[0] <= 1.0 && coord[1] >= 0.0 && coord[1] <= 1.0){
            float weight = 1.0;
            color += texture( tex0, coord) * weight;
            total += weight;
        }
    }
    color /= float(total);*/

    float blur_mult = 1.0;
    vec3 vel = texture( tex2, tex).rgb * blur_mult;
    float depth = DistFromDepth(texture( tex1, tex).r);
    vec4 noise = texture( tex3, gl_FragCoord.xy / 256.0 );
    float dist;
    vec3 dominant_dir = texture( tex4, tex).rgb * blur_mult;
    color = vec4(0.0);
    float total = 0.0 ;
    const int num_samples = 5;
    float max_blur_dist = min(0.01, length(dominant_dir)) * 5.0 / float(num_samples);
    dominant_dir = normalize(dominant_dir);
    if(isnan(dominant_dir[0])){
        dominant_dir = vec3(0.0);
    }
    for(int i=0; i<num_samples; ++i){
        float offset_amount;
        if( i == num_samples/2){
            offset_amount = min(0.01, abs(dot(vel, dominant_dir))) * 5.0 / float(num_samples) * float(i-(num_samples / 2.0)+noise.r);
        } else {
            offset_amount = max_blur_dist * float(i-(num_samples / 2.0)+noise.r);
        }
        vec2 offset = dominant_dir.xy * offset_amount;
        vec2 coord = tex + offset;
        if(coord[0] >= 0.0 && coord[0] <= 1.0 && coord[1] >= 0.0 && coord[1] <= 1.0){
            vec3 sample_vel = texture( tex2, coord).rgb * blur_mult;
            if(abs(offset_amount) < length(sample_vel) || i == num_samples/2){
                float sample_depth = DistFromDepth(texture( tex1, coord).r);
                if(sample_depth < depth + 0.1 || i == num_samples/2){
                    float weight = 1.0;
                    color += texture( tex0, coord) * weight;
                    total += weight;
                }
            }
        }
    }
    color /= float(total);
#else
    color = texture( tex0, tex );
#endif
}