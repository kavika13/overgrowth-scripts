#include "interpdirection.as"

bool controlled = false; //True if controlled by a human player
int num_frames; //How many timesteps passed since the last update

vec3 GetVelocityForTarget(const vec3&in start, const vec3&in end, float max_horz, float max_vert, float arc){
    vec3 rel_vec = end - start;
    vec3 rel_vec_flat = vec3(rel_vec.x, 0.0f, rel_vec.z);
    vec3 flat = vec3(xz_distance(start, end), rel_vec.y, 0.0f);
    float min_x_time = flat.x / max_horz;
    float grav = physics.gravity_vector.y;
    if(2*grav*flat.y+max_vert*max_vert <= 0.0f){
        return vec3(0.0f);
    }
    float max_y_time = (sqrt(2*grav*flat.y+max_vert*max_vert) + max_vert)/-grav;
    if(min_x_time > max_y_time){
        return vec3(0.0f);
    }
    float time = mix(min_x_time, max_y_time, arc);
    vec3 flat_vel(flat.x / time,
                  flat.y / time - physics.gravity_vector.y * time * 0.5f,
                  0.0f);
    //Print("Flat vel: "+flat_vel.x+" "+flat_vel.y+"\n");
    vec3 vel = flat_vel.x * normalize(rel_vec_flat) + vec3(0.0f, flat_vel.y, 0.0f);
    //Print("Vel: "+vel.x+" "+vel.y+" "+vel.z+"\n");
    return vel;
}
    
const float _damage_mult = 0.005f;
void Collided(float impulse){
    if(impulse < 5.0f){
        return;
    }
    //Print("Collided: "+impulse+"\n");
    int old_knocked_out = knocked_out;
    TakeDamage(impulse*_damage_mult);
    if(old_knocked_out == _awake && knocked_out == _unconscious){
        string sound = "Data/Sounds/hit/hit_medium_juicy.xml";
        PlaySoundGroup(sound, this_mo.position);
    }
    if(old_knocked_out != _dead && knocked_out == _dead){
        string sound = "Data/Sounds/hit/hit_hard.xml";
        PlaySoundGroup(sound, this_mo.position);
        SetRagdollType(_RGDL_LIMP);
    }
}

void MouseControlJumpTest() {
    vec3 start = camera.GetPos();
    vec3 end = camera.GetPos() + camera.GetMouseRay()*400.0f;
    this_mo.GetSweptSphereCollision(start, end, _leg_sphere_size);
    DebugDrawWireSphere(sphere_col.position, _leg_sphere_size, vec3(0.0f,1.0f,0.0f), _delete_on_update);
    vec3 rel_dist = sphere_col.position - this_mo.position;
    vec3 flat_rd = vec3(rel_dist.x, 0.0f, rel_dist.z);
    vec3 jump_target = sphere_col.position;
    this_mo.SetRotationFromFacing(flat_rd);
    vec3 start_vel = GetVelocityForTarget(this_mo.position, sphere_col.position, _run_speed*1.5f, _jump_vel*1.7f, 0.55f);
    if(start_vel.y != 0.0f){
        bool low_success = false;
        bool med_success = false;
        bool high_success = false;
        const float _success_threshold = 0.1f;
        vec3 end;
        vec3 low_vel = GetVelocityForTarget(this_mo.position, jump_target, _run_speed*1.5f, _jump_vel*1.7f, 0.15f);
        jump_info.jump_start_vel = low_vel;
        JumpTestEq(this_mo.position, jump_info.jump_start_vel, jump_info.jump_path); 
        end = jump_info.jump_path[jump_info.jump_path.size()-1];
        for(int i=0; i<int(jump_info.jump_path.size())-1; ++i){
            DebugDrawLine(jump_info.jump_path[i] - vec3(0.0f, _leg_sphere_size, 0.0f), 
                jump_info.jump_path[i+1] - vec3(0.0f, _leg_sphere_size, 0.0f), 
                vec3(1.0f,0.0f,0.0f), 
                _delete_on_update);
        }
        if(jump_info.jump_path.size() != 0){
            vec3 land_point = jump_info.jump_path[jump_info.jump_path.size()-1];
            DebugDrawWireSphere(land_point, _leg_sphere_size, vec3(1.0f,0.0f,0.0f), _delete_on_update);
            if(distance_squared(land_point, jump_target) < _success_threshold){
                low_success = true;
            }
        } 
        vec3 med_vel = GetVelocityForTarget(this_mo.position, jump_target, _run_speed*1.5f, _jump_vel*1.7f, 0.55f);
        jump_info.jump_start_vel = med_vel;
        JumpTestEq(this_mo.position, jump_info.jump_start_vel, jump_info.jump_path); 
        end = jump_info.jump_path[jump_info.jump_path.size()-1];
        for(int i=0; i<int(jump_info.jump_path.size())-1; ++i){
            DebugDrawLine(jump_info.jump_path[i] - vec3(0.0f, _leg_sphere_size, 0.0f), 
                jump_info.jump_path[i+1] - vec3(0.0f, _leg_sphere_size, 0.0f), 
                vec3(0.0f,0.0f,1.0f), 
                _delete_on_update);
        }
        if(jump_info.jump_path.size() != 0){
            vec3 land_point = jump_info.jump_path[jump_info.jump_path.size()-1];
            DebugDrawWireSphere(land_point, _leg_sphere_size, vec3(1.0f,0.0f,0.0f), _delete_on_update);
            if(distance_squared(land_point, jump_target) < _success_threshold){
                med_success = true;
            }
        } 
        vec3 high_vel = GetVelocityForTarget(this_mo.position, jump_target, _run_speed*1.5f, _jump_vel*1.7f, 1.0f);
        jump_info.jump_start_vel = high_vel;
        JumpTestEq(this_mo.position, jump_info.jump_start_vel, jump_info.jump_path); 
        end = jump_info.jump_path[jump_info.jump_path.size()-1];
        for(int i=0; i<int(jump_info.jump_path.size())-1; ++i){
            DebugDrawLine(jump_info.jump_path[i] - vec3(0.0f, _leg_sphere_size, 0.0f), 
                jump_info.jump_path[i+1] - vec3(0.0f, _leg_sphere_size, 0.0f), 
                vec3(0.0f,1.0f,0.0f), 
                _delete_on_update);
        }
        if(jump_info.jump_path.size() != 0){
            vec3 land_point = jump_info.jump_path[jump_info.jump_path.size()-1];
            DebugDrawWireSphere(land_point, _leg_sphere_size, vec3(0.0f,1.0f,0.0f), _delete_on_update);
            if(distance_squared(land_point, jump_target) < _success_threshold){
                high_success = true;
            }
        }
        jump_info.jump_path.resize(0);

        if(low_success){
            start_vel = low_vel;
        } else if(med_success){
            start_vel = med_vel;
        } else if(high_success){
            start_vel = high_vel;
        } else {
            start_vel = vec3(0.0f);
        }

        if(GetInputPressed("mouse0") && start_vel.y != 0.0f){
            jump_info.StartJump(start_vel, true);
            SetOnGround(false);
        }
    }
}

const float _reset_delay = 4.0f;
float reset_timer = _reset_delay;
void VictoryCheck() {
    if(ThreatsRemaining() <= 0 && ThreatsPossible() > 0){
        reset_timer -= time_step * num_frames;
        if(reset_timer <= 0.0f){
            this_mo.ResetLevel();
            reset_timer = _reset_delay;
        }
    }
    if(knocked_out != _awake){
        reset_timer -= time_step * num_frames;
        if(reset_timer <= 0.0f){
            this_mo.ResetLevel();
            reset_timer = _reset_delay;
        }
    }
}


void UpdateMusic() {
    int threats_remaining = ThreatsRemaining();
    if(threats_remaining == 0){
        PlaySong("ambient-happy");
        return;
    }
    if(target_id != -1 && this_mo.ReadCharacterID(target_id).IsKnockedOut() == _awake){
        PlaySong("combat");
        return;
    }
    PlaySong("ambient-tense");
}

vec3 old_slide_vel;
vec3 new_slide_vel;
float friction = 1.0f;

void Update(bool _controlled, int _num_frames) {
    if(on_ground){
        old_slide_vel = this_mo.velocity;
        this_mo.velocity = new_slide_vel;
    }

    controlled = _controlled;
    num_frames = _num_frames;
    time += time_step;

    if(!controlled && on_ground){
        //MouseControlJumpTest();
    }

    if(controlled){
        VictoryCheck();
        UpdateMusic();
    }


    HandleSpecialKeyPresses();

    UpdateBrain(); //in playercontrol.as or enemycontrol.as
    UpdateState();

    if(controlled){
        UpdateAirWhooshSound();
        ApplyCameraControls();
    }
    
    if(on_ground){
        new_slide_vel = this_mo.velocity;
        float new_friction = this_mo.GetFriction(this_mo.position + vec3(0.0f,_leg_sphere_size * -0.4f,0.0f));
        friction = max(0.01f, friction);
        friction = pow(mix(pow(friction,0.01), pow(new_friction,0.01), 0.05f),100);
        this_mo.velocity = mix(this_mo.velocity, old_slide_vel, pow(1.0f-friction, num_frames));
    }
}


void JumpTest(const vec3&in initial_pos, 
              const vec3&in initial_vel,
              array<vec3>&inout jump_path) 
{
    const float _jump_test_steps = 40.0f;
    jump_path.resize(0);
    vec3 start = initial_pos;
    vec3 end = start;
    vec3 fake_vel = initial_vel;
    for(int i=0; i< 400; ++i){
        for(int j=0; j<_jump_test_steps / num_frames; ++j){
            fake_vel += physics.gravity_vector * time_step * num_frames;
            fake_vel = CheckTerminalVelocity(fake_vel);
            end += fake_vel * time_step * num_frames;
        }
        jump_path.push_back(start);
        this_mo.GetSweptSphereCollision(start,
                                     end,
                                     _leg_sphere_size);
        start = end;
        if(sphere_col.NumContacts() > 0){
            jump_path.push_back(sphere_col.position);
            break;
        }
    }
}

void JumpTestEq(const vec3&in initial_pos, 
                const vec3&in initial_vel,
                array<vec3>&inout jump_path) 
{
    const float _jump_test_steps = 20.0f;
    jump_path.resize(0);
    vec3 start = initial_pos;
    vec3 end = start;
    vec3 flat_vel = vec3(
        sqrt(initial_vel.x*initial_vel.x + initial_vel.z+initial_vel.z),
        initial_vel.y,
        0.0f);
    vec3 flat_dir = vec3(initial_vel.x, 0.0f, initial_vel.z);
    float time = 0.0f;
    float height;
    for(int i=0; i< 400; ++i){
        time += time_step * num_frames * _jump_test_steps;
        height = flat_vel.y * time + 0.5f * physics.gravity_vector.y * time * time;
        end = initial_pos + flat_dir * time;
        end.y += height;
        jump_path.push_back(start);
        this_mo.GetSweptSphereCollision(start,
                                     end,
                                     _leg_sphere_size);
        start = end;
        if(sphere_col.NumContacts() > 0){
            jump_path.push_back(sphere_col.position);
            break;
        }
    }
}

void HandleSpecialKeyPresses() {
    if(GetInputDown("z") && !GetInputDown("ctrl")){
        GoLimp();
    }
    if(GetInputDown("n")){                
        if(state != _ragdoll_state){
            string sound = "Data/Sounds/hit/hit_hard.xml";
            PlaySoundGroup(sound, this_mo.position);
        }
        Ragdoll(_RGDL_INJURED);
    }
    if(GetInputDown("m")){        
        Ragdoll(_RGDL_LIMP);
    }
    if(GetInputDown("x")){        
        knocked_out = _awake;
        block_health = 1.0f;
        temp_health = 1.0f;
        permanent_health = 1.0f;
        recovery_time = 0.0f;
    }

    if(controlled){
        if(GetInputPressed("l")){
            //this_mo.LoadLevel("Data/Levels/DesertFort_IGF.xml");
            this_mo.ResetLevel();
        }
        if(GetInputPressed("v")){
            string sound = "Data/Sounds/voice/torikamal/kill_intent.xml";
            this_mo.ForceSoundGroupVoice(sound, 0.0f);
        }
        if(GetInputPressed("1")){    
            SwitchCharacter("Data/Characters/guard.xml");
        }
        if(GetInputPressed("2")){
            SwitchCharacter("Data/Characters/guard2.xml");
        }
        if(GetInputPressed("3")){
            SwitchCharacter("Data/Characters/turner.xml");
        }
        if(GetInputPressed("4")){
            SwitchCharacter("Data/Characters/civ.xml");
        }
        if(GetInputPressed("5")){
            SwitchCharacter("Data/Characters/wolf.xml");
        }
        if(GetInputPressed("6")){
            SwitchCharacter("Data/Characters/rabbot.xml");
        }
        if(GetInputPressed("b")){
            this_mo.AddLayer("Data/Animations/r_bow.anm",4.0f,0);
        }
    }
    if(GetInputPressed("p") && target_id != -1){
        Print("Getting path");
        NavPath temp = this_mo.GetPath(this_mo.position,
                                        this_mo.ReadCharacterID(target_id).position);
        int num_points = temp.NumPoints();
        for(int i=0; i<num_points-1; i++){
            DebugDrawLine(temp.GetPoint(i),
                          temp.GetPoint(i+1),
                          vec3(1.0f,1.0f,1.0f),
                          _persistent);
        }
    }
}

vec3 CheckTerminalVelocity(const vec3&in velocity){
    const float _terminal_velocity = 50.0f;
    const float _terminal_velocity_sqrd = _terminal_velocity*_terminal_velocity;
    if(length_squared(velocity) > _terminal_velocity_sqrd){
        return velocity * pow(0.99f,num_frames);
    } 
    return velocity;
}

