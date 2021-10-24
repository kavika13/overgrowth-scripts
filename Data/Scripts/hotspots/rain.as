void Init() {
}

const float frequency = 0.0005f;
float delay = frequency;
const vec3 initial_velocity(0.0f, -9.0f, 0.0f);
vec3 pos_previous = vec3(0.0);

void Update() {
    vec3 pos = camera.GetPos();
    vec3 scale = vec3(3.0);
    vec3 movement_vec = pos - pos_previous;
    
    delay -= time_step;
    while(delay <= 0.0f){
        vec3 offset;
        offset.x += RangedRandomFloat(-scale.x*2.0f,scale.x*2.0f);
        offset.y += RangedRandomFloat(-scale.y*2.0f,scale.y*2.0f);;
        offset.z += RangedRandomFloat(-scale.z*2.0f,scale.z*2.0f);
        uint32 id = MakeParticle("Data/Particles/rain.xml", pos + offset + movement_vec*20, initial_velocity);
        delay += frequency;
    }
    pos_previous = pos;
}