#version 150

uniform sampler2D tex0;
uniform sampler2D tex5;
uniform float size;
uniform vec2 viewport_dims;
uniform vec4 color_tint;

in vec2 tex_coord;

out vec4 out_color;

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
    
    vec4 color_tex = texture(tex0, tex_coord);
    
    color = color_tint.xyz * color_tex.xyz;

    float env_depth = LinearizeDepth(texture(tex5,gl_FragCoord.xy / viewport_dims).r);
    float particle_depth = LinearizeDepth(gl_FragCoord.z);
    float depth = env_depth - particle_depth;
    float depth_blend = depth / size * 0.5;
    depth_blend = max(0.0,min(1.0,depth_blend));
    depth_blend *= max(0.0,min(1.0, particle_depth*0.5-0.1));
    
    out_color = vec4(color * 5.0,color_tex.a*color_tint.a*depth_blend);
}