// States are used to differentiate between various widely different situations
const int _movement_state = 0; // character is moving on the ground
const int _ground_state = 1; // character has fallen down or is raising up, ATM ragdolls handle most of this
const int _attack_state = 2; // character is performing an attack
const int _hit_reaction_state = 3; // character was hit or dealt damage to and has to react to it in some manner
const int _ragdoll_state = 4; // character is falling in ragdoll mode
int state = _movement_state;

void UpdateState() {
    UpdateHeadLook();
    UpdateBlink();
    UpdateEyeLook();

    UpdateActiveBlock();
    RegenerateHealth();

     if(state == _ragdoll_state){ // This is not part of the else chain because
        UpdateRagDoll();         // the character may wake up and need other
        HandlePickUp();          // state updates
    } 
    
    if(state == _movement_state){
        UpdateDuckAmount();
        UpdateGroundAndAirTime();
        HandleAccelTilt();
        UpdateMovementControls();
        UpdateAnimation();
        ApplyPhysics();
        HandlePickUp();
        HandleGroundCollision();
    } else if(state == _ground_state){
        HandleAccelTilt();
        UpdateGroundState();
    } else if(state == _attack_state){
        HandleAccelTilt();
        UpdateAttacking();
        HandleGroundCollision();
    } else if(state == _hit_reaction_state){
        UpdateHitReaction();
        HandleAccelTilt();
        HandleGroundCollision();
    }

    if(!controlled && state != _ragdoll_state){
        HandleCollisionsBetweenCharacters();
    }
    this_mo.velocity = CheckTerminalVelocity(this_mo.velocity);   

    UpdateTilt();
    
    if(on_ground && state == _movement_state){
        DecalCheck();
    }
    left_smear_time += time_step * num_frames;
    right_smear_time += time_step * num_frames;
    smear_sound_time += time_step * num_frames;
}

vec3 target_tilt(0.0f);
vec3 tilt(0.0f);

void UpdateTilt() {
    const float _tilt_inertia = 0.9f;
    tilt = tilt * pow(_tilt_inertia,num_frames) +
           target_tilt * (1.0f - pow(_tilt_inertia,num_frames));
    this_mo.SetTilt(tilt);
}

vec3 head_dir;
vec3 target_head_dir;

void UpdateHeadLook() {
    const float _target_look_threshold = 7.0f; // How close target must be to look at it
    const float _target_look_threshold_sqrd = 
        _target_look_threshold * _target_look_threshold;
    const float _head_inertia = 0.8f;

    bool look_at_target = false;
    vec3 target_dir;
    if(target_id != -1){
        vec3 target_pos = this_mo.ReadCharacterID(target_id).position;
        if(distance_squared(this_mo.position,target_pos) < _target_look_threshold_sqrd){
            look_at_target = true;
            target_dir = normalize(target_pos - this_mo.position);
        }
    }
    if(controlled){
        if(!look_at_target){
            target_head_dir = camera.GetFacing();
        } else {
            target_head_dir = target_dir;
        }
    } else {
        if(!look_at_target){
            target_head_dir = this_mo.GetFacing();
        } else {
            target_head_dir = target_dir;
        }
    }

    head_dir = normalize(mix(target_head_dir, head_dir, _head_inertia));
    this_mo.SetIKTargetOffset("head",head_dir);
}

vec3 eye_dir; // Direction eyes are looking
vec3 target_eye_dir; // Direction eyes want to look
float eye_delay = 0.0f; // How much time until the next eye dir adjustment

void UpdateEyeLook(){
    const float _eye_inertia = 0.85f;
    const float _eye_min_delay = 0.5f; //Minimum time before changing eye direction
    const float _eye_max_delay = 2.0f; //Maximum time before changing eye direction

    if(eye_delay <= 0.0f){
        eye_delay = RangedRandomFloat(_eye_min_delay,_eye_max_delay);
        target_eye_dir.x = RangedRandomFloat(-1.0f, 1.0f);        
        target_eye_dir.y = RangedRandomFloat(-1.0f, 1.0f);        
        target_eye_dir.z = RangedRandomFloat(-1.0f, 1.0f);    
        normalize(target_eye_dir);
    }
    eye_delay -= time_step * num_frames;
    eye_dir = normalize(mix(target_eye_dir, eye_dir, _eye_inertia));

    // Set weights for carnivore
    this_mo.SetMorphTargetWeight("look_r",max(0.0f,eye_dir.x),1.0f);
    this_mo.SetMorphTargetWeight("look_l",max(0.0f,-eye_dir.x),1.0f);
    this_mo.SetMorphTargetWeight("look_u",max(0.0f,eye_dir.y),1.0f);
    this_mo.SetMorphTargetWeight("look_d",max(0.0f,-eye_dir.y),1.0f);

    // Set weights for herbivore
    this_mo.SetMorphTargetWeight("look_u",max(0.0f,eye_dir.y),1.0f);
    this_mo.SetMorphTargetWeight("look_d",max(0.0f,-eye_dir.y),1.0f);
    this_mo.SetMorphTargetWeight("look_f",max(0.0f,eye_dir.z),1.0f);
    this_mo.SetMorphTargetWeight("look_b",max(0.0f,-eye_dir.z),1.0f);

    // Set weights for independent-eye herbivore
    this_mo.SetMorphTargetWeight("look_u_l",max(0.0f,eye_dir.y),1.0f);
    this_mo.SetMorphTargetWeight("look_u_r",max(0.0f,eye_dir.y),1.0f);
    this_mo.SetMorphTargetWeight("look_d_l",max(0.0f,-eye_dir.y),1.0f);
    this_mo.SetMorphTargetWeight("look_d_r",max(0.0f,-eye_dir.y),1.0f);

    float right_front = eye_dir.z;
    float left_front = eye_dir.z;
    this_mo.SetMorphTargetWeight("look_f_r",max(0.0f,right_front),1.0f);
    this_mo.SetMorphTargetWeight("look_b_r",max(0.0f,-right_front),1.0f);
    this_mo.SetMorphTargetWeight("look_f_l",max(0.0f,left_front),1.0f);
    this_mo.SetMorphTargetWeight("look_b_l",max(0.0f,-left_front),1.0f);
}

bool blinking = false;  // Currently in the middle of blinking?
float blink_progress = 0.0f; // Progress from 0.0 (pre-blink) to 1.0 (post-blink)
float blink_delay = 0.0f; // Time until next blink
float blink_amount = 0.0f; // How open eyes currently are
void UpdateBlink() {
    const float _blink_speed = 5.0f;
    const float _blink_min_delay = 1.0f;
    const float _blink_max_delay = 5.0f;

    bool unconscious = (state != _ragdoll_state && ragdoll_type == _RGDL_LIMP);
    if(!unconscious){
        if(blink_delay < 0.0f){
            blink_delay = RangedRandomFloat(_blink_min_delay,
                                            _blink_max_delay);
            blinking = true;
            blink_progress = 0.0f;
        }
        if(blinking){
            blink_progress += time_step * num_frames * 5.0f;
            blink_amount = sin(blink_progress*3.14f);
            if(blink_progress > 1.0f){
                blink_amount = 0.0f;
                blinking = false;
            }
        } else {
            blink_amount = 0.0f;
        }
        blink_delay -= time_step * num_frames;
    } else {
        blink_amount = mix(blink_amount, 1.0f, 0.1f);
    }
    this_mo.SetMorphTargetWeight("wink_r",blink_amount,1.0f);
    this_mo.SetMorphTargetWeight("wink_l",blink_amount,1.0f);
}

bool active_blocking = false;

void UpdateActiveBlock() {
    if(controlled){
        UpdateActiveBlockMechanics();
    } else {
        active_blocking = (rand()%4)==0;
    }
}

float active_block_duration = 0.0f; // How much longer can the active block last
float active_block_recharge = 0.0f; // How long until the active block recharges

void UpdateActiveBlockMechanics() {
    if(WantsToStartActiveBlock()){
        if(active_block_recharge <= 0.0f){
            active_blocking = true;
            active_block_duration = 0.2f;
        }
        active_block_recharge = 0.2f;
    } 
    if(active_blocking){
        active_block_duration -= time_step * num_frames;
        if(active_block_duration <= 0.0f){
            active_blocking = false;
        }
    } else {
        if(active_block_recharge > 0.0f){
            active_block_recharge -= time_step * num_frames;
        }
    }
}

float block_health = 1.0f; // How strong is auto-block? Similar to ssb shield
float temp_health = 1.0f; // Remaining regenerating health until knocked out
float permanent_health = 1.0f; // Remaining non-regenerating health until killed

const int _awake = 0;
const int _unconscious = 1;
const int _dead = 2;
int knocked_out = _awake;

void RegenerateHealth() {
    const float _block_recover_speed = 0.3f;
    const float _temp_health_recover_speed = 0.05f;
    block_health += time_step * _block_recover_speed * num_frames;
    block_health = min(temp_health, block_health);
    temp_health += time_step * _temp_health_recover_speed * num_frames;
    temp_health = min(permanent_health, temp_health);
}

float ragdoll_time; // How long spent in ragdoll mode this time
bool frozen; // Dead or unconscious ragdoll no longer needs to be simulated
bool no_freeze = false; // Freezing is disabled, e.g. for active ragdolls
float injured_mouth_open; // How open mouth is during injured writhe

void UpdateRagDoll() {
    ragdoll_time += time_step * num_frames;
    ragdoll_limp_stun -= time_step * num_frames;
    ragdoll_limp_stun = max(0.0, ragdoll_limp_stun);

    if(!frozen){
        switch(ragdoll_type){
            case _RGDL_FALL:
                SetActiveRagdollFallPose();
                break;
            case _RGDL_INJURED:
                SetActiveRagdollInjuredPose();
                break;
        }
        
        UpdateRagdollDamping();
    }
    
    if(knocked_out == _awake){
        HandleRagdollRecovery();
    }
    /*
    mat4 torso_transform = this_mo.GetAvgIKChainTransform("torso");
    vec3 torso_vec = torso_transform.GetColumn(1);//(torso_transform * vec4(0.0f,0.0f,1.0f,0.0));
    //Print(""+torso_vec.x +" "+torso_vec.y+" "+torso_vec.z+"\n");
    DebugDrawLine(this_mo.position,
                  this_mo.position + torso_vec,
                  vec3(1.0f),
                  _delete_on_update);
    torso_vec = torso_transform.GetColumn(2);//(torso_transform * vec4(0.0f,0.0f,1.0f,0.0));
    //Print(""+torso_vec.x +" "+torso_vec.y+" "+torso_vec.z+"\n");
    DebugDrawLine(this_mo.position,
                  this_mo.position + torso_vec,
                  vec3(1.0f),
                  _delete_on_update);*/
}

float ragdoll_static_time; // How long ragdoll has been stationary

void UpdateRagdollDamping() {
    const float _ragdoll_static_threshold = 0.4f; // Velocity below which ragdoll is considered static

    if(length(this_mo.GetAvgVelocity())<_ragdoll_static_threshold){
        ragdoll_static_time += time_step * num_frames;
    } else {
        ragdoll_static_time = 0.0f;
    }
    
    if(!no_freeze){
        const float damping_mult = 0.5f;
        float damping = min(1.0f,ragdoll_static_time*damping_mult);
        this_mo.SetRagdollDamping(damping);
        if(damping >= 1.0f){
            frozen = true;
        }
    } else {
        this_mo.SetRagdollDamping(0.0f);
    }
}

void SetActiveRagdollFallPose() {
    const float danger_radius = 4.0f;
    vec3 danger_vec;
    this_mo.GetSlidingSphereCollision(this_mo.position, danger_radius * 0.25f); // Create sliding sphere at ragdoll center to detect nearby surfaces
    danger_vec = this_mo.position - sphere_col.adjusted_position;
    danger_vec += normalize(danger_vec) * danger_radius * 0.75f;
    if(sphere_col.NumContacts() == 0){
        this_mo.GetSlidingSphereCollision(this_mo.position, danger_radius * 0.5f); // Create sliding sphere at ragdoll center to detect nearby surfaces
        danger_vec = this_mo.position - sphere_col.adjusted_position;
        danger_vec += normalize(danger_vec) * danger_radius * 0.5f;
    }
    if(sphere_col.NumContacts() == 0){
        this_mo.GetSlidingSphereCollision(this_mo.position, danger_radius); // Create sliding sphere at ragdoll center to detect nearby surfaces
        danger_vec = this_mo.position - sphere_col.adjusted_position;
    }
    float penetration = length(danger_vec);
    float penetration_ratio = penetration / danger_radius;
    float protect_amount = min(1.0f,max(0.0f,penetration_ratio*4.0f-2.0));
    this_mo.SetLayerOpacity(ragdoll_layer_fetal, protect_amount); // How much to try to curl up into a ball

    mat4 torso_transform = this_mo.GetAvgIKChainTransform("torso");
    vec3 torso_vec = torso_transform.GetColumn(1);
    vec3 hazard_dir;
    if(penetration != 0.0f){
        hazard_dir = danger_vec / penetration;
    }
    float front_protect_amount = max(0.0f,dot(torso_vec, hazard_dir) * protect_amount);
    this_mo.SetLayerOpacity(ragdoll_layer_catchfallfront, front_protect_amount); // How much to put arms out front to catch fall

    float ragdoll_strength = length(this_mo.GetAvgVelocity())*0.1f;
    ragdoll_strength = min(0.8f, ragdoll_strength);
    ragdoll_strength = max(0.0f, ragdoll_strength - ragdoll_limp_stun);
    this_mo.SetRagdollStrength(ragdoll_strength);
}

