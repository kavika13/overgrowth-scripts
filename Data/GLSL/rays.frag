uniform sampler2D tex0;
uniform float time;

varying vec3 light_vertex;
varying vec3 vertex;

void main()
{    
    vec3 color;
    vec3 dir = normalize(vertex);
    vec3 light_dir = normalize(light_vertex);
    float brightness = 1.5-length(light_dir.xy)*4.0;
    
    if(brightness>0.0){
        vec2 uv = gl_TexCoord[0].xy;
        
        uv.y = dir.y;
        dir.y = 0.0;
        dir = normalize(dir);
        uv.x =acos(dir.x)/3.1416*2.0;
        if(dir.z<0.0)uv.x*=-1.0;
        uv.x += time;
        
        uv.x-=0.01;
        uv.y-=0.1;
        
        vec4 cloud_tex = texture2D(tex0,uv)*texture2D(tex0,uv*1.5+vec2(time*-0.5,time*-1.3))*texture2D(tex,uv*2.0+vec2(time*-0.4,time*0.5));
        float cloud_density = min((cloud_tex.a)*20.0,1.0);

        color.xyz = max(brightness-cloud_density,0.0)*gl_LightSource[0].diffuse.xyz;
    }
    else color = vec3(0.0);
    
    gl_FragColor = vec4(color,1.0);
}