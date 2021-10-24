void Init() {
}

const float frequency = 0.01f;
float delay = frequency;
float distance_to_spawn = 0.0f;
vec3 pos_previous = vec3(0.0);

void Update() {
    vec3 pos = camera.GetPos();
    float domain_size = 5.0f;
    vec3 scale = vec3(domain_size);
    vec3 movement_vec = pos - pos_previous;

    delay -= time_step;
    while(delay <= 0.0f){
        vec3 offset;
        offset.x += RangedRandomFloat(-scale.x*2.0f,scale.x*2.0f);
        offset.y += RangedRandomFloat(-scale.y*2.0f,scale.y*2.0f);;
        offset.z += RangedRandomFloat(-scale.z*2.0f,scale.z*2.0f);
        uint32 id = MakeParticle("Data/Particles/snow.xml", pos + offset + movement_vec*150, vec3(0.0f, 0.0f, 0.0f));
        delay += frequency;
    }
    pos_previous = pos;
}