void SetActiveRagdollInjuredPose(){
    const float time_until_death = 12.0f;
    float speed = length(this_mo.GetAvgVelocity());
    float ragdoll_strength = min(1.0f,max(0.2f,2.0f-speed*0.3f));
    ragdoll_strength *= (time_until_death - ragdoll_time)*0.1f;
    ragdoll_strength = min(0.9f, ragdoll_strength);
    ragdoll_strength = max(0.0f, ragdoll_strength - ragdoll_limp_stun);
    this_mo.SetRagdollStrength(ragdoll_strength);

    injured_mouth_open = mix(injured_mouth_open, 
                             sin(time*4.0f)*0.5f+sin(time*6.3f)*0.5f, 
                             ragdoll_strength);
    this_mo.SetMorphTargetWeight("mouth_open",injured_mouth_open,1.0f);

    if(ragdoll_time > time_until_death){
        ragdoll_type = _RGDL_LIMP;
        no_freeze = false;
        ragdoll_static_time = 0.0f;
        this_mo.EnableSleep();
        this_mo.SetRagdollStrength(0.0f);
    }
}

float recovery_time;
void HandleRagdollRecovery() {
    recovery_time -= time_step * num_frames;
    if(recovery_time <= 0.0f){
        bool can_roll = CanRoll();
        if(can_roll){
            WakeUp(_wake_stand);
        } else {
            WakeUp(_wake_fall);
        }
    } else {
        if(WantsToRollFromRagdoll()){
            bool can_roll = CanRoll();
            if(!can_roll){
                WakeUp(_wake_flip);
            } else {
                WakeUp(_wake_roll);
            }
        }
        return;
    }
}


const int _RGDL_NO_TYPE = 3;
const int _RGDL_FALL = 0;
const int _RGDL_LIMP = 1;
const int _RGDL_INJURED = 2;

int ragdoll_type;
int ragdoll_layer_fetal;
int ragdoll_layer_catchfallfront;
float ragdoll_limp_stun;

void SetRagdollType(int type) {
    if(ragdoll_type == type){
        Print("*Setting ragdoll type to "+type+"\n");
        return;
    }
    Print("Setting ragdoll type to "+type+"\n");
    ragdoll_type = type;
    switch(ragdoll_type){
        case _RGDL_LIMP:
            no_freeze = false;
            this_mo.EnableSleep();
            this_mo.SetRagdollStrength(0.0);
            this_mo.StartAnimation("Data/Animations/r_idle.anm",4.0f);
            break;
        case _RGDL_FALL:
            no_freeze = true;
            this_mo.EnableSleep();
            this_mo.SetRagdollStrength(1.0);
            this_mo.StartAnimation("Data/Animations/r_flail.anm",4.0f);
            ragdoll_layer_catchfallfront = 
                this_mo.AddLayer("Data/Animations/r_catchfallfront.anm",4.0f,0);
            ragdoll_layer_fetal = 
                this_mo.AddLayer("Data/Animations/r_fetal.anm",4.0f,0);
            break;
        case _RGDL_INJURED:
            no_freeze = true;
            this_mo.DisableSleep();
            this_mo.SetRagdollStrength(1.0);
            this_mo.StartAnimation("Data/Animations/r_writhe.anm",4.0f);
            //ragdoll_layer_fetal = 
            //    this_mo.AddLayer("Data/Animations/r_grabface.anm",4.0f,0);
            injured_mouth_open = 0.0f;
            break;
    }
}

void Ragdoll(int type){
    const float _ragdoll_recovery_time = 1.0f;
    recovery_time = _ragdoll_recovery_time;
    
    if(state == _ragdoll_state){
        return;
    }
    
    this_mo.Ragdoll();
    SetState(_ragdoll_state);
    ragdoll_static_time = 0.0f;
    ragdoll_time = 0.0f;
    ragdoll_limp_stun = 0.0f;
    frozen = false;
    ragdoll_type = _RGDL_NO_TYPE;
    SetRagdollType(type);
}

void GoLimp() {
    Ragdoll(_RGDL_FALL);
}

void NotifySound(int created_by_id, vec3 pos) {
    if(!listening){
        return;
    }
    if(target_id == -1){
        bool same_team = false;
        character_getter.Load(this_mo.char_path);
        if(character_getter.OnSameTeam(this_mo.ReadCharacterID(created_by_id).char_path) == 1){
            same_team = true;
        }
        if(!same_team){
            target_id = created_by_id;
            last_seen_target_position = pos;
        }
    }
}


// WasBlocked() is executed if this character's attack was blocked by a different character
void WasBlocked() {
    this_mo.SwapAnimation(attack_getter.GetBlockedAnimPath());
    if(attack_getter.GetSwapStance() != attack_getter.GetSwapStanceBlocked()){
        mirrored_stance = !mirrored_stance;
    }
}

const int _miss = 0;
const int _going_to_block = 1;
const int _hit = 2;
const int _block_impact = 3;
const int _invalid = 4;

// Handles what happens if a character was hit.  Includes blocking enemies' attacks, hit reactions, taking damage, going ragdoll and applying forces to ragdoll.
// Type is a string that identifies the action and thus the reaction, dir is the vector from the attacker to the defender, and pos is the impact position.
int WasHit(string type, string attack_path, vec3 dir, vec3 pos, int attacker_id) {
    attack_getter2.Load(attack_path);

    if(type == "grabbed"){
        return WasGrabbed(dir, pos, attacker_id);
    } else if(type == "attackblocked"){
        return BlockedAttack(dir, pos, attacker_id);
    } else if(type == "blockprepare"){
        return PrepareToBlock(dir, pos, attacker_id);
    } else if(type == "attackimpact"){
        return HitByAttack(dir, pos, attacker_id);
    } else {
        return _invalid;
    }
}

int WasGrabbed(const vec3&in dir, const vec3&in pos, int attacker_id){
    if(state == _ragdoll_state){
        return _miss;
    }
    this_mo.position = pos;
    this_mo.SetRotationFromFacing(dir);
    int8 flags = _ANM_MOBILE;
    if(attack_getter2.GetMirrored() == 0){
        flags = flags | _ANM_MIRRORED;
    }
    this_mo.StartAnimation(attack_getter2.GetThrownAnimPath(),1000.0f,flags);
    SetState(_hit_reaction_state);
    hit_reaction_anim_set = true;
    if(!controlled){
        this_mo.PlaySoundGroupVoice("surprise", 0.3f);
        this_mo.PlaySoundGroupVoice("land_hit", 0.6f);
    }
    return _hit;
}

int BlockedAttack(const vec3&in dir, const vec3&in pos, int attacker_id){
    string sound = "Data/Sounds/hit/hit_block.xml";
    PlaySoundGroup(sound, pos);
    MakeParticle("Data/Particles/impactfast.xml",pos,vec3(0.0f));
    MakeParticle("Data/Particles/impactslow.xml",pos,vec3(0.0f));
    TimedSlowMotion(0.1f,0.3f, 0.05f);
    if(controlled){
        camera.AddShake(0.5f);
    }
    return _block_impact;
}

int PrepareToBlock(const vec3&in dir, const vec3&in pos, int attacker_id){
    if(state != _movement_state || !on_ground || flip_info.IsFlipping() ||
       !active_blocking || attack_getter2.GetUnblockable() != 0)
    {
        return _miss;
    }

    reaction_getter.Load(attack_getter2.GetReactionPath());
    SetState(_hit_reaction_state);
    hit_reaction_anim_set = false;
    hit_reaction_event = "blockprepare";

    vec3 flat_dir(dir.x, 0.0f, dir.z);
    flat_dir = normalize(flat_dir) * -1;
    if(length_squared(flat_dir)>0.0f){
        this_mo.SetRotationFromFacing(flat_dir);
    }
    ActiveBlocked();
    return _going_to_block;
}

int HitByAttack(const vec3&in dir, const vec3&in pos, int attacker_id){
    if(target_id == -1){
        target_id = attacker_id;
    }
    if(attack_getter2.GetHeight() == _high && duck_amount > 0.5f){
        return _miss;
    }
    if(controlled){
        camera.AddShake(1.0f);
    } else {
        this_mo.PlaySoundGroupVoice("hit",0.0f);
    }

    if(attack_getter2.GetSpecial() == "legcannon"){
        block_health = 0.0f;
    }
        
    block_health -= attack_getter2.GetBlockDamage();
    block_health = max(0.0f, block_health);

    if(block_health <= 0.0f || state == _attack_state || !on_ground){
        HandleRagdollImpact(dir, pos);
    } else {
        HandlePassiveBlockImpact(dir, pos);
    }
    return _hit;
}

void HandleRagdollImpact(const vec3&in dir, const vec3&in pos){
    MakeParticle("Data/Particles/impactfast.xml",pos,vec3(0.0f));
    MakeParticle("Data/Particles/impactslow.xml",pos,vec3(0.0f));
    float force = attack_getter2.GetForce()*(1.0f-temp_health*0.5f);
    GoLimp();
    ragdoll_limp_stun = 0.9f;

    vec3 impact_dir = attack_getter2.GetImpactDir();
    vec3 right;
    right.x = -dir.z;
    right.z = dir.x;
    right.y = dir.y;
    vec3 impact_dir_adjusted = impact_dir.x * right +
                               impact_dir.z * dir;
    impact_dir_adjusted.y += impact_dir.y;
    this_mo.ApplyForceToRagdoll(impact_dir_adjusted * force, pos);

    block_health = 0.0f;
    TakeDamage(attack_getter2.GetDamage());
    if(knocked_out == _dead){
        string sound = "Data/Sounds/hit/hit_hard.xml";
        PlaySoundGroup(sound, pos);
    } else {
        string sound = "Data/Sounds/hit/hit_medium.xml";
        PlaySoundGroup(sound, pos);
    }
    temp_health = max(0.0f, temp_health);
}

void HandlePassiveBlockImpact(const vec3&in dir, const vec3&in pos){
    string sound = "Data/Sounds/hit/hit_normal.xml";
    PlaySoundGroup(sound, pos);
    MakeParticle("Data/Particles/impactfast.xml",pos,vec3(0.0f));
    MakeParticle("Data/Particles/impactslow.xml",pos,vec3(0.0f));
    
    reaction_getter.Load(attack_getter2.GetReactionPath());
    SetState(_hit_reaction_state);
    hit_reaction_anim_set = false;

    hit_reaction_event = "attackimpact";

    vec3 flat_dir(dir.x, 0.0f, dir.z);
    flat_dir = normalize(flat_dir) * -1;
    if(length_squared(flat_dir)>0.0f){
        this_mo.SetRotationFromFacing(flat_dir);
    }
}

void EndAttack() {
    SetState(_movement_state);
    if(!on_ground){
        flip_info.StartLegCannonFlip(this_mo.GetFacing()*-1.0f, leg_cannon_flip);
    }
}

void EndHitReaction() {
    SetState(_movement_state);
}

void TakeDamage(float how_much){
    const float _permananent_damage_mult = 0.4f;
    temp_health -= how_much;
    permanent_health -= how_much * _permananent_damage_mult;
    if(permanent_health <= 0.0f && knocked_out != _dead){
        knocked_out = _dead;
    }
    if(temp_health <= 0.0f && knocked_out == _awake){
        knocked_out = _unconscious;
        TimedSlowMotion(0.1f,0.7f, 0.05f);
        if(!controlled){
            this_mo.PlaySoundGroupVoice("death",0.4f);
        }
    }
}

// whether the character is in the ground or in the air, and how long time has passed since the status changed. 
bool on_ground = false;

const float _duck_speed_mult = 0.5f;

const float _ground_normal_y_threshold = 0.5f;
const float _leg_sphere_size = 0.45f; // affects the size of a sphere collider used for leg collisions
const float _bumper_size = 0.5f;

const float _run_speed = 8.0f; // used to calculate movement and jump velocities, change this instead of max_speed
float max_speed = _run_speed; // this is recalculated constantly because actual max speed is affected by slopes

const float _tilt_transition_vel = 8.0f;

vec3 ground_normal(0,1,0);

// feet are moving if character isn't standing still, defined by targetvelocity being larger than 0.0 in UpdateGroundMovementControls()
bool feet_moving = false;
float getting_up_time;

int run_phase = 1;

string hit_reaction_event;

bool attack_animation_set = false;
bool hit_reaction_anim_set = false;
bool attacking_with_throw;

const float _attack_range = 1.6f;
const float _close_attack_range = 1.0f;

// running and movement
const float _run_threshold = 0.8f; // when character is moving faster than this, it runs
const float _walk_threshold = 0.6f; // when character is moving slower than this, it's idling
const float _walk_accel = 35.0f; // how fast characters accelerate when moving

const float _roll_speed = 2.0f;
const float _roll_accel = 50.0f;
const float _roll_ground_speed = 12.0f;
vec3 roll_direction;

float leg_cannon_flip;


// center of mass offset that will eventually be used for animation, but is probably used yet.
vec3 com_offset;
vec3 com_offset_vel;

bool mirrored_stance = false;

vec3 old_vel;
vec3 last_col_pos;

float cancel_delay;

string curr_attack; 
int target_id = -1;
int self_id;

bool holding_weapon = false;
int weapon_id = -1;

vec3 last_seen_target_position;
vec3 last_seen_target_velocity;


// Animation events are created by the animation files themselves. For example, when the run animation is played, it calls HandleAnimationEvent( "leftrunstep", left_foot_pos ) when the left foot hits the ground.
void HandleAnimationEvent(string event, vec3 world_pos){
    HandleAnimationMaterialEvent(event, world_pos);
    HandleAnimationCombatEvent(event, world_pos);
    //DebugDrawText(world_pos, event, _persistent);
}

