#ifndef LIGHTING_GLSL
#define LIGHTING_GLSL

float GetDirectContribSimple( float amount ) {
    return amount * gl_LightSource[0].diffuse.a;
}

float GetDirectContrib( const vec3 light_pos,
                        const vec3 normal, 
                        const float unshadowed ) {
    float direct_contrib;
    direct_contrib = max(0.0,dot(light_pos, normal));
    direct_contrib *= unshadowed;
    return GetDirectContribSimple(direct_contrib);
}

vec3 UnpackObjNormal(const vec4 normalmap) {
    return normalize(vec3(2.0,2.0,-2.0)*normalmap.xzy + vec3(-1.0,-1.0,1.0));
    /*x = 2.0 * nm.x - 1.0
    y = 2.0 * nm.z - 1.0
    z = -2.0 * nm.y + 1.0    
    
    nm.x = 0.5 * x + 0.5
    nm.y = -0.5 * z + 0.5
    nm.z = 0.5 * y + 0.5*/
}

vec3 UnpackObjNormalV3(const vec3 normalmap) {
    return normalize(vec3(2.0,2.0,-2.0)*normalmap.xzy + vec3(-1.0,-1.0,1.0));
}



vec3 PackObjNormal(const vec3 normal) {
    return vec3(0.5,-0.5,0.5)*normal.xzy + vec3(0.5,0.5,0.5);
    
}

vec3 UnpackTanNormal(const vec4 normalmap) {
    return normalize(vec3(vec2(2.0,-2.0)*normalmap.xy + vec2(-1.0,1.0),normalmap.z));
}

vec3 GetDirectColor(const float intensity) {
    return gl_LightSource[0].diffuse.xyz * intensity;
}

vec3 LookupCubemap(const mat3 obj2world_mat3, 
                   const vec3 vec, 
                   const samplerCube cube_map) {
    vec3 world_space_vec = obj2world_mat3 * vec;
    world_space_vec.xy *= -1.0;
    return textureCube(cube_map,world_space_vec).xyz;
}

vec3 LookupCubemapMat4(const mat4 obj2world, 
                   const vec3 vec, 
                   const samplerCube cube_map) {
    vec3 world_space_vec = (obj2world * vec4(vec,0.0)).xyz;
    world_space_vec.xy *= -1.0;
    return textureCube(cube_map,world_space_vec).xyz;
}

vec3 LookupCubemapSimple(const vec3 vec, 
                   const samplerCube cube_map) {
    vec3 world_space_vec = vec;
    world_space_vec.xy *= -1.0;
    return textureCube(cube_map,world_space_vec).xyz;
}

float GetAmbientMultiplier() {
    return (1.5-gl_LightSource[0].diffuse.a*0.5);
}

float GetAmbientMultiplierScaled() {
    return GetAmbientMultiplier()/1.5;
}

float GetAmbientContrib (const float unshadowed) {
    float contrib = min(1.0,max(unshadowed * 1.5, 0.5));
    contrib *= GetAmbientMultiplier();
    return contrib;
}

float GetSpecContrib ( const vec3 light_pos,
                       const vec3 normal,
                       const vec3 vertex_pos,
                       const float unshadowed ) {
    vec3 H = normalize(normalize(vertex_pos*-1.0) + normalize(light_pos));
    return min(1.0, pow(max(0.0,dot(normal,H)),10.0)*1.0)*unshadowed*gl_LightSource[0].diffuse.a;
}

float GetSpecContrib ( const vec3 light_pos,
                       const vec3 normal,
                       const vec3 vertex_pos,
                       const float unshadowed,
                       const float pow_val) {
    vec3 H = normalize(normalize(vertex_pos*-1.0) + normalize(light_pos));
    return min(1.0, pow(max(0.0,dot(normal,H)),pow_val)*1.0)*unshadowed*gl_LightSource[0].diffuse.a;
}

float BalanceAmbient ( const float direct_contrib ) {
    return 1.0-direct_contrib*0.2;
}

float GetHazeAmount( in vec3 relative_position ) { 
    float near = 0.1;
    float far = 1000.0;
    float fog_opac = min(1.0,length(relative_position)/far);
    return fog_opac;
}

void AddHaze( inout vec3 color, 
              in vec3 relative_position,
              in samplerCube fog_cube ) { 
    vec3 fog_color = textureCube(fog_cube,relative_position).xyz;
    color = mix(color, fog_color, GetHazeAmount(relative_position));
}

float Exposure() {
    return gl_LightSource[0].ambient.a;
}
/*
float GetAnis(vec3 ws_vertex, vec3 ws_light, vec3 ws_normal){
    vec3 V = normalize(ws_vertex*-1.0);
    vec3 L = normalize(ws_light);
    vec3 N = normalize(ws_normal);
    //vec3 thread = normalize(cross(vec3(0,1,0),L));
    vec3 thread = vec3(0,1,0);
    vec3 T = normalize(thread-dot(thread,N)*N);
    vec3 H = normalize(V + L);
    N = normalize(H - dot(T,H)*T);
    float spec_val = min(1.0, pow(max(0.0,dot(N,H)),100.0)*1.0);
    spec_val *= dot(N,ws_normal);
    spec_val *= max(0.0,min(1.0,dot(ws_normal,L)*10.0));
    return spec_val;
}*/

float GammaCorrectFloat(in float val) {
#ifdef GAMMA_CORRECT
    return pow(val,2.2);
#else
    return val;
#endif
}

vec3 GammaCorrectVec3(in vec3 val) {
#ifdef GAMMA_CORRECT
    return vec3(pow(val.r,2.2),pow(val.g,2.2),pow(val.b,2.2));
#else
    return val;
#endif
}

vec3 GammaAntiCorrectVec3(in vec3 val) {
#ifdef GAMMA_CORRECT
    return vec3(pow(val.r,1.0/2.2),pow(val.g,1.0/2.2),pow(val.b,1.0/2.2));
#else
    return val;
#endif
}

#endif
