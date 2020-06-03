#extension GL_ARB_texture_rectangle : enable

uniform sampler2D tex0;
uniform sampler2DRect tex5;
uniform float size;

float LinearizeDepth(float z)
{
  float n = 0.1; // camera z near
  float f = 1000.0; // camera z far
  float depth = (2.0 * n) / (f + n - z * (f - n));
  return (f-n)*depth + n;
}

void main()
{    
    vec3 color;
    
    vec4 color_tex = texture2D(tex0,gl_TexCoord[0].xy);
    
    color = gl_Color.xyz * color_tex.xyz;

    gl_FragColor = vec4(color,color_tex.a*gl_Color.a);

    float env_depth = LinearizeDepth(texture2DRect(tex5,gl_FragCoord.xy).r);
    float particle_depth = LinearizeDepth(gl_FragCoord.z);
    float depth = env_depth - particle_depth;
    float depth_blend = depth / size * 0.5;
    depth_blend = max(0.0,min(1.0,depth_blend));
    /*if(depth_blend > 0.5 && gl_TexCoord[0].x < 0.55  && gl_TexCoord[0].x > 0.45
                         && gl_TexCoord[0].y < 0.55  && gl_TexCoord[0].y > 0.45){
        depth_blend = 1.0;
    } else {
        discard;
    }*/

    depth_blend *= max(0.0,min(1.0, particle_depth*0.5-0.1));
    
    gl_FragColor = vec4(color,color_tex.a*gl_Color.a*depth_blend);
}