void HandleAnimationMaterialEvent(const string&in event, const vec3&in world_pos) {
    if(event == "leftstep" ||
       event == "leftwalkstep" ||
       event == "leftwallstep" ||
       event == "leftrunstep" ||
       event == "leftcrouchwalkstep")
    {
        //this_mo.MaterialDecalAtBone("step", "left_leg");
        this_mo.MaterialParticleAtBone("step","left_leg");
    }

    if(event == "rightstep" ||
       event == "rightwalkstep" ||
       event == "rightwallstep" ||
       event == "rightrunstep" ||
       event == "rightcrouchwalkstep")
    {
        //this_mo.MaterialDecalAtBone("step", "right_leg");
        this_mo.MaterialParticleAtBone("step","right_leg");
    }
    
    if(event == "leftstep" || event == "rightstep" ||
       event == "leftwallstep" || event == "rightwallstep" ||
       event == "leftrunstep" || event == "rightrunstep" ||
       event == "leftwalkstep" || event == "rightwalkstep" ||
       event == "leftcrouchwalkstep" || event == "rightcrouchwalkstep")
    {
        this_mo.MaterialEvent(event, world_pos);
    }
}

void HandleAnimationCombatEvent(const string&in event, const vec3&in world_pos) {
    if(event == "golimp"){
        //if(attack_getter2.IsThrow() == 1){
        //    TakeDamage(attack_getter2.GetDamage());
        //}
        GoLimp();
    }

    bool attack_event = false;
    if(event == "attackblocked" ||
        event == "attackimpact" ||
        event == "blockprepare")
    {
        attack_event = true;
    }
    if(attack_event == true && target_id != -1){
        vec3 target_pos = this_mo.ReadCharacterID(target_id).position;
        if(distance(this_mo.position, target_pos) < _attack_range){
            vec3 facing = this_mo.GetFacing();
            vec3 facing_right = vec3(-facing.z, facing.y, facing.x);
            vec3 dir = normalize(target_pos - this_mo.position);
            int return_val = this_mo.ReadCharacterID(target_id).WasHit(
                   event, attack_getter.GetPath(), dir, world_pos, this_mo.getID());
            if(return_val == _going_to_block){
                WasBlocked();
            }
            if((return_val == _hit || return_val == _block_impact) && controlled){
                camera.AddShake(0.5f);
            }
            if(return_val != _miss && attack_getter.GetSpecial() == "legcannon"){
                this_mo.velocity += dir * -10.0f;
            }
            if(event == "frontkick"){
                if(distance(this_mo.position, target_pos) < 1.0f){
                    vec3 dir = normalize(target_pos - this_mo.position);
                    this_mo.ReadCharacterID(target_id).position = 
                        this_mo.position + dir;
                }
            }
            /*if((return_val == _hit) && !controlled){
                if(rand()%2==0){
                    string sound = "Data/Sounds/voice/torikamal/hit_taunt.xml";
                    this_mo.PlaySoundGroupVoice(sound,0.2f);
                }
            }*/
        }
    }
}

#include "aircontrols.as"

// remove Y component, the up component, from a vector. 
vec3 flatten(vec3 vec){
    return vec3(vec.x,0.0,vec.z);
}

vec3 WorldToGroundSpace(vec3 world_space_vec){
    vec3 right = normalize(cross(ground_normal,vec3(0,0,1)));
    vec3 front = normalize(cross(right,ground_normal));
    vec3 ground_space_vec = right * world_space_vec.x +
                            front * world_space_vec.z +
                            ground_normal * world_space_vec.y;
    return ground_space_vec;
}

// Pre-jump happens after jump key is pressed and before the character gets upwards velocity. The time available for the jump animation that happens on the ground. 
bool pre_jump = false;
float pre_jump_time;

// WantsToDoSomething functions are called by the player or the AI in playercontrol.as or enemycontrol.as
// For the player, they return true when the appopriate control key is down.
void UpdateGroundMovementControls() {
    vec3 target_velocity = GetTargetVelocity(); // GetTargetVelocity() is defined in enemycontrol.as and playercontrol.as. Player target velocity depends on the camera and controls, AI's on player's position.
    if(length_squared(target_velocity)>0.0f){
        feet_moving = true;
    }

    // target_duck_amount is used in UpdateDuckAmount() 
    if(WantsToCrouch()){
        target_duck_amount = 1.0f;
    } else {
        target_duck_amount = 0.0f;
    }
    
    if(WantsToRoll() && length_squared(target_velocity)>0.2f){
        // flip_info handles actions in the air, including jump flips
        if(!flip_info.IsFlipping()){
            flip_info.StartRoll(target_velocity);
        }
    }

    // If the characters has been touching the ground for longer than _jump_threshold_time and isn't already jumping, update variables 
    // Actual jump is activated after the if(pre_jump) clause below.
    if(WantsToJump() && on_ground_time > _jump_threshold_time && !pre_jump){
        pre_jump = true;
        const float _pre_jump_delay = 0.04f; // the time between a jump being initiated and the jumper getting upwards velocity, time available for pre-jump animation
        pre_jump_time = _pre_jump_delay;
        duck_vel = 30.0f * (1.0f-duck_amount * 0.6f); // The character crouches down, getting ready for the jump
        vec3 target_jump_vel = jump_info.GetJumpVelocity(target_velocity);
        target_tilt = vec3(target_jump_vel.x, 0, target_jump_vel.z)*2.0f;
    }

    // Preparing for the jump
    if(pre_jump){
        if(pre_jump_time <= 0.0f && !flip_info.IsFlipping()){
            jump_info.StartJump(target_velocity, false);
            //jump_info.StartJump(jump_info.jump_start_vel, true);
            SetOnGround(false);
            pre_jump = false;
        } else {
            pre_jump_time -= time_step * num_frames;
        }
    }
    
    vec3 flat_ground_normal = ground_normal;
    flat_ground_normal.y = 0.0f;
    float flat_ground_length = length(flat_ground_normal);
    flat_ground_normal = normalize(flat_ground_normal);
    if(flat_ground_length > 0.9f){
        if(dot(target_velocity, flat_ground_normal)<0.0f){
            target_velocity -= dot(target_velocity, flat_ground_normal) *
                               flat_ground_normal;
        }
    }
    if(flat_ground_length > 0.6f){
        if(dot(this_mo.velocity, flat_ground_normal)>-0.8f){
            target_velocity -= dot(target_velocity, flat_ground_normal) *
                               flat_ground_normal;
            target_velocity += flat_ground_normal * flat_ground_length;
            feet_moving = true;
        }
        if(length(target_velocity)>1.0f){
            target_velocity = normalize(target_velocity);
        }
    }

    vec3 adjusted_vel = WorldToGroundSpace(target_velocity);

    // Adjust speed based on ground slope
    max_speed = _run_speed;
    float curr_speed = length(this_mo.velocity);

    max_speed *= 1.0 - adjusted_vel.y;
    max_speed = max(curr_speed * 0.98f, max_speed);

    float speed = _walk_accel * run_phase;
    speed = mix(speed,speed*_duck_speed_mult,duck_amount);

    this_mo.velocity += adjusted_vel * time_step * num_frames * speed;
}

// Draws a sphere on the position of the bone's IK target. Useful for understanding what the IK targets do, or are supposed to do.
// Useful strings:  leftarm, rightarm, left_leg, right_leg
void DrawIKTarget(string str) {
    vec3 pos = this_mo.GetIKTargetPosition(str);
    DebugDrawWireSphere(pos,
                        0.1f,
                        vec3(1.0f),
                        _delete_on_draw);
}

// sets IK target and draws a debugging line between the old and new positions of the IK target.
void MoveIKTarget(string str, vec3 offset) {
    vec3 pos = this_mo.GetIKTargetPosition(str);
    DebugDrawLine(pos,
                  pos+offset,
                  vec3(1.0f),
                  _delete_on_draw);
    this_mo.SetIKTargetOffset(str, offset);

}

void draw() {
    this_mo.DrawBody();
}

void ForceApplied(vec3 force) {
}

int IsKnockedOut() {
    return knocked_out;
}

float GetTempHealth() {
    return temp_health;
}

// Executed only when the  character is in _movement_state. Called by UpdateGroundControls() 
void UpdateGroundAttackControls() {
    if(WantsToAttack()||WantsToThrowEnemy()){
        TargetClosest();
    }
    if(target_id == -1){
        return;
    }
    if(WantsToAttack() && distance(this_mo.position,this_mo.ReadCharacterID(target_id).position) <= _attack_range){
        SetState(_attack_state);
        //Print("Starting attack\n");
        attack_animation_set = false;
        attacking_with_throw = false;
        if(!controlled){
            this_mo.PlaySoundGroupVoice("attack",0.0f);
        }

        /*if(target.GetTempHealth() <= 0.4f && target.IsKnockedOut()==0){
            TimedSlowMotion(0.2f,0.4f, 0.15f);
        }*/
    } else if(WantsToThrowEnemy() && distance(this_mo.position,this_mo.ReadCharacterID(target_id).position) <= _attack_range){
        SetState(_attack_state);
        //Print("Starting attack\n");
        attack_animation_set = false;
        attacking_with_throw = true;
        /*if(target.GetTempHealth() <= 0.4f && target.IsKnockedOut()==0){
            TimedSlowMotion(0.2f,0.4f, 0.15f);
        }*/
    }
}

void UpdateAirAttackControls() {
    if(WantsToAttack()){
        TargetClosest();
    }
    if(target_id == -1){
        return;
    }
    if(WantsToAttack() && !flip_info.IsFlipping() &&
        distance(this_mo.position + this_mo.velocity * 0.3f,
                 this_mo.ReadCharacterID(target_id).position + this_mo.ReadCharacterID(target_id).velocity * 0.3f) <= _attack_range)
    {
        SetState(_attack_state);
        attack_animation_set = false;
        attacking_with_throw = false;
    }
}

// Executed only when the  character is in _movement_state.  Called by UpdateMovementControls() .
void UpdateGroundControls() {
    UpdateGroundAttackControls();
    UpdateGroundMovementControls();
}

vec3 accel_tilt;

// handles tilting caused by accelerating when moving on the ground.
void HandleAccelTilt() {
    if(on_ground){
        if(feet_moving && state == _movement_state){
            target_tilt = this_mo.velocity * 0.5f;
            accel_tilt = mix((this_mo.velocity - old_vel)*120.0f/num_frames, accel_tilt, pow(0.95f,num_frames));
        } else {
            target_tilt = vec3(0.0f);
            accel_tilt *= pow(0.8f,num_frames);
        }
        target_tilt += accel_tilt;
        target_tilt.y = 0.0f;
        old_vel = this_mo.velocity;
    } else {
        accel_tilt = vec3(0.0f);
        old_vel = vec3(0.0f);
    }
}

// Executed only when the  character is in _movement_state.  Called from the update() function.
void UpdateMovementControls() {
    if(on_ground){ 
        if(!flip_info.HasControl()){
            UpdateGroundControls();
        }
        flip_info.UpdateRoll();
    } else {
        jump_info.UpdateAirControls();
        UpdateAirAttackControls();
        if(jump_info.ClimbedUp()){
            SetOnGround(true);
            duck_amount = 1.0f;
            duck_vel = 2.0f;
            target_duck_amount = 1.0f;
            this_mo.StartAnimation(character_getter.GetAnimPath("idle"),20.0f);
            HandleBumperCollision();
            HandleStandingCollision();
            this_mo.position = sphere_col.position;
            this_mo.velocity = vec3(0.0f);
            feet_moving = false;
            this_mo.MaterialEvent("land_soft", this_mo.position);
            //string path = "Data/Sounds/concrete_foley/bunny_jump_land_soft_concrete.xml";
            //this_mo.PlaySoundGroupAttached(path, this_mo.position);
        } else {
            flip_info.UpdateFlip();
            
            target_tilt = vec3(this_mo.velocity.x, 0, this_mo.velocity.z)*2.0f;
            if(abs(this_mo.velocity.y)<_tilt_transition_vel && !flip_info.HasFlipped()){
                target_tilt *= pow(abs(this_mo.velocity.y)/_tilt_transition_vel,0.5);
            }
            if(this_mo.velocity.y<0.0f || flip_info.HasFlipped()){
                target_tilt *= -1.0f;
            }
        }
    }
}

// Used when the character starts or stops touching the ground. The timer affects how quickly a character can jump after landing, and other things. 
void SetOnGround(bool _on_ground){
    on_ground_time = 0.0f;
    air_time = 0.0f;
    on_ground = _on_ground;
}

const float vision_threshold = 40.0f;
const float vision_threshold_squared = vision_threshold*vision_threshold;

float GetVisionDistance(const vec3&in target_pos){
    float direct_vision = dot(this_mo.GetFacing(), normalize(target_pos-this_mo.position));
    direct_vision = max(0.0f, direct_vision);
    return direct_vision * vision_threshold;
}

bool IsTargetInFOV(const vec3&in target_pos){
    float dist = GetVisionDistance(target_pos);
    if(distance_squared(this_mo.position, target_pos) > dist*dist){
        return false;
    }
    return true;
}

int ThreatsPossible() {
    int num = this_mo.GetNumCharacters();
    int num_threats = 0;
    for(int i=0; i<num; ++i){
        vec3 target_pos = this_mo.ReadCharacter(i).position;
        if(this_mo.position == target_pos){
            continue;
        }
        if(character_getter.OnSameTeam(this_mo.ReadCharacter(i).char_path) == 0)
        {
            ++num_threats;
        }
    }
    return num_threats;
}

int ThreatsRemaining() {
    int num = this_mo.GetNumCharacters();
    int num_threats = 0;
    for(int i=0; i<num; ++i){
        vec3 target_pos = this_mo.ReadCharacter(i).position;
        if(this_mo.position == target_pos){
            continue;
        }
        if(this_mo.ReadCharacter(i).IsKnockedOut() == _awake &&
           character_getter.OnSameTeam(this_mo.ReadCharacter(i).char_path) == 0)
        {
            ++num_threats;
        }
    }
    return num_threats;
}

