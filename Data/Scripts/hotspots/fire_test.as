void Init() {
}

float delay = 0.0f;

class Particle {
    vec3 pos;
    vec3 vel;
    float heat;
    float spawn_time;
}

int count = 0;

class Ribbon {
    array<Particle> particles;
    vec3 rel_pos;
    vec3 pos;
    float base_rand;
    float spawn_new_particle_delay;
    void Update(float delta_time, float curr_game_time) {
        spawn_new_particle_delay -= delta_time;
        if(spawn_new_particle_delay <= 0.0f){
            Particle particle;
            particle.pos = pos;
            particle.vel = vec3(0.0, 0.0, 0.0);
            particle.heat = RangedRandomFloat(0.5,1.5);
            particle.spawn_time = curr_game_time;
            particles.push_back(particle);
        
            while(spawn_new_particle_delay <= 0.0f){
                spawn_new_particle_delay += 0.1f;
            }
        }
        Object@ obj = ReadObjectFromID(hotspot.GetID());
        vec3 fire_pos = obj.GetTranslation();
        int max_particles = 5;
        if(int(particles.size()) > max_particles){
            for(int i=0; i<max_particles; ++i){
                particles[i].pos = particles[particles.size()-max_particles+i].pos;
                particles[i].vel = particles[particles.size()-max_particles+i].vel;
                particles[i].heat = particles[particles.size()-max_particles+i].heat;
                particles[i].spawn_time = particles[particles.size()-max_particles+i].spawn_time;
            }
            particles.resize(max_particles);
        }
        for(int i=0, len=particles.size(); i<len; ++i){
            particles[i].vel *= pow(0.2f, delta_time);
            particles[i].pos += particles[i].vel * delta_time;
            particles[i].vel += GetWind(particles[i].pos * 5.0f, curr_game_time, 10.0f) * delta_time * 1.0f;
            particles[i].vel += GetWind(particles[i].pos * 30.0f, curr_game_time, 10.0f) * delta_time * 2.0f;
            vec3 rel = particles[i].pos - fire_pos;
            rel[1] = 0.0;
            particles[i].heat -= delta_time * (2.0f + min(1.0f, pow(dot(rel,rel), 2.0)*64.0f)) * 2.0f;
            if(dot(rel,rel) > 1.0){
                rel = normalize(rel);
            }

            particles[i].vel += rel * delta_time * -3.0f * 6.0f;
            particles[i].vel[1] += delta_time * 12.0f;
        }
        /*for(int i=0, len=particles.size()-1; i<len; ++i){
            //DebugDrawLine(particles[i].pos, particles[i+1].pos, ColorFromHeat(particles[i].heat), ColorFromHeat(particles[i+1].heat), _delete_on_update);
            DebugDrawRibbon(particles[i].pos, particles[i+1].pos, ColorFromHeat(particles[i].heat), ColorFromHeat(particles[i+1].heat), flame_width * max(particles[i].heat, 0.0), flame_width * max(particles[i+1].heat, 0.0), _delete_on_update);
        }*/
    }
    void PreDraw(float curr_game_time) {
        int ribbon_id = DebugDrawRibbon(_delete_on_draw);
        const float flame_width = 0.12f;
        for(int i=0, len=particles.size(); i<len; ++i){
            AddDebugDrawRibbonPoint(ribbon_id, particles[i].pos, vec4(particles[i].heat, particles[i].spawn_time + base_rand, curr_game_time + base_rand, 0.0), flame_width);
        }
    }
}

array<Ribbon> ribbons;

vec3 GetWind(vec3 check_where, float curr_game_time, float change_rate) {
    vec3 wind_vel;
    check_where[0] += curr_game_time*0.7f*change_rate;
    check_where[1] += curr_game_time*0.3f*change_rate;
    check_where[2] += curr_game_time*0.5f*change_rate;
    wind_vel[0] = sin(check_where[0])+cos(check_where[1]*1.3f)+sin(check_where[2]*3.0f);
    wind_vel[1] = sin(check_where[0]*1.2f)+cos(check_where[1]*1.8f)+sin(check_where[2]*0.8f);
    wind_vel[2] = sin(check_where[0]*1.6f)+cos(check_where[1]*0.5f)+sin(check_where[2]*1.2f);

    return wind_vel;
}

