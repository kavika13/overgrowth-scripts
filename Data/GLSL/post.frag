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
uniform float time;
uniform vec3 tint;
uniform vec3 vignette_tint;

uniform float near_blur_amount;
uniform float far_blur_amount;
uniform float near_sharp_dist;
uniform float far_sharp_dist;
uniform float near_blur_transition_size;
uniform float far_blur_transition_size;

uniform float motion_blur_mult;

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

vec4 FXAA(sampler2D buf0, vec2 texCoords, vec2 frameBufSize) {
    float FXAA_SPAN_MAX = 8.0;
    float FXAA_REDUCE_MUL = 1.0/8.0;
    float FXAA_REDUCE_MIN = 1.0/128.0;

    vec3 rgbNW=texture(buf0,texCoords+(vec2(-1.0,-1.0)/frameBufSize)).xyz;
    vec3 rgbNE=texture(buf0,texCoords+(vec2(1.0,-1.0)/frameBufSize)).xyz;
    vec3 rgbSW=texture(buf0,texCoords+(vec2(-1.0,1.0)/frameBufSize)).xyz;
    vec3 rgbSE=texture(buf0,texCoords+(vec2(1.0,1.0)/frameBufSize)).xyz;
    vec3 rgbM=texture(buf0,texCoords).xyz;

    vec3 luma=vec3(0.299, 0.587, 0.114);
    float lumaNW = dot(rgbNW, luma);
    float lumaNE = dot(rgbNE, luma);
    float lumaSW = dot(rgbSW, luma);
    float lumaSE = dot(rgbSE, luma);
    float lumaM  = dot(rgbM,  luma);

    float lumaMin = min(lumaM, min(min(lumaNW, lumaNE), min(lumaSW, lumaSE)));
    float lumaMax = max(lumaM, max(max(lumaNW, lumaNE), max(lumaSW, lumaSE)));

    vec2 dir;
    dir.x = -((lumaNW + lumaNE) - (lumaSW + lumaSE));
    dir.y =  ((lumaNW + lumaSW) - (lumaNE + lumaSE));

    float dirReduce = max(
        (lumaNW + lumaNE + lumaSW + lumaSE) * (0.25 * FXAA_REDUCE_MUL),
        FXAA_REDUCE_MIN);

    float rcpDirMin = 1.0/(min(abs(dir.x), abs(dir.y)) + dirReduce);

    dir = min(vec2( FXAA_SPAN_MAX,  FXAA_SPAN_MAX),
          max(vec2(-FXAA_SPAN_MAX, -FXAA_SPAN_MAX),
          dir * rcpDirMin)) / frameBufSize;

    vec3 rgbA = (1.0/2.0) * (
        texture(buf0, texCoords.xy + dir * (1.0/3.0 - 0.5)).xyz +
        texture(buf0, texCoords.xy + dir * (2.0/3.0 - 0.5)).xyz);
    vec3 rgbB = rgbA * (1.0/2.0) + (1.0/4.0) * (
        texture(buf0, texCoords.xy + dir * (0.0/3.0 - 0.5)).xyz +
        texture(buf0, texCoords.xy + dir * (3.0/3.0 - 0.5)).xyz);
    float lumaB = dot(rgbB, luma);

    if((lumaB < lumaMin) || (lumaB > lumaMax)){
        return vec4(rgbA, 1.0);
    }else{
        return vec4(rgbB, 1.0);
    }
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
#elif defined(DOF)
    color = vec4(0.0);
    const int num_samples = 10;
    vec4 noise = texture( tex3, gl_FragCoord.xy / 256.0 );
    float angle = noise.x * 6.28;
    float curr_angle = angle;
    float delta_angle = 6.28 / float(num_samples);
    float sample_depth = DistFromDepth(texture( tex1, tex).r);
    float blur_amount = max(0.0, min(2.0, (pow(sample_depth, 0.5) - far_sharp_dist) / far_blur_transition_size));
    float total = 0.0;
    if(far_blur_amount > 0.0){
        for(int i=0; i<num_samples; ++i){
            float weight = 1.0;
            vec2 offset = vec2(sin(curr_angle) / screen_width, cos(curr_angle) / screen_height) * 5.0 * blur_amount * far_blur_amount;
            float sample_depth = DistFromDepth(texture( tex1, tex + offset).r);
            float temp_blur_amount = max(0.0, min(1.0, (pow(sample_depth, 0.5) - far_sharp_dist) / far_blur_transition_size));
            if(temp_blur_amount < blur_amount){
                weight *= temp_blur_amount + 0.0001;
            }
            color += texture( tex0, tex + offset) * weight;
            total += weight;
            curr_angle += delta_angle;
        }
        color /= total;
    } else {
        color = texture( tex0, tex );
    }

    if(near_blur_amount > 0.0){
        blur_amount = min(1.0, max(0.0, near_sharp_dist - sample_depth) / near_blur_transition_size);
        vec4 orig_color = color;
        total = 0.0;
        color = vec4(0.0);
        for(int i=0; i<num_samples; ++i){
            vec2 offset = vec2(sin(curr_angle) / screen_width, cos(curr_angle) / screen_height) * mix(0.0, 10.0, pow(near_blur_amount, 1.0));
            float sample_depth = DistFromDepth(texture( tex1, tex + offset).r);
            float temp_blur_amount = min(1.0, max(0.0, near_sharp_dist - sample_depth) / near_blur_transition_size);
            float weight = max(blur_amount, temp_blur_amount);
            color += texture( tex0, tex + offset) * weight;
            total += weight;
            color += orig_color * (1.0 - weight);
            total += (1.0 - weight);
            curr_angle += delta_angle;
        }
        color /= total;
    }
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

    color.xyz *= tint;

    if(vignette_tint != vec3(1.0)){
        float vignette_amount = 1.0;
        // Vignette
        float vignette = 1.0 - distance(gl_FragCoord.xy, vec2(screen_width*0.5, screen_height*0.5)) / max(screen_width, screen_height);
        float vignette_opac = 1.0 - mix(1.0, pow(vignette, 3.0), vignette_amount);
        color.xyz *= mix(vec3(1.0), vignette_tint, vignette_opac);
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
    world_pos.xyz -= vel * time_offset * world_pos[3];
    color = texture( tex0, tex );
    vec3 vel_3d = (view_mat * world_pos - view_mat * world_pos2).xyz;
    vel_3d /= time_offset;
    vel_3d.x += vel_3d.z * screen_coord.x;
    vel_3d.y += vel_3d.z * screen_coord.y;
    vel_3d.z = 0.0;
    vel_3d *= 0.002;
    color.xyz = vel_3d;
#elif defined(APPLY_MOTION_BLUR)
    vec3 vel = texture( tex2, tex).rgb * motion_blur_mult;
    float depth = DistFromDepth(texture( tex1, tex).r);
    vec4 noise = texture( tex3, gl_FragCoord.xy / 256.0 );
    float dist;
    vec3 dominant_dir = texture( tex4, tex).rgb * motion_blur_mult;
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
        float weight = 1.0;
        if(coord[0] >= 0.0 && coord[0] <= 1.0 && coord[1] >= 0.0 && coord[1] <= 1.0){
        } else {
            weight *= 0.0001;   
        }
        vec3 sample_vel = texture( tex2, coord).rgb * motion_blur_mult;
        if(abs(offset_amount) < length(sample_vel) || i == num_samples/2){
            float sample_depth = DistFromDepth(texture( tex1, coord).r);
            if(sample_depth < depth + 0.1 || i == num_samples/2){
                color += texture( tex0, coord) * weight;
                total += weight;
            }
        }
    }
    color /= float(total);
    //color.xyz = abs(texture( tex2, tex).rgb);
#else
    color = texture( tex0, tex );

    //#define DARK_WORLD_TEST
    #ifdef DARK_WORLD_TEST
        // Average grayscale method
        //float avg = (color[0] + color[1] + color[2]) / 3.0;
        //color.xyz = mix(color.xyz, vec3(avg), sin(time)*0.5+0.5);
        
        float dark_world_amount = sin(time)*0.5+0.5;
        // Luminosity grayscale method
        float avg = 0.21*color[0] + 0.72*color[1] + 0.07*color[2];
        color.xyz = mix(color.xyz, vec3(avg), dark_world_amount);

    #endif

    //vec2 buf = vec2(screen_width, screen_height);
    //color = FXAA(tex0, tex, buf);
#endif
}