void TargetClosest(){
    int num = this_mo.GetNumCharacters();
    int closest_id = -1;
    float closest_dist = 0.0f;

    for(int i=0; i<num; ++i){
        vec3 target_pos = this_mo.ReadCharacter(i).position;
        if(this_mo.position == target_pos){
            continue;
        }
        if(this_mo.ReadCharacter(i).IsKnockedOut() != _awake){
            continue;
        }
        
        character_getter.Load(this_mo.char_path);
        if(character_getter.OnSameTeam(this_mo.ReadCharacter(i).char_path) == 1){
            continue;
        }

        if(!controlled && target_id != this_mo.ReadCharacter(i).getID()){
            if(!IsTargetInFOV(target_pos)){
                continue;
            }
            vec3 head_pos = this_mo.GetAvgIKChainPos("head");
            if(!this_mo.ReadCharacter(i).VisibilityCheck(head_pos)){
                continue;
            }
        }
        
        if(closest_id == -1 || 
           distance_squared(this_mo.position, target_pos) < closest_dist)
       {
           closest_dist = distance_squared(this_mo.position, target_pos);
           closest_id = i;
        }
    }
    if(closest_id != -1){
        if(target_id == -1){
            last_seen_target_position = this_mo.ReadCharacter(closest_id).position;
            last_seen_target_velocity = this_mo.ReadCharacter(closest_id).velocity;
        }
        target_id = this_mo.ReadCharacter(closest_id).getID();
    } else {
        target_id = -1;
    }
    //Print("Targeting character "+closest_id+" aka "+target_id+"\n");
}

void ClearTarget(){
    target_id = -1;
}

// this is called when the character lands in a non-ragdoll mode
void Land(vec3 vel) {
    // this is true when the character initiated a flip during jump and isn't finished yet
    if(flip_info.ShouldRagdollOnLanding()){
        GoLimp();
        return;
    }

    SetOnGround(true);
    
    float land_speed = 10.0f;//min(30.0f,max(10.0f, -vel.y));
    this_mo.StartAnimation(character_getter.GetAnimPath("idle"),land_speed);

    if(dot(this_mo.velocity*-1.0f, ground_normal)>0.3f){
        float slide_amount = 1.0f - (dot(normalize(this_mo.velocity*-1.0f), normalize(ground_normal)));
        //Print("Slide amount: "+slide_amount+"\n");
        //Print("Slide vel: "+slide_amount*length(this_mo.velocity)+"\n");
        this_mo.MaterialEvent("land", this_mo.position - vec3(0.0f,_leg_sphere_size, 0.0f), 1.0f);
        if(slide_amount > 0.0f){
            float slide_vel = slide_amount*length(this_mo.velocity);
            float vol = min(1.0f,slide_amount * slide_vel * 0.2f);
            if(vol > 0.2f){
                this_mo.MaterialEvent("slide", this_mo.position - vec3(0.0f,_leg_sphere_size, 0.0f), vol);
            }
        }
        duck_amount = 1.0;
        target_duck_amount = 1.0;
        duck_vel = land_speed * 0.3f;
    } else {
        this_mo.MaterialEvent("land_soft", this_mo.position - vec3(0.0f,_leg_sphere_size, 0.0f));
        //string path = "Data/Sounds/concrete_foley/bunny_jump_land_soft_concrete.xml";
        //this_mo.PlaySoundGroupAttached(path, this_mo.position);
    }

    if(WantsToCrouch()){
        duck_vel = max(6.0f,duck_vel);
    }

    feet_moving = false;

    flip_info.Land();
    old_slide_vel = this_mo.velocity;
}

const float offset = 0.05f;

vec3 HandleBumperCollision(){
    this_mo.GetSlidingSphereCollision(this_mo.position+vec3(0,0.3f,0), _bumper_size);
    // the value of sphere_col.adjusted_position variable was set by the GetSlidingSphereCollision() called on the previous line.
    this_mo.position = sphere_col.adjusted_position-vec3(0,0.3f,0);
    return (sphere_col.adjusted_position - sphere_col.position);
}

vec3 HandlePiecewiseBumperCollision(vec3 old_pos){
    vec3 new_pos = this_mo.position; 
    vec3 old_new_pos = new_pos;
    old_pos.y += 0.3f;
    new_pos.y += 0.3f;
    vec3 offset;
    vec3 test_pos = mix(old_pos, new_pos, 0.25f);
    this_mo.GetSlidingSphereCollision(test_pos, _bumper_size);
    offset = sphere_col.adjusted_position - sphere_col.position;
    new_pos += offset/0.25f;
    test_pos = mix(old_pos, new_pos, 0.5f);
    this_mo.GetSlidingSphereCollision(test_pos, _bumper_size);
    offset = sphere_col.adjusted_position - sphere_col.position;
    new_pos += offset/0.5f;
    test_pos = mix(old_pos, new_pos, 0.75f);
    this_mo.GetSlidingSphereCollision(test_pos, _bumper_size);
    offset = sphere_col.adjusted_position - sphere_col.position;
    new_pos += offset/0.75f;
    test_pos = mix(old_pos, new_pos, 1.0f);
    this_mo.GetSlidingSphereCollision(test_pos, _bumper_size);
    offset = sphere_col.adjusted_position - sphere_col.position;
    new_pos += offset/1.0f;
    new_pos.y -= 0.3f;
    this_mo.position = new_pos;
    return new_pos - old_new_pos;
}

vec3 HandleSweptBumperCollision(vec3 old_pos){
    vec3 new_pos = this_mo.position; 
    old_pos.y += 0.3f;
    new_pos.y += 0.3f;
    vec3 slide = col.GetSlidingCapsuleCollision(old_pos, new_pos, _bumper_size);
    vec3 offset = slide - new_pos;
    slide.y -= 0.3f;
    // the value of sphere_col.adjusted_position variable was set by the GetSlidingSphereCollision() called on the previous line.
    this_mo.position = slide;
    return offset;
}


bool HandleStandingCollision() {
    vec3 upper_pos = this_mo.position+vec3(0,0.1f,0);
    vec3 lower_pos = this_mo.position+vec3(0,-0.2f,0);
    this_mo.GetSweptSphereCollision(upper_pos,
                                 lower_pos,
                                 _leg_sphere_size);
    return (sphere_col.position == lower_pos);
}

const float _shock_damage_threshold = 30.0f;
const float _shock_damage_multiplier = 0.1f;
void CheckForVelocityShock(float vert_vel) {
    float shock = vert_vel * -1.0f;
    //Print("Velocity shock: "+shock+"\n");
    if(shock > _shock_damage_threshold){
        TakeDamage((shock-_shock_damage_threshold)*_shock_damage_multiplier);
        if(knocked_out == _unconscious){
            Ragdoll(_RGDL_INJURED);
            string sound = "Data/Sounds/hit/hit_hard.xml";
            PlaySoundGroup(sound, this_mo.position);
        } else if(knocked_out == _dead){
            Ragdoll(_RGDL_LIMP);
            string sound = "Data/Sounds/hit/hit_hard.xml";
            PlaySoundGroup(sound, this_mo.position);
        } else {
            string sound = "Data/Sounds/hit/hit_medium_juicy.xml";
            PlaySoundGroup(sound, this_mo.position);
        }
    }
}

void HandleGroundCollision() {
    vec3 air_vel = this_mo.velocity;
    if(on_ground){
        this_mo.velocity += HandleBumperCollision() / (time_step * num_frames);

        if(sphere_col.NumContacts() != 0 && flip_info.ShouldRagdollIntoWall()){
            //GoLimp();    
        }

        if((sphere_col.NumContacts() != 0 ||
            ground_normal.y < _ground_normal_y_threshold)
            && this_mo.velocity.y > 0.2f){
            SetOnGround(false);
            jump_info.StartFall();
        }

        bool in_air = HandleStandingCollision();
        if(in_air){
            SetOnGround(false);
            jump_info.StartFall();
        } else {
            this_mo.position = sphere_col.position;
            /*DebugDrawWireSphere(sphere_col.position,
                                sphere_col.radius,
                                vec3(1.0f,0.0f,0.0f),
                                _delete_on_update);*/
            for(int i=0; i<sphere_col.NumContacts(); i++){
                const CollisionPoint contact = sphere_col.GetContact(i);
                if(distance(contact.position, this_mo.position)<=_leg_sphere_size+0.01f){
                    ground_normal = ground_normal * 0.9f +
                                    contact.normal * 0.1f;
                    ground_normal = normalize(ground_normal);
                    /*DebugDrawLine(sphere_col.position,
                                  sphere_col.position-contact.normal,
                                  vec3(1.0f,0.0f,0.0f),
                                  _delete_on_update);*/
                }
            }/*
            DebugDrawLine(sphere_col.position,
                              sphere_col.position-ground_normal,
                              vec3(0.0f,1.0f,0.0f),
                              _delete_on_update);
            */
            
            if(flip_info.ShouldRagdollIntoSteepGround() &&
               dot(this_mo.GetFacing(),ground_normal) < -0.6f){
                //GoLimp();    
            }
        }
    } else {
        vec3 offset = this_mo.position - last_col_pos; 
        this_mo.position = last_col_pos;
        bool landing = false;
        vec3 landing_normal;
        vec3 old_vel = this_mo.velocity;
        for(int i=0; i<num_frames; ++i){
            if(on_ground){
                break;
            }
            this_mo.position += offset/num_frames;
            this_mo.GetSlidingSphereCollision(this_mo.position, _leg_sphere_size);
            this_mo.position = sphere_col.adjusted_position;
            this_mo.velocity += (sphere_col.adjusted_position - sphere_col.position) / (time_step * num_frames);
            offset += (sphere_col.adjusted_position - sphere_col.position) * (num_frames);
            for(int i=0; i<sphere_col.NumContacts(); i++){
                const CollisionPoint contact = sphere_col.GetContact(i);
                if(contact.normal.y < _ground_normal_y_threshold){
                    jump_info.HitWall(normalize(contact.position-this_mo.position));
                }
            }    
            for(int i=0; i<sphere_col.NumContacts(); i++){
                if(landing){
                    break;
                }
                const CollisionPoint contact = sphere_col.GetContact(i);
                if(contact.normal.y > _ground_normal_y_threshold ||
                   (this_mo.velocity.y < 0.0f && contact.normal.y > 0.2f))
                {
                    if(air_time > 0.1f){
                        landing = true;
                        landing_normal = contact.normal;
                    }
                }
            }
        }
        if(landing){
            CheckForVelocityShock(old_vel.y);
            if(knocked_out == _awake){
                ground_normal = landing_normal;
                Land(air_vel);
                if(state != _ragdoll_state){
                    SetState(_movement_state);
                }
            }
        }
    }
    last_col_pos = this_mo.position;
    /*if(on_ground){
        vec3 y_vec = ground_normal;
        vec3 x_vec = normalize(cross(y_vec,vec3(0,0,1)));
        vec3 z_vec = cross(y_vec, x_vec);
        this_mo.velocity = x_vec * ground_vel.x +
                           y_vec * ground_vel.y +
                           z_vec * ground_vel.z;
    }*/
}

float duck_amount = 0.0f; // duck_amount is changed incrementally to animate crouching or standing up from a crouch
float target_duck_amount = 0.0f; // this is 1.0 when the character crouches down,  0.0 otherwise. Used in UpdateDuckAmount() 
float duck_vel = 0.0f;

void UpdateDuckAmount() { // target_duck_amount is 1.0 when the character should crouch down, and 0.0 when it should stand straight.
    const float _duck_accel = 120.0f;
    const float _duck_vel_inertia = 0.89f;
    duck_vel += (target_duck_amount - duck_amount) * time_step * num_frames * _duck_accel;
    duck_vel *= pow(_duck_vel_inertia,num_frames);
    duck_amount += duck_vel * time_step * num_frames;
}

float air_time = 0.0f;
float on_ground_time = 0.0f;

void UpdateGroundAndAirTime() { // tells how long the character has been touching the ground, or been in the air
    if(on_ground){
        on_ground_time += time_step * num_frames;
    } else {
        air_time += time_step * num_frames;
    }
}

void UpdateAirWhooshSound() { // air whoosh sounds get louder at higher speed.
    float whoosh_amount;
    if(state != _ragdoll_state){
       whoosh_amount = length(this_mo.velocity)*0.05f;
    } else {
       whoosh_amount = length(this_mo.GetAvgVelocity())*0.05f;
    }
    if(state != _ragdoll_state){
        whoosh_amount += flip_info.WhooshAmount();
    }
    float whoosh_pitch = min(2.0f,whoosh_amount*0.5f + 0.5f);
    if(!on_ground){
        whoosh_amount *= 1.5f;
    }
    //Print("Whoosh amount: "+whoosh_amount+"\n");
    SetAirWhoosh(whoosh_amount*0.5f,whoosh_pitch);
}