const int num_ribbons = 4;
int fire_object_id = -1;

float last_game_time = 0.0f;

void Dispose() {
    if(fire_object_id != -1){
        QueueDeleteObjectID(fire_object_id);
    }
}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
        OnEnter(mo);
    } else if(event == "exit"){
        OnExit(mo);
    }
}

void OnEnter(MovementObject @mo) {
    mo.ReceiveMessage("ignite");
}

void OnExit(MovementObject @mo) {
}

void PreDraw(float curr_game_time) {
    float delta_time = curr_game_time - last_game_time;
    if(ribbons.size() == num_ribbons){
        for(int ribbon_index=0; 
            ribbon_index < num_ribbons;
            ++ribbon_index)
        {   
            ribbons[ribbon_index].Update(delta_time, curr_game_time);
            ribbons[ribbon_index].PreDraw(curr_game_time);
        }
        if(ribbons[0].particles.size()>3){
            Object@ fire_obj = ReadObjectFromID(fire_object_id);
            fire_obj.SetTranslation(mix(ribbons[0].particles[3].pos, ribbons[0].particles[2].pos, ribbons[0].spawn_new_particle_delay / 0.1f));
            fire_obj.SetTint(0.2 * vec3(2.0,1.0,0.0)*(2.0 + mix(ribbons[0].particles[3].heat, ribbons[0].particles[2].heat, ribbons[0].spawn_new_particle_delay / 0.1f)));
            fire_obj.SetScale(vec3(10.0f));
        }
    }
    last_game_time = curr_game_time;
}

vec4 ColorFromHeat(float heat){
    if(heat < 0.0){
        return vec4(0.0);
    } else {
        if(heat > 0.5){
            return mix(vec4(2.0, 1.0, 0.0, 1.0), vec4(4.0, 4.0, 0.0, 1.0), (heat-0.5)/0.5);
        } else {
            return mix(vec4(0.0, 0.0, 0.0, 0.0), vec4(2.0, 1.0, 0.0, 1.0), (heat)/0.5);            
        }
    }
}

void Update() {
    Object@ obj = ReadObjectFromID(hotspot.GetID());
    vec3 pos = obj.GetTranslation();
    vec3 scale = obj.GetScale();
    quaternion rot = obj.GetRotation();
    if(ribbons.size() != num_ribbons){
        ribbons.resize(num_ribbons);
        for(int i=0; i<num_ribbons; ++i){
            ribbons[i].rel_pos = vec3(RangedRandomFloat(-1.0f, 1.0f), 0.0f, RangedRandomFloat(-1.0f,1.0f));
            ribbons[i].base_rand += RangedRandomFloat(0.0f, 100.0f);
            ribbons[i].spawn_new_particle_delay = RangedRandomFloat(0.0f, 0.1f);
        }
    }
    --count;
    for(int ribbon_index=0; 
        ribbon_index < num_ribbons;
        ++ribbon_index)
    {
        ribbons[ribbon_index].pos = pos + rot*vec3(ribbons[ribbon_index].rel_pos[0]*scale[0],scale[1]*2.0,ribbons[ribbon_index].rel_pos[2]*scale[2]);
    }
    if(count <= 0){
        count = 10;
    }
    delay -= time_step;

    if(delay <= 0.0f){
        for(int i=0; i<1; ++i){
            uint32 id = MakeParticle("Data/Particles/firespark.xml", ribbons[int(RangedRandomFloat(0, num_ribbons-0.01))].pos, vec3(RangedRandomFloat(-2.0f, 2.0f), RangedRandomFloat(5.0f, 10.0f), RangedRandomFloat(-2.0f, 2.0f)), vec3(1.0f));
        }
        delay += RangedRandomFloat(0.0f, 0.6f);
    }
    if(fire_object_id == -1){
        fire_object_id = CreateObject("Data/Objects/default_light.xml", true);
    }
}