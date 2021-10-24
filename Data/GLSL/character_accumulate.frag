#version 150
#include "object_frag150.glsl"
#include "object_shared150.glsl"
#include "ambient_tet_mesh.glsl"
#include "decals.glsl"

uniform int tex_width;
uniform int tex_height;
uniform mat4 transform;
uniform sampler2D tex0;
uniform float time;
uniform mat4 fire_decal_matrix[5];
uniform int fire_decal_num;
uniform mat4 water_decal_matrix[5];
uniform int water_decal_num;

#if defined(DRY) || defined(EXPAND) || defined(IGNITE) || defined(EXTINGUISH)
    in vec2 tex_coord;
#else
    in vec2 fur_tex_coord;
    #ifndef DEPTH_ONLY
    in vec3 concat_bone1;
    in vec3 concat_bone2;
    in vec2 tex_coord;
    in vec2 morphed_tex_coord;
    in vec3 world_vert;
    in vec3 orig_vert;
    in vec3 vel;
    #endif
#endif

#pragma bind_out_color
out vec4 out_color;

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
    out_color = texture(tex0, tex_coord);
    #ifdef WATER_CUBE
        out_color.a = 1.0;
        int burn_int = int(out_color.b * 255.0);
        int on_fire = 0;
        if(burn_int > 127){
            on_fire = 1;
        }
        int burnt_amount = burn_int - on_fire * 128;

        if(out_color.g == 1.0){
            out_color.g = 254.0/255.0;
        }

        for(int i=0; i<water_decal_num; ++i){
            mat4 test = inverse(water_decal_matrix[i]);

            vec3 temp = (test * vec4(world_vert, 1.0)).xyz;

            if(temp[0] < -0.5 || temp[0] > 0.5 || temp[1] < -0.5 || temp[1] > 0.5 || temp[2] < -0.5 || temp[2] > 0.5){
            } else {
                out_color.g = 1.0;
                out_color.r = 0.0;
                if(on_fire == 1){
                    on_fire = 0;
                }
            }
        }

        /*
        for(int i=0; i<fire_decal_num; ++i){
            mat4 test = inverse(fire_decal_matrix[i]);

            vec3 temp = (test * vec4(world_vert, 1.0)).xyz;

            if(temp[0] < -0.5 || temp[0] > 0.5 || temp[1] < -0.5 || temp[1] > 0.5 || temp[2] < -0.5 || temp[2] > 0.5){
            } else {
                float fade = max(0.0, (0.5 - length(temp))*8.0)* max(0.0, fractal(temp.xz*7.0)+0.3);
                temp = world_vert * 2.0;
                float fire = abs(fractal(temp.xz*11.0+time*3.0)+fractal(temp.xy*7.0-time*3.0)+fractal(temp.yz*5.0-time*3.0));
                float flame_amount = max(0.0, 0.5 - (fire*0.5 / pow(fade, 2.0))) * 2.0;
                flame_amount += pow(max(0.0, 0.7-fire), 2.0);
                if(flame_amount > 0 && on_fire == 0){
                    on_fire = 1;          
                }
            }
        }*/

        burn_int = on_fire * 128 + burnt_amount;
        out_color.b = float(burn_int)/255.0;


    #endif
    #ifdef DRY
        out_color.g = max(0.0, out_color.g - 1.0/255.0);
        int burn_int = int(out_color.b * 255.0);
        int on_fire = 0;
        if(burn_int > 127){
            on_fire = 1;
        }
        int burnt_amount = burn_int - on_fire * 128;
        if(on_fire == 1){
            //vec3 temp = world_vert * 2.0;
            //float fire = fractal(tex_coord.xy*11.0+vec2(time*1.0, 0.0))+fractal(tex_coord.xy*7.0-time*1.0)+fractal(tex_coord.xy*5.0-vec2(0.0, time*1.0));
            //if(fire > 0.25){
                burnt_amount = min(127, burnt_amount+3);
                /*if(burnt_amount == 127){
                    on_fire = 0;
                }*/
            //}
        }
        burn_int = on_fire * 128 + burnt_amount;
        out_color.b = float(burn_int)/255.0;
        //out_color.b = 0.0;
        /*vec4 test;
        test = texture(tex0, tex_coord + vec2(1.0/float(tex_width), 0.0));
        if(test.a == 1.0){
            out_color.b = max(out_color.b, test.b);
        }
        test = texture(tex0, tex_coord + vec2(0.0, 1.0/float(tex_height)));
        if(test.a == 1.0){
            out_color.b = max(out_color.b, test.b);
        }
        test = texture(tex0, tex_coord - vec2(1.0/float(tex_width), 0.0));
        if(test.a == 1.0){
            out_color.b = max(out_color.b, test.b);
        }
        test = texture(tex0, tex_coord - vec2(0.0, 1.0/float(tex_height)));
        if(test.a == 1.0){
            out_color.b = max(out_color.b, test.b);
        }*/
        //if(out_color.g == 0.0 && tex_coord.x >= 0.9 && tex_coord.y >= 0.9){
        //    out_color.b = min(1.0, out_color.b + 10.0/255.0);
        //}
    #endif
    #ifdef IGNITE
        int burn_int = int(out_color.b * 255.0);
        int on_fire = 0;
        if(burn_int > 127){
            on_fire = 1;
        }
        int burnt_amount = burn_int - on_fire * 128;
        on_fire = 1;
        burn_int = on_fire * 128 + burnt_amount;
        out_color.b = float(burn_int)/255.0;
    #endif
    #ifdef EXTINGUISH
        int burn_int = int(out_color.b * 255.0);
        int on_fire = 0;
        if(burn_int > 127){
            on_fire = 1;
        }
        int burnt_amount = burn_int - on_fire * 128;
        on_fire = 0;
        burn_int = on_fire * 128 + burnt_amount;
        out_color.b = float(burn_int)/255.0;
    #endif
    #ifdef EXPAND // If pixel is blank, fill with non-blank neighbor
        if(out_color.a != 1.0){
            out_color = texture(tex0, tex_coord + vec2(1.0/float(tex_width), 0.0));
        }
        if(out_color.a != 1.0){
            out_color = texture(tex0, tex_coord + vec2(0.0, 1.0/float(tex_height)));
        }
        if(out_color.a != 1.0){
            out_color = texture(tex0, tex_coord - vec2(1.0/float(tex_width), 0.0));
        }
        if(out_color.a != 1.0){
            out_color = texture(tex0, tex_coord - vec2(0.0, 1.0/float(tex_height)));
        }
    #endif
}