// called when state equals _attack_state
void UpdateAttacking() {    
    flip_info.UpdateRoll();

    vec3 direction;
    if(target_id != -1){
        direction = this_mo.ReadCharacterID(target_id).position - this_mo.position;
    } else {
        direction = this_mo.GetFacing();
    }
    float attack_distance = length(direction);
    direction.y = 0.0f;
    direction = normalize(direction);
    if(on_ground){
        this_mo.velocity *= pow(0.95f,num_frames);
    } else {
        ApplyPhysics();
    }
    if(attack_animation_set){
        if(attack_getter.IsThrow() == 0){
            this_mo.SetRotationFromFacing(InterpDirections(this_mo.GetFacing(),
                                                           direction,
                                                           1.0-pow(0.9f,num_frames)));
        } else {
            if(target_id != -1){
                this_mo.ReadCharacterID(target_id).velocity = this_mo.velocity;
            }
            //this_mo.ReadCharacter(target_id).position = this_mo.position;
            //this_mo.ReadCharacter(target_id).position -= 
            //    this_mo.ReadCharacter(target_id).GetFacing() * 0.2f;
            //this_mo.ReadCharacter(target_id).SetRotationFromFacing(this_mo.GetFacing());
        }
    }
    vec3 right_direction;
    right_direction.x = direction.z;
    right_direction.z = -direction.x;
    if(!on_ground){
        float leg_cannon_target_flip;
        if(target_id != -1){
            float rel_height = normalize(this_mo.ReadCharacterID(target_id).position - this_mo.position).y;
            leg_cannon_target_flip = -1.4f - rel_height;
        } else {
            leg_cannon_target_flip = -1.4f;
        }
        leg_cannon_flip = mix(leg_cannon_flip, leg_cannon_target_flip, 0.1f);
        this_mo.SetFlip(right_direction,leg_cannon_flip,0.0f);
    }
    
    bool mirrored;
    if(!mirrored_stance){
        // GetTargetVelocitY() is defined in enemycontrol.as and playercontrol.as. Player target velocity depends on the camera and controls, AI's on player's position.
        mirrored = (dot(right_direction, GetTargetVelocity())>0.1f);
    } else {
        mirrored = (dot(right_direction, GetTargetVelocity())>-0.1f);
    }
    // Checks if the character is standing still. Used in ChooseAttack() to see if the character should perform a front kick.
    bool front = //(dot(direction, GetTargetVelocity())>0.7f) || 
                 length_squared(GetTargetVelocity())<0.1f;

    

    if(attack_animation_set &&
       this_mo.GetStatusKeyValue("cancel")>=1.0f && 
       WantsToCancelAnimation())
    {
        if(cancel_delay <= 0.0f){
            EndAttack();
        }
        cancel_delay -= time_step * num_frames;
    } else {
        cancel_delay = 0.01f;
    }

    if(!attack_animation_set){
        // Defined in playercontrol.as and enemycontrol.as. Boolean front tells if the character is standing still, and if it's true a front kick may be performed.
        // ChooseAttack() sets the value of the curr_attack variable.
        string attack_path;
        if(attacking_with_throw){
            attack_path="Data/Attacks/throw.xml";
        } else {
            ChooseAttack(front);
            attack_path;
            if(curr_attack == "stationary"){
                if(attack_distance < _close_attack_range){
                    attack_path = character_getter.GetAttackPath("stationary_close");
                } else {
                    attack_path = character_getter.GetAttackPath("stationary");
                }
            } else if(curr_attack == "moving"){
                if(attack_distance < _close_attack_range){
                    attack_path = character_getter.GetAttackPath("moving_close");
                } else {
                    attack_path = character_getter.GetAttackPath("moving");
                }
            } else if(curr_attack == "low"){
                attack_path = character_getter.GetAttackPath("low");
            } else if(curr_attack == "air"){
                attack_path = character_getter.GetAttackPath("air");
            }
        }
        attack_getter.Load(attack_path);
        if(attack_getter.GetSpecial() == "legcannon"){    
            leg_cannon_flip = 0.0f;
        }

        if(attack_getter.GetDirection() == _left) {
            mirrored = !mirrored;
        }

        bool flipped = false;
        if(attack_getter.GetDirection() != _front) {
            flipped = mirrored;
        } else {
            flipped = !mirrored_stance;
        }
        if(flipped){
            attack_path += " m";
        }
        attack_getter.Load(attack_path);

        if(attack_getter.GetHeight() == _low){
            duck_amount = 1.0f;
        } else {
            duck_amount = 0.0f;
        }
        bool mirror = false;
        if(attack_getter.GetDirection() != _front){
            mirror = mirrored;
            mirrored_stance = mirrored;
        } else {
            mirror = mirrored_stance;
        }

        int8 flags = 0;
        if(attack_getter.GetMobile() == 1){
            flags = flags | _ANM_MOBILE;
        }
        if(mirror){
            flags = flags | _ANM_MIRRORED;
        }
        if(attack_getter.GetFlipFacing() == 1){
            flags = flags | _ANM_FLIP_FACING;
        }


        string anim_path;
        if(attack_getter.IsThrow() == 0){
            anim_path = attack_getter.GetUnblockedAnimPath();
        } else {
            anim_path = attack_getter.GetThrowAnimPath();
            int hit = _miss;
            if(target_id != -1){
                hit = this_mo.ReadCharacterID(target_id).WasHit(
                    "grabbed", attack_getter.GetPath(), direction, this_mo.position, this_mo.getID());        
            }
            if(hit == _miss){
                EndAttack();
                return;
            }
            this_mo.SetRotationFromFacing(direction);
        }

        this_mo.StartAnimation(anim_path, 20.0f, flags);

        string material_event = attack_getter.GetMaterialEvent();
        if(material_event.length() > 0){
            Print(material_event);
            this_mo.MaterialEvent(material_event,
                        this_mo.position-vec3(0.0f,_leg_sphere_size, 0.0f));
        }
        if(attack_getter.GetSwapStance() != 0){
            mirrored_stance = !mirrored_stance;
        }
        this_mo.SetAnimationCallback("void EndAttack()");
        attack_animation_set = true;
    }

    /*float old_attacking_time = attacking_time;
    attacking_time += time_step;
    if(attacking_time > 0.25f && old_attacking_time <= 0.25f){
        target.ApplyForce(direction*20);
        TimedSlowMotion(0.1f,0.7f);
    }*/
}

// the animations referred here are mostly blocks, and they're defined in the character-specific XML files.
void UpdateHitReaction() {
    if(!hit_reaction_anim_set){
        if(hit_reaction_event == "blockprepare"){
            bool right = (attack_getter2.GetDirection() != _left);
            if(attack_getter2.GetMirrored() != 0){
                right = !right;
            }
            if(mirrored_stance){
                right = !right;
            }
            string block_string;
            if(attack_getter2.GetHeight() == _high){
                block_string += "high";
            } else if(attack_getter2.GetHeight() == _medium){
                block_string += "med";
            } else if(attack_getter2.GetHeight() == _low){
                block_string += "low";
            }        
            if(right){
                block_string += "right";
            } else {
                block_string += "left";
            }
            block_string += "block";
            if(mirrored_stance){
                this_mo.StartAnimation(character_getter.GetAnimPath(block_string),40.0f, _ANM_MIRRORED);
            } else {
                this_mo.StartAnimation(character_getter.GetAnimPath(block_string),40.0f);
            }
        } else if(hit_reaction_event == "attackimpact") {
            if(reaction_getter.GetMirrored() == 0){
                this_mo.StartAnimation(reaction_getter.GetAnimPath(1.0f-block_health),20.0f,_ANM_MOBILE);
                mirrored_stance = false;
            } else {
                this_mo.StartAnimation(reaction_getter.GetAnimPath(1.0f-block_health),20.0f,_ANM_MOBILE|_ANM_MIRRORED);
                mirrored_stance = true;
            }
        }
        this_mo.SetAnimationCallback("void EndHitReaction()");
        hit_reaction_anim_set = true;
        this_mo.SetFlip(vec3(1.0f,0.0f,0.0f),0.0f,0.0f);
    }
    this_mo.velocity *= pow(0.95f,num_frames);
    if(this_mo.GetStatusKeyValue("cancel")>=1.0f && WantsToCancelAnimation()){
        EndHitReaction();
    }
}

void SetState(int _state) {
    state = _state;
    if(state == _ground_state){
        //Print("Setting state to ground state");
        if(wake_up_torso_front.y < 0){
            this_mo.SetAnimation("Data/Animations/r_standfromfront.anm", 20.0f, _ANM_MOBILE|_ANM_FLIP_FACING);
        } else {
            this_mo.SetAnimation("Data/Animations/r_standfromback.anm", 20.0f, _ANM_MOBILE);
        }
        this_mo.SetAnimationCallback("void EndGetUp()");
        this_mo.SetRotationFromFacing(normalize(vec3(wake_up_torso_up.x,0.0f,wake_up_torso_up.z))*-1.0f);

        //this_mo.StartAnimation("Data/Animations/kipup.anm");
        /*if(!mirrored_stance){
            this_mo.StartAnimation(character_getter.GetAnimPath("idle"));
        } else {
            this_mo.StartAnimation(character_getter.GetAnimPath("idle"),5.0f,_ANM_MIRRORED);
        }
        this_mo.SetAnimationCallback("void EndGetUp()");
        */
        getting_up_time = 0.0f;    
    }
    if(state != _attack_state){
        curr_attack = "";
    }
}

const int _wake_stand = 0;
const int _wake_flip = 1;
const int _wake_roll = 2;
const int _wake_fall = 3;

vec3 wake_up_torso_up;
vec3 wake_up_torso_front;
float ragdoll_cam_recover_time = 0.0f;
float ragdoll_cam_recover_speed = 1.0f;

// WakeUp is called when a character gets out of the ragdoll mode. 
void WakeUp(int how) {
    mat4 torso_transform = this_mo.GetAvgIKChainTransform("torso");
    wake_up_torso_front = torso_transform.GetColumn(1);
    wake_up_torso_up = torso_transform.GetColumn(2);
    ragdoll_cam_recover_time = 1.0f;

    SetState(_movement_state);
    this_mo.UnRagdoll();
    
    HandleBumperCollision();
    HandleStandingCollision();
    this_mo.position = sphere_col.position;

    // No standing up animations yet
    /*if(how == _wake_stand){
        how = _wake_fall;
    }*/

    duck_amount = 1.0f;
    duck_vel = 0.0f;
    target_duck_amount = 1.0f;
    if(how == _wake_stand){
        SetOnGround(true);
        flip_info.Land();
        SetState(_ground_state);
        ragdoll_cam_recover_speed = 2.0f;
        this_mo.SetRagdollFadeSpeed(4.0f); 
    } else if(how == _wake_fall){
        SetOnGround(true);
        flip_info.Land();
        if(!mirrored_stance){
            this_mo.StartAnimation(character_getter.GetAnimPath("idle"));
        } else {
            this_mo.StartAnimation(character_getter.GetAnimPath("idle"),5.0f,_ANM_MIRRORED);
        }
        ragdoll_cam_recover_speed = 10.0f;
        this_mo.SetRagdollFadeSpeed(10.0f);
    } else if (how == _wake_flip) {
        SetOnGround(false);
        jump_info.StartFall();
        flip_info.StartFlip();
        flip_info.FlipRecover();
        this_mo.StartAnimation(character_getter.GetAnimPath("jump"));
        ragdoll_cam_recover_speed = 100.0f;
        this_mo.SetRagdollFadeSpeed(10.0f);
    } else if (how == _wake_roll) {
        SetOnGround(true);
        flip_info.Land();
        if(!mirrored_stance){
            this_mo.StartAnimation(character_getter.GetAnimPath("idle"));
        } else {
            this_mo.StartAnimation(character_getter.GetAnimPath("idle"),5.0f,_ANM_MIRRORED);
        }
        vec3 roll_dir = GetTargetVelocity();
        vec3 flat_vel = vec3(this_mo.velocity.x, 0.0f, this_mo.velocity.z);
        if(length(flat_vel)>1.0f){
            roll_dir = normalize(flat_vel);
        }
        flip_info.StartRoll(roll_dir);
        ragdoll_cam_recover_speed = 10.0f;
        this_mo.SetRagdollFadeSpeed(10.0f);
    }
}

bool CanRoll() {
    vec3 sphere_center = this_mo.position;
    float radius = 1.0f;
    this_mo.GetSlidingSphereCollision(sphere_center, radius);
    bool can_roll = true;
    vec3 roll_point;
    if(sphere_col.NumContacts() == 0){
        can_roll = false;
    } else {
        can_roll = false;
        roll_point = sphere_col.GetContact(0).position;
        for(int i=0; i<sphere_col.NumContacts(); i++){
            const CollisionPoint contact = sphere_col.GetContact(i);
            if(contact.position.y < roll_point.y){
                roll_point = contact.position;
            }
            if(contact.normal.y > 0.5f){
                can_roll = true;
            }
        }
    }
    return can_roll;
}

int count = 0;

void EndGetUp(){
    state = _movement_state;
    duck_amount = 1.0f;
    duck_vel = 0.0f;
    target_duck_amount = 1.0f;
}

void HandleGroundStateCollision() {
    HandleBumperCollision();
    HandleStandingCollision();
    this_mo.position = sphere_col.position;
    if(sphere_col.NumContacts() == 0){
        this_mo.position.y -= 0.1f;
    }
    for(int i=0; i<sphere_col.NumContacts(); i++){
        const CollisionPoint contact = sphere_col.GetContact(i);
        if(distance(contact.position, this_mo.position)<=_leg_sphere_size+0.01f){
            ground_normal = ground_normal * 0.9f +
                            contact.normal * 0.1f;
            ground_normal = normalize(ground_normal);
        }
    }
}

// Nothing() does nothing.
void Nothing() {
}

// Called only when state equals _ground_state
void UpdateGroundState() {
    this_mo.velocity = vec3(0.0f);
    //this_mo.velocity = GetTargetVelocity() * _walk_accel * 0.15f;
    
    HandleGroundStateCollision();
    getting_up_time += time_step * num_frames;
}

// the main timer of the script, used whenever anything has to know how much time has passed since something else happened.
float time = 0;

// The following variables and function affect the track decals foots make on the ground, when that feature is enabled
const float _smear_time_threshold = 0.3f;
float smear_sound_time = 0.0f;
float left_smear_time = 0.0f;
float right_smear_time = 0.0f;
float _dist_threshold = 0.1f;
vec3 left_decal_pos;
vec3 right_decal_pos;
void DecalCheck(){
    /*DebugDrawWireSphere(left_decal_pos,
                        0.1f,
                        vec3(1.0f),
                        _delete_on_update);*/
    if(!feet_moving || length_squared(this_mo.velocity) < 0.3f){
        vec3 curr_left_decal_pos = this_mo.GetIKTargetPosition("left_leg");
        vec3 curr_right_decal_pos = this_mo.GetIKTargetPosition("right_leg");
        /*DebugDrawWireSphere(curr_left_decal_pos,
                        0.1f,
                        vec3(1.0f),
                        _delete_on_update);*/
        if(distance(curr_left_decal_pos, left_decal_pos) > _dist_threshold){
            if(left_smear_time < _smear_time_threshold){
                //this_mo.ChangeLastMaterialDecalDirection("left_leg",curr_left_decal_pos - left_decal_pos);
            } 
            /*if(smear_sound_time > 0.1f){
                PlaySoundGroup("Data/Sounds/footstep_mud.xml", curr_left_decal_pos);
                smear_sound_time = 0.0f;
            }*/
            //this_mo.MaterialDecalAtBone("step","left_leg");
            this_mo.MaterialParticleAtBone("skid","left_leg");
            //MakeSplatParticle(curr_left_decal_pos);
            left_decal_pos = curr_left_decal_pos;
            left_smear_time = 0.0f;
        }
        if(distance(curr_right_decal_pos, right_decal_pos) > _dist_threshold){
            if(right_smear_time < _smear_time_threshold){
                //this_mo.ChangeLastMaterialDecalDirection("right_leg",curr_right_decal_pos - right_decal_pos);
            }
            /*if(smear_sound_time > 0.1f){
                PlaySoundGroup("Data/Sounds/footstep_mud.xml", curr_left_decal_pos);
                smear_sound_time = 0.0f;
            }*/
            right_decal_pos = curr_right_decal_pos;
            //this_mo.MaterialDecalAtBone("step","right_leg");
            this_mo.MaterialParticleAtBone("skid","right_leg");
            //MakeSplatParticle(curr_right_decal_pos);
            right_smear_time = 0.0f;
        }
    }
}

void HandleCollisionsBetweenTwoCharacters(int which){
    if(this_mo.position == this_mo.ReadCharacter(which).position){
        return;
    }

    if(state == _attack_state && attack_getter.IsThrow() == 1){
        return;
    }
    if(state == _hit_reaction_state && attack_getter2.IsThrow() == 1){
        return;
    }

    if(knocked_out == _awake && this_mo.ReadCharacter(which).IsKnockedOut() == _awake){
        float distance_threshold = 0.7f;
        vec3 this_com = this_mo.GetCenterOfMass();
        vec3 other_com = this_mo.ReadCharacter(which).GetCenterOfMass();
        this_com.y = this_mo.position.y;
        other_com.y = this_mo.ReadCharacter(which).position.y;
        if(distance_squared(this_com, other_com) < distance_threshold*distance_threshold){
            vec3 dir = other_com - this_com;
            float dist = length(dir);
            dir /= dist;
            dir *= distance_threshold - dist;
            if(on_ground || this_mo.ReadCharacter(which).IsOnGround()==1){
                this_mo.ReadCharacter(which).position += dir * 0.5f;
                this_mo.position -= dir * 0.5f;
            } else {
                this_mo.ReadCharacter(which).velocity += dir * 0.5f / (time_step * num_frames);
                this_mo.velocity -= dir * 0.5f / (time_step * num_frames);
            }
        }    
    }
}

void HandleCollisionsBetweenCharacters() {
    int num_chars = this_mo.GetNumCharacters();

    for(int i=0; i<num_chars; ++i){
        HandleCollisionsBetweenTwoCharacters(i);
    }
}

void HandlePickUp() {
    if(WantsToPickUpItem()){
        int num_items = this_mo.GetNumItems();
        
        if(!holding_weapon){
            for(int i=0; i<num_items; i++){
                this_mo.ReadItem(i);
                vec3 pos = item_object_getter.GetPhysicsPosition();
                vec3 hand_pos = this_mo.GetIKTargetTransform("rightarm").GetTranslationPart();
                if(distance(hand_pos, pos)<0.9f){ 
                    holding_weapon = true;
                    weapon_id = i;
                    this_mo.AttachItem(i);
                    break;
                }
            }
        }
        if(holding_weapon){
            this_mo.SetMorphTargetWeight("fist_r",1.0f,1.0f);
            /*this_mo.ReadItem(weapon_id);
            vec3 pos = item_object_getter.GetPhysicsPosition();
            mat4 transform = this_mo.GetIKTargetTransform("rightarm");
            mat4 transform_rot = transform;
            transform_rot.SetTranslationPart(vec3(0.0f));
            mat4 new_transform;
            new_transform.SetColumn(0, transform.GetColumn(0));
            new_transform.SetColumn(1, transform.GetColumn(2)*-1.0f);
            new_transform.SetColumn(2, transform.GetColumn(1));
            new_transform.SetTranslationPart(
                transform.GetTranslationPart() + transform_rot * vec3(0.03f,0.15f,0.09f));
            item_object_getter.SetPhysicsTransform(new_transform);*/
        }
    } else {
        if(holding_weapon){
            this_mo.SetMorphTargetWeight("fist_r",1.0f,0.0f);
            this_mo.DetachItem(weapon_id);
            item_object_getter.ActivatePhysics();
            holding_weapon = false;
        }
    }
}

vec3 old_cam_pos;
float target_rotation = 0.0f;
float target_rotation2 = 0.0f;
float cam_rotation = 0.0f;
float cam_rotation2 = 0.0f;
float cam_distance = 1.0f;

vec3 ragdoll_cam_pos;

void ApplyCameraControls() {
    const float _camera_rotation_inertia = 0.5f;
    const float _cam_follow_distance = 2.0f;
    const float _cam_collision_radius = 0.15f;

    SetGrabMouse(true);

    target_rotation -= GetLookXAxis();
    target_rotation2 -= GetLookYAxis();    

    target_rotation2 = max(-90,min(50,target_rotation2));

/*
    vec3 true_pos = camera.GetPos() + camera.GetFacing() * cam_distance;
    this_mo.GetSweptSphereCollision(true_pos,
                                    true_pos - vec3(0.0f,5.0f,0.0f),
                                    _cam_collision_radius);
    vec3 new_pos = sphere_col.position;
    vec3 new_dir = normalize(new_pos - camera.GetPos());
    float max_rotation2 = asin(new_dir.y)*-180/3.1415 - 2.0f;
    Print(""+max_rotation2+"\n");

    target_rotation2 = min(target_rotation2, max_rotation2);*/

    vec3 cam_pos = this_mo.position;
    if(state != _ragdoll_state){
        cam_pos += vec3(0.0f,0.6f,0.0f);
    } else {
        cam_pos += vec3(0.0f,0.3f,0.0f);
    }

    ApplyCameraCones(cam_pos);

    //this_mo.GetSlidingSphereCollision(sphere_col.adjusted_position, radius);
    //DebugDrawWireSphere(sphere_col.adjusted_position, radius, vec3(0.0f,1.0f,0.5f), _delete_on_update);

    /*
    bool hit_something = false;
    float radius = 1.0f;
    vec3 offset;
    while(!hit_something){
        this_mo.GetSlidingSphereCollision(cam_pos, radius);
        if(sphere_col.NumContacts() > 0){
            hit_something = true;
            offset = (sphere_col.adjusted_position - cam_pos)/radius;
            break;
        }
        break;   
    }
    Print("Targetrotation2: "+target_rotation2+"\n");
    DebugDrawLine(cam_pos,
                  cam_pos + offset,
                  vec3(1.0f),
                  _delete_on_update);

    if(offset.y > 0.0f){
        target_rotation2 = min(target_rotation2, max(-20,90 - offset.y*140.0f));
    }*/

    float inertia = pow(_camera_rotation_inertia, num_frames);
    cam_rotation = cam_rotation * inertia + 
               target_rotation * (1.0f - inertia);
    cam_rotation2 = cam_rotation2 * inertia + 
               target_rotation2 * (1.0f - inertia);


    mat4 rotationY_mat,rotationX_mat;
    rotationY_mat.SetRotationY(cam_rotation*3.1415f/180.0f);
    rotationX_mat.SetRotationX(cam_rotation2*3.1415f/180.0f);
    mat4 rotation_mat = rotationY_mat * rotationX_mat;
    vec3 facing = rotation_mat * vec3(0.0f,0.0f,-1.0f);
    //vec3 facing = camera.GetFacing();
    vec3 right = normalize(vec3(-facing.z,facing.y,facing.x));

    //camera.SetZRotation(0.0f);
    //camera.SetZRotation(dot(right,this_mo.velocity+accel_tilt)*-0.1f);
    

    if(old_cam_pos == vec3(0.0f)){
        old_cam_pos = camera.GetPos();
    }
    old_cam_pos += this_mo.velocity * time_step * num_frames;

    if(ragdoll_cam_recover_time > 0.0f){
        cam_pos = mix(cam_pos, ragdoll_cam_pos, ragdoll_cam_recover_time);
        ragdoll_cam_recover_time -= time_step * num_frames * ragdoll_cam_recover_speed;
    }

    cam_pos = mix(cam_pos,old_cam_pos,0.8f);

    camera.SetVelocity(this_mo.velocity); 

    this_mo.GetSweptSphereCollision(cam_pos,
                                    cam_pos - facing * 
                                                _cam_follow_distance,
                                    _cam_collision_radius);
    
    float target_cam_distance = _cam_follow_distance;
    if(sphere_col.NumContacts() != 0){
        target_cam_distance = distance(cam_pos, sphere_col.position);
    }
    cam_distance = min(cam_distance, target_cam_distance);
    cam_distance = mix(target_cam_distance, cam_distance, 0.95f);

    //new_follow_distance = -0.1f;
    /*
    vec3 adjusted_pos = sphere_col.position;
    if(distance(adjusted_pos, cam_pos) < 1.0f){
        adjusted_pos -= facing * (1.0f - distance(adjusted_pos, cam_pos));
    }
    this_mo.GetSlidingSphereCollision(adjusted_pos, _cam_collision_radius);
    cam_pos += sphere_col.adjusted_position - adjusted_pos;*/
/*
    if(new_follow_distance<5.0f){
        new_follow_distance = 5.0f;
        vec3 temp_pos = 
            cam_pos - facing * new_follow_distance;
        this_mo.GetSweptSphereCollision(temp_pos + vec3(0.0f,5.0f,0.0f),
                                        temp_pos,
                                        _cam_collision_radius);
        vec3 new_pos = sphere_col.position;
        vec3 new_dir = normalize(new_pos - cam_pos);
        cam_rotation2 = asin(new_dir.y)*-180/3.1415 - 2.0f;
        //Print(""+cam_rotation2.x+" "+cam_rotation2.y+" "+cam_rotation2.z+"\n");
        Print(""+cam_rotation2+"\n");
    }*/
    
    camera.SetYRotation(cam_rotation);    
    camera.SetXRotation(cam_rotation2);

    camera.SetFOV(90);

    camera.SetPos(cam_pos);

    if(state == _ragdoll_state){
        ragdoll_cam_pos = cam_pos;
    }

    //cam_pos = this_mo.GetAvgIKChainTransform("head") * vec3(0.0f,0.0f,0.0f);
    //camera.SetFOV(20);
    //camera.SetPos(cam_pos);
    

    old_cam_pos = cam_pos;
    camera.CalcFacing();

    camera.SetDistance(cam_distance);
    UpdateListener(camera.GetPos(),vec3(0,0,0),camera.GetFacing(),camera.GetUpVector());

    camera.SetInterpSteps(num_frames);
}

void ApplyCameraCones(vec3 cam_pos){
    bool debug_viz = false;
    float radius = 0.8f;
    if(debug_viz){
        DebugDrawWireSphere(cam_pos, radius, vec3(1.0f,0.0f,0.0f), _delete_on_update);
    }
    this_mo.GetSlidingSphereCollision(cam_pos, radius);
    vec3 offset = sphere_col.adjusted_position - cam_pos;
    vec3 bad_dir = normalize(offset*-1.0f);
    if(debug_viz){
        DebugDrawLine(cam_pos,
                      cam_pos + bad_dir * radius,
                      vec3(1.0f),
                      _delete_on_update);
    }
    float penetration = 1.0f-length(offset)/radius;
    //Print("Angle: "+penetration_angle+"\n");

    if(debug_viz){
        float penetration_angle = acos(penetration);
        vec3 b_up(0.0f,1.0f,0.0f);
        if(abs(dot(b_up, bad_dir))>0.9f){
            b_up = vec3(1.0f,1.0f,1.0f);
        }
        vec3 b_right = normalize(cross(bad_dir, b_up));
        b_up = normalize(cross(bad_dir, b_right));
        DebugDrawLine(cam_pos,
                      cam_pos + bad_dir * penetration + b_right * sin(penetration_angle),
                      vec3(1.0f),
                      _delete_on_update);
        DebugDrawLine(cam_pos,
                      cam_pos + bad_dir * penetration - b_right * sin(penetration_angle),
                      vec3(1.0f),
                      _delete_on_update);
        DebugDrawLine(cam_pos,
                      cam_pos + bad_dir * penetration + b_up * sin(penetration_angle),
                      vec3(1.0f),
                      _delete_on_update);
        DebugDrawLine(cam_pos,
                      cam_pos + bad_dir * penetration - b_up * sin(penetration_angle),
                      vec3(1.0f),
                      _delete_on_update);
    }

    

    mat4 rotationY_mat,rotationX_mat;
    rotationY_mat.SetRotationY(target_rotation*3.1415f/180.0f);
    rotationX_mat.SetRotationX(target_rotation2*3.1415f/180.0f);
    mat4 rotation_mat = rotationY_mat * rotationX_mat;
    vec3 facing = rotation_mat * vec3(0.0f,0.0f,-1.0f);

    penetration -= 0.3f;
    //Print("Penetration: "+penetration+"\n");
    penetration = max(-0.2f, penetration);

    if(dot(facing, bad_dir * -1.0f) > penetration){ 
        float old_target_rotation = target_rotation;
        vec3 new_right = normalize(cross(normalize(cross(bad_dir,facing)),bad_dir)); 

        if(facing == bad_dir){
            facing += vec3(0.1f,0.1f,0.1f);
        }

        vec3 rot_facing;
        rot_facing.x = dot(facing, bad_dir)*-1.0f ;
        rot_facing.y = dot(facing, new_right);
        bool neg = rot_facing.y < 0;

        //Print("Rot_facing: "+rot_facing.x+" "+rot_facing.y+"\n");
        rot_facing.x = penetration;
        rot_facing.y = sqrt(1.0f - penetration * penetration);
        if(neg){
            rot_facing.y *= -1.0f;
        }
        //Print("Fixed rot_facing: "+rot_facing.x+" "+rot_facing.y+"\n");

        facing = bad_dir * rot_facing.x * -1.0f + new_right * rot_facing.y;
        target_rotation2 = asin(facing.y)/3.14159265 * 180.0f;
        facing.y = 0.0f;
        facing = normalize(facing);
        target_rotation = atan2(-facing.x,-facing.z)/3.14159265 * 180.0f;
        //Print("New target rotation: "+target_rotation+"\n");
        while(target_rotation > old_target_rotation + 180.0f){
            target_rotation -= 360.0f;
        }
        while(target_rotation < old_target_rotation - 180.0f){
            target_rotation += 360.0f;
        }
    }

}

void SwitchCharacter(string path){
    this_mo.char_path = path;
    character_getter.Load(this_mo.char_path);
    this_mo.RecreateRiggedObject(this_mo.char_path);
    this_mo.StartAnimation(character_getter.GetAnimPath("idle"));
    SetState(_movement_state);
}

void init(string character_path) {
    this_mo.char_path = character_path;
    character_getter.Load(this_mo.char_path);
    this_mo.RecreateRiggedObject(this_mo.char_path);
    for(int i=0; i<5; ++i){
        HandleBumperCollision();
        HandleStandingCollision();
        this_mo.position = sphere_col.position;
        last_col_pos = this_mo.position;
    }
    SetState(_movement_state);
}

void ScriptSwap() {
    last_col_pos = this_mo.position;
    this_mo.position.y += 0.5f;
}

void Reset() {
    if(state == _ragdoll_state){
        this_mo.UnRagdoll();
        this_mo.StartAnimation(character_getter.GetAnimPath("idle"));
        ragdoll_cam_recover_speed = 1000.0f;
        this_mo.SetRagdollFadeSpeed(1000.0f);
    }
    this_mo.SetTilt(vec3(0.0f,1.0f,0.0f));
    this_mo.SetFlip(vec3(0.0f,1.0f,0.0f),0.0f,0.0f);
}

void UpdateAnimation() {
    vec3 flat_velocity = vec3(this_mo.velocity.x,0,this_mo.velocity.z);

    float run_amount, walk_amount, idle_amount;
    float speed = length(flat_velocity);
    
    this_mo.SetBlendCoord("tall_coord",1.0f-duck_amount);
    
    if(on_ground){
        // rolling on the ground
        if(flip_info.UseRollAnimation()){
            this_mo.SetAnimation(character_getter.GetAnimPath("roll"),7.0f);
            float forwards_rollness = 1.0f-abs(dot(flip_info.GetAxis(),this_mo.GetFacing()));
            this_mo.SetBlendCoord("forward_roll_coord",forwards_rollness);
            this_mo.SetIKEnabled(false);
            roll_ik_fade = min(roll_ik_fade + time_step * 5.0f * num_frames, 1.0f);
        } else {
            // running, walking and idle animation
            this_mo.SetIKEnabled(true);
            
            // when he's moving instead of idling, the character turns to the movement direction.
            // the different movement types are listed in XML files, and are blended together
            // by variables such as speed or crouching amount (blending values should be 0 and 1)
            // when there are more than two animations to blend, the XML file refers to another 
            // XML file which asks for another blending variable.
            if(speed > _walk_threshold && feet_moving){
                this_mo.SetRotationFromFacing(InterpDirections(this_mo.GetFacing(),
                                                               normalize(flat_velocity),
                                                               1.0 - pow(0.8f, num_frames)));
                this_mo.SetAnimation(character_getter.GetAnimPath("movement"));
                this_mo.SetBlendCoord("speed_coord",speed);
                this_mo.SetBlendCoord("ground_speed",speed);
            } else {
                if(!mirrored_stance){
                    this_mo.SetAnimation(character_getter.GetAnimPath("idle"));
                } else {
                    this_mo.SetAnimation(character_getter.GetAnimPath("idle"),5.0f,_ANM_MIRRORED);
                }
                this_mo.SetIKEnabled(true);
            }
            roll_ik_fade = max(roll_ik_fade - time_step * 5.0f * num_frames, 0.0f);
        }
    } else {
        jump_info.UpdateAirAnimation();
    }

    // center of mass offset
    this_mo.SetCOMOffset(com_offset, com_offset_vel);
}

const float _check_up = 1.0f;
const float _check_down = -1.0f;
    
vec3 GetLegTargetOffset(vec3 initial_pos, vec3 anim_pos){
    /*DebugDrawLine(initial_pos + vec3(0.0f,_check_up,0.0f),
                  initial_pos + vec3(0.0f,_check_down,0.0f),
                  vec3(1.0f),
                  _delete_on_draw);*/
    this_mo.GetSweptSphereCollision(initial_pos + vec3(0.0f,_check_up,0.0f),
                                    initial_pos + vec3(0.0f,_check_down,0.0f),
                                    0.05f);

    if(sphere_col.NumContacts() == 0){
        return vec3(0.0f);
    }

    float target_y_pos = sphere_col.position.y;
    float height = anim_pos.y + _leg_sphere_size + 0.2f;
    target_y_pos += height;
    /*DebugDrawWireSphere(initial_pos,
                  0.05f,
                  vec3(1.0f,0.0f,0.0f),
                  _delete_on_draw);
    DebugDrawWireSphere(sphere_col.position,
                  0.05f,
                  vec3(0.0f,1.0f,0.0f),
                  _delete_on_draw);*/

    float offset_amount = target_y_pos - initial_pos.y;
    offset_amount /= max(0.0f,height)+1.0f;

    offset_amount = max(-0.15f,min(0.15f,offset_amount));

    return vec3(0.0f,offset_amount,0.0f);
}

float offset_height = 0.0f;


vec3 GetLimbTargetOffset(vec3 initial_pos, vec3 anim_pos){
    /*DebugDrawLine(initial_pos + vec3(0.0f,0.0f,0.0f),
                  initial_pos + vec3(0.0f,_check_down,0.0f),
                  vec3(1.0f),
                  _delete_on_draw);
    */
    this_mo.GetSweptSphereCollision(initial_pos + vec3(0.0f,_check_up,0.0f),
                                    initial_pos + vec3(0.0f,_check_down,0.0f),
                                    0.05f);

    if(sphere_col.NumContacts() == 0){
        return vec3(0.0f);
    }

    float target_y_pos = sphere_col.position.y;
    float height = anim_pos.y + 0.8f;// _leg_sphere_size;
    target_y_pos += height;
    /*DebugDrawWireSphere(sphere_col.position,
                  0.05f,
                  vec3(1.0f),
                  _delete_on_draw);
    */
    float offset_amount = target_y_pos - initial_pos.y;
    //offset_amount /= max(0.0f,height)+1.0f;

    offset_amount = max(-0.3f,min(0.3f,offset_amount));

    return vec3(0.0,offset_amount, 0.0f);
}

void SetLimbTargetOffset(string name){
    vec3 pos = this_mo.GetIKTargetPosition(name);
    vec3 anim_pos = this_mo.GetIKTargetAnimPosition(name);
    vec3 offset = GetLimbTargetOffset(pos, anim_pos);
    this_mo.SetIKTargetOffset(name,offset+vec3(0.0f,-0.15f,0.0f));
}

void GroundState_UpdateIKTargets() {
    vec3 offset = vec3(0.0f,0.0f,0.0f);

    SetLimbTargetOffset("left_leg");
    SetLimbTargetOffset("right_leg");
    SetLimbTargetOffset("leftarm");
    SetLimbTargetOffset("rightarm");
    this_mo.SetIKTargetOffset("full_body", vec3(0.0f,-0.05f,0.0f));
    //this_mo.SetIKTargetOffset("full_body", ground_normal * 0.05);
    
    vec3 axis = cross(ground_normal, vec3(0.0f,1.0f,0.0f));

    float x_amount = ground_normal.y;
    float y_amount = length(vec3(ground_normal.x, 0.0f, ground_normal.z));
    float angle = atan2(y_amount, x_amount);

    getting_up_time = 0.0f;
    angle *= min(1.0f,max(0.0f,1.0f - (getting_up_time-0.3f) * 2.0f));
    this_mo.SetFlip(axis,-angle,0.0f);
}

float roll_ik_fade = 0.0f;

int IsOnGround() {
    if(on_ground){
        return 1;
    } else {
        return 0;
    }
}

void MovementState_UpdateIKTargets() {
    if(!on_ground){
        jump_info.UpdateIKTargets();
    } else {
        vec3 tilt_offset = tilt * -0.005f;
        float left_ik_weight = this_mo.GetIKWeight("left_leg");
        float right_ik_weight = this_mo.GetIKWeight("right_leg");

        vec3 left_leg = this_mo.GetIKTargetPosition("left_leg");
        vec3 right_leg = this_mo.GetIKTargetPosition("right_leg");
        vec3 left_leg_anim = this_mo.GetIKTargetAnimPosition("left_leg");
        vec3 right_leg_anim = this_mo.GetIKTargetAnimPosition("right_leg");


        vec3 foot_apart = right_leg - left_leg;
        foot_apart.y = 0.0f;
        float bring_feet_together = min(0.4f,max(0.0f,1.0f-ground_normal.y)*2.0f);

        float two_feet_on_ground;
        if(left_ik_weight > right_ik_weight){
            two_feet_on_ground = right_ik_weight / left_ik_weight;
        } else if(right_ik_weight > left_ik_weight){
            two_feet_on_ground = left_ik_weight / right_ik_weight;
        } else {
            two_feet_on_ground = 1.0f;
        }

        bring_feet_together *= two_feet_on_ground;

        vec3 left_leg_offset = foot_apart * bring_feet_together * 0.5f;
        vec3 right_leg_offset = foot_apart * bring_feet_together * -0.5f;

        left_leg_offset += GetLegTargetOffset(left_leg+left_leg_offset,left_leg_anim);
        right_leg_offset += GetLegTargetOffset(right_leg+right_leg_offset,right_leg_anim);
        
        this_mo.SetIKTargetOffset("left_leg",left_leg_offset*(1.0f-roll_ik_fade)-tilt_offset*0.5f);
        this_mo.SetIKTargetOffset("right_leg",right_leg_offset*(1.0f-roll_ik_fade)-tilt_offset*0.5f);
            
        //float curr_avg_offset_height = min(0.0f,
        //                          min(left_leg_offset.y, right_leg_offset.y));
        float avg_offset_height = (left_leg_offset.y + right_leg_offset.y) * 0.5f;
        float min_offset_height = min(0.0f, min(left_leg_offset.y, right_leg_offset.y));
        float mix_amount = 1.0f;//min(1.0f,length(this_mo.velocity));
        float curr_offset_height = mix(min_offset_height, avg_offset_height,mix_amount);
        offset_height = mix(offset_height, curr_offset_height, 1.0f-(pow(0.9f,num_frames)));
        vec3 height_offset = vec3(0.0f,offset_height*(1.0f-roll_ik_fade)-0.1f*roll_ik_fade,0.0f);
        this_mo.SetIKTargetOffset("full_body",tilt_offset + height_offset);

        float ground_conform = this_mo.GetStatusKeyValue("groundconform");
        //Print(""+ground_conform+"\n");
        if(ground_conform > 0.0f){
            ground_conform = min(1.0f, ground_conform);
            vec3 axis = cross(ground_normal, vec3(0.0f,1.0f,0.0f));

            float x_amount = ground_normal.y;
            float y_amount = length(vec3(ground_normal.x, 0.0f, ground_normal.z));
            float angle = atan2(y_amount, x_amount);

            this_mo.SetFlip(axis,-angle*ground_conform,0.0f);
            this_mo.SetIKTargetOffset("full_body", vec3(0.0f,offset_height*(1.0f-ground_conform),0.0f));
        }
    }
}

void UpdateIKTargets() {
    MovementState_UpdateIKTargets();
}

void UpdateVelocity() {
    // GetTargetVelocitY() is defined in enemycontrol.as and playercontrol.as. Player target velocity depends on the camera and controls, AI's on player's position.
    this_mo.velocity += GetTargetVelocity() * time_step * _walk_accel * num_frames;
}

void ApplyPhysics() {
    if(!on_ground){
        this_mo.velocity += physics.gravity_vector * time_step * num_frames;
    }
    if(on_ground){
        //Print("Friction "+friction+"\n");
        if(!feet_moving){
            this_mo.velocity *= pow(0.95f,num_frames);
        } else {
            const float e = 2.71828183f;
            float exp = _walk_accel*time_step*-1/max_speed;
            float current_movement_friction = pow(e,exp);
            this_mo.velocity *= pow(current_movement_friction, num_frames);
        }
    }
}