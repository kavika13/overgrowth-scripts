#include "interpdirection.as"
#include "aschar_aux.as"
#include "aircontrols.as"

JumpInfo jump_info;
LedgeInfo ledge_info;

bool left_handed = true;

enum AIEvent{_ragdolled, _activeblocked, _thrown, _choking, _jumped, _can_climb,
             _grabbed_ledge, _climbed_up};

int head_choke_queue = -1;
vec3 push_velocity;
float block_stunned = 0.0f;
int block_stunned_by_id = -1;
vec3 old_slide_vel;
vec3 new_slide_vel;
float friction = 1.0f;
uint32 last_blood_particle_id = 0;
int blood_delay = 0;
bool cut_throat = false;
bool cut_torso = false;
const float _max_blood_amount = 10.0f;
float blood_amount = _max_blood_amount;
const float _spurt_frequency = 7.0f;
float spurt_sound_delay = 0.0f;
const float _spurt_delay_amount = 6.283185f/_spurt_frequency;
const float _body_part_drag_dist = 0.2f;
bool in_animation = false;
bool backslash = false;
float last_knife_time = 0.0f;
int knife_layer_id = -1;
int throw_knife_layer_id = -1;

float plant_rustle_delay = 0.0f;
float in_plant = 0.0f;
float blood_damage = 0.0f; // How much blood damage remains to be dealt
float blood_health = 1.0f; // How much blood remaining before passing out
float block_health = 1.0f; // How strong is auto-block? Similar to ssb shield
float temp_health = 1.0f; // Remaining regenerating health until knocked out
float permanent_health = 1.0f; // Remaining non-regenerating health until killed

int knocked_out = _awake;
float knocked_out_time = 0.0f;

// Parameter values
float p_aggression;
float p_damage_multiplier;
float p_block_skill;
float p_block_followup;
float p_attack_speed_mult;
float p_speed_mult;
float p_attack_damage_mult;
float p_attack_knockback_mult;
int p_lives;

float roll_ik_fade = 0.0f;

float offset_height = 0.0f;

const float _check_up = 1.0f;
const float _check_down = -1.0f;

bool idle_stance = false;
float idle_stance_amount = 0.0f;

const float _stance_move_threshold = 5.0f;

vec3 drag_target;

// States are used to differentiate between various widely different situations
const int _movement_state = 0; // character is moving on the ground
const int _ground_state = 1; // character has fallen down or is raising up, ATM ragdolls handle most of this
const int _attack_state = 2; // character is performing an attack
const int _hit_reaction_state = 3; // character was hit or dealt damage to and has to react to it in some manner
const int _ragdoll_state = 4; // character is falling in ragdoll mode
int state = _movement_state;

bool blinking = false;  // Currently in the middle of blinking?
float blink_progress = 0.0f; // Progress from 0.0 (pre-blink) to 1.0 (post-blink)
float blink_delay = 0.0f; // Time until next blink
float blink_amount = 0.0f; // How open eyes currently are

vec3 target_tilt(0.0f);
vec3 tilt(0.0f);

float stance_move_fade = 0.0f;
float stance_move_fade_val = 0.0f;
vec3 head_dir;
    
float head_look_opac;
float choke_look_time = 0.0f;

int force_look_target_id = -1;
vec3 random_look_dir;
float random_look_delay = 0.0f;
float look_inertia;
LookTarget look_target;

vec3 head_vel;
float layer_attacking_fade = 0.0f;
float layer_throwing_fade = 0.0f;

vec3 eye_dir; // Direction eyes are looking
vec3 target_eye_dir; // Direction eyes want to look
float eye_delay = 0.0f; // How much time until the next eye dir adjustment

vec3 dodge_dir;
bool active_dodging = false;
bool active_blocking = false;
int active_block_flinch_layer = -1;

float active_block_duration = 0.0f; // How much longer can the active block last
float active_block_recharge = 0.0f; // How long until the active block recharges

float active_dodge_duration = 0.0f; // How much longer can the active dodge last
float active_dodge_recharge = 0.0f; // How long until the active dodge recharges

float ragdoll_time; // How long spent in ragdoll mode this time
bool frozen; // Dead or unconscious ragdoll no longer needs to be simulated
bool no_freeze = false; // Freezing is disabled, e.g. for active ragdolls
float injured_mouth_open; // How open mouth is during injured writhe

float ragdoll_static_time; // How long ragdoll has been stationary

const float _auto_wake_vel_threshold = 20.0f;

float recovery_time;
float roll_recovery_time;

const int _RGDL_NO_TYPE = 0;
const int _RGDL_FALL = 1;
const int _RGDL_LIMP = 2;
const int _RGDL_INJURED = 3;
const int _RGDL_ANIMATION = 4;

int ragdoll_type;
int ragdoll_layer_fetal;
int ragdoll_layer_catchfallfront;
float ragdoll_limp_stun;

const int _miss = 0;
const int _going_to_block = 1;
const int _hit = 2;
const int _block_impact = 3;
const int _invalid = 4;

bool startled = false;
const float drop_weapon_probability = 0.3f;

// whether the character is in the ground or in the air, and how long time has passed since the status changed. 
bool on_ground = false;

const float _duck_speed_mult = 0.5f;

const float _ground_normal_y_threshold = 0.5f;
const float _leg_sphere_size = 0.45f; // affects the size of a sphere collider used for leg collisions
const float _bumper_size = 0.5f;

const float _base_run_speed = 8.0f; // used to calculate movement and jump velocities, change this instead of max_speed
const float _base_true_max_speed = 12.0f; // speed can never exceed this amount
float run_speed = _base_run_speed;
float true_max_speed = _base_true_max_speed;
float max_speed = run_speed; // this is recalculated constantly because actual max speed is affected by slopes

const float _tilt_transition_vel = 8.0f;

vec3 ground_normal(0,1,0);

// feet are moving if character isn't standing still, defined by targetvelocity being larger than 0.0 in UpdateGroundMovementControls()
bool feet_moving = false;
float getting_up_time;

int run_phase = 1;

string hit_reaction_event;

bool attack_animation_set = false;
bool hit_reaction_anim_set = false;
bool hit_reaction_dodge = false;
bool hit_reaction_thrown = false;
int attacking_with_throw;

const float _attack_range = 1.5f;
const float _close_attack_range = 1.0f;
float range_extender = 0.0f;
float range_multiplier = 1.0f;

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

enum WeaponSlot {
    _held_left=0,
    _held_right=1,
    _sheathed_left=2,
    _sheathed_right=3,
    _sheathed_left_sheathe=4,
    _sheathed_right_sheathe=5,
};

int primary_weapon_slot = _held_right;
int secondary_weapon_slot = _held_left;
const int _num_weap_slots = 6;
array<int> weapon_slots;

// Pre-jump happens after jump key is pressed and before the character gets upwards velocity. The time available for the jump animation that happens on the ground. 
bool pre_jump = false;
float pre_jump_time;

bool feinting;
bool can_feint;
float tether_dist;
vec3 tether_rel;

const int _TETHERED_FREE = 0;
const int _TETHERED_REARCHOKE = 1;
const int _TETHERED_REARCHOKED = 2;
const int _TETHERED_DRAGBODY = 3;
const int _TETHERED_DRAGGEDBODY = 4;
string drag_body_part;
int drag_body_part_id;
float drag_strength_mult;
const vec3 drag_offset(0.15f, 0.0f, 0.3f);
int tethered = _TETHERED_FREE;
int tether_id = -1;

const float _max_tether_height_diff = 0.2f;
bool executing = false;

vec3 accel_tilt;

enum IdleType{_stand, _active, _combat};
IdleType idle_type = _active;

const float vision_threshold = 40.0f;
const float vision_threshold_squared = vision_threshold*vision_threshold;

const uint16 _TC_ENEMY = (1<<0);
const uint16 _TC_CONSCIOUS = (1<<1);
const uint16 _TC_THROWABLE = (1<<2);
const uint16 _TC_NON_RAGDOLL = (1<<3);
const uint16 _TC_ALLY = (1<<4);
const uint16 _TC_IDLE = (1<<5);
const uint16 _TC_VEL_OFFSET = (1<<6);
const uint16 _TC_UNAWARE = (1<<7);
const uint16 _TC_RAGDOLL = (1<<8);
const uint16 _TC_UNCONSCIOUS = (1<<9);

const float offset = 0.05f;

const bool _draw_collision_spheres = false;

const float _shock_damage_threshold = 30.0f;
const float _shock_damage_multiplier = 0.1f;

const bool _draw_predict_path = true;

enum PredictPathType {_ppt_drop, _ppt_climb, _ppt_none};
class PredictPathOutput {
    PredictPathType type;
    vec3 start_pos;
    vec3 end_pos;
    vec3 normal;
};

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

float _base_launch_speed = 20.0f;
float _base_up_speed = 10.0f;

const float _get_weapon_time_limit = 0.4f;
float trying_to_get_weapon_time;
int trying_to_get_weapon = 0;
vec3 get_weapon_dir;
vec3 get_weapon_pos;
int pickup_layer = -1;
int pickup_layer_attempts = 0;
bool going_to_throw_item = false;
float going_to_throw_item_time;
int sheathe_layer_id = -1;

float _pick_up_range = 2.0f;

vec3 old_cam_pos;
float target_rotation = 0.0f;
float target_rotation2 = 0.0f;
float cam_rotation = 0.0f;
float cam_rotation2 = 0.0f; 
bool cam_rotation_set = false;
float cam_distance = 1.0f;
float auto_cam_override = 0.0f;

vec3 ragdoll_cam_pos;
vec3 cam_pos_offset;

vec3 chase_cam_pos;
float target_side_weight = 0.5f;
float target_weight = 0.0f;
float angle = 0.2f;
const bool cam_input = true;
float shared_cam_elevation = 0.0f;
float target_shared_cam_elevation = 0.0f;
array<float> shared_cam_elevation_history;
float reset_no_collide = 0.2f;

bool stance_move = true;

class Foot {
    vec3 pos;
    vec3 old_pos;
    vec3 target_pos;
    float progress;
    bool planted;
    float height;
};

Foot[] foot;
bool use_foot_plants = false;
bool old_use_foot_plants = false;

int lives;

float duck_amount = 0.0f; // duck_amount is changed incrementally to animate crouching or standing up from a crouch
float target_duck_amount = 0.0f; // this is 1.0 when the character crouches down,  0.0 otherwise. Used in UpdateDuckAmount() 
float duck_vel = 0.0f;

float threat_amount = 0.0f;
float target_threat_amount = 0.0f;
float threat_vel = 0.0f;

float air_time = 0.0f;
float on_ground_time = 0.0f;

float attack_predictability = 0.0f;

float hit_reaction_time;

bool active_block_anim = false;

vec3 mov_start;

const int _wake_stand = 0;
const int _wake_flip = 1;
const int _wake_roll = 2;
const int _wake_fall = 3;
const int _wake_block_stand = 4;

vec3 wake_up_torso_up;
vec3 wake_up_torso_front;
float ragdoll_cam_recover_time = 0.0f;
float ragdoll_cam_recover_speed = 1.0f;

int count = 0;

void ChokedOut(int target){
    head_choke_queue = target;
}

void HitByItem(string material, vec3 point, int id, int type) {
    //Print(""+ this_mo.getID() + " was hit by item id "+id+" with material \""+material+"\" at ");
    //PrintVec3(point);
    //Print("\n");
    ItemObject@ io = ReadItemID(id);
    vec3 lin_vel = io.GetLinearVelocity();
    vec3 force = (lin_vel - this_mo.velocity) * io.GetMass();
    this_mo.velocity += force * 0.1f;
    float force_len = length(force);
    TakeDamage(force_len / 30.0f);
    if(type == 1){
        TakeBloodDamage(force_len / 50.0f);
    }
    if(type == 2){
        TakeBloodDamage(force_len / 8.0f);
    }
    if(length(force) > 20.0f || knocked_out != _awake || !on_ground){
        HandleRagdollImpactImpulse(force * 200.0f, point, 0.0f);
    } else {
        vec3 face_dir = lin_vel * -1.0f;
        face_dir.y = 0.0f;
        face_dir = normalize(face_dir);
        this_mo.SetRotationFromFacing(face_dir);
        
        reaction_getter.Load("Data/Attacks/reaction_medfront.xml");
        string anim_path = reaction_getter.GetAnimPath(force_len/20.0f);
        SetState(_hit_reaction_state);
        hit_reaction_anim_set = true;

        int8 flags = _ANM_MOBILE | _ANM_FROM_START;
        if(mirrored_stance){
            flags = flags | _ANM_MIRRORED;
        }
        this_mo.SetAnimation(anim_path,10.0f,flags);
        this_mo.SetAnimationCallback("void EndHitReaction()");
    }
}

vec3 GetVelocityForTarget(const vec3&in start, const vec3&in end, float max_horz, float max_vert, float arc, float&out time){
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
    time = mix(min_x_time, max_y_time, arc);
    vec3 flat_vel(flat.x / time,
                  flat.y / time - physics.gravity_vector.y * time * 0.5f,
                  0.0f);
    //Print("Flat vel: "+flat_vel.x+" "+flat_vel.y+"\n");
    vec3 vel = flat_vel.x * normalize(rel_vec_flat) + vec3(0.0f, flat_vel.y, 0.0f);
    //Print("Vel: "+vel.x+" "+vel.y+" "+vel.z+"\n");
    return vel;
}
    
void Collided(float impulse){
    if(impulse < 5.0f){
        return;
    }
    const float _impact_damage_mult = 0.005f;
    int old_knocked_out = knocked_out;
    TakeDamage(impulse*_impact_damage_mult);
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

int IsBlockStunned() {
    return (block_stunned > 0.0f)?1:0;
}

vec3 FlipFacing() {
    if(target_id != -1 && throw_knife_layer_id != -1){
        MovementObject@ mo = ReadCharacterID(target_id);
        vec3 vec = mo.position - this_mo.position;
        vec.y = 0.0f;
        vec = normalize(vec);
        return vec;
    } else {
        return camera.GetFlatFacing();
    }
}

void MouseControlJumpTest() {
    vec3 start = camera.GetPos();
    vec3 end = camera.GetPos() + camera.GetMouseRay()*400.0f;
    col.GetSweptSphereCollision(start, end, _leg_sphere_size);
    DebugDrawWireSphere(sphere_col.position, _leg_sphere_size, vec3(0.0f,1.0f,0.0f), _delete_on_update);
    vec3 rel_dist = sphere_col.position - this_mo.position;
    vec3 flat_rd = vec3(rel_dist.x, 0.0f, rel_dist.z);
    vec3 jump_target = sphere_col.position;
    this_mo.SetRotationFromFacing(flat_rd);
    float time;
    vec3 start_vel = GetVelocityForTarget(this_mo.position, sphere_col.position, run_speed*1.5f, _jump_vel*1.7f, 0.55f, time);
    if(start_vel.y != 0.0f){
        bool low_success = false;
        bool med_success = false;
        bool high_success = false;
        const float _success_threshold = 0.1f;
        vec3 end;
        vec3 low_vel = GetVelocityForTarget(this_mo.position, jump_target, run_speed*1.5f, _jump_vel*1.7f, 0.15f, time);
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
        vec3 med_vel = GetVelocityForTarget(this_mo.position, jump_target, run_speed*1.5f, _jump_vel*1.7f, 0.55f, time);
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
        vec3 high_vel = GetVelocityForTarget(this_mo.position, jump_target, run_speed*1.5f, _jump_vel*1.7f, 1.0f, time);
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

        if(GetInputPressed(this_mo.controller_id, "mouse0") && start_vel.y != 0.0f){
            jump_info.StartJump(start_vel, true);
            SetOnGround(false);
        }
    }
}

void UpdateCutThroatEffect(const Timestep &in ts) {
    const float _blood_loss_speed = 0.5f;
    if(blood_delay <= 0){
        if(rand()%16 == 0){
            this_mo.CreateBloodDrip("head", 1, vec3(RangedRandomFloat(-1.0f,1.0f),RangedRandomFloat(-0.3f,0.3f),1.0f));//head_transform * vec3(0.0f,1.0f,0.0f));
        }
        if(rand()%32 == 0){
            //this_mo.CreateBloodDrip("rightarm", 0, vec3(1.0f,0.0f,0.0f));//head_transform * vec3(0.0f,1.0f,0.0f));
            //this_mo.CreateBloodDrip("leftarm", 0, vec3(-1.0f,0.0f,0.0f));//head_transform * vec3(0.0f,1.0f,0.0f));
        }
        
        vec3 head_pos = this_mo.GetAvgIKChainPos("head");
        vec3 torso_pos = this_mo.GetAvgIKChainPos("torso");
        vec3 bleed_pos = mix(head_pos, torso_pos, 0.2f);
        mat4 head_transform = this_mo.GetAvgIKChainTransform("head");
        head_transform.SetColumn(3, vec3(0.0f));
        float blood_force = sin(time*_spurt_frequency)*0.5f+0.5f;
        uint32 id = MakeParticle("Data/Particles/blooddrop.xml",bleed_pos,(head_transform*vec3(0.0f,blood_amount*blood_force,0.0f)+this_mo.velocity));
        if(last_blood_particle_id != 0){
            ConnectParticles(last_blood_particle_id, id);
        }
        last_blood_particle_id = id;
        blood_delay = 2;
    }
    blood_amount -= ts.step() * _blood_loss_speed;
    spurt_sound_delay -= ts.step();
    if(spurt_sound_delay <= 0.0f){
        spurt_sound_delay += _spurt_delay_amount;
        vec3 head_pos = this_mo.GetAvgIKChainPos("head");
        vec3 torso_pos = this_mo.GetAvgIKChainPos("torso");
        vec3 bleed_pos = mix(head_pos, torso_pos, 0.2f);
        PlaySoundGroup("Data/Sounds/blood/artery_squirt.xml", bleed_pos, blood_amount/_max_blood_amount);
    }
    -- blood_delay;
}

void StartBodyDrag(string part, int part_id, int char_id){
    MovementObject@ char = ReadCharacterID(char_id);
    drag_body_part = part;
    drag_body_part_id = part_id;
    tether_id = char_id;
    tethered = _TETHERED_DRAGBODY;
    drag_strength_mult = 0.0f;
    char.Execute("SetTetherID(" + this_mo.getID() + ");" +
                 "SetTethered(_TETHERED_DRAGGEDBODY);");
}

void CheckForStartBodyDrag(){
    if(tethered == _TETHERED_FREE && this_mo.controlled && WantsToDragBody()){
        int closest_id = GetClosestCharacterID(2.0f, _TC_RAGDOLL | _TC_UNCONSCIOUS);
        if(closest_id != -1){
            vec3 drag_offset_world;
            drag_offset_world.x = this_mo.position.x;
            drag_offset_world.z = this_mo.position.z;
            MovementObject@ char = ReadCharacterID(closest_id);
            string closest_part = "";
            string test_part;
            int closest_part_id;
            int test_part_id;
            float closest_dist = 0.0f;
            for(int i=0; i<5; ++i){
                switch(i){
                    case 0: test_part = "head"; test_part_id = 0; break;
                    case 1: test_part = "leftarm"; test_part_id = 0;  break;
                    case 2: test_part = "rightarm"; test_part_id = 0;  break;
                    case 3: test_part = "left_leg"; test_part_id = 0;  break;
                    case 4: test_part = "right_leg"; test_part_id = 0; break;
                }
                float dist;
                dist = distance_squared(char.GetIKChainPos(test_part,test_part_id),
                                              this_mo.position);
                if(closest_part == "" || dist < closest_dist){
                    closest_dist = dist;
                    closest_part_id = test_part_id;
                    closest_part = test_part;
                }
            }
            if(head_choke_queue == closest_id){
                closest_part = "head";
                closest_part_id = 0;
                closest_dist = 0.0f;
                head_choke_queue = -1;
            }
            if(closest_dist <= _body_part_drag_dist * 1.5f){
                if(active_block_flinch_layer != -1){
                    this_mo.RemoveLayer(active_block_flinch_layer, 4.0f);
                    active_block_flinch_layer = -1;
                } 

                StartBodyDrag(closest_part, closest_part_id, closest_id);
            }
        }
    }
}

void ApplyLevelBoundaries(){
    const float _level_size = 460.0f;
    const float _push_level_size = 450.0f;
    const float _push_force_mult = 0.2f;
    this_mo.position.x = max(-_level_size, min(_level_size, this_mo.position.x));
    this_mo.position.z = max(-_level_size, min(_level_size, this_mo.position.z));
    vec3 push_force;
    if(this_mo.position.x < -_push_level_size){
        push_force.x -= (this_mo.position.x + _push_level_size);
    }
    if(this_mo.position.x > _push_level_size){
        push_force.x -= (this_mo.position.x - _push_level_size);
    }
    if(this_mo.position.z < -_push_level_size){
        push_force.z -= (this_mo.position.z + _push_level_size);
    }
    if(this_mo.position.z > _push_level_size){
        push_force.z -= (this_mo.position.z - _push_level_size);
    }
    push_force *= _push_force_mult;
    if(length_squared(push_force) > 0.0f){
        this_mo.velocity += push_force;
        if(state == _ragdoll_state){
            this_mo.ApplyForceToRagdoll(push_force * 500.0f, this_mo.GetCenterOfMass());       
        }
    }
}

void MakeBeaconParticle(){
    if(!this_mo.controlled && knocked_out == _awake && distance_squared(camera.GetPos(), this_mo.position) > 100.0f){
        MakeParticle("Data/Particles/rayspark.xml",this_mo.position,vec3(0.0f,500.0f,0.0f));
    }
}

void MovementObjectDeleted(int id){
    if(id == target_id){
        target_id = -1;       
    }
    if(id == force_look_target_id){
        force_look_target_id = -1;       
    }
    if(id == look_target.id){
        look_target.id = -1;
        look_target.type = _none;
    }
    AIMovementObjectDeleted(id);
}

void PrintWeaponSlotDebugText(){  
    DebugText("char"+this_mo.getID()+"0","Character ID: "+this_mo.getID(), 0.5f);
    DebugText("char"+this_mo.getID()+"00","Pos: "+
        FloatString(this_mo.position.x,6)+", "+
        FloatString(this_mo.position.y,6)+", "+
        FloatString(this_mo.position.z,6), 0.5f);
    DebugText("char"+this_mo.getID()+"1","Weapon slot \"held left\"     : "+weapon_slots[_held_left], 0.5f);
    DebugText("char"+this_mo.getID()+"2","Weapon slot \"held right\"    : "+weapon_slots[_held_right], 0.5f);
    DebugText("char"+this_mo.getID()+"3","Weapon slot \"sheathed left\" : "+weapon_slots[_sheathed_left], 0.5f);
    DebugText("char"+this_mo.getID()+"4","Weapon slot \"sheathed right\": "+weapon_slots[_sheathed_right], 0.5f);
    DebugText("char"+this_mo.getID()+"5","Weapon slot \"sheath left\"   : "+weapon_slots[_sheathed_left_sheathe], 0.5f);
    DebugText("char"+this_mo.getID()+"6","Weapon slot \"sheath right\"  : "+weapon_slots[_sheathed_right_sheathe], 0.5f);
    DebugText("char"+this_mo.getID()+"7","Primary weapon slot: "+primary_weapon_slot, 0.5f);
}

void Update(int num_frames) {
    Timestep ts(time_step, num_frames);

    ApplyLevelBoundaries();

    if(knocked_out != _awake){
        knocked_out_time += ts.step();
    }

    if(in_animation){        
        if(this_mo.controlled){
            if(this_mo.controller_id == 0){
                UpdateAirWhooshSound();
            }
            if(this_mo.controller_id == 0 || GetSplitscreen()){
                ApplyCameraControls(ts);
            }
        }
        ApplyPhysics(ts);
        HandleCollisions(ts);
        HandleSpecialKeyPresses();
        return;
    }    
    
    reset_no_collide = max(0.0f, reset_no_collide - ts.step());
    if(being_executed == 1){
        int other_id = tether_id;
        CutThroat();
        vec3 impulse = this_mo.GetFacing() * 1000.0f;
        this_mo.ApplyForceToRagdoll(impulse, this_mo.GetIKChainPos("head", 1));
        ReadCharacterID(other_id).Execute("ChokedOut(" + this_mo.getID() + ");");
        being_executed = 0;
    }
    if(cut_throat && blood_amount > 0.0f){
        UpdateCutThroatEffect(ts);
    }
    if(cut_torso && blood_amount > 0.0f){
        if(blood_delay <= 0){
            this_mo.CreateBloodDrip("torso", 1, vec3(0.0f,RangedRandomFloat(-1.0f,1.0f),RangedRandomFloat(-1.0f,1.0f)));
            blood_delay = 2;
        }
        blood_amount -= ts.step() * 0.5f;
        -- blood_delay;
    }

    if(on_ground){
        push_velocity *= pow(0.9f, ts.frames());
        vec3 offset = this_mo.velocity - old_slide_vel;
        old_slide_vel = this_mo.velocity;
        this_mo.velocity = new_slide_vel + offset;
    } else {
        push_velocity = vec3(0.0f);
    }
    time += ts.step();

    if(!this_mo.controlled && on_ground){
        //MouseControlJumpTest();
    }

    HandleSpecialKeyPresses();
    if(in_animation){
        return;
    }
    UpdateBrain(ts); //in playercontrol.as or enemycontrol.as
    UpdateState(ts);

    if(this_mo.controlled){
        if(this_mo.controller_id == 0){
            UpdateAirWhooshSound();
        }
        if(this_mo.controller_id == 0 || GetSplitscreen()){
            ApplyCameraControls(ts);
        }
    }

    if(on_ground){
        new_slide_vel = this_mo.velocity;
        float new_friction = this_mo.GetFriction(this_mo.position + vec3(0.0f,_leg_sphere_size * -0.4f,0.0f));
        friction = max(0.01f, friction);
        friction = pow(mix(pow(friction,0.01f), pow(new_friction,0.01f), 0.05f),100.0f);
        this_mo.velocity = mix(this_mo.velocity, old_slide_vel, pow(1.0f-friction, ts.frames()));
        old_slide_vel = this_mo.velocity;
        for(int i=0; i<2; ++i){
            foot[i].old_pos += (old_slide_vel - new_slide_vel) * ts.step();
        }
    }
}


void JumpTest(const vec3&in initial_pos, 
              const vec3&in initial_vel,
              array<vec3>&inout jump_path,
              const Timestep &in ts) 
{
    const float _jump_test_steps = 40.0f;
    jump_path.resize(0);
    vec3 start = initial_pos;
    vec3 end = start;
    vec3 fake_vel = initial_vel;
    for(int i=0; i< 400; ++i){
        for(int j=0; j<_jump_test_steps / ts.frames(); ++j){
            fake_vel += physics.gravity_vector * ts.step();
            fake_vel = CheckTerminalVelocity(fake_vel, ts);
            end += fake_vel * ts.step();
        }
        jump_path.push_back(start);
        col.GetSweptSphereCollision(start,
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
        time += time_step * _jump_test_steps;
        height = flat_vel.y * time + 0.5f * physics.gravity_vector.y * time * time;
        end = initial_pos + flat_dir * time;
        end.y += height;
        jump_path.push_back(start);
        col.GetSweptSphereCollision(start,
                                     end,
                                     _leg_sphere_size);
        start = end;
        if(sphere_col.NumContacts() > 0){
            jump_path.push_back(sphere_col.position);
            break;
        }
    }
}

void EndAnim(){
    in_animation = false;
    this_mo.SetAnimatedItemID(1, -1);
}

void RecoverHealth() {      
    SetKnockedOut(_awake);
    knocked_out_time = 0.0f;
    blood_health = 1.0f;
    block_health = 1.0f;
    blood_damage = 0.0f;
    temp_health = 1.0f;
    permanent_health = 1.0f;
}

void Recover() {      
    RecoverHealth();
    cut_throat = false;
    cut_torso = false;
    this_mo.CleanBlood();
    ClearTemporaryDecals();
    blood_amount = _max_blood_amount;
    recovery_time = 0.0f;
    roll_recovery_time = 0.0f;
    lives = p_lives;
}

void CutThroat() {
    if(!cut_throat){
        string sound = "Data/Sounds/hit/hit_splatter.xml";
        PlaySoundGroup(sound, this_mo.position);

        spurt_sound_delay = _spurt_delay_amount*0.24f;
        cut_throat = true;
        blood_amount = _max_blood_amount;
        last_blood_particle_id = 0;
        SetKnockedOut(_dead);
        Ragdoll(_RGDL_INJURED);
        
        mat4 head_transform = this_mo.GetAvgIKChainTransform("head");
        vec3 head_pos = this_mo.GetAvgIKChainPos("head");
        vec3 torso_pos = this_mo.GetAvgIKChainPos("torso");
        vec3 bleed_pos = mix(head_pos, torso_pos, 0.2f);
        head_transform.SetColumn(3, vec3(0.0f));
        float blood_force = sin(time*7.0f)*0.5f+0.5f;
        for(int i=0; i<10; ++i){
            vec3 mist_vel = vec3(RangedRandomFloat(-5.0f,5.0f),RangedRandomFloat(0.0f,5.0f), 0.0f);
            MakeParticle("Data/Particles/bloodcloud.xml",bleed_pos,(head_transform*mist_vel+this_mo.velocity));
        } 
    }
}

void SwapWeaponHands() {
    if(weapon_slots[_held_left] == -1 && weapon_slots[_held_right] == -1){
        return;
    }
    if(sheathe_layer_id != -1){
        return;
    }
    int8 flags = 0;
    if(mirrored_stance){
        flags = flags | _ANM_MIRRORED;
    }
    sheathe_layer_id = this_mo.AddLayer("Data/Animations/r_heldweaponswap.anm",8.0f,flags);
}

void HandleSpecialKeyPresses() {
    if(GetInputDown(this_mo.controller_id, "z") && !GetInputDown(this_mo.controller_id, "ctrl")){
        GoLimp();
    }
    if(GetInputDown(this_mo.controller_id, "n")){                
        if(state != _ragdoll_state){
            string sound = "Data/Sounds/hit/hit_hard.xml";
            PlaySoundGroup(sound, this_mo.position);
        }
        Ragdoll(_RGDL_INJURED);
    }
    if(GetInputPressed(this_mo.controller_id, ",")){   
        //this_mo.CreateBloodDrip("head", 1, vec3(RangedRandomFloat(-1.0f,1.0f),RangedRandomFloat(-0.3f,0.3f),1.0f));//head_transform * vec3(0.0f,1.0f,0.0f));
        
        CutThroat();
    }
    if(GetInputDown(this_mo.controller_id, "m")){        
        Ragdoll(_RGDL_LIMP);
    }
    if(GetInputDown(this_mo.controller_id, "x")){      
        Recover();
    }

    if(this_mo.controlled){
        if(GetInputDown(this_mo.controller_id, "v")){
            string sound = "Data/Sounds/voice/torikamal/fallscream.xml";
            this_mo.ForceSoundGroupVoice(sound, 0.0f);
        }
        if(GetInputPressed(this_mo.controller_id, "f")){
            int num_chars = GetNumCharacters();
            for(int i=0; i<num_chars; ++i){
                MovementObject @char = ReadCharacter(i);
                if(char.getID() == this_mo.getID()){
                    continue;
                }
                vec3 start = this_mo.GetAvgIKChainPos("head");
                vec3 end = char.GetAvgIKChainPos("torso");
                float length = distance(end, start);
                if(length > 10){
                    continue;
                }
                PlaySound("Data/Sounds/ambient/amb_canyon_rock_1.wav", this_mo.position);
                MakeMetalSparks(start);
                MakeMetalSparks(end);
                int num_sparks = length * 5;
                for(int j=0; j<num_sparks; ++j){
                    MakeMetalSparks(mix(start, end, j/float(num_sparks)));
                }
                vec3 force = normalize(char.position - this_mo.position) * 40000.0f;
                force.y += 1000.0f;
                char.Execute("vec3 impulse = vec3("+force.x+", "+force.y+", "+force.z+");" +
                             "HandleRagdollImpactImpulse(impulse, this_mo.GetAvgIKChainPos(\"torso\"), 5.0f);"+
                             "ragdoll_limp_stun = 1.0f;"+
                             "recovery_time = 2.0f;");
            }
        }
        if(GetInputPressed(this_mo.controller_id, "1")){    
            SwitchCharacter("Data/Characters/guard.xml");
        }
        if(GetInputPressed(this_mo.controller_id, "2")){
            SwitchCharacter("Data/Characters/guard2.xml");
        }
        if(GetInputPressed(this_mo.controller_id, "3")){
            SwitchCharacter("Data/Characters/turner.xml");
        }
        if(GetInputPressed(this_mo.controller_id, "4")){
            SwitchCharacter("Data/Characters/civ.xml");
        }
        if(GetInputPressed(this_mo.controller_id, "5")){
            SwitchCharacter("Data/Characters/wolf.xml");
        }
        if(GetInputPressed(this_mo.controller_id, "6")){
            SwitchCharacter("Data/Characters/rabbot.xml");
        }
        if(GetInputPressed(this_mo.controller_id, "7")){
            SwitchCharacter("Data/Characters/cat.xml");
        }
        if(GetInputPressed(this_mo.controller_id, "8")){
            SwitchCharacter("Data/Characters/raider_rabbit.xml");
        }
        if(GetInputPressed(this_mo.controller_id, "b")){
            /*int8 flags = _ANM_FROM_START;
            if(mirrored_stance){
                flags = flags | _ANM_MIRRORED;
            }
            this_mo.SetAnimation("Data/Animations/w_combatidlewild.anm",20.0f,flags);
            in_animation = true;
            this_mo.SetAnimationCallback("void EndAnim()");*/
            //this_mo.AddLayer("Data/Animations/r_knifethrowlayer.anm",8.0f,0);
            //this_mo.AddLayer("Data/Animations/r_painflinch.anm",8.0f,0);
            /*if(sheathed_weapon == -1 && held_weapon != -1) {
                //this_mo.AddLayer("Data/Animations/r_knifesheathe.anm",8.0f,0);
                this_mo.AddLayer("Data/Animations/r_swordsheathe.anm",8.0f,0);
            } else if(sheathed_weapon != -1 && held_weapon == -1) {
                this_mo.AddLayer("Data/Animations/r_knifeunsheathe.anm",8.0f,0);
            }*/
            /*int8 flags = _ANM_FROM_START;
            if(weapon_slots[primary_weapon_slot] != -1) {
                this_mo.SetAnimation("Data/Animations/r_swordsheathe.anm",20.0f,flags);
                this_mo.SetAnimatedItemID(1, weapon_slots[_sheathed_right]);
            } else if(weapon_slots[primary_weapon_slot] == -1) {
                this_mo.SetAnimation("Data/Animations/r_swordunsheathe.anm",20.0f,flags);
                this_mo.SetAnimatedItemID(1, weapon_slots[_sheathed_right_sheathe]);
            }
            in_animation = true;
            this_mo.SetAnimationCallback("void EndAnim()");*/
            SwapWeaponHands();
            //CheckPossibleAttacks();
        }
        if(GetInputPressed(this_mo.controller_id, "h")){
            context.PrintGlobalVars();
        } 
    }
    if(GetInputPressed(this_mo.controller_id, "p") && target_id != -1){
        Print("Getting path");
        NavPath temp = GetPath(this_mo.position,
                               ReadCharacterID(target_id).position);
        int num_points = temp.NumPoints();
        for(int i=0; i<num_points-1; i++){
            DebugDrawLine(temp.GetPoint(i),
                          temp.GetPoint(i+1),
                          vec3(1.0f,1.0f,1.0f),
                          _persistent);
        }
    }
}

vec3 CheckTerminalVelocity(const vec3&in velocity, const Timestep &in ts){
    const float _terminal_velocity = 50.0f;
    const float _terminal_velocity_sqrd = _terminal_velocity*_terminal_velocity;
    if(length_squared(velocity) > _terminal_velocity_sqrd){
        return velocity * pow(0.99f,ts.frames());
    } 
    return velocity;
}

void UnTether() {
    if(tether_id != -1){
        MovementObject @char = ReadCharacterID(tether_id);
        char.Execute("SetTethered(_TETHERED_FREE); SetTetherID(-1);");
        tether_id = -1;
        tethered = _TETHERED_FREE;
    }
}

void HandlePlantCollisions(const Timestep &in ts){
    in_plant = 0.0f;
    {
        vec3 offset;
        vec3 scale;
        float size;
        GetCollisionSphere(offset, scale, size);
        scale.x *= 0.5f;
        scale.z *= 0.5f;
        col.GetScaledSpherePlantCollision(this_mo.position+offset, size*0.2f, scale);
        if(sphere_col.NumContacts() != 0){
            in_plant += 0.25f;
        }
        col.GetScaledSpherePlantCollision(this_mo.position+offset, size*0.4f, scale);
        if(sphere_col.NumContacts() != 0){
            in_plant += 0.25f;
        }
        col.GetScaledSpherePlantCollision(this_mo.position+offset, size*0.6f, scale);
        if(sphere_col.NumContacts() != 0){
            in_plant += 0.25f;
        }
        col.GetScaledSpherePlantCollision(this_mo.position+offset, size*0.8f, scale);
        if(sphere_col.NumContacts() != 0){
            in_plant += 0.25f;
        }
        col.GetScaledSpherePlantCollision(this_mo.position+offset, size, scale);
        /*vec3 color;
        if(in_plant == 0.0f){ 
            color = vec3(0.0f,1.0f,0.3f);
        } else {
            color = vec3(1.0f,0.0f,0.0f);
        }
        DebugDrawWireScaledSphere(this_mo.position+offset,size,scale,color,_delete_on_update);
        if(in_plant < 1.0f){ 
            color = vec3(0.0f,1.0f,0.3f);
        } else {
            color = vec3(1.0f,0.0f,0.0f);
        }
        DebugDrawWireScaledSphere(this_mo.position+offset,size*0.2f,scale,color,_delete_on_update);
        if(in_plant < 0.75f){ 
            color = vec3(0.0f,1.0f,0.3f);
        } else {
            color = vec3(1.0f,0.0f,0.0f);
        }
        DebugDrawWireScaledSphere(this_mo.position+offset,size*0.4f,scale,color,_delete_on_update);
        if(in_plant < 0.5f){ 
            color = vec3(0.0f,1.0f,0.3f);
        } else {
            color = vec3(1.0f,0.0f,0.0f);
        }
        DebugDrawWireScaledSphere(this_mo.position+offset,size*0.6f,scale,color,_delete_on_update);
        if(in_plant < 0.25f){ 
            color = vec3(0.0f,1.0f,0.3f);
        } else {
            color = vec3(1.0f,0.0f,0.0f);
        }
        DebugDrawWireScaledSphere(this_mo.position+offset,size*0.8f,scale,color,_delete_on_update);*/
    }
    array<int> plant_ids;
    {
        bool already_known_plant;
        for(int i=0; i<sphere_col.NumContacts(); i++){
            const CollisionPoint contact = sphere_col.GetContact(i);
            //DebugDrawWireSphere(contact.position, 0.1f, vec3(1.0f), _delete_on_update);
            already_known_plant = false;
            for(uint j=0; j<plant_ids.size(); ++j){
                if(plant_ids[j] == contact.id){
                    already_known_plant = true;
                }
            }
            if(!already_known_plant){
                plant_ids.push_back(contact.id);
            }
        }
    }
    float speed = length_squared(this_mo.velocity);
    if(in_plant > 0.25f){
        int plant = rand()%plant_ids.size();
        SendMessage(plant_ids[plant], _plant_movement_msg, this_mo.position, this_mo.velocity);
        EnvObject@ eo = ReadEnvObjectID(plant_ids[plant]);
        for(int j=0; j<3; ++j){
            if(RangedRandomFloat(0.0f,100.0f) < speed){
                eo.CreateLeaf(this_mo.position, this_mo.velocity * 0.8f, 10);
            }
            if(RangedRandomFloat(0.0f,100.0f) < speed){
                eo.CreateLeaf(vec3(0.0f),vec3(0.0f),1);
            }
        }
    }
    plant_rustle_delay = max(0.0f, plant_rustle_delay-ts.step());
    if(plant_rustle_delay <= 0.0f && in_plant > 0.5f){
        if(speed > 3.0f){   
            plant_rustle_delay = 0.7f;
            string sound;
            //Print("Speed: "+speed+"\n");
            if(speed < 15.0f){
                sound = "Data/Sounds/plant_foley/bush_slow.xml";
                //Print("Slow\n");
            } else if(speed > 70.0f){
                sound = "Data/Sounds/plant_foley/bush_fast.xml";
                //Print("Fast\n");
            } else {
                sound = "Data/Sounds/plant_foley/bush_medium.xml";
                //Print("Medium\n");
            }
            this_mo.PlaySoundGroupAttached(sound,this_mo.position);
        }
    }
    if(in_plant > 0.0f && !on_ground && !flip_info.IsFlipping()){
        this_mo.velocity.x *= pow(0.97f, ts.frames()*in_plant);
        this_mo.velocity.z *= pow(0.97f, ts.frames()*in_plant);
        if(this_mo.velocity.y > 0.0f){
            this_mo.velocity.y *= pow(0.97f, ts.frames()*in_plant);
        }
        if(speed > 110.0f){
            GoLimp();
        }
    }
}


//int plant_flinch_layer = -1;
void UpdatePlantAvoid() {
    /*if(plant_flinch_layer == -1 && in_plant != 0.0f){
        Print("Adding plant avoid\n");
        plant_flinch_layer = 
            this_mo.AddLayer("Data/Animations/r_plantavoid.anm",4.0f,0);
    } 
    if(in_plant == 0.0f && plant_flinch_layer != -1){
        this_mo.RemoveLayer(plant_flinch_layer, 4.0f);
        plant_flinch_layer = -1;
    }*/
}


void UpdateState(const Timestep &in ts) {
    cam_pos_offset = vec3(0.0f);
    UpdateHeadLook(ts);
    UpdateBlink(ts);
    UpdateEyeLook(ts);

    UpdatePlantAvoid();
    UpdateActiveBlockAndDodge(ts);
    RegenerateHealth(ts);

    trying_to_get_weapon = max(0,trying_to_get_weapon-1);

     if(state == _ragdoll_state){ // This is not part of the else chain because
        UpdateRagDoll(ts);         // the character may wake up and need other
        HandlePickUp();          // state updates
    } 
    
    use_foot_plants = false;

    UpdateThreatAmount(ts);
    UpdateIdleType();
    if(state == _movement_state){
        UpdateDuckAmount(ts);
        UpdateGroundAndAirTime(ts);
        HandleAccelTilt(ts);
        CheckForStartBodyDrag();
        UpdateMovementControls(ts);
        UpdateAnimation(ts);
        ApplyPhysics(ts);
        HandlePickUp();
        HandleCollisions(ts);
    } else if(state == _ground_state){
        UpdateDuckAmount(ts);
        HandleAccelTilt(ts);
        UpdateGroundState(ts);
    } else if(state == _attack_state){
        HandleAccelTilt(ts);
        UpdateAttacking(ts);
        HandleCollisions(ts);
    } else if(state == _hit_reaction_state){
        if(active_block_anim && hit_reaction_time > 0.1f){
            UpdateGroundAttackControls(ts);
       } 
        UpdateHitReaction(ts);
        HandleAccelTilt(ts);
        HandleCollisions(ts);
    }
    
    HandlePlantCollisions(ts);

    old_use_foot_plants = use_foot_plants;
    if(!use_foot_plants && foot.length() != 0){
        for(int i=0; i<2; ++i){
            foot[i].pos *= 0.9f;
            foot[i].height *= 0.9f;
        }
    }

    HandleTethering(ts);

    this_mo.velocity = CheckTerminalVelocity(this_mo.velocity, ts);   

    UpdateTilt(ts);
    
    if(on_ground && state == _movement_state){
        DecalCheck();
    }
    left_smear_time += ts.step();
    right_smear_time += ts.step();
    smear_sound_time += ts.step();
}

void UpdateIdleType() {
    if(situation.NeedsCombatPose()){
        idle_type = _combat;
    } else if(WantsReadyStance()){
        idle_type = _active;
    } else {
        idle_type = _stand;
    }
}

int GetCharPrimaryWeapon(MovementObject@ mo){
    return mo.GetArrayIntVar("weapon_slots",mo.GetIntVar("primary_weapon_slot"));
}

void HandleTethering(const Timestep &in ts) {
    
    if(tethered == _TETHERED_REARCHOKE){
        MovementObject @char = ReadCharacterID(tether_id);
        if((!WantsToThrowEnemy() || abs(this_mo.position.y - char.position.y) > _max_tether_height_diff) && !executing){
            UnTether();
            return;
        }
        if(tether_id != -1 && state == _movement_state){
            vec3 rel = char.position - this_mo.position;
            rel.y = 0.0f;
            rel = normalize(rel);
            tether_rel = mix(rel, tether_rel, pow(0.1f, ts.frames()));
            vec3 mid_point = (char.position + this_mo.position)*0.5f;
            vec3 old_pos0;
            vec3 old_pos1;
            old_pos0 = this_mo.position;
            old_pos1 = char.position;
            char.position = mix(char.position, mid_point + tether_rel*tether_dist*0.5f, 1.0f);
            this_mo.position = mix(this_mo.position, mid_point - tether_rel*tether_dist*0.5f, 1.0f);
            this_mo.position.y = old_pos0.y;
            char.position.y = old_pos1.y;
            this_mo.velocity += (this_mo.position - old_pos0)/(ts.step());
            char.velocity += (char.position - old_pos1)/(ts.step());
            char.SetRotationFromFacing(tether_rel);
            this_mo.SetRotationFromFacing(tether_rel);

            //DebugDrawWireSphere(char.GetAvgIKChainPos("head"), 0.1f, vec3(1.0f), _delete_on_update);
            //DebugDrawWireSphere(this_mo.GetAvgIKChainPos("torso"), 0.1f, vec3(1.0f), _delete_on_update);
            /*mat4 torso_transform = this_mo.GetAvgIKChainTransform("torso");
            Print("Vec: ");
            PrintVec3(invert(torso_transform)*char.GetAvgIKChainPos("head"));
            Print("\n");
            vec3 target_offset = vec3(-0.1f, 0.2f, 0.3f);
            DebugDrawWireSphere(torso_transform * target_offset, 0.1f, vec3(1.0f), _delete_on_update);
*/
            float avg_duck = duck_amount;
            avg_duck += char.GetFloatVar("duck_amount");
            avg_duck *= 0.5f;
            duck_amount = avg_duck;
            char.Execute("duck_amount = "+avg_duck+";");
        }
    }
    if(tethered == _TETHERED_REARCHOKED){
        DropWeapon();
        // Choking
        
        MovementObject@ char = ReadCharacterID(tether_id);
        int weap_id = GetCharPrimaryWeapon(char);
        if(weap_id == -1){
            TakeDamage(ts.step() * 0.25f);
            if(knocked_out != _awake){
                this_mo.MaterialEvent("choke_fall", this_mo.position);
                int other_char_id = tether_id;
                Ragdoll(_RGDL_LIMP);
                ReadCharacterID(other_char_id).Execute("ChokedOut(" + this_mo.getID() + ");");
            }
        }
    }
    if(tethered == _TETHERED_DRAGBODY){
        if(!WantsToDragBody()){
            UnTether();
            return;
        }
        MovementObject@ char = ReadCharacterID(tether_id);
        vec3 arm_pos = GetDragOffsetWorld();
        vec3 head_pos = char.GetIKChainPos(drag_body_part,drag_body_part_id);
        vec3 arm_pos_flat = vec3(arm_pos.x, 0.0f, arm_pos.z);
        vec3 head_pos_flat = vec3(head_pos.x, 0.0f, head_pos.z);
        float dist = distance(arm_pos_flat, head_pos_flat);
        if(dist > 0.2f){
            this_mo.velocity += (normalize(head_pos_flat - arm_pos_flat) * (dist - 0.2f)) * 5.0f * drag_strength_mult;            
        }
        if(drag_strength_mult > 0.3f){
            drag_target = mix(arm_pos, drag_target, pow(0.95f, ts.frames()));
            char.MoveRagdollPart(drag_body_part,drag_target,drag_strength_mult);
        } else {
            drag_target = head_pos;
        }
        char.Execute("RagdollRefresh(1);");
        
        float old_drag_strength_mult = drag_strength_mult;
        drag_strength_mult = mix(1.0f, drag_strength_mult, pow(0.95f,ts.frames()));
        if(old_drag_strength_mult < 0.7f && drag_strength_mult >= 0.7f){
            PlaySoundGroup("Data/Sounds/hit/grip.xml", this_mo.position);
        }
        //DebugDrawWireSphere(head_pos,0.2f, vec3(1.0f), _delete_on_update);
        tether_rel = char.position - this_mo.position;
        tether_rel.y = 0.0f;
        tether_rel = normalize(tether_rel);
        this_mo.SetRotationFromFacing(InterpDirections(this_mo.GetFacing(),tether_rel,1.0 - pow(0.95f, ts.frames())));
    }
}

void UpdateTilt(const Timestep &in ts) {
    const float _tilt_inertia = 0.9f;
    tilt = tilt * pow(_tilt_inertia,ts.frames()) +
           target_tilt * (1.0f - pow(_tilt_inertia,ts.frames()));
    this_mo.SetTilt(tilt);
}



vec3 GetTargetHeadDir(const Timestep &in ts) {
    bool look_at_target = false;
    vec3 target_dir;
    vec3 target_head_dir;
    if(tethered == _TETHERED_REARCHOKED){
        if(choke_look_time <= 0.0f){
            target_head_dir = vec3(RangedRandomFloat(-1.0f, 1.0f),
                                   RangedRandomFloat(-0.2f, 0.2f),
                                   RangedRandomFloat(-1.0f, 1.0f));
            choke_look_time = RangedRandomFloat(0.1f,0.3f);
            look_inertia = 0.8f;
            if(rand()%4 == 0){
                this_mo.MaterialEvent("choke_move", this_mo.position, RangedRandomFloat(0.0f,1.0f));
            }
        }
        choke_look_time = max(0.0f, choke_look_time - ts.step());
    } else if(trying_to_get_weapon != 0){
        look_inertia = 0.8f;
        target_head_dir = normalize(get_weapon_pos - this_mo.GetAvgIKChainPos("head"));
    } else {
        if(throw_knife_layer_id != -1 && target_id != -1){
            force_look_target_id = target_id;
        }
        if(force_look_target_id != -1){
            vec3 target_pos = ReadCharacterID(force_look_target_id).GetAvgIKChainPos("head");
            look_at_target = true;
            target_dir = normalize(target_pos - this_mo.GetAvgIKChainPos("head"));
        }
        if(look_at_target){
            target_head_dir = target_dir;
            look_inertia = 0.8f;
        } else if(this_mo.controlled){
            vec3 dir_flat = camera.GetFacing();
            dir_flat.y = 0.0f;
            target_head_dir = mix(dir_flat, normalize(dir_flat), 0.5f);
            target_head_dir.y = camera.GetFacing().y * 0.4f;
            if(!on_ground){
                target_head_dir = mix(target_head_dir, this_mo.GetFacing(), 0.5f);
            }
            target_head_dir = normalize(target_head_dir);
            look_inertia = 0.8f;
        } else {
            if(look_target.type == _none){
                target_head_dir = random_look_dir;
            } else if(look_target.type == _character){
                vec3 target_pos = ReadCharacterID(look_target.id).GetAvgIKChainPos("head");
                target_head_dir = normalize(target_pos - this_mo.GetAvgIKChainPos("head"));
            }
            look_inertia = 0.9f;
        }
    }

    random_look_delay -= ts.step();
    if(random_look_delay <= 0.0f){
        random_look_delay = RangedRandomFloat(0.8f,2.0f);
        vec3 rand_dir;
        do {
            rand_dir = vec3(RangedRandomFloat(-1.0f,1.0f),
                            0.0f,
                            RangedRandomFloat(-1.0f,1.0f));
        } while(length_squared(rand_dir) > 1.0f);
        if(dot(this_mo.GetFacing(), rand_dir) < 0.0f){
            rand_dir *= -1.0f;
        }
        rand_dir = normalize(rand_dir);
        rand_dir.y += RangedRandomFloat(-0.3f,0.3f);
        random_look_dir = normalize(rand_dir);
        random_look_dir = mix(this_mo.GetFacing(), random_look_dir, 0.5f);
        situation.GetLookTarget(look_target);
    }

    return target_head_dir;
}



void UpdateHeadLook(const Timestep &in ts) {
    vec3 target_head_dir = GetTargetHeadDir(ts);
    const bool _draw_gaze_line = false;
    if(_draw_gaze_line){
        vec3 head_pos = this_mo.GetAvgIKChainPos("head");
        DebugDrawLine(head_pos, head_pos + target_head_dir, vec3(1.0f,0.0f,0.0f), _fade);
        DebugDrawLine(head_pos, head_pos + head_dir, vec3(0.0f,1.0f,0.0f), _fade);
    }

    float target_head_look_opac = 1.0f;
    if((state == _attack_state && attacking_with_throw != 0) ||
        tethered == _TETHERED_REARCHOKE || tethered == _TETHERED_DRAGBODY)
    {
        target_head_look_opac = 0.0f;
    }

    head_look_opac = mix(target_head_look_opac, head_look_opac, pow(0.95f, ts.frames()));
    head_dir = head_dir + head_vel * ts.step();
    vec3 target_head_vel = normalize(mix(target_head_dir, head_dir, look_inertia)) - head_dir;
    head_vel = mix(target_head_vel * 50.0f, head_vel, 0.7f);
    //head_dir = normalize(mix(target_head_dir, head_dir, look_inertia));
    //head_look_opac = 0.0f;
    this_mo.SetIKTargetOffset("head",head_dir * head_look_opac);
    if(!stance_move){
        stance_move_fade_val = mix(stance_move_fade,stance_move_fade_val,pow(0.9f,ts.frames()));
    } else {
        stance_move_fade_val = mix(0.5f,stance_move_fade_val,pow(0.9f,ts.frames()));
    }
    if(state != _movement_state || flip_info.IsFlipping()){
        stance_move_fade_val = 0.0f;
    }
    vec3 flat_head_dir = head_dir;
    flat_head_dir.y = 0.0f;
    flat_head_dir = normalize(flat_head_dir);
    float torso_control = min(0.0,dot(flat_head_dir, this_mo.GetFacing()))+1.0f;
    torso_control *= max(0.3f,stance_move_fade_val);
    torso_control = min(head_look_opac, torso_control);
    if(IsLayerAttacking()){
        layer_attacking_fade = mix(1.0f, layer_attacking_fade, pow(0.9f, ts.frames()));
    } else {
        layer_attacking_fade = mix(0.0f, layer_attacking_fade, pow(0.95f, ts.frames()));
    }
    torso_control *= (1.0f - layer_attacking_fade);
    torso_control *= (1.0f - duck_amount);
    
    if(throw_knife_layer_id != -1){
        layer_throwing_fade = mix(1.0f, layer_attacking_fade, pow(0.9f, ts.frames()));
    } else {
        layer_throwing_fade = mix(0.0f, layer_attacking_fade, pow(0.95f, ts.frames()));
    }
    torso_control = mix(torso_control,0.5f,layer_throwing_fade);
    //torso_control = 0.0f;
    this_mo.SetIKTargetOffset("torso",head_dir*torso_control);
    stance_move_fade = max(0.0f, stance_move_fade - ts.step());
    //Print("stance_move_fade: "+stance_move_fade+"\n");
}

void UpdateEyeLook(const Timestep &in ts){
    if(knocked_out != _awake){
        return;
    }

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
    eye_delay -= ts.step();
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

void UpdateBlink(const Timestep &in ts) {
    const float _blink_speed = 5.0f;
    const float _blink_min_delay = 1.0f;
    const float _blink_max_delay = 5.0f;

    if(knocked_out == _awake){
        if(blink_delay < 0.0f){
            blink_delay = RangedRandomFloat(_blink_min_delay,
                                            _blink_max_delay);
            blinking = true;
            blink_progress = 0.0f;
        }
        if(blinking){
            blink_progress += ts.step() * 5.0f;
            blink_amount = sin(blink_progress*3.14f);
            if(blink_progress > 1.0f){
                blink_amount = 0.0f;
                blinking = false;
            }
        } else {
            blink_amount = 0.0f;
        }
        blink_delay -= ts.step();
    } else if(knocked_out == _unconscious){
        blink_amount = mix(blink_amount, 0.7f, 0.1f);
    }
    this_mo.SetMorphTargetWeight("wink_r",blink_amount,1.0f);
    this_mo.SetMorphTargetWeight("wink_l",blink_amount,1.0f);
}

void UpdateActiveBlockAndDodge(const Timestep &in ts) {
    if(tethered != _TETHERED_FREE){
        return;
    }
    block_stunned = max(0.0f, block_stunned - ts.step());
    UpdateActiveBlockMechanics(ts);
    UpdateActiveDodgeMechanics(ts);
    if(active_blocking){
        if(active_block_flinch_layer == -1 && state != _hit_reaction_state){
            active_block_flinch_layer = 
                this_mo.AddLayer(character_getter.GetAnimPath("blockflinch"),10.0f,0);
        }
    } else {
        if(active_block_flinch_layer != -1){
            this_mo.RemoveLayer(active_block_flinch_layer, 4.0f);
            active_block_flinch_layer = -1;
        } 
    }
}


bool CanBlock(){
    if(state == _movement_state || 
       state == _ragdoll_state ||
       state == _ground_state ||
      (state == _hit_reaction_state && !hit_reaction_thrown) ||
      (state == _attack_state && block_stunned > 0.0f)){
        if(!on_ground || flip_info.IsFlipping()){
            return false;
        } else {
            return true;
        }
    } else {
        return false;
    }
}

void UpdateActiveBlockMechanics(const Timestep &in ts) {
    bool can_block = CanBlock();
    if(WantsToStartActiveBlock(ts) && can_block){
        if(active_block_recharge <= 0.0f){
            active_blocking = true;
            active_block_duration = 0.2f;
        }
        active_block_recharge = 0.2f;
    } 
    if(active_blocking){
        active_block_duration -= ts.step();
        if(active_block_duration <= 0.0f){
            active_blocking = false;
        }
    } else {
        if(active_block_recharge > 0.0f){
            active_block_recharge -= ts.step();
        }
    }
}

void UpdateActiveDodgeMechanics(const Timestep &in ts) {
    bool can_dodge = CanBlock();
    if(WantsToDodge() && can_dodge){
        if(active_dodge_recharge <= 0.0f){
            active_dodging = true;
            active_dodge_duration = 0.2f;
            dodge_dir = GetTargetVelocity();
        }
        active_dodge_recharge = 0.2f;
    } 
    if(active_dodging){
        active_dodge_duration -= ts.step();
        if(active_dodge_duration <= 0.0f){
            active_dodging = false;
        }
    } else {
        if(active_dodge_recharge > 0.0f){
            active_dodge_recharge -= ts.step();
        }
    }
}

void RegenerateHealth(const Timestep &in ts) {
    const float _block_recover_speed = 0.3f;
    const float _temp_health_recover_speed = 0.05f;
    block_health += _block_recover_speed * ts.step();
    block_health = min(temp_health, block_health);
    temp_health += _temp_health_recover_speed * ts.step();
    temp_health = min(permanent_health, temp_health);
    if(blood_damage > 0.0f){
        float damage = min(time_step, blood_damage);
        blood_damage -= damage;
        blood_health -= damage;
        if(blood_health <= 0.0f && knocked_out == _awake){
            SetKnockedOut(_unconscious);
            Ragdoll(_RGDL_LIMP);
        }
    }
}

void UpdateRagDoll(const Timestep &in ts) {
    ragdoll_time += ts.step();
    ragdoll_limp_stun -= ts.step();
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
        
        UpdateRagdollDamping(ts);
    }
    
    if(knocked_out == _awake){
        HandleRagdollRecovery(ts);
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

void RagdollRefresh(int val){
    ragdoll_static_time = 0.0f;
    frozen = false;
    this_mo.SetRagdollDamping(0.0f);
    this_mo.RefreshRagdoll();
}

void UpdateRagdollDamping(const Timestep &in ts) {
    const float _ragdoll_static_threshold = 0.4f; // Velocity below which ragdoll is considered static

    if(length(this_mo.GetAvgVelocity())<_ragdoll_static_threshold){
        ragdoll_static_time += ts.step();
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

    /*if(!this_mo.controlled){
        Print("Ragdoll static time: "+ragdoll_static_time+"\n");
    }*/
}

void SetActiveRagdollFallPose() {
    const float danger_radius = 4.0f;
    vec3 danger_vec;
    col.GetSlidingSphereCollision(this_mo.position, danger_radius * 0.25f); // Create sliding sphere at ragdoll center to detect nearby surfaces
    danger_vec = this_mo.position - sphere_col.adjusted_position;
    danger_vec += normalize(danger_vec) * danger_radius * 0.75f;
    if(sphere_col.NumContacts() == 0){
        col.GetSlidingSphereCollision(this_mo.position, danger_radius * 0.5f); // Create sliding sphere at ragdoll center to detect nearby surfaces
        danger_vec = this_mo.position - sphere_col.adjusted_position;
        danger_vec += normalize(danger_vec) * danger_radius * 0.5f;
    }
    if(sphere_col.NumContacts() == 0){
        col.GetSlidingSphereCollision(this_mo.position, danger_radius); // Create sliding sphere at ragdoll center to detect nearby surfaces
        danger_vec = this_mo.position - sphere_col.adjusted_position;
    }

    float ragdoll_strength = length(this_mo.GetAvgVelocity())*0.1f;
    ragdoll_strength = min(0.8f, ragdoll_strength);
    ragdoll_strength = max(0.0f, ragdoll_strength - ragdoll_limp_stun);
    this_mo.SetRagdollStrength(ragdoll_strength);

    float penetration = length(danger_vec);
    float penetration_ratio = penetration / danger_radius;
    float protect_amount = min(1.0f,max(0.0f,penetration_ratio*4.0f-2.0));
    protect_amount = mix(1.0f, protect_amount, ragdoll_strength / 0.8f);
    this_mo.SetLayerOpacity(ragdoll_layer_fetal, protect_amount); // How much to try to curl up into a ball
    /*if(this_mo.controlled){
        Print("Protect amount: "+protect_amount+"\n");
    }*/

    mat4 torso_transform = this_mo.GetAvgIKChainTransform("torso");
    vec3 torso_vec = torso_transform.GetColumn(1);
    vec3 hazard_dir;
    if(penetration != 0.0f){
        hazard_dir = danger_vec / penetration;
    }
    float front_protect_amount = max(0.0f,dot(torso_vec, hazard_dir) * protect_amount);
    this_mo.SetLayerOpacity(ragdoll_layer_catchfallfront, front_protect_amount); // How much to put arms out front to catch fall

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

void HandleRagdollRecovery(const Timestep &in ts) {
    recovery_time -= ts.step();
    roll_recovery_time -= ts.step();
    if(recovery_time <= 0.0f && length_squared(this_mo.GetAvgVelocity())<_auto_wake_vel_threshold){
        bool can_roll = CanRoll();
        if(can_roll){
            WakeUp(_wake_stand);
        } else {
            WakeUp(_wake_fall);
        }
    } else {
        if(WantsToRollFromRagdoll() && roll_recovery_time <= 0.0f){
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


void SetRagdollType(int type) {
    if(ragdoll_type == type){
        //Print("*Setting ragdoll type to "+type+" but skipping\n");
        return;
    }    
    if(ragdoll_layer_fetal != -1){
        this_mo.RemoveLayer(ragdoll_layer_fetal, 4.0f);       
    }
    if(ragdoll_layer_catchfallfront != -1){
        this_mo.RemoveLayer(ragdoll_layer_catchfallfront, 4.0f);       
    }
    //Print("Setting ragdoll type to "+type+"\n");
    ragdoll_type = type;
    switch(ragdoll_type){
        case _RGDL_LIMP:
            no_freeze = false;
            this_mo.EnableSleep();
            this_mo.SetRagdollStrength(0.0);
            this_mo.SetAnimation("Data/Animations/r_idle.anm",4.0f,_ANM_FROM_START);
            break;
        case _RGDL_FALL:
            no_freeze = false;
            this_mo.EnableSleep();
            this_mo.SetRagdollStrength(1.0);
            this_mo.SetAnimation("Data/Animations/r_flail.anm",4.0f,_ANM_FROM_START);
            ragdoll_layer_catchfallfront = 
                this_mo.AddLayer("Data/Animations/r_catchfallfront.anm",4.0f,0);
            ragdoll_layer_fetal = 
                this_mo.AddLayer("Data/Animations/r_fetal.anm",4.0f,0);
            break;
        case _RGDL_INJURED:
            no_freeze = true;
            this_mo.DisableSleep();
            this_mo.SetRagdollStrength(1.0);
            this_mo.SetAnimation("Data/Animations/r_writhe.anm",4.0f,_ANM_FROM_START);
            //ragdoll_layer_fetal = 
            //    this_mo.AddLayer("Data/Animations/r_grabface.anm",4.0f,0);
            injured_mouth_open = 0.0f;
            break;
        case _RGDL_ANIMATION:
            no_freeze = true;
            this_mo.DisableSleep();
            this_mo.SetRagdollStrength(1.0);
            this_mo.SetAnimation("Data/Animations/r_idle.anm",4.0f,_ANM_FROM_START);
            this_mo.AddLayer("Data/Animations/r_stomachcut.anm",4.0f,_ANM_FROM_START);
            break;
    }
}

void Ragdoll(int type){
    //Print("Ragdoll type " + type+"\n");
    UnTether();
    this_mo.SetRagdollDamping(0.0f);
    HandleAIEvent(_ragdolled);
    const float _ragdoll_recovery_time = 1.0f;
    recovery_time = _ragdoll_recovery_time;
    roll_recovery_time = 0.2f;
    ragdoll_time = 0.0f;
    
    if(state == _ragdoll_state){
        return;
    }
    ledge_info.on_ledge = false;
    this_mo.Ragdoll();
    SetState(_ragdoll_state);
    ragdoll_layer_catchfallfront = -1;
    ragdoll_layer_fetal = -1;
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

void SwitchToBlockedAnim() {
    //this_mo.SetAnimationCallback("");
    this_mo.SwapAnimation(attack_getter.GetBlockedAnimPath());
    this_mo.SetAnimationCallback("void EndAttack()");
    if(attack_getter.GetSwapStance() != attack_getter.GetSwapStanceBlocked()){
        mirrored_stance = !mirrored_stance;
    }
}

// WasBlocked() is executed if this character's attack was blocked by a different character
void WasBlocked() {
    SwitchToBlockedAnim();
    block_stunned = 0.5f;
    block_stunned_by_id = target_id;
}


void LayerRemoved(int id) {
    //Print("Removed layer: "+id+"\n");
    if(id == knife_layer_id){
        //Print("That was the active knife slash layer\n");
        knife_layer_id = -1;
    }
    if(id == throw_knife_layer_id){
        //Print("That was the active knife slash layer\n");
        throw_knife_layer_id = -1;
    }
    if(id == sheathe_layer_id){
        sheathe_layer_id = -1;
    }
}

// Handles what happens if a character was hit.  Includes blocking enemies' attacks, hit reactions, taking damage, going ragdoll and applying forces to ragdoll.
// Type is a string that identifies the action and thus the reaction, dir is the vector from the attacker to the defender, and pos is the impact position.
int WasHit(string type, string attack_path, vec3 dir, vec3 pos, int attacker_id, float attack_damage_mult, float attack_knockback_mult) {
    attack_getter2.Load(attack_path);

    if(knife_layer_id != -1){
        this_mo.RemoveLayer(knife_layer_id, 4.0f);       
    }
    if(throw_knife_layer_id != -1){
        this_mo.RemoveLayer(throw_knife_layer_id, 4.0f);       
    }

    if(type == "grabbed"){
        return WasGrabbed(dir, pos, attacker_id);
    } else if(type == "attackblocked"){
        return BlockedAttack(dir, pos, attacker_id);
    } else if(type == "blockprepare"){
        return PrepareToBlock(dir, pos, attacker_id);
    } else if(type == "attackimpact"){
        return HitByAttack(dir, pos, attacker_id, attack_damage_mult, attack_knockback_mult);
    } else {
        return _invalid;
    }
}

void PrintVec3(vec3 vec){
    Print("("+vec.x + ", " + vec.y + ", " + vec.z + ")");
}

int WasGrabbed(const vec3&in dir, const vec3&in pos, int attacker_id){
    if(state == _ragdoll_state){
        return _miss;
    }
    if(tether_id != attacker_id){
        UnTether();
    }
    MovementObject@ attacker = ReadCharacterID(attacker_id);
    vec3 offset(attacker.position.x - this_mo.position.x,
                0.0f,
                attacker.position.z - this_mo.position.z);
    float dir_rotation = atan2(dir.z, dir.x);
    vec3 facing = this_mo.GetFacing();
    float cur_rotation = atan2(facing.z, facing.x);
    float rot_offset = cur_rotation - dir_rotation;
    this_mo.velocity.x = attacker.velocity.x;
    this_mo.velocity.z = attacker.velocity.z;
    int8 flags = _ANM_MOBILE | _ANM_FROM_START;
    mirrored_stance = false;
    if(attack_getter2.GetMirrored() == 0){
        flags = flags | _ANM_MIRRORED;
        mirrored_stance = true;
    }
    this_mo.SetAnimation(attack_getter2.GetThrownAnimPath(),5.0f,flags);
    this_mo.AddAnimationOffset(offset);
    this_mo.AddAnimationRotOffset(rot_offset);
    this_mo.SetAnimationCallback("void EndHitReaction()");
    HandleAIEvent(_thrown);
    SetState(_hit_reaction_state);
    hit_reaction_anim_set = true;
    hit_reaction_thrown = true;
    flip_info.EndFlip();
    if(tethered == _TETHERED_REARCHOKED){
        HandleAIEvent(_choking);
    }
    return _hit;
}

void HandleWeaponCollision(int other_id, vec3 pos){                   
    if(other_id == -1 || weapon_slots[primary_weapon_slot] == -1){
        return;
    }
    MovementObject@ char = ReadCharacterID(other_id);
    int other_held_weapon = GetCharPrimaryWeapon(char);
    if(other_held_weapon == -1){
        return;
    }
       
    ItemObject@ item_obj_a = ReadItemID(weapon_slots[primary_weapon_slot]);
    ItemObject@ item_obj_b = ReadItemID(other_held_weapon);
    if(item_obj_a.GetNumLines() == 0 ||
       item_obj_b.GetNumLines() == 0)
    {
        return;
    }
    vec3 a_start, a_end;
    vec3 b_start, b_end;
    mat4 trans_a = item_obj_a.GetPhysicsTransform();
    mat4 trans_b = item_obj_b.GetPhysicsTransform();
    vec3 mu, col_point;
    float dist, closest_dist = 0.0f;
    vec3 a_point, b_point;
    int closest_line_a = -1;
    int closest_line_b;

    int num_lines_a = item_obj_a.GetNumLines();
    int num_lines_b = item_obj_b.GetNumLines();
    for(int i=0; i<num_lines_a; ++i){
        a_start = trans_a * item_obj_a.GetLineStart(i);
        a_end = trans_a * item_obj_a.GetLineEnd(i);
        for(int j=0; j<num_lines_b; ++j){
            b_start = trans_b * item_obj_b.GetLineStart(j);
            b_end = trans_b * item_obj_b.GetLineEnd(j);

            vec3 mu = LineLineIntersect(a_start, a_end, b_start, b_end);
            mu.x = min(1.0,max(0.0,mu.x));
            mu.y = min(1.0,max(0.0,mu.y));
            a_point = a_start + (a_end-a_start)*mu.x;
            b_point = b_start + (b_end-b_start)*mu.y;
            dist = distance_squared(a_point, b_point);
            if(closest_line_a == -1 || dist < closest_dist){
                closest_line_a = i;
                closest_line_b = j;
                closest_dist = dist;
                col_point = (a_point + b_point) * 0.5f;
            }
        }        
    }
    

    string mat_a, mat_b;
    mat_a = item_obj_a.GetLineMaterial(closest_line_a);
    mat_b = item_obj_b.GetLineMaterial(closest_line_b);

    string sound;
    if(mat_a == "metal" && mat_b == "metal"){
        sound = "Data/Sounds/weapon_foley/impact/weapon_metal_hit_metal_strong.xml";
        MakeMetalSparks(col_point);
    } else if(mat_a == "wood" && mat_b == "wood"){
        sound = "Data/Sounds/weapon_foley/impact/weapon_staff_hit_staff_strong.xml";
        MakeParticle("Data/Particles/impactfast.xml",col_point,vec3(0.0f));
        MakeParticle("Data/Particles/impactslow.xml",col_point,vec3(0.0f));
        int num_sparks = rand()%5;
        for(int i=0; i<num_sparks; ++i){
            MakeParticle("Data/Particles/woodspeck.xml",col_point,vec3(RangedRandomFloat(-5.0f,5.0f),
                                                                       RangedRandomFloat(-5.0f,5.0f),
                                                                       RangedRandomFloat(-5.0f,5.0f)));
        }   
    } else {
        sound = "Data/Sounds/weapon_foley/impact/weapon_staff_hit_metal_strong.xml";
        MakeParticle("Data/Particles/impactfast.xml",col_point,vec3(0.0f));
        MakeParticle("Data/Particles/impactslow.xml",col_point,vec3(0.0f));
        int num_sparks = rand()%10;
        for(int i=0; i<num_sparks; ++i){
            MakeParticle("Data/Particles/woodspeck.xml",col_point,vec3(RangedRandomFloat(-5.0f,5.0f),
                                                                       RangedRandomFloat(-5.0f,5.0f),
                                                                       RangedRandomFloat(-5.0f,5.0f)));
        }   
    }

    int sound_priority;
    if(this_mo.controlled || char.controlled){
        sound_priority = _sound_priority_very_high;  
    } else {
        sound_priority = _sound_priority_high;  
    }
    PlaySoundGroup(sound, col_point, sound_priority);  
}

int BlockedAttack(const vec3&in dir, const vec3&in pos, int attacker_id){
    string sound;
    if(attack_getter2.GetFleshUnblockable() == 0){
        level.SendMessage("active_blocked "+this_mo.getID()+" "+attacker_id);
        sound = "Data/Sounds/hit/hit_block.xml";
        MakeParticle("Data/Particles/impactfast.xml",pos,vec3(0.0f));
        MakeParticle("Data/Particles/impactslow.xml",pos,vec3(0.0f));

        MovementObject@ char = ReadCharacterID(attacker_id);
        int sound_priority;
        if(this_mo.controlled || char.controlled){
            sound_priority = _sound_priority_very_high;  
        } else {
            sound_priority = _sound_priority_high;  
        } 
        PlaySoundGroup(sound, pos, sound_priority);
    } else {
        HandleWeaponCollision(attacker_id, pos);
    }
    //TimedSlowMotion(0.1f,0.3f, 0.05f);
    if(this_mo.controlled){
        camera.AddShake(0.5f);
    }
    return _block_impact;
}

int IsDodging(){
    return (state == _hit_reaction_state && hit_reaction_dodge)?1:0;
}

int PrepareToBlock(const vec3&in dir, const vec3&in pos, int attacker_id){
    if(active_dodging){
        if(HandleDodge(dodge_dir, attacker_id)){
            return _miss;
        }
    }

    // active_blocking = true;
    if(!on_ground || flip_info.IsFlipping() || !active_blocking || 
        attack_getter2.GetUnblockable() != 0 || 
        (attack_getter2.GetFleshUnblockable() != 0 && weapon_slots[primary_weapon_slot] == -1))
    {
        return _miss;
    }

    if(active_block_flinch_layer != -1){
        this_mo.RemoveLayer(active_block_flinch_layer, 100.0f);
        active_block_flinch_layer = -1;
    }

    if(state != _ragdoll_state && state != _ground_state){
        reaction_getter.Load(attack_getter2.GetReactionPath());
        SetState(_hit_reaction_state);
        hit_reaction_event = "blockprepare";
        active_block_anim = true;

        vec3 flat_dir(dir.x, 0.0f, dir.z);
        flat_dir = normalize(flat_dir) * -1;
        if(length_squared(flat_dir)>0.0f){
            this_mo.SetRotationFromFacing(flat_dir);
        }
    } else if(knocked_out == _awake) {
        WakeUp(_wake_block_stand);
        vec3 impact_dir = attack_getter2.GetImpactDir();
        vec3 right;
        right.x = -dir.z;
        right.z = dir.x;
        vec3 impact_dir_adjusted = impact_dir.x * right +
                                   impact_dir.z * dir;
        impact_dir_adjusted.y = 0.0f;
        this_mo.SetRotationFromFacing(impact_dir_adjusted);
    }

    HandleAIEvent(_activeblocked);
    return _going_to_block;
}

void AddBloodToStabWeapon(int attacker_id) {
    MovementObject@ attacker = ReadCharacterID(attacker_id);
    vec3 char_pos = attacker.position;
    int attacker_held_weapon = GetCharPrimaryWeapon(attacker);
    if(attacker_held_weapon != -1){
        ItemObject@ item_obj = ReadItemID(attacker_held_weapon);
        mat4 trans = item_obj.GetPhysicsTransform();
        int num_lines = item_obj.GetNumLines();
        vec3 dist_point;
        bool found_dist_point = false;
        vec3 start, end;
        float dist, far_dist = 0.0f;
        for(int i=0; i<num_lines; ++i){
            start = trans * item_obj.GetLineStart(i);
            end = trans * item_obj.GetLineEnd(i);
            dist = distance_squared(start, char_pos);
            if(!found_dist_point || dist > far_dist){
                found_dist_point = true;
                dist_point = start;
                far_dist = dist;
            }
            dist = distance_squared(end, char_pos);
            if(dist > far_dist){
                dist_point = end;
                far_dist = dist;
            }
        }
        vec3 weap_dir = normalize(end-start);
        vec3 side = normalize(cross(weap_dir, vec3(RangedRandomFloat(-1.0f,1.0f),
                                                   RangedRandomFloat(-1.0f,1.0f),
                                                   RangedRandomFloat(-1.0f,1.0f))));
        item_obj.AddBloodDecal(dist_point, normalize(side + weap_dir*2.0f), 0.5f);
    }
}

void AddBloodToCutPlaneWeapon(int attacker_id, vec3 dir) {
    MovementObject@ attacker = ReadCharacterID(attacker_id);
    int attacker_held_weapon = GetCharPrimaryWeapon(attacker);
    if(attacker_held_weapon != -1){
        ItemObject@ item_obj = ReadItemID(attacker_held_weapon);
        mat4 trans = item_obj.GetPhysicsTransform();
        mat4 torso_transform = this_mo.GetAvgIKChainTransform("head");
        vec3 char_pos = torso_transform * vec3(0.0f);
        vec3 point;
        vec3 col_point;
        float closest_dist = 0.0f;
        float closest_line = -1;
        vec3 start, end;
        float dist;
        int num_lines = item_obj.GetNumLines();
        for(int i=0; i<num_lines; ++i){
            if(item_obj.GetLineMaterial(i) != "metal"){
                continue;
            }
            start = trans * item_obj.GetLineStart(i);
            end = trans * item_obj.GetLineEnd(i);
            vec3 mu = LineLineIntersect(start, end, this_mo.position, char_pos);
            mu.x = min(1.0,max(0.0,mu.x));
            mu.y = min(1.0,max(0.0,mu.y));
            point = start + (end-start)*mu.x;
            dist = distance_squared(point, char_pos);
            //DebugDrawLine(start, end, vec3(1.0f), _persistent);
            if(closest_line == -1 || dist < closest_dist){
                closest_line = i;
                closest_dist = dist;
                col_point = point;
            }
        }
        vec3 weap_dir = normalize(end-start);
        dir = normalize(dir - dot(dir, weap_dir) * weap_dir);
        //DebugDrawLine(this_mo.position, char_pos, vec3(0.0f,0.0f,1.0f), _persistent);
        //DebugDrawWireSphere(col_point, 0.1f, vec3(1.0f,0.0f,0.0f), _persistent);
        item_obj.AddBloodDecal(col_point, dir, 0.5f);
    }
}

void TakeSharpDamage(float sharp_damage, vec3 pos, int attacker_id) {
    this_mo.AddLayer("Data/Animations/r_painflinch.anm",8.0f,0);
    TakeBloodDamage(sharp_damage);
     /*for(int i=0; i<5; ++i){
        MakeParticle("Data/Particles/bloodcloud.xml",pos,
            vec3(RangedRandomFloat(-1.0f,1.0f),RangedRandomFloat(-1.0f,1.0f),RangedRandomFloat(-1.0f,1.0f)));
        MakeParticle("Data/Particles/bloodsplat.xml",pos,
            vec3(RangedRandomFloat(-2.0f,2.0f),RangedRandomFloat(-2.0f,2.0f),RangedRandomFloat(-2.0f,2.0f)));
     }
     cut_torso = true;
     for(int i=0; i<100; ++i){
            this_mo.CreateBloodDrip("torso", 1, vec3(0.0f,RangedRandomFloat(-1.0f,1.0f),RangedRandomFloat(-1.0f,1.0f)));
     }*/
    if(attack_getter2.HasCutPlane()){
        vec3 cut_plane_local = attack_getter2.GetCutPlane();
        int cut_plane_type = attack_getter2.GetCutPlaneType();
        if(attack_getter2.GetMirrored() == 1){
            cut_plane_local.x *= -1.0f;
        }
        vec3 facing = ReadCharacterID(attacker_id).GetFacing();
        vec3 facing_right = vec3(-facing.z, facing.y, facing.x);
        vec3 up(0.0f,1.0f,0.0f);
        vec3 cut_plane_world = facing * cut_plane_local.z +
            facing_right * cut_plane_local.x +
            up * cut_plane_local.y;
        this_mo.CutPlane(cut_plane_world, pos, facing, cut_plane_type);
        const bool _draw_cut_plane = false;
        vec3 cut_plane_z = normalize(cross(up, cut_plane_world));
        vec3 cut_plane_x = normalize(cross(cut_plane_world, cut_plane_z));
        if(_draw_cut_plane){
            for(int i=-10; i<=10; ++i){
                DebugDrawLine(pos-cut_plane_z*0.5f+cut_plane_x*(i*0.1f)+facing*0.5, pos+cut_plane_z*0.5f+cut_plane_x*(i*0.1f)+facing*0.5, vec3(1.0f,1.0f,1.0f), _fade);
                DebugDrawLine(pos-cut_plane_x*0.5f+cut_plane_z*(i*0.1f)+facing*0.5, pos+cut_plane_x*0.5f+cut_plane_z*(i*0.1f)+facing*0.5, vec3(1.0f,1.0f,1.0f), _fade);
            }
        }
        AddBloodToCutPlaneWeapon(attacker_id, cut_plane_x*0.8f+cut_plane_world*0.2f);
    }
    if(attack_getter2.HasStabDir()){
        int attack_weapon_id = GetCharPrimaryWeapon(ReadCharacterID(attacker_id));
        if(attack_weapon_id != -1){
            int stab_type = attack_getter2.GetStabDirType();
            ItemObject@ item_obj = ReadItemID(attack_weapon_id);
            mat4 trans = item_obj.GetPhysicsTransform();
            mat4 trans_rotate = trans;
            trans_rotate.SetColumn(3, vec3(0.0f));
            vec3 stab_pos = trans * vec3(0.0f,0.0f,0.0f);
            //vec3 stab_dir = trans_rotate * attack_getter2.GetStabDir();
            int num_lines = item_obj.GetNumLines();
            vec3 start = trans * item_obj.GetLineStart(num_lines-1);
            vec3 end = trans * item_obj.GetLineEnd(num_lines-1);
            vec3 stab_dir = normalize(end-start);
            stab_pos -= stab_dir * 5.0f;
            const bool _draw_cut_line = false;
            if(_draw_cut_line){
                DebugDrawLine(stab_pos,
                    stab_pos + stab_dir*10.0f,
                    vec3(1.0f),
                    _fade);
            }
            this_mo.Stab(stab_pos, stab_dir, stab_type);
            AddBloodToStabWeapon(attacker_id);
        }
    }
}

void MakeMetalSparks(vec3 pos){
    int num_sparks = rand()%20;
    for(int i=0; i<num_sparks; ++i){
        MakeParticle("Data/Particles/metalspark.xml",pos,vec3(RangedRandomFloat(-5.0f,5.0f),
                                                         RangedRandomFloat(-5.0f,5.0f),
                                                         RangedRandomFloat(-5.0f,5.0f)));
        
        MakeParticle("Data/Particles/metalflash.xml",pos,vec3(RangedRandomFloat(-5.0f,5.0f),
                                                         RangedRandomFloat(-5.0f,5.0f),
                                                         RangedRandomFloat(-5.0f,5.0f)));
    }   
}

int HitByAttack(const vec3&in dir, const vec3&in pos, int attacker_id, float attack_damage_mult, float attack_knockback_mult){
    if((state == _hit_reaction_state && hit_reaction_dodge) ||
       (attack_getter2.GetHeight() == _high && duck_amount >= 0.5f))
    {
        level.SendMessage("dodged "+this_mo.getID()+" "+attacker_id);
        return _miss;
    }
    if(target_id == -1){
        target_id = attacker_id;
    }
    if(this_mo.controlled){
        camera.AddShake(1.0f);
    }

    if(tether_id != attacker_id){
        UnTether();
    }

    if(attack_getter2.GetSpecial() == "legcannon"){
        block_health = 0.0f;
    }
        
    float block_damage = attack_getter2.GetBlockDamage() * p_damage_multiplier * attack_damage_mult;
    if(this_mo.controlled){
        AchievementEventFloat("player_block_damage", block_damage);
    }
    
    block_health -= block_damage;
    block_health = max(0.0f, block_health);

    float sharp_damage = attack_getter2.GetSharpDamage();

    bool can_passive_block = true;
    if((startled && !this_mo.controlled) ||
       block_health <= 0.0f || 
       flip_info.IsFlipping() || 
       state == _attack_state || 
       !on_ground || 
       blood_health <= 0.0f || 
       state == _ragdoll_state ||
       (sharp_damage > 0.0f && weapon_slots[primary_weapon_slot] == -1))
    {
       can_passive_block = false;
    }

    if(sharp_damage == 0.0f){
        MakeParticle("Data/Particles/impactfast.xml",pos,vec3(0.0f));
        MakeParticle("Data/Particles/impactslow.xml",pos,vec3(0.0f));
    }

    bool knocked_over = false;
    
    if(!can_passive_block){
        if(sharp_damage > 0.0f){        
            TakeSharpDamage(sharp_damage * attack_damage_mult, pos, attacker_id);
        }
		if(sharp_damage == 0.0f || knocked_out != _awake){
            float force = attack_getter2.GetForce()*(1.0f-temp_health*0.5f) * attack_knockback_mult;
            float damage = attack_getter2.GetDamage() * attack_damage_mult;
            HandleRagdollImpact(dir, pos, damage, force);
            knocked_over = true;
            if(!this_mo.controlled){
                this_mo.PlaySoundGroupVoice("hit",0.0f);
            }
            if(sharp_damage > 0.0f && sharp_damage < 0.5f){
                ragdoll_limp_stun = 0.0f;
            }
        }
    } else {
        HandlePassiveBlockImpact(dir, pos);
        if(!this_mo.controlled){
            this_mo.PlaySoundGroupVoice("block_hit",0.0f);
        }
    }
    
    MovementObject@ char = ReadCharacterID(attacker_id);
    int sound_priority;
    if(this_mo.controlled || char.controlled){
        sound_priority = _sound_priority_very_high;  
    } else {
        sound_priority = _sound_priority_high;  
    } 
    if(sharp_damage <= 0.0f){
        if(knocked_over){
            level.SendMessage("knocked_over "+this_mo.getID()+" "+attacker_id);
            if(knocked_out == _dead){
                string sound = "Data/Sounds/hit/hit_hard.xml";
                PlaySoundGroup(sound, pos, sound_priority);
            } else {
                string sound = "Data/Sounds/hit/hit_medium.xml";
                PlaySoundGroup(sound, pos, sound_priority);
            }
        } else {
            level.SendMessage("passive_blocked "+this_mo.getID()+" "+attacker_id);
            string sound = "Data/Sounds/hit/hit_normal.xml";
            PlaySoundGroup(sound, pos, sound_priority);        
        }
    } else {
        string sound;
        if(block_health > 0.0f && weapon_slots[primary_weapon_slot] != -1){
            HandleWeaponCollision(attacker_id, pos);
        } else {
            sound = "Data/Sounds/weapon_foley/cut/flesh_hit.xml";
            PlaySoundGroup(sound, pos, sound_priority);  
        }
        if(RangedRandomFloat(0.0f,1.0f) < drop_weapon_probability){
            DropWeapon();
        }
    }
    active_dodge_recharge = 0.0f;
    
    return _hit;
}

void HandleRagdollImpactImpulse(const vec3&in impulse, const vec3&in pos, float damage){
    GoLimp();
    ragdoll_limp_stun = 0.9f;
    this_mo.ApplyForceToRagdoll(impulse, pos);
    block_health = 0.0f;
    TakeDamage(damage);
    if(startled && knocked_out == _awake){
        TakeDamage(damage);
    }
    temp_health = max(0.0f, temp_health);
}

void HandleRagdollImpact(const vec3&in dir, const vec3&in pos, float damage, float force){
    vec3 impact_dir = attack_getter2.GetImpactDir();
    vec3 right;
    right.x = -dir.z;
    right.z = dir.x;
    right.y = dir.y;
    vec3 impact_dir_adjusted = impact_dir.x * right +
                               impact_dir.z * dir;
    impact_dir_adjusted.y += impact_dir.y;
    HandleRagdollImpactImpulse(impact_dir_adjusted * force, pos, damage);
}

void HandlePassiveBlockImpact(const vec3&in dir, const vec3&in pos){
    
    reaction_getter.Load(attack_getter2.GetReactionPath());
    SetState(_hit_reaction_state);

    hit_reaction_event = "attackimpact";

    vec3 flat_dir(dir.x, 0.0f, dir.z);
    flat_dir = normalize(flat_dir) * -1;
    if(length_squared(flat_dir)>0.0f){
        this_mo.SetRotationFromFacing(flat_dir);
    }
}

bool HandleDodge(const vec3&in dir, int attacker_id){

    vec3 face_dir = ReadCharacterID(attacker_id).position - this_mo.position;
    face_dir.y = 0.0;
    face_dir = normalize(face_dir);
    if(dot(face_dir, dodge_dir) > 0.85f){
        return false;
    }

    vec3 right_face_dir = vec3(face_dir.z, 0.0f, -face_dir.x);
    vec3 right_dir = vec3(dir.z, 0.0f, -dir.x);

    string anim_path;
    if(attack_getter2.GetHeight() == _high){
        anim_path = "Data/Animations/r_dodgebackhigh.anm";
    } else if(attack_getter2.GetHeight() == _medium){
        anim_path = "Data/Animations/r_dodgebackmid.anm";
    } else if(attack_getter2.GetHeight() == _low){
        anim_path = "Data/Animations/r_dodgebacklow.anm";
    }        
    this_mo.SetRotationFromFacing(dir * -1.0f);
    /*if(dot(dir,right_face_dir) > 0.85f || (dot(dir,face_dir)>0.0f && dot(dir,right_face_dir)>0.0f)){
        if(!mirrored_stance){
            anim_path = "Data/Animations/r_dodgeleft.anm";
        } else {
            anim_path = "Data/Animations/r_dodgeright.anm";
        }
        this_mo.SetRotationFromFacing(right_dir*-1.0f);
    }
    if(dot(dir,right_face_dir) < -0.85f || (dot(dir,face_dir)>0.0f && dot(dir,right_face_dir) <= 0.0f)){
        if(mirrored_stance){
            anim_path = "Data/Animations/r_dodgeleft.anm";
        } else {
            anim_path = "Data/Animations/r_dodgeright.anm";
        }
        this_mo.SetRotationFromFacing(right_dir*1.0f);
    }*/

    SetState(_hit_reaction_state);
    hit_reaction_anim_set = true;
    hit_reaction_dodge = true;

    int8 flags = _ANM_MOBILE | _ANM_FROM_START;
    if(mirrored_stance){
        flags = flags | _ANM_MIRRORED;
    }
    this_mo.SetAnimation(anim_path,10.0f,flags);
    this_mo.SetAnimationCallback("void EndHitReaction()");
    //TimedSlowMotion(0.1f,0.4f, 0.15f);
    target_id = attacker_id;
    return true;
}

void EndExecution() {
    executing = false;
}

void EndAttack() {
    this_mo.SetAnimationCallback("");
    if(state != _attack_state){
        return;
    }
    SetState(_movement_state);
    if(!on_ground){
        flip_info.StartLegCannonFlip(this_mo.GetFacing()*-1.0f, leg_cannon_flip);
    }
}

void EndHitReaction() {
    this_mo.SetAnimationCallback("");
    if(state != _hit_reaction_state){
        return;
    }
    SetState(_movement_state);
}

void AchievementEvent(string event_str){
    level.Execute("AchievementEvent(\""+event_str+"\")");
}

void AchievementEventFloat(string event_str, float val){
    level.Execute("AchievementEventFloat(\""+event_str+"\", "+val+")");
}

void SetKnockedOut(int val) {
    knocked_out = val;
    if(!this_mo.controlled){
        if(val == _dead || blood_health <= 0.0f ){
            AchievementEvent("enemy_died");
        }
    }
}

void TakeDamage(float how_much){
    if(this_mo.controlled){
        AchievementEventFloat("player_damage", how_much);
    }
    const float _permananent_damage_mult = 0.4f;
    how_much *= p_damage_multiplier;
    temp_health -= how_much;
    permanent_health -= how_much * _permananent_damage_mult;
    if(permanent_health <= 0.0f && knocked_out != _dead){
        level.SendMessage("character_died "+this_mo.getID());
        SetKnockedOut(_dead);
        this_mo.StopVoice();
    }
    if(temp_health <= 0.0f && knocked_out == _awake){
        level.SendMessage("character_knocked_out "+this_mo.getID());
        SetKnockedOut(_unconscious);
        --lives;
        if(lives > 0){
            RecoverHealth();
            recovery_time = 3.0f;
            roll_recovery_time = 3.0f;
        } else {
            if(this_mo.controlled){
                TimedSlowMotion(0.1f,0.7f, 0.05f);
            }
            if(!this_mo.controlled && tethered == _TETHERED_FREE){
                this_mo.PlaySoundGroupVoice("death",0.4f);
            }
            //SetRagdollType(_RGDL_INJURED);
        }
    }
}

void TakeBloodDamage(float how_much){
    if(this_mo.controlled){
        AchievementEventFloat("player_blood_loss", how_much);
    }
    how_much *= p_damage_multiplier;
    blood_health -= how_much;
    if(blood_health <= 0.0f && knocked_out == _awake){
        SetKnockedOut(_unconscious);
    }
}

void TakeDelayedBloodDamage(float how_much){
    how_much *= p_damage_multiplier;
    blood_damage += how_much;
}

// Animation events are created by the animation files themselves. For example, when the run animation is played, it calls HandleAnimationEvent( "leftrunstep", left_foot_pos ) when the left foot hits the ground.
void HandleAnimationEvent(string event, vec3 world_pos){
    HandleAnimationMiscEvent(event, world_pos);
    HandleAnimationMaterialEvent(event, world_pos);
    HandleAnimationCombatEvent(event, world_pos);
    /*if(this_mo.controlled){
        DebugText("event"+(event_counter--), "Event: "+event, 3.0f);
    }*/
    //DebugDrawText(world_pos, event, _persistent);
}

void AttachWeapon(int which){
    if(weapon_slots[primary_weapon_slot] != -1 && weapon_slots[secondary_weapon_slot] != -1){
        Print("Can't attach weapon, already holding one!");
        return;
    }
    ItemObject@ item_obj = ReadItemID(which);
    vec3 pos = item_obj.GetPhysicsPosition();
    string sound_modifier = item_obj.GetSoundModifier();
    string sound;
    if(sound_modifier == "soft"){
        sound = "Data/Sounds/weapon_foley/impact/soft_bag_on_soft.xml";
    } else {
        sound = "Data/Sounds/weapon_foley/grab/weapon_grap_metal_leather_glove.xml";
    }
    PlaySoundGroup(sound, pos,0.5f);
    if(weapon_slots[primary_weapon_slot] == -1){
        bool mirror = primary_weapon_slot != _held_right;
        this_mo.AttachItemToSlot(which, _at_grip, mirror);
        HandleEditorAttachment(which, _at_grip, mirror);
    } else {
        bool mirror = secondary_weapon_slot != _held_right;
        this_mo.AttachItemToSlot(which, _at_grip, mirror);
        HandleEditorAttachment(which, _at_grip, mirror);
    }
}

void HandleEditorAttachment(int which, int attachment_type, bool mirror){
    Print("Handling editor attachment\n");
    ItemObject@ item_obj = ReadItemID(which);
    int weap_slot = -1;
    if(attachment_type == _at_grip){
        if(mirror){
            weap_slot = _held_left;
        } else {
            weap_slot = _held_right;
        } 
    } else if(attachment_type == _at_sheathe){
        if(mirror){
            weap_slot = _sheathed_right;
        } else {
            weap_slot = _sheathed_left;
        }         
    }
    
    Print("HandleEditorAttachment("+which+", "+attachment_type+", "+mirror+");\n");
    
    if(weap_slot == -1 || weapon_slots[weap_slot] != -1){
        return;
    }    
    weapon_slots[weap_slot] = which;
    
    if(weap_slot == _held_left || weap_slot == _held_right){
        UpdateItemFistGrip();
        UpdatePrimaryWeapon();
    }
}

void GrabWeaponFromBody(int stuck_id, int weapon_id, const vec3 &in pos) {{
    MovementObject@ char = ReadCharacterID(stuck_id);
    char.UnStickItem(weapon_id);
    if(stuck_id != this_mo.getID())
        char.Execute("RagdollRefresh(1);");
        char.ApplyForceToRagdoll(vec3(0.0f,1000.0f,0.0f), pos);
    }
    MakeParticle("Data/Particles/bloodcloud.xml",pos,vec3(0.0f,1.0f,0.0f));
    string sound = "Data/Sounds/weapon_foley/pickup/knife_remove.xml";
    PlaySoundGroup(sound, pos, 0.5f);
}

void Sheathe(int src, int dst){
    if(weapon_slots[src] != -1 && weapon_slots[dst+2] == -1){
        ItemObject@ item_obj = ReadItemID(weapon_slots[src]);
        vec3 pos = item_obj.GetPhysicsPosition();
        string sound = "Data/Sounds/weapon_foley/impact/weapon_drop_light_dirt.xml";
        PlaySoundGroup(sound, pos,0.5f);

        bool dst_right = (dst == _sheathed_right);
        this_mo.SheatheItem(weapon_slots[src], dst_right);
        weapon_slots[dst+2] = weapon_slots[dst];
        weapon_slots[dst] = weapon_slots[src];
        weapon_slots[src] = -1;
        UpdateItemFistGrip();
        UpdatePrimaryWeapon();
    }
}

void UnSheathe(int dst, int src){    
    if(weapon_slots[src] != -1 && weapon_slots[dst] == -1){
        ItemObject@ item_obj = ReadItemID(weapon_slots[src]);
        vec3 pos = item_obj.GetPhysicsPosition();
        string sound = "Data/Sounds/weapon_foley/grab/weapon_grap_metal_leather_glove.xml";
        PlaySoundGroup(sound, pos,0.5f);

        bool dst_right = (dst == _held_right);
        this_mo.UnSheatheItem(weapon_slots[src], dst_right);
        weapon_slots[dst] = weapon_slots[src];
        weapon_slots[src] = weapon_slots[src+2];
        weapon_slots[src+2] = -1;
        UpdateItemFistGrip();
        UpdatePrimaryWeapon();
    }
}

void HandleAnimationMiscEvent(const string&in event, const vec3&in world_pos) {
    if(event == "grabitem" && (weapon_slots[primary_weapon_slot] == -1 || weapon_slots[secondary_weapon_slot] == -1) && knocked_out == _awake && tethered == _TETHERED_FREE )
    {
        vec3 hand_pos;
        if(weapon_slots[_held_right] == -1 && (primary_weapon_slot == _held_right || weapon_slots[_held_left] != -1)){
            hand_pos = this_mo.GetIKTargetTransform("rightarm").GetTranslationPart();
        } else {
            hand_pos = this_mo.GetIKTargetTransform("leftarm").GetTranslationPart();
        }
        int nearest_weapon = GetNearestPickupableWeapon(hand_pos, 0.9f);
        if(nearest_weapon != -1){
            ItemObject@ item_obj = ReadItemID(nearest_weapon);
            vec3 pos = item_obj.GetPhysicsPosition();
            int stuck_id = item_obj.StuckInWhom();
            if(stuck_id != -1){
                GrabWeaponFromBody(stuck_id, item_obj.GetID(), pos);
            }
            AttachWeapon(item_obj.GetID());
            if(pickup_layer != -1){
                this_mo.RemoveLayer(pickup_layer, 4.0f);
                pickup_layer = -1;
            } 
        }
        ++pickup_layer_attempts;
        if(pickup_layer_attempts > 4 && pickup_layer != -1){
            this_mo.RemoveLayer(pickup_layer, 4.0f);
            pickup_layer = -1;
        }
    }
    if(event == "heldweaponswap" ){ 
        if(weapon_slots[_held_left] != -1){
            this_mo.DetachItem(weapon_slots[_held_left]);
        }
        if(weapon_slots[_held_right] != -1){
            this_mo.DetachItem(weapon_slots[_held_right]);
        }
        int temp = weapon_slots[_held_left];
        weapon_slots[_held_left] = weapon_slots[_held_right];
        weapon_slots[_held_right] = temp;
        if(weapon_slots[_held_left] != -1){
            this_mo.AttachItemToSlot(weapon_slots[_held_left], _at_grip, true);
        }
        if(weapon_slots[_held_right] != -1){
            this_mo.AttachItemToSlot(weapon_slots[_held_right], _at_grip, false);
        }
        string sound = "Data/Sounds/weapon_foley/impact/weapon_drop_light_dirt.xml";
        PlaySoundGroup(sound, world_pos,0.5f);
        UpdateItemFistGrip();
        UpdatePrimaryWeapon();
    }
    if(event == "sheatherighthandlefthip" ){ 
        Sheathe(_held_right, _sheathed_left);
    } else if(event == "sheathelefthandrighthip" ){
        Sheathe(_held_left, _sheathed_right);
    } else if(event == "sheathelefthandlefthip" ){
        Sheathe(_held_left, _sheathed_left);
    } else if(event == "sheatherighthandrighthip" ){
        Sheathe(_held_right, _sheathed_right);
    }
    if(event == "unsheatherighthandlefthip" ){ 
        UnSheathe(_held_right, _sheathed_left);
    } else if(event == "unsheathelefthandrighthip" ){
        UnSheathe(_held_left, _sheathed_right);
    } else if(event == "unsheathelefthandlefthi" ){
        UnSheathe(_held_left, _sheathed_left);
    } else if(event == "unsheatherighthandrighthi" ){
        UnSheathe(_held_right, _sheathed_right);
    }
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
        if(this_mo.controlled){
            AchievementEvent("player_was_hit");
        }
        if(state == _hit_reaction_state && hit_reaction_thrown){
            level.SendMessage("character_thrown "+this_mo.getID() + " " + target_id);
        }
        //if(attack_getter2.IsThrow() == 1){
        //    TakeDamage(attack_getter2.GetDamage());
        //}
        GoLimp();
    }
    if(event == "throatcut"){
        if(tether_id != -1){
            MovementObject@ char = ReadCharacterID(tether_id);
            char.Execute("Execute(1);"); 
            vec3 pos = char.GetIKChainPos("head",1); 
            for(int i=0; i<3; ++i){
                AddBloodToCutPlaneWeapon(this_mo.getID(), pos + vec3(RangedRandomFloat(-0.3f,0.3f),RangedRandomFloat(-0.3f,0.3f),RangedRandomFloat(-0.3f,0.3f)));
            }
        }
    }
    if(event == "rightweaponrelease"){
         ThrowWeapon();
    } else if(event == "leftweaponrelease"){
         ThrowWeapon();
    }

    bool attack_event = false;
    if(event == "attackblocked" ||
        event == "attackimpact" ||
        event == "blockprepare")
    {
        attack_event = true;
    }
    if(event == "attackblocked" && feinting){
        string sound = "Data/Sounds/weapon_foley/swoosh/weapon_whoos_big.xml";
        this_mo.PlaySoundGroupAttached(sound,this_mo.position);
        level.SendMessage("character_attack_feint "+this_mo.getID()+" "+target_id);
        return;
    }
    if(event == "blockprepare"){
        can_feint = false;
    }
    if(attack_event == true && target_id != -1){
        vec3 target_pos = ReadCharacterID(target_id).position;
        bool missed = true;
        if(/*event == "blockprepare" || */event == "attackblocked" || distance(this_mo.position, target_pos) < _attack_range + range_extender + 0.1f){
            vec3 facing = this_mo.GetFacing();
            vec3 facing_right = vec3(-facing.z, facing.y, facing.x);
            vec3 dir = normalize(target_pos - this_mo.position);
            int return_val = ReadCharacterID(target_id).WasHit(
                   event, attack_getter.GetPath(), dir, world_pos, this_mo.getID(), p_attack_damage_mult, p_attack_knockback_mult);
            if(return_val == _going_to_block){
                WasBlocked();
            }
            if(return_val == _hit){
                if(attack_getter.GetSharpDamage() > 0.0f && weapon_slots[primary_weapon_slot] != -1){
                    ItemObject@ item_obj = ReadItemID(weapon_slots[primary_weapon_slot]);
                    item_obj.AddBlood();
                }
            }
            if((return_val == _hit || return_val == _block_impact) && this_mo.controlled){
                camera.AddShake(0.5f);
            }
            if(return_val != _miss){
                missed = false;
            }
            if(return_val != _miss && attack_getter.GetSpecial() == "legcannon"){
                this_mo.velocity += dir * -10.0f;
            }
            if(event == "frontkick"){
                if(distance(this_mo.position, target_pos) < 1.0f){
                    vec3 dir = normalize(target_pos - this_mo.position);
                    MovementObject @char = ReadCharacterID(target_id);
                    char.position = this_mo.position + dir;
                }
            }
            /*if((return_val == _hit) && !this_mo.controlled){
                if(rand()%2==0){
                    string sound = "Data/Sounds/voice/torikamal/hit_taunt.xml";
                    this_mo.PlaySoundGroupVoice(sound,0.2f);
                }
            }*/
        }
        if(missed && (event == "attackblocked" || event == "attackimpact")){
            level.SendMessage("character_attack_missed "+this_mo.getID()+" "+target_id);
            MovementObject@ char = ReadCharacterID(target_id);
            int sound_priority;
            if(this_mo.controlled || char.controlled){
                sound_priority = _sound_priority_very_high;  
            } else {
                sound_priority = _sound_priority_high;  
            } 
            string sound = "Data/Sounds/whoosh/hit_whoosh.xml";
            PlaySoundGroup(sound, world_pos, sound_priority);
        }
    }
}

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
    if(!this_mo.controlled){
        vec3 flat = normalize(world_space_vec)*
            sqrt(ground_space_vec.x*ground_space_vec.x + 
                 ground_space_vec.z*ground_space_vec.z);
        ground_space_vec.x = flat.x;
        ground_space_vec.z = flat.z;
    }
    return ground_space_vec;
}

// WantsToDoSomething functions are called by the player or the AI in playercontrol.as or enemycontrol.as
// For the player, they return true when the appopriate control key is down.
void UpdateGroundMovementControls(const Timestep &in ts) {
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
    if(tethered == _TETHERED_DRAGBODY && drag_strength_mult < 0.7f){
        target_duck_amount = 1.0f;    
    }        
    if(tethered == _TETHERED_FREE){
        if(WantsToRoll() && length_squared(target_velocity)>0.2f){
            // flip_info handles actions in the air, including jump flips
            if(!flip_info.IsFlipping()){
                flip_info.StartRoll(target_velocity);
            }
        }

        // If the characters has been touching the ground for longer than _jump_threshold_time and isn't already jumping, update variables 
        // Actual jump is activated after the if(pre_jump) clause below.
        if(WantsToJump() && on_ground_time > _jump_threshold_time && !pre_jump){
            int jump_arm_layer = this_mo.AddLayer("Data/Animations/r_jump_arms.anm",2.0f,0);
            this_mo.SetLayerOpacity(jump_arm_layer, 0.5f); 
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
                if(TargetedJump()){
                    jump_info.StartJump(GetTargetJumpVelocity(), true);
                } else {
                    jump_info.StartJump(target_velocity, false);
                }
                HandleAIEvent(_jumped);
                SetOnGround(false);
                pre_jump = false;
            } else {
                pre_jump_time -= ts.step();
            }
        }
    }

    vec3 flat_ground_normal = ground_normal;
    flat_ground_normal.y = 0.0f;
    float flat_ground_length = length(flat_ground_normal);
    flat_ground_normal = normalize(flat_ground_normal);
    if(flat_ground_length > 0.9f){
        if(this_mo.controlled && dot(target_velocity, flat_ground_normal)<0.0f){
            target_velocity -= dot(target_velocity, flat_ground_normal) *
                               flat_ground_normal;
        }
    }
    if(flat_ground_length > 0.6f){
        if(this_mo.controlled && dot(this_mo.velocity, flat_ground_normal)>-0.8f){
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
    max_speed = run_speed;
    if(tethered != _TETHERED_FREE){
        max_speed *= 0.25f;   
        //if(tethered == _TETHERED_DRAGBODY){
            max_speed *= 0.5f;   
        //}
    }
    float curr_speed = length(this_mo.velocity);

    max_speed *= 1.0 - adjusted_vel.y;
    max_speed = max(curr_speed * 0.98f, max_speed);
    max_speed = min(max_speed, true_max_speed);

    float speed = _walk_accel * run_phase;
    speed = mix(speed,speed*_duck_speed_mult,duck_amount);
    if(in_plant > 0.0f){
        speed *= mix(1.0f,mix(0.3f, 0.6f, duck_amount),in_plant);
    }

    this_mo.velocity += adjusted_vel * ts.step() * speed;
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
    /*DebugDrawWireSphere(this_mo.position,
                        _leg_sphere_size,
                        vec3(1.0f),
                        _delete_on_draw);
    DebugDrawLine(this_mo.position,
                  this_mo.position + this_mo.GetFacing(),
                  vec3(1.0f),
                  _delete_on_draw);*/
    /*mat4 transform = this_mo.GetAvgIKChainTransform("head");
    mat4 transform_offset;
    transform_offset.SetRotationX(-70);
    transform.SetRotationPart(transform.GetRotationPart()*transform_offset);
    DebugDrawWireMesh("Data/Models/fov.obj", transform, vec4(1.0f), _delete_on_draw); 
    
    array<int> nearby_characters;
    GetCharactersInHull("Data/Models/fov.obj", transform, nearby_characters);
    for(int i=0; i<nearby_characters.size(); ++i){
        if(nearby_characters[i] == this_mo.getID()){
            continue;    
        }
        DebugDrawWireSphere(ReadCharacterID(nearby_characters[i]).position,
                            1.0f,
                            vec3(1.0f,0.0f,0.0f),
                            _delete_on_draw);
    }*/
}

void ForceApplied(vec3 force) {
}

float GetTempHealth() {
    return temp_health;
}

vec3 GetDragOffsetWorld(){
    vec3 facing = this_mo.GetFacing();
    vec3 right_facing = vec3(-facing.z, 0.0f, facing.x);
    if(mirrored_stance){
        right_facing *= -1.0f;
    }
    vec3 drag_offset_world = this_mo.position + 
        facing * drag_offset.z + 
        right_facing * drag_offset.x +
        vec3(0.0f,1.0f,0.0f) * drag_offset.y;
    drag_offset_world.y += 0.1f - duck_amount * 0.2f;
    return drag_offset_world;
}

void SetTethered(int val){
    tethered = val;
}

void SetTetherID(int val){
    tether_id = val;
}

bool IsLayerAttacking() {
    return last_knife_time <= time && last_knife_time >= time - 0.3f;
}

// Executed only when the  character is in _movement_state. Called by UpdateGroundControls() 
void UpdateGroundAttackControls(const Timestep &in ts) {
    if(IsLayerAttacking()){
        return;
    }
    //DebugDrawWireSphere(this_mo.position, _attack_range + range_extender, vec3(1.0f), _delete_on_update);
    const float range = (_attack_range + range_extender)*range_multiplier - _leg_sphere_size;
    int attack_id = -1;
    int throw_id = -1;
    int sneak_throw_id = -1;
    if(WantsToAttack()){
        int closest_id = GetClosestCharacterID(range, _TC_ENEMY | _TC_CONSCIOUS);
        if(closest_id != -1){
            int danger_id = GetClosestCharacterID(range, _TC_ENEMY | _TC_CONSCIOUS | _TC_NON_RAGDOLL);
            if(danger_id == -1){
                attack_id = closest_id;
            } else {
                attack_id = danger_id;
            }
        }
    }
    if(WantsToThrowEnemy()){
        throw_id = GetClosestCharacterID(range, _TC_ENEMY | _TC_CONSCIOUS | _TC_NON_RAGDOLL | _TC_THROWABLE);
        sneak_throw_id = GetClosestCharacterID(range, _TC_ENEMY | _TC_CONSCIOUS | _TC_NON_RAGDOLL | _TC_UNAWARE);
    }
    if(throw_id != -1){
        if(this_mo.controlled){
            AchievementEvent("player_counter_attacked");
        }
        SetState(_attack_state);
        attack_animation_set = false;
        attacking_with_throw = 1;
        can_feint = false;
        feinting = false;
        target_id = throw_id;
    } else if(sneak_throw_id != -1 && 
        abs(this_mo.position.y - ReadCharacterID(sneak_throw_id).position.y) < 
        _max_tether_height_diff)
    {
        if(this_mo.controlled){
            AchievementEvent("player_sneak_attacked");
        }
        SetState(_attack_state);
        attack_animation_set = false;
        attacking_with_throw = 2;
        can_feint = false;
        feinting = false;
        target_id = sneak_throw_id;
        tethered = _TETHERED_REARCHOKE;
        tether_id = target_id;
        MovementObject @char = ReadCharacterID(target_id);
        tether_rel = char.position - this_mo.position;
        tether_rel.y = 0.0f;
        tether_rel = normalize(tether_rel);
        char.Execute("SetTethered(_TETHERED_REARCHOKED);" +
                     "SetTetherID(" + this_mo.getID() + ");");
        
        char.MaterialEvent("choke_grab", char.position);
        //PlaySoundGroup("Data/Sounds/hit/grip.xml", this_mo.position);
    } else if(attack_id != -1){
        if(this_mo.controlled){
            AchievementEvent("player_attacked");
        }
        LoadAppropriateAttack(false);
        if(attack_getter.GetAsLayer() == 1){
            if(mirrored_stance && state == _movement_state){
                mirrored_stance = left_handed;
                ApplyIdle(4.0f, true);
            }
            int flags = 0;
            if(primary_weapon_slot == _held_left){
                flags = _ANM_MIRRORED;
            }
            if(backslash){
                knife_layer_id = this_mo.AddLayer("Data/Animations/r_knifebackslash.anm",7.0f,flags);
                attack_getter.Load("Data/Attacks/knifebackslash.xml");
                //Print("Back slash\n");
            } else {
                knife_layer_id = this_mo.AddLayer("Data/Animations/r_knifeslash.anm",7.0f,flags);
                attack_getter.Load("Data/Attacks/knifeslash.xml");
                //Print("Front slash\n");
            }
            backslash = !backslash;
            last_knife_time = time;
            if(!this_mo.controlled){
                this_mo.PlaySoundGroupVoice("attack",0.0f);
            }
        } else {
            if(this_mo.controlled){
                AchievementEvent("player_attacked");
            }
            SetState(_attack_state);
            attack_animation_set = false;
        }
        attacking_with_throw = 0;
        can_feint = true;
        feinting = false;
        target_id = attack_id;
    } 
}

void UpdateAirAttackControls() {
    int air_attack_id = -1;
    if(WantsToAttack()){
        int closest_id = GetClosestCharacterID(3.0f, _TC_ENEMY | _TC_CONSCIOUS);
        air_attack_id = closest_id;
    }
    if(air_attack_id == -1){
        return;
    }
    if(WantsToAttack() && !flip_info.IsFlipping() &&
        distance(this_mo.position + this_mo.velocity * 0.3f,
                 ReadCharacterID(air_attack_id).position + ReadCharacterID(air_attack_id).velocity * 0.3f) <= _attack_range + range_extender)
    {
        target_id = air_attack_id;
        SetState(_attack_state);
        can_feint = false;
        feinting = false;
        attack_animation_set = false;
        attacking_with_throw = 0;
    }
}

// Executed only when the  character is in _movement_state.  Called by UpdateMovementControls() .
void UpdateGroundControls(const Timestep &in ts) {
    if(tethered == _TETHERED_FREE){
        UpdateGroundAttackControls(ts);
    } else if(tethered == _TETHERED_REARCHOKE && WantsToAttack() && !executing && weapon_slots[primary_weapon_slot] != -1) {
        //Print("Throat cut!\n");
        uint8 flags = _ANM_FROM_START;
        if(mirrored_stance){
            flags = flags|_ANM_MIRRORED;   
        }
        this_mo.SetAnimation("Data/Animations/r_throatcutter.anm", 10.0f, flags);
        this_mo.SetAnimationCallback("void EndExecution()");
        this_mo.SetAnimatedItemID(0, weapon_slots[primary_weapon_slot]);
        executing = true;        
        vec3 pos = ReadItemID(weapon_slots[primary_weapon_slot]).GetPhysicsPosition();
        string sound = "Data/Sounds/weapon_foley/cut/flesh_hit.xml";
        PlaySoundGroup(sound, pos, _sound_priority_very_high);  
        MovementObject@ char = ReadCharacterID(tether_id);
        char.CutPlane(vec3(0.0f,1.0f,0.0f), pos, this_mo.GetFacing() * -1.0f, 0);
        char.Execute("Execute(2);");
    }
    UpdateGroundMovementControls(ts);
}

// handles tilting caused by accelerating when moving on the ground.
void HandleAccelTilt(const Timestep &in ts) {
    if(on_ground){
        if(feet_moving && state == _movement_state){
            target_tilt = this_mo.velocity * 0.5f;
            accel_tilt = mix((this_mo.velocity - old_vel)*120.0f/ts.frames(), accel_tilt, pow(0.95f,ts.frames()));
        } else {
            target_tilt = vec3(0.0f);
            accel_tilt *= pow(0.8f,ts.frames());
        }
        target_tilt += accel_tilt;
        target_tilt.y = 0.0f;
        old_vel = this_mo.velocity;
    } else {
        accel_tilt = vec3(0.0f);
        old_vel = vec3(0.0f);
    }
}

void ApplyIdle(float speed, bool start){
    uint8 flags = 0;
    if(mirrored_stance){
        flags = flags|_ANM_MIRRORED;   
    }
    if(start){
        flags = flags | _ANM_FROM_START;
    }

    if(blood_health < 1.0f){
        if(blood_health < 0.5f && length_squared(this_mo.velocity) < 0.5f){
            this_mo.SetAnimAndCharAnim("Data/Animations/r_woundedidle.xml", speed, flags,"idle");
        } else {
            this_mo.SetAnimAndCharAnim("Data/Animations/r_halfwoundedidle.xml", speed, flags,"idle");
        }
    } else {
        if(idle_type == _combat){
            this_mo.SetCharAnimation("idle",speed,flags);
        } else {
            string path;
            if(idle_type == _active){
                path = "Data/Animations/r_actionidle.xml";
            } else if(idle_type == _stand){
                path = "Data/Animations/r_relaxidle.xml";
            }
            this_mo.SetAnimAndCharAnim(path, speed, flags,"idle");
        }
    }
    /*if(this_mo.controlled){
        DebugText("a","Primary weapon: "+weapon_slots[primary_weapon_slot],0.5f);
    }*/
    this_mo.SetAnimatedItemID(0, weapon_slots[primary_weapon_slot]);
}

// Executed only when the  character is in _movement_state.  Called from the update() function.
void UpdateMovementControls(const Timestep &in ts) {
    if(on_ground){ 
        if(!flip_info.HasControl()){
            UpdateGroundControls(ts);
        } 
        flip_info.UpdateRoll(ts);
    } else {
        if(ledge_info.on_ledge){
            ledge_info.UpdateLedge(ts);
            flip_info.UpdateFlip(ts);
        } else {
            jump_info.UpdateAirControls(ts);
            UpdateAirAttackControls();
            if(jump_info.ClimbedUp()){
                SetOnGround(true);
                duck_amount = 1.0f;
                duck_vel = 2.0f;
                target_duck_amount = 1.0f;
                ApplyIdle(20.0f, true);
                HandleBumperCollision();
                HandleStandingCollision();
                this_mo.position = sphere_col.position;
                //this_mo.velocity = vec3(0.0f);
                this_mo.velocity = GetTargetVelocity() * true_max_speed * 0.2f;
                feet_moving = false;
                this_mo.MaterialEvent("land_soft", this_mo.position);
            } else {
                flip_info.UpdateFlip(ts);
                
                target_tilt = vec3(this_mo.velocity.x, 0, this_mo.velocity.z)*2.0f;
                vec3 flail_tilt(sin(time*5.0f)*10.0f,0.0f,cos(time*3.0f+0.75f)*10.0f);
                target_tilt += jump_info.GetFlailingAmount()*flail_tilt;
                if(abs(this_mo.velocity.y)<_tilt_transition_vel && !flip_info.HasFlipped()){
                    target_tilt *= pow(abs(this_mo.velocity.y)/_tilt_transition_vel,0.5);
                }
                if(this_mo.velocity.y<0.0f || flip_info.HasFlipped()){
                    target_tilt *= -1.0f;
                }
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

float GetVisionDistance(const vec3&in target_pos){
    float direct_vision = dot(this_mo.GetFacing(), normalize(target_pos-this_mo.position));
    direct_vision = max(0.0f, direct_vision);
    return direct_vision * vision_threshold;
}

int GetClosestCharacterInArray(vec3 pos, array<int> characters, uint16 flags, float range){
    int num = characters.size();
    int closest_id = -1;
    float closest_dist = 0.0f;

    for(int i=0; i<num; ++i){
        if(this_mo.getID() == characters[i]){
            continue;
        }
        MovementObject@ char = ReadCharacterID(characters[i]);
        if(flags & _TC_CONSCIOUS != 0 && char.GetIntVar("knocked_out") != _awake){
            continue;
        }

        if(flags & _TC_UNCONSCIOUS != 0 && char.GetIntVar("knocked_out") == _awake){
            continue;
        }
        
        character_getter.Load(this_mo.char_path);
        if(flags & _TC_ENEMY != 0 && this_mo.OnSameTeam(char))
        {
            continue;
        }

        if(flags & _TC_ALLY != 0 && !this_mo.OnSameTeam(char))
        {
            continue;
        }
        
        if(flags & _TC_IDLE != 0 && 
           char.QueryIntFunction("int IsIdle()") == 0)
        {
            continue;
        }

        if(flags & _TC_THROWABLE != 0 && 
           (char.GetFloatVar("block_stunned") == 0.0f ||
            char.GetIntVar("block_stunned_by_id") != this_mo.getID()))
        {
            continue;
        }
        
        if(flags & _TC_NON_RAGDOLL != 0 && 
           char.GetIntVar("state") == _ragdoll_state)
        {
            continue;
        }
        
        if(flags & _TC_RAGDOLL != 0 && 
           char.GetIntVar("state") != _ragdoll_state)
        {
            continue;
        }
        
        if(flags & _TC_UNAWARE != 0 && 
           char.QueryIntFunction("int IsUnaware()")!=1)
        {
            continue;
        }
        
        vec3 target_pos = char.position;
        if(flags & _TC_VEL_OFFSET != 0){
            target_pos += char.velocity * 0.2f;
        }
        float dist = distance_squared(pos, target_pos);
        if(range > 0.0f && dist > range * range){
            continue;
        }
        if(closest_id == -1 || dist < closest_dist){
           closest_dist = dist;
           closest_id = characters[i];
        }
    }
    return closest_id;
}

void GetVisibleCharacters(uint16 flags, array<int> &visible_characters){
    mat4 transform = this_mo.GetAvgIKChainTransform("head");
    mat4 transform_offset;
    transform_offset.SetRotationX(-70);
    transform.SetRotationPart(transform.GetRotationPart()*transform_offset);
    array<int> nearby_characters;
    GetCharactersInHull("Data/Models/fov.obj", transform, nearby_characters);
    //DebugDrawWireMesh("Data/Models/fov.obj", transform, vec4(1.0f), _fade);
    vec3 head_pos = this_mo.GetAvgIKChainPos("head");
    for(uint i=0; i<nearby_characters.size(); ++i){
        if(this_mo.getID() != nearby_characters[i] &&
           ReadCharacterID(nearby_characters[i]).VisibilityCheck(head_pos))
        {
            visible_characters.push_back(nearby_characters[i]);
        }
    }
}

int GetClosestVisibleCharacterID(uint16 flags){
    array<int> visible_characters;
    GetVisibleCharacters(flags, visible_characters);
    return GetClosestCharacterInArray(this_mo.position, visible_characters, flags, 0.0f);
}

int GetClosestCharacterID(float range, uint16 flags){
    array<int> nearby_characters;
    GetCharactersInSphere(this_mo.position, range + 1.0f, nearby_characters);
    return GetClosestCharacterInArray(this_mo.position, nearby_characters, flags, range + _leg_sphere_size);
}

// this is called when the character lands in a non-ragdoll mode
void Land(vec3 vel, const Timestep &in ts) {
    // this is true when the character initiated a flip during jump and isn't finished yet
    if(flip_info.ShouldRagdollOnLanding()){
        level.SendMessage("character_failed_flip "+this_mo.getID());
        GoLimp();
        return;
    }

    SetOnGround(true);
    
    float land_speed = 10.0f;//min(30.0f,max(10.0f, -vel.y));
    ApplyIdle(land_speed, true);

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
    }

    if(WantsToCrouch()){
        duck_vel = max(6.0f,duck_vel);
    }

    feet_moving = false;

    flip_info.Land();
    old_slide_vel = this_mo.velocity;
    this_mo.velocity.y = max(this_mo.velocity.y, -10.0f);
}

void GetCollisionSphere(vec3 &out offset, vec3 &out scale, float &out size){
    if(on_ground){
        offset = vec3(0.0f,mix(0.3f,0.15f,duck_amount),0.0f);
        scale = vec3(1.0f,mix(1.2f,0.6f,duck_amount),1.0f);
        size = _bumper_size;
    } else {
        offset = vec3(0.0f,mix(0.2f,0.35f,flip_info.GetTuck()),0.0f);
        scale = vec3(1.0f,mix(1.25f,1.0f,flip_info.GetTuck()),1.0f);
        size = _leg_sphere_size;
    }
}

vec3 HandleBumperCollision(){
    vec3 offset;
    vec3 scale;
    float size;
    GetCollisionSphere(offset, scale, size);
    col.GetSlidingScaledSphereCollision(this_mo.position+offset, size, scale);
    if(_draw_collision_spheres){
        DebugDrawWireScaledSphere(this_mo.position+offset,size,scale,vec3(0.0f,1.0f,0.0f),_delete_on_update);
    }
    // the value of sphere_col.adjusted_position variable was set by the GetSlidingSphereCollision() called on the previous line.
    this_mo.position = sphere_col.adjusted_position-offset;
    return (sphere_col.adjusted_position - sphere_col.position);
}

vec3 HandlePiecewiseBumperCollision(vec3 old_pos){
    vec3 new_pos = this_mo.position; 
    vec3 old_new_pos = new_pos;
    old_pos.y += 0.3f;
    new_pos.y += 0.3f;
    vec3 offset;
    vec3 test_pos = mix(old_pos, new_pos, 0.25f);
    col.GetSlidingSphereCollision(test_pos, _bumper_size);
    offset = sphere_col.adjusted_position - sphere_col.position;
    new_pos += offset/0.25f;
    test_pos = mix(old_pos, new_pos, 0.5f);
    col.GetSlidingSphereCollision(test_pos, _bumper_size);
    offset = sphere_col.adjusted_position - sphere_col.position;
    new_pos += offset/0.5f;
    test_pos = mix(old_pos, new_pos, 0.75f);
    col.GetSlidingSphereCollision(test_pos, _bumper_size);
    offset = sphere_col.adjusted_position - sphere_col.position;
    new_pos += offset/0.75f;
    test_pos = mix(old_pos, new_pos, 1.0f);
    col.GetSlidingSphereCollision(test_pos, _bumper_size);
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
    col.GetSweptSphereCollision(upper_pos,
                                 lower_pos,
                                 _leg_sphere_size);

    if(_draw_collision_spheres){
        DebugDrawWireSphere(upper_pos,_leg_sphere_size,vec3(0.0f,0.0f,1.0f),_delete_on_update);
        DebugDrawWireSphere(lower_pos,_leg_sphere_size,vec3(0.0f,0.0f,1.0f),_delete_on_update);
    }
    return (sphere_col.position == lower_pos);
}

void CheckForVelocityShock(float vert_vel) {
    float shock = vert_vel * -1.0f;
    //Print("Velocity shock: "+shock+"\n");
    if(shock > _shock_damage_threshold){
        TakeDamage((shock-_shock_damage_threshold)*_shock_damage_multiplier);
        if(knocked_out == _unconscious){
            Ragdoll(_RGDL_INJURED);
            string sound = "Data/Sounds/hit/hit_hard.xml";
            PlaySoundGroup(sound, this_mo.position);
            /*for(int i=0; i<500; ++i){
                MakeParticle("Data/Particles/bloodsplat.xml",this_mo.position,
                    vec3(RangedRandomFloat(-2.0f,2.0f),RangedRandomFloat(-2.0f,2.0f),RangedRandomFloat(-2.0f,2.0f))*3.0f);
            }*/
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

PredictPathOutput PredictPath(vec3 start, vec3 end){
    PredictPathOutput predict_path_output;
    predict_path_output.type = _ppt_none;

    vec3 raycast_point = NavRaycast(start, end);
    if(distance_squared(raycast_point, NavRaycast(start, end + normalize(end-start))) > 0.01f){
        return predict_path_output;
    }
    vec3 dir = end - start;
    dir.y = 0.0f;
    dir = normalize(dir);
    vec3 right = vec3(-dir.z, 0.0f, dir.x);
    
    vec3 point = raycast_point + vec3(0.0f,2.5f,0.0f);
    col.GetSlidingSphereCollision(point,2.0f);
    if(sphere_col.NumContacts() == 0){
        //DebugDrawWireSphere(point,2.0f,vec3(1.0f,0.0f,0.0f),_delete_on_update);
        col.GetSweptSphereCollision(point + dir * 4.0f, point + dir * 4.0f+ vec3(0.0f,-100.0f,0.0f), _leg_sphere_size);
        vec3 fall_point = sphere_col.position;
        //DebugDrawWireSphere(fall_point,_leg_sphere_size,vec3(1.0f,1.0f,1.0f),_delete_on_update);
        
        vec3 low = fall_point;
        vec3 high = fall_point;
        high.y = start.y;
        /*DebugDrawLine(start, high, vec3(1.0f), _fade);
        DebugDrawLine(low, high, vec3(1.0f), _fade);
        DebugDrawLine(low, low+right*0.1f, vec3(1.0f), _fade);
        DebugDrawLine(low, low-right*0.1f, vec3(1.0f), _fade);
        DebugDrawLine(high, high+right*0.1f, vec3(1.0f), _fade);
        DebugDrawLine(high, high-right*0.1f, vec3(1.0f), _fade);*/

        predict_path_output.type = _ppt_drop;
        predict_path_output.start_pos = high;
        predict_path_output.end_pos = low;
    } else {
        //DebugDrawWireSphere(point,2.0f,vec3(1.0f,1.0f,1.0f),_delete_on_update);
        vec3 sphere_offset = normalize(point - sphere_col.adjusted_position);
        vec3 intersect = sphere_col.adjusted_position + sphere_offset * 2.0f;
        sphere_offset.y = 0.0f;
        sphere_offset = normalize(sphere_offset);
        //DebugDrawWireSphere(intersect,1.0f,vec3(0.0f,1.0f,0.0f),_delete_on_update);
        vec3 ledge_height_check = intersect - sphere_offset*_leg_sphere_size;
        ledge_height_check.y = start.y;
        LedgeHeightInfo ledge_height_info = GetLedgeHeightInfo(ledge_height_check, sphere_offset);
        if(ledge_height_info.success){
            vec3 low = raycast_point;
            vec3 high = point;
            high.y = ledge_height_info.edge_height;
            vec3 sphere_offset_right(-sphere_offset.z, 0.0f, sphere_offset.x);
            /*DebugDrawLine(start, low, vec3(1.0f), _fade);
            DebugDrawLine(low, high, vec3(1.0f), _fade);
            DebugDrawLine(low, low+sphere_offset_right*0.1f, vec3(1.0f), _fade);
            DebugDrawLine(low, low-sphere_offset_right*0.1f, vec3(1.0f), _fade);
            DebugDrawLine(high, high+sphere_offset_right*0.1f+vec3(0.0f,-0.3f,0.0f), vec3(1.0f), _fade);
            DebugDrawLine(high, high-sphere_offset_right*0.1f+vec3(0.0f,-0.3f,0.0f), vec3(1.0f), _fade);*/
            predict_path_output.type = _ppt_climb;
            predict_path_output.start_pos = low;
            predict_path_output.end_pos = high;
            predict_path_output.normal = sphere_offset;
        }
    }
    return predict_path_output;
}

void HandleGroundCollisions(const Timestep &in ts) {
    vec3 bumper_collision_response = HandleBumperCollision();
    /*if(!this_mo.controlled && length_squared(bumper_collision_response) > 0.0f){
        if(ledge_info.CheckLedges(true)){
            HandleAIEvent(_can_climb);
        }
    }*/
    this_mo.velocity += bumper_collision_response / ts.step(); // Push away from wall, and apply velocity change verlet style

    //if(sphere_col.NumContacts() != 0 && flip_info.ShouldRagdollIntoWall()){
    //    GoLimp();    
    //}

    if((/*sphere_col.NumContacts() != 0 ||*/                                // If standing on overly-sloped surface, start this_mo.controlled fall
        ground_normal.y < _ground_normal_y_threshold)                       
        && this_mo.velocity.y > 0.2f &&
        false)
    {
        SetOnGround(false);
        jump_info.StartFall();
        UnTether();
    }

    bool in_air = HandleStandingCollision();                                // Move vertically to stand on surface, or fall if there is no surface
    if(in_air){
        SetOnGround(false);
        jump_info.StartFall();
        UnTether();
    } else {
        this_mo.position = sphere_col.position;
        /*DebugDrawWireSphere(sphere_col.position,
        sphere_col.radius,
        vec3(1.0f,0.0f,0.0f),
        _delete_on_update);*/
        for(int i=0; i<sphere_col.NumContacts(); i++){
            const CollisionPoint contact = sphere_col.GetContact(i);
            float dist = distance(contact.position, this_mo.position);
            if(dist <= _leg_sphere_size + 0.01f){
                ground_normal = ground_normal * 0.9f +                      // Calculate ground_normal with moving average of contact point normals
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

        /*if(flip_info.ShouldRagdollIntoSteepGround() &&
        dot(this_mo.GetFacing(),ground_normal) < -0.6f){
        GoLimp();    
        }*/
    }
}

void HandleAirCollisions(const Timestep &in ts) {
    vec3 initial_vel = this_mo.velocity;
    vec3 offset = this_mo.position - last_col_pos; 
    this_mo.position = last_col_pos;
    bool landing = false;
    vec3 landing_normal;
    vec3 old_vel = this_mo.velocity;
    for(int i=0; i<ts.frames(); ++i){                                        // Divide movement into multiple pieces to help prevent surface penetration
        if(on_ground){
            break;
        }
        this_mo.position += offset/ts.frames();
        vec3 col_offset;
        vec3 col_scale;
        float size;
        GetCollisionSphere(col_offset, col_scale, size);
        col.GetSlidingScaledSphereCollision(this_mo.position+col_offset, _leg_sphere_size, col_scale);
        if(_draw_collision_spheres){
            DebugDrawWireScaledSphere(this_mo.position+col_offset, _leg_sphere_size, col_scale, vec3(0.0f,1.0f,0.0f), _delete_on_update);
        }
        this_mo.position = sphere_col.adjusted_position-col_offset;         // Collide like a sliding sphere with verlet-integrated velocity response
        vec3 adjustment = (this_mo.position - (sphere_col.position-col_offset));
        adjustment.y = min(0.0f,adjustment.y);
        this_mo.velocity += adjustment / (ts.step());
        offset += (sphere_col.adjusted_position - sphere_col.position) * ts.frames();
        vec3 closest_point;
        float closest_dist = -1.0f;
        for(int i=0; i<sphere_col.NumContacts(); i++){
            const CollisionPoint contact = sphere_col.GetContact(i);
            if(contact.normal.y < _ground_normal_y_threshold){              // If collision with a surface that can't be walked on, check for wallrun
                float dist = distance_squared(contact.position, this_mo.position);
                if(closest_dist == -1.0f || dist < closest_dist){
                    closest_dist = dist;
                    closest_point = contact.position;
                }
            }
        }    
        if(closest_dist != -1.0f){
            jump_info.HitWall(normalize(closest_point-this_mo.position));
        }
        for(int i=0; i<sphere_col.NumContacts(); i++){
            if(landing){
                break;
            }
            const CollisionPoint contact = sphere_col.GetContact(i);
            if(contact.normal.y > _ground_normal_y_threshold ||
               (this_mo.velocity.y < 0.0f && contact.normal.y > 0.2f))
            {                                                               // If collision with a surface that can be walked on, then land
                if(air_time > 0.1f){
                    landing = true;
                    landing_normal = contact.normal;
                }
            }
        }
    }
    if(landing){
        CheckForVelocityShock(old_vel.y);                                   // Check landing damage from high-speed falls
        if(knocked_out == _awake){                                          // If still conscious, land properly
            ground_normal = landing_normal;
            Land(initial_vel, ts);
            if(state != _ragdoll_state){
                SetState(_movement_state);
            }
        }
    }
}


void HandleLedgeCollisions(const Timestep &in ts) {
    if(ledge_info.ghost_movement){
        return;
    }
    vec3 col_offset(0.0f,0.8f,0.0f);
    vec3 col_scale(1.05f);
    col.GetSlidingScaledSphereCollision(this_mo.position+col_offset, _leg_sphere_size, col_scale);
    if(_draw_collision_spheres){
        DebugDrawWireScaledSphere(this_mo.position+col_offset, _leg_sphere_size, col_scale, vec3(0.0f,1.0f,0.0f), _delete_on_update);
    }
    this_mo.position = sphere_col.adjusted_position-col_offset;                 // Collide like a sliding sphere with verlet-integrated velocity response
    vec3 adjustment = (this_mo.position - (sphere_col.position-col_offset));
    //Print("Adjustment: "+adjustment.x+" "+adjustment.y+" "+adjustment.z+"\n");
    this_mo.velocity += adjustment / ts.step();
    vec3 closest_point;
    float closest_dist = -1.0f;
    for(int i=0; i<sphere_col.NumContacts(); i++){
        const CollisionPoint contact = sphere_col.GetContact(i);
        if(contact.normal.y < _ground_normal_y_threshold){                      // If collision with a surface that can't be walked on, check for wallrun
            float dist = distance_squared(contact.position, this_mo.position);
            if(closest_dist == -1.0f || dist < closest_dist){
                closest_dist = dist;
                closest_point = contact.position;
            }
        }
    }    
}

void HandleCollisions(const Timestep &in ts) {
    vec3 initial_vel = this_mo.velocity;
    if(_draw_collision_spheres){
        DebugDrawWireSphere(this_mo.position,
                            _leg_sphere_size,
                            vec3(1.0f,1.0f,1.0f),
                            _delete_on_update);
    }    
    if(on_ground){
        HandleGroundCollisions(ts);
    } else {
        if(ledge_info.on_ledge){
            HandleLedgeCollisions(ts);
        } else {
            HandleAirCollisions(ts);
        }
    }
    last_col_pos = this_mo.position;

    if(dot(initial_vel, this_mo.velocity) < 0.0f){                              // If velocity is in opposite direction from old velocity,
        vec3 initial_dir = normalize(initial_vel);                              // flatten it against plane with normal of old velocity
        float wrong_dist = -dot(initial_dir, this_mo.velocity);
        this_mo.velocity += initial_dir * wrong_dist;
    }

    if(length_squared(initial_vel) < length_squared(this_mo.velocity)){         // If speed is greater than before collision, set it to the
        this_mo.velocity = normalize(this_mo.velocity)*length(initial_vel);     // old speed
    }
}


void UpdateDuckAmount(const Timestep &in ts) { // target_duck_amount is 1.0 when the character should crouch down, and 0.0 when it should stand straight.
    const float _duck_accel = 120.0f;
    const float _duck_vel_inertia = 0.89f;
    duck_vel += (target_duck_amount - duck_amount) * ts.step() * _duck_accel;
    duck_vel *= pow(_duck_vel_inertia,ts.frames());
    duck_amount += duck_vel * ts.step();
    duck_amount = min(1.0,duck_amount);
}


void UpdateThreatAmount(const Timestep &in ts) { 
    target_threat_amount = (WantsToAttack() && state == _movement_state || state == _attack_state)?1.0f:0.0f;
    const float _threat_accel = (weapon_slots[primary_weapon_slot] != -1)?150.0f:300.0f;
    const float _threat_vel_inertia = 0.89f;
    threat_vel += (target_threat_amount - threat_amount) * ts.step() * _threat_accel;
    threat_vel *= pow(_threat_vel_inertia,ts.frames());
    threat_amount += threat_vel * ts.step();
}


void UpdateGroundAndAirTime(const Timestep &in ts) { // tells how long the character has been touching the ground, or been in the air
    if(on_ground){
        on_ground_time += ts.step();
    } else {
        air_time += ts.step();
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

int GetState() {
    return state;
}

bool IsAttackMirrored(){
    vec3 direction = GetAttackDirection();
    vec3 right_direction;
    right_direction.x = direction.z;
    right_direction.z = -direction.x;

    bool mirrored;
    if(!mirrored_stance){
        // GetTargetVelocitY() is defined in enemycontrol.as and playercontrol.as. Player target velocity depends on the camera and controls, AI's on player's position.
        mirrored = (dot(right_direction, GetTargetVelocity())>0.1f);
    } else {
        mirrored = (dot(right_direction, GetTargetVelocity())>-0.1f);
    }
    if(!this_mo.controlled){
        mirrored = rand()%2==0;
    }    
    return mirrored;
}

void CheckPossibleAttack(string &in attack_str) {
    attack_getter.Load(character_getter.GetAttackPath(attack_str));
    string anim_path = attack_getter.GetUnblockedAnimPath();
    float impact_time = GetAnimationEventTime(anim_path, "attackimpact");
    Print(attack_str + ": " + character_getter.GetAttackPath(attack_str) + "( " + impact_time + ")\n");
    //DebugText("impact_time", "Attack impact_time: "+impact_time, 1.0f);
}

void CheckPossibleAttacks() {
    CheckPossibleAttack("low");
    CheckPossibleAttack("moving_low");
    CheckPossibleAttack("stationary");
    CheckPossibleAttack("moving");
    CheckPossibleAttack("stationary_close");
    CheckPossibleAttack("moving_close");
}

void LoadAppropriateAttack(bool mirrored) {
    // Checks if the character is standing still. Used in ChooseAttack() to see if the character should perform a front kick.
    bool front = length_squared(GetTargetVelocity())<0.1f;

    vec3 direction = GetAttackDirection();
    float attack_distance = length(direction);
    bool ragdoll_enemy = false;
    bool ducking_enemy = false;
    if(target_id != -1){
        if(ReadCharacterID(target_id).GetIntVar("state")==_ragdoll_state){
            ragdoll_enemy = true;
        }
        if(ReadCharacterID(target_id).GetFloatVar("duck_amount") >= 0.5f){
            ducking_enemy = true;
        }
    }
    
    string attack_path;
    if(attacking_with_throw != 0){
        if(attacking_with_throw == 1){
            attack_path="Data/Attacks/throw.xml";
        } else if(attacking_with_throw == 2){
            if(weapon_slots[primary_weapon_slot] == -1){
                attack_path="Data/Attacks/rearchoke.xml";
            } else {
                attack_path="Data/Attacks/rearknifecapture.xml";
            }
            executing = false;
        }
    } else {
        ChooseAttack(front);
        if(curr_attack == "moving" && ragdoll_enemy){
            attack_path = character_getter.GetAttackPath("moving_low");
        } else if(curr_attack == "stationary" ||
           (curr_attack == "moving" && ducking_enemy)){
            if(attack_distance < _close_attack_range + range_extender * 0.5f){
                attack_path = character_getter.GetAttackPath("stationary_close");
            } else {
                attack_path = character_getter.GetAttackPath("stationary");
            }
        } else if(curr_attack == "moving"){
            if(attack_distance < _close_attack_range + range_extender * 0.5f){
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
}

vec3 GetAttackDirection() {
    vec3 direction;
    if(target_id != -1 && ReadCharacterID(target_id).QueryIntFunction("int IsDodging()") == 0){
        direction = ReadCharacterID(target_id).position - this_mo.position;
    } else {
        direction = this_mo.GetFacing();
    }
    return direction;
}

// called when state equals _attack_state
void UpdateAttacking(const Timestep &in ts) {    
    flip_info.UpdateRoll(ts);

    if(target_id != -1){
        vec3 avg_pos = ReadCharacterID(target_id).GetAvgPosition();
        //DebugDrawWireSphere(avg_pos, 0.5f, vec3(1.0f), _delete_on_update);
        //DebugDrawWireSphere(this_mo.GetAvgPosition(), 0.5f, vec3(1.0f), _delete_on_update);
        float height_rel = avg_pos.y - this_mo.GetAvgPosition().y;
        this_mo.SetBlendCoord("attack_height_coord",height_rel);
        //Print("Height_rel: "+height_rel+"\n");
    }

    if(on_ground){
        this_mo.velocity *= pow(0.95f,ts.frames());
    } else {
        ApplyPhysics(ts);
    }
    
    vec3 direction = GetAttackDirection();
    direction.y = 0.0f;
    direction = normalize(direction);

    if(attack_animation_set){
        if(attack_getter.IsThrow() == 0){
            float attack_facing_inertia = 0.9f;
            if(attack_getter.GetSharpDamage() > 0.0f){
                attack_facing_inertia = 0.8f;
            }
            this_mo.SetRotationFromFacing(InterpDirections(this_mo.GetFacing(),
                                                           direction,
                                                           1.0-pow(attack_facing_inertia,ts.frames())));
            if(WantsToFeint() && can_feint){
                SwitchToBlockedAnim();
                feinting = true;
            }
        } else {
            if(target_id != -1){
                MovementObject @char = ReadCharacterID(target_id);
                char.velocity.x = this_mo.velocity.x;
                char.velocity.z = this_mo.velocity.z;
                tether_dist = 0.4f;
            }
        }
    }
    vec3 right_direction;
    right_direction.x = direction.z;
    right_direction.z = -direction.x;
    if(!on_ground){
        float leg_cannon_target_flip;
        if(target_id != -1){
            float rel_height = normalize(ReadCharacterID(target_id).position - this_mo.position).y;
            leg_cannon_target_flip = -1.4f - rel_height;
        } else {
            leg_cannon_target_flip = -1.4f;
        }
        leg_cannon_flip = mix(leg_cannon_flip, leg_cannon_target_flip, 0.1f);
        this_mo.SetFlip(right_direction,leg_cannon_flip,0.0f);
    }

    if(attack_animation_set &&
       this_mo.GetStatusKeyValue("cancel")>=1.0f && 
       WantsToCancelAnimation())
    {
        if(cancel_delay <= 0.0f){
            EndAttack();
        }
        cancel_delay -= ts.step();
    } else {
        cancel_delay = 0.01f;
    }

    if(!attack_animation_set){
        bool mirrored = IsAttackMirrored();
        LoadAppropriateAttack(mirrored);
        if(attack_getter.GetAsLayer() == 1){
            //Print("Attacking with layered attack in wrong mode\n");
            SetState(_movement_state);
            return;
        }

        if(attack_getter.GetSpecial() == "legcannon"){    
            leg_cannon_flip = 0.0f;
        }

        if(attack_getter.GetHeight() == _low){
            duck_amount = 1.0f;
        } else {
            duck_amount = 0.0f;
        }
        
        if(attack_getter.GetDirection() == _left) {
            mirrored = !mirrored;
        }

        bool mirror = false;
        if(attack_getter.GetDirection() != _front){
            mirror = mirrored;
            mirrored_stance = mirrored;
        } else {
            mirror = mirrored_stance;
        }

        int8 flags = _ANM_FROM_START;
        if(attack_getter.GetMobile() == 1){
            flags = flags | _ANM_MOBILE;
        }
        if(mirror){
            flags = flags | _ANM_MIRRORED;
        }                

        string anim_path;
        if(attack_getter.IsThrow() == 0){
            anim_path = attack_getter.GetUnblockedAnimPath();
            attack_predictability = this_mo.CheckAttackHistory(attack_getter.GetPath());
            this_mo.AddToAttackHistory(attack_getter.GetPath());
            //Print("Updating attack history\n"); 
            //DebugText("test", "Attack predictability: "+attack_predictability, 1.0f);
        } else {
            anim_path = attack_getter.GetThrowAnimPath();
            int hit = _miss;
            if(target_id != -1){
                hit = ReadCharacterID(target_id).WasHit(
                    "grabbed", attack_getter.GetPath(), direction, this_mo.position, this_mo.getID(), p_attack_damage_mult, p_attack_knockback_mult);        
            } else {
                //Print("Grabbing no target\n");
            }
            if(hit == _miss){
                EndAttack();
                return;
            }
            this_mo.SetRotationFromFacing(direction);
        }

        if(!this_mo.controlled){
            this_mo.PlaySoundGroupVoice("attack",0.0f);
        }

        this_mo.SetAnimation(anim_path, 20.0f, flags);
        this_mo.SetSpeedMult(p_attack_speed_mult);

        string material_event = attack_getter.GetMaterialEvent();
        if(material_event.length() > 0){
            //Print(material_event);
            this_mo.MaterialEvent(material_event,
                        this_mo.position-vec3(0.0f,_leg_sphere_size, 0.0f));
        }
        if(attack_getter.GetSwapStance() != 0){
            mirrored_stance = !mirrored_stance;
        }
        this_mo.SetAnimationCallback("void EndAttack()");
        this_mo.SetAnimatedItemID(0, weapon_slots[primary_weapon_slot]);
        attack_animation_set = true;
    }
}

// the animations referred here are mostly blocks, and they're defined in the character-specific XML files.
void UpdateHitReaction(const Timestep &in ts) {
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
                this_mo.SetCharAnimation(block_string,20.0f, _ANM_MIRRORED | _ANM_FROM_START);
            } else {
                this_mo.SetCharAnimation(block_string,20.0f, _ANM_FROM_START);
            }
        } else if(hit_reaction_event == "attackimpact") {
            if(reaction_getter.GetMirrored() == 0 || (reaction_getter.GetMirrored() == 2 && !mirrored_stance)){
                this_mo.SetAnimation(reaction_getter.GetAnimPath(1.0f-block_health),20.0f,_ANM_MOBILE | _ANM_FROM_START);
                mirrored_stance = false;
            } else {
                this_mo.SetAnimation(reaction_getter.GetAnimPath(1.0f-block_health),20.0f,_ANM_MOBILE|_ANM_MIRRORED | _ANM_FROM_START);
                mirrored_stance = true;
            }
        }
        this_mo.SetAnimationCallback("void EndHitReaction()");
        hit_reaction_anim_set = true;
    }
    this_mo.velocity *= pow(0.95f,ts.frames());
    if(this_mo.GetStatusKeyValue("cancel")>=1.0f && WantsToCancelAnimation() && hit_reaction_time > 0.1f){
        EndHitReaction();
    }
    if(this_mo.GetStatusKeyValue("escape")>=1.0f && WantsToCounterThrow()){
        level.SendMessage("character_throw_escape "+this_mo.getID() + " " + target_id);
        this_mo.SwapAnimation(attack_getter2.GetThrownCounterAnimPath());
        this_mo.SetAnimationCallback("void EndHitReaction()");
        string sound = "Data/Sounds/weapon_foley/swoosh/weapon_whoos_big.xml";
        this_mo.PlaySoundGroupAttached(sound,this_mo.position);
        //TimedSlowMotion(0.1f,0.3f, 0.1f);
    }
    hit_reaction_time += ts.step();
}

void PlayStandAnimation(bool blocked) {
    int8 flags = _ANM_MOBILE;
    if(left_handed){
        flags |= _ANM_MIRRORED;
    }
    mirrored_stance = left_handed;
    if(!blocked){ 
        if(wake_up_torso_front.y < 0){
            this_mo.SetAnimation("Data/Animations/r_standfromfront.anm", 20.0f, flags);
        } else {
            this_mo.SetAnimation("Data/Animations/r_standfromback.anm", 20.0f, flags);
        }
    } else {
        this_mo.SetAnimation("Data/Animations/r_blockfrontfromground.anm", 200.0f, flags);
    }
    this_mo.SetAnimationCallback("void EndGetUp()");
    this_mo.SetRotationFromFacing(normalize(vec3(wake_up_torso_up.x,0.0f,wake_up_torso_up.z))*-1.0f);
    getting_up_time = 0.0f;  
}

void SetState(int _state) {
    state = _state;
    if(state == _movement_state){
        StartFootStance();
    } else {
        stance_move = false;
    }
    if(state != _attack_state){
        curr_attack = "";
    }
    if(state == _hit_reaction_state){
        active_block_anim = false;
        hit_reaction_time = 0.0f;
        hit_reaction_anim_set = false;
        hit_reaction_thrown = false;
        hit_reaction_dodge = false;
        this_mo.SetFlip(vec3(1.0f,0.0f,0.0f),0.0f,0.0f);
    }
}

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

    duck_amount = 1.0f;
    duck_vel = 0.0f;
    target_duck_amount = 1.0f;
    if(how == _wake_stand || how == _wake_block_stand){
        SetOnGround(true);
        flip_info.Land();
        SetState(_ground_state);
        PlayStandAnimation(how == _wake_block_stand);
        ragdoll_cam_recover_speed = 2.0f;
        if(how != _wake_block_stand){
            this_mo.SetRagdollFadeSpeed(4.0f); 
        } else {
            this_mo.SetRagdollFadeSpeed(40.0f); 
        }
        target_duck_amount = 0.0f;
    } else if(how == _wake_fall){
        SetOnGround(true);
        flip_info.Land();
        ApplyIdle(5.0f, true);
        ragdoll_cam_recover_speed = 10.0f;
        this_mo.SetRagdollFadeSpeed(10.0f);
    } else if (how == _wake_flip) {
        SetOnGround(false);
        jump_info.StartFall();
        flip_info.StartFlip();
        flip_info.FlipRecover();
        this_mo.SetCharAnimation("jump", 5.0f, _ANM_FROM_START);
        ragdoll_cam_recover_speed = 100.0f;
        this_mo.SetRagdollFadeSpeed(10.0f);
    } else if (how == _wake_roll) {
        SetOnGround(true);
        flip_info.Land();
        ApplyIdle(5.0f, true);
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
    col.GetSlidingSphereCollision(sphere_center, radius);
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

void EndGetUp(){
    if(state == _ground_state){
        SetState(_movement_state);
        duck_amount = 1.0f;
        duck_vel = 0.0f;
        target_duck_amount = 1.0f;
    }
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
void UpdateGroundState(const Timestep &in ts) {
    this_mo.velocity = vec3(0.0f);
    //this_mo.velocity = GetTargetVelocity() * _walk_accel * 0.15f;
    
    HandleGroundStateCollision();
    getting_up_time += ts.step();
}

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
            right_smear_time = 0.0f;
        }
    }
}

int being_executed = 0;
void Execute(int type) {
    being_executed = type;
}

void HandleCollisionsBetweenTwoCharacters(MovementObject @other){
    if(state == _ragdoll_state || 
       reset_no_collide > 0.0f ||
       other.GetIntVar("state") == _ragdoll_state ||
       (state == _attack_state && attack_getter.IsThrow() == 1) ||
       (state == _hit_reaction_state && attack_getter2.IsThrow() == 1) ||
       (tethered != _TETHERED_FREE && other.getID() == tether_id))
    {
        return;
    }

    if(knocked_out == _awake && other.GetIntVar("knocked_out") == _awake){
        float distance_threshold = 0.7f;
        vec3 this_com = this_mo.GetCenterOfMass();
        vec3 other_com = other.GetCenterOfMass();
        this_com.y = this_mo.position.y;
        other_com.y = other.position.y;
        if(distance_squared(this_com, other_com) < distance_threshold*distance_threshold){
            vec3 dir = other_com - this_com;
            float dist = length(dir);
            dir /= dist;
            dir *= distance_threshold - dist;
            other.position += dir * 0.5f;
            this_mo.position -= dir * 0.5f;
                
            vec3 other_push = dir * 0.5f / (time_step) * 0.15f;
            push_velocity -= other_push;
            other.Execute("push_velocity += vec3("+other_push.x+","+other_push.y+","+other_push.z+");");
        }    
    }
}

void UpdatePrimaryWeapon(){
    int primary_weapon_id = weapon_slots[primary_weapon_slot];
    this_mo.SetPrimaryWeaponID(primary_weapon_id);
    if(primary_weapon_id == -1){
        range_extender = 0.0f;
        range_multiplier = 1.0f;
    } else {
        ItemObject@ item_obj = ReadItemID(primary_weapon_id);
        range_extender = item_obj.GetRangeExtender();
        range_multiplier = item_obj.GetRangeMultiplier();
    }
}

void UpdateItemFistGrip(){
    if(weapon_slots[_held_left] != -1){
        this_mo.SetMorphTargetWeight("fist_l",1.0f,1.0f);
    } else {
        this_mo.SetMorphTargetWeight("fist_l",1.0f,0.0f);
    }
    if(weapon_slots[_held_right] != -1){
        this_mo.SetMorphTargetWeight("fist_r",1.0f,1.0f);
    } else {
        this_mo.SetMorphTargetWeight("fist_r",1.0f,0.0f);
    }
}

void NotifyItemDetach(int item_id){
    if(weapon_slots[primary_weapon_slot] == item_id) {
        weapon_slots[primary_weapon_slot] = -1;
        UpdatePrimaryWeapon();
    }
    for(int i=0; i<6; ++i){
        if(weapon_slots[i] == item_id){
            weapon_slots[i] = -1;
        }
    }
    UpdateItemFistGrip();
}

void DropWeapon() {
    if(weapon_slots[_held_left] != -1){
        this_mo.DetachItem(weapon_slots[_held_left]);
        weapon_slots[_held_left] = -1;
    } else if(weapon_slots[_held_right] != -1){
        this_mo.DetachItem(weapon_slots[_held_right]);
        weapon_slots[_held_right] = -1;
    }
    if(pickup_layer != -1){
        this_mo.RemoveLayer(pickup_layer, 4.0f);
        pickup_layer = -1;
    }
    UpdateItemFistGrip();
    UpdatePrimaryWeapon();
}

vec3 CalcLaunchVel(vec3 start, vec3 end, float mass, vec3 vel, vec3 targ_vel, float&out time) {
    vec3 dir = normalize(end - start);
    vec3 flat_dir = normalize(vec3(dir.x, 0.0f, dir.z));
    float flat_launch_speed = _base_launch_speed / max(1.0f,mass) +
                              dot(flat_dir, this_mo.velocity);
    float max_up_speed = this_mo.velocity.y + _base_up_speed / max(1.0f,mass);
    float arc = 0.0f;
    vec3 launch_vel = GetVelocityForTarget(start, end, flat_launch_speed, max_up_speed, arc, time);
    launch_vel = GetVelocityForTarget(start, end + targ_vel*time, flat_launch_speed, max_up_speed, arc, time);
    launch_vel = GetVelocityForTarget(start, end + targ_vel*time, flat_launch_speed, max_up_speed, arc, time);
    if(launch_vel == vec3(0.0f)){
        launch_vel = flat_launch_speed * flat_dir + vec3(0.0f,max_up_speed,0.0f);
    }
    if(length(launch_vel) > flat_launch_speed + max_up_speed){
        launch_vel = normalize(launch_vel) * (flat_launch_speed + max_up_speed);
    }
    return launch_vel;
}

void ThrowWeapon() {
    if(weapon_slots[primary_weapon_slot] != -1){
        int target = target_id;
        if(target != -1){
            int weapon_id = weapon_slots[primary_weapon_slot];
            this_mo.DetachItem(weapon_id);
            weapon_slots[primary_weapon_slot] = -1;
            MovementObject@ char = ReadCharacterID(target);
            ItemObject@ io = ReadItemID(weapon_id);
            float time;
            vec3 start = io.GetPhysicsPosition();
            vec3 end = char.GetAvgIKChainPos("torso");
            vec3 launch_vel = CalcLaunchVel(start, end, io.GetMass(), this_mo.velocity, char.velocity, time);
            io.SetLinearVelocity(launch_vel);
            vec3 ang_vel = io.GetAngularVelocity();
            vec3 dir = normalize(end - start);
            vec3 twist_ang_vel = dir * dot(ang_vel, dir);
            ang_vel = ang_vel - twist_ang_vel;
            float num_turns = floor(time * 2.0f / io.GetMass()) + 0.25f;
            // Calculate spins
            //Print("Num turns: "+num_turns+"\n");
            //Print("Time: "+time+"\n");
            io.SetThrown();
            io.SetAngularVelocity((normalize(ang_vel)* 6.28318f * num_turns)/time + twist_ang_vel);
            this_mo.velocity -= launch_vel * io.GetMass() * 0.05f;
            //io.SetVelocity(vec3(0.0f,5.0f,0.0f));
            UpdatePrimaryWeapon();
            UpdateItemFistGrip();
        }
    }
}

int GetNumHandsFree() {
    int hands_free = 2;
    if(weapon_slots[primary_weapon_slot] != -1){
        ItemObject@ item_obj = ReadItemID(weapon_slots[primary_weapon_slot]);
        hands_free -= item_obj.GetNumHands();
    }
    if(weapon_slots[secondary_weapon_slot] != -1){
        ItemObject@ item_obj = ReadItemID(weapon_slots[secondary_weapon_slot]);
        hands_free -= item_obj.GetNumHands();
    }
    return hands_free;
}

int GetNearestPickupableWeapon(vec3 point, float max_range){
    int num_items = GetNumItems();
    int closest_id = -1;
    float closest_dist = 0.0f;
    int hands_free = GetNumHandsFree();
    for(int i=0; i<num_items; i++){
        ItemObject@ item_obj = ReadItem(i);
        if(item_obj.GetType() == _misc){
            continue;
        }
        if(item_obj.GetNumHands() > hands_free){
            continue;
        }
        if(item_obj.IsHeld()){
            int holder_id = item_obj.HeldByWhom();
            if(holder_id == -1){
                continue;
            }    
            MovementObject@ holder = ReadCharacterID(holder_id);
            if(holder.GetIntVar("knocked_out") == _awake){
                continue;
            }
        }
        vec3 item_pos = item_obj.GetPhysicsPosition();
        if(closest_id == -1 || distance_squared(point, item_pos) < closest_dist){ 
            closest_dist = distance_squared(point, item_pos);
            closest_id = item_obj.GetID();
        }
    }
    if(closest_dist < max_range*max_range){
        return closest_id;
    } else {
        return -1;
    }
}

void StartSheathing(int slot){
    ItemObject @obj = ReadItemID(weapon_slots[slot]);
    bool prefer_same_side = obj.GetMass() < 0.55f;
    int side_a, side_b;
    if( (prefer_same_side && slot == _held_right) ||
       (!prefer_same_side && slot != _held_right))
    {
        side_a = _sheathed_right;
        side_b = _sheathed_left;
    } else {
        side_a = _sheathed_left;
        side_b = _sheathed_right;
    }
    int dst = -1;
    // Put weapon in sheathe if possible, otherwise put in empty slot
    if(weapon_slots[side_a] != -1 && DoesItemFitInItem(weapon_slots[slot], weapon_slots[side_a])){
        dst = side_a;
    } else if(weapon_slots[side_b] != -1 && DoesItemFitInItem(weapon_slots[slot], weapon_slots[side_b])){
        dst = side_b;
    } else if(weapon_slots[side_a] == -1){
        dst = side_a;
    } else if(weapon_slots[side_b] == -1){
        dst = side_b;
    }
    //slot = _held_left;
    //dst = _sheathed_left;
    if(dst != -1){
        int flags = 0;
        if(slot == _held_left){
            flags = _ANM_MIRRORED;
        }
        if((slot == _held_left && dst == _sheathed_right) ||
           (slot == _held_right && dst == _sheathed_left))
        {
            ItemObject@ item_obj = ReadItemID(weapon_slots[slot]);
            if(item_obj.HasSheatheAttachment()){
                sheathe_layer_id = this_mo.AddLayer("Data/Animations/r_knifesheathe.anm",8.0f,flags);
                this_mo.SetLayerItemID(sheathe_layer_id, 0, weapon_slots[slot]);
            }
        } else {
            ItemObject@ item_obj = ReadItemID(weapon_slots[slot]);
            if(item_obj.HasSheatheAttachment()){
                sheathe_layer_id = this_mo.AddLayer("Data/Animations/r_knifesheathesameside.anm",8.0f,flags);
                this_mo.SetLayerItemID(sheathe_layer_id, 0, weapon_slots[slot]);
            }
        }
    }
}

void HandlePickUp() {
    if((WantsToDropItem() && throw_knife_layer_id == -1) || knocked_out != _awake){
        DropWeapon();
    }
    if(knocked_out != _awake || state == _ragdoll_state || tethered != _TETHERED_FREE){
        return;
    }
    if(WantsToPickUpItem()){
        if(weapon_slots[primary_weapon_slot] == -1 || weapon_slots[secondary_weapon_slot] == -1){
            vec3 hand_pos;
            if(weapon_slots[_held_right] == -1 && (primary_weapon_slot == _held_right || weapon_slots[_held_left] != -1)){
                hand_pos = this_mo.GetIKTargetTransform("rightarm").GetTranslationPart();
            } else {
                hand_pos = this_mo.GetIKTargetTransform("leftarm").GetTranslationPart();
            }
            int nearest_weapon = GetNearestPickupableWeapon(hand_pos, 0.9f);
            if(nearest_weapon != -1){
                ItemObject@ item_obj = ReadItemID(nearest_weapon);
                vec3 pos = item_obj.GetPhysicsPosition();
                if(flip_info.IsFlipping()){
                    int stuck_id = item_obj.StuckInWhom();
                    if(stuck_id != -1){
                        GrabWeaponFromBody(stuck_id, item_obj.GetID(), pos);
                    }
                    AttachWeapon(item_obj.GetID());
                } else {
                    if(pickup_layer == -1){
                        int flags = 0;
                        if(!(weapon_slots[_held_right] == -1 && (primary_weapon_slot == _held_right || weapon_slots[_held_left] != -1))){
                            flags |= _ANM_MIRRORED;
                        }
                        pickup_layer = this_mo.AddLayer("Data/Animations/r_pickup.anm",4.0f,flags);
                        pickup_layer_attempts = 0;
                    }
                }
            }
        }
        if(weapon_slots[primary_weapon_slot] == -1 || weapon_slots[secondary_weapon_slot] == -1){
            int nearest_weapon = GetNearestPickupableWeapon(this_mo.position, _pick_up_range);
            if(nearest_weapon != -1){
                ItemObject@ item_obj = ReadItemID(nearest_weapon);
                vec3 pos = item_obj.GetPhysicsPosition();
                vec3 flat_dir = pos-this_mo.position;
                flat_dir.y = 0.0f;
                if(length_squared(flat_dir) > 1.0f){
                    flat_dir = normalize(flat_dir);
                }
                target_duck_amount = max(target_duck_amount,1.0f-length_squared(flat_dir));
                get_weapon_dir = flat_dir;
                get_weapon_pos = pos;
                trying_to_get_weapon = 2;
                trying_to_get_weapon_time = 0.0f;
            }
        }
    } else {
        if(pickup_layer != -1){
            this_mo.RemoveLayer(pickup_layer, 4.0f);
            pickup_layer = -1;
        } 
    }
    if(WantsToThrowItem() && weapon_slots[primary_weapon_slot] != -1 && throw_knife_layer_id == -1){        
        float throw_range = 50.0f;
        int target = GetClosestCharacterID(throw_range, _TC_ENEMY | _TC_CONSCIOUS | _TC_NON_RAGDOLL);
        if(target != -1 && (on_ground || flip_info.IsFlipping())){
            target_id = target;
            going_to_throw_item = true;
            going_to_throw_item_time = time;
        }
    }
    if(going_to_throw_item && going_to_throw_item_time <= time && going_to_throw_item_time > time - 1.0f){
        if(!flip_info.IsFlipping() || flip_info.flip_progress > 0.5f){
            int8 flags = 0;
            if(primary_weapon_slot == _held_left){
                flags |= _ANM_MIRRORED;   
            }
            if(!flip_info.IsFlipping()){
                throw_knife_layer_id = this_mo.AddLayer("Data/Animations/r_knifethrowlayer.anm",8.0f,flags);
            } else {
                throw_knife_layer_id = this_mo.AddLayer("Data/Animations/r_knifethrowfliplayer.anm",8.0f,flags);
            }
            going_to_throw_item = false;
        }
    }
    if(sheathe_layer_id == -1){
        int src;
        if(WantsToSheatheItem() && weapon_slots[primary_weapon_slot] != -1){ 
            StartSheathing(primary_weapon_slot);
        } else if(WantsToUnSheatheItem(src) && weapon_slots[primary_weapon_slot] == -1){
            if(src != -1){
                int flags = 0;
                if(primary_weapon_slot == _held_left){
                    flags = _ANM_MIRRORED;
                }
                if((primary_weapon_slot == _held_left && src == _sheathed_right) ||
                   (primary_weapon_slot == _held_right && src == _sheathed_left))
                {
                    sheathe_layer_id = this_mo.AddLayer("Data/Animations/r_knifeunsheathe.anm",8.0f,flags);
                } else {
                    sheathe_layer_id = this_mo.AddLayer("Data/Animations/r_knifeunsheathesameside.anm",8.0f,flags);
                }
            }
        }
    }
}

void ApplyCameraControls(const Timestep &in ts) {
    bool shared_cam = !GetSplitscreen() && GetNumCharacters() == 2 && ReadCharacter(0).controlled && ReadCharacter(1).controlled;
    int other_player_id;
    if(shared_cam){
        if(ReadCharacter(0).getID() == this_mo.getID()){
            other_player_id = ReadCharacter(1).getID();
        } else {
            other_player_id = ReadCharacter(0).getID();
        }
    }

    const float _camera_rotation_inertia = 0.5f;
    const float _cam_follow_distance = 2.0f;
    const float _cam_collision_radius = 0.15f;

    vec3 cam_center;
    if(!shared_cam){
        vec3 dir = normalize(vec3(0.0f,1.0f,0.0f)-this_mo.GetFacing());
        col.GetSlidingSphereCollision(this_mo.position+dir*_leg_sphere_size*0.25f, _leg_sphere_size*0.75f);
        cam_center = sphere_col.adjusted_position-dir*_leg_sphere_size*0.25f;
    }

    if(shared_cam){
        MovementObject @char = ReadCharacterID(other_player_id);
        cam_center = (char.position + this_mo.position) * 0.5;
    }

    vec3 cam_pos = cam_center;
    if(!shared_cam){
        cam_pos += cam_pos_offset;
        if(state != _ragdoll_state){
            vec3 cam_offset;
            if(on_ground){
                cam_offset = vec3(0.0f,mix(0.6f,0.4f,duck_amount),0.0f);
            } else {
                cam_offset = vec3(0.0f,0.6f,0.0f);
            }
            col.GetSweptSphereCollision(cam_pos, cam_pos+cam_offset, _cam_collision_radius);
            cam_pos = sphere_col.position;
        } else {
            cam_pos += vec3(0.0f,0.3f,0.0f);
        }
    } else {
        cam_pos += vec3(0.0f,0.6f,0.0f);
    }


    if(!level.HasFocus()){
        SetGrabMouse(true);
    }
    if(!camera.GetAutoCamera()){
        if(!level.HasFocus() && cam_input){   
            target_rotation -= GetLookXAxis(this_mo.controller_id);
            target_rotation2 -= GetLookYAxis(this_mo.controller_id);   
        }
    } else {
        float old_tr = target_rotation;
        float old_tr2 = target_rotation2;
        chase_cam_pos = mix(cam_pos - camera.GetFacing() * cam_distance, 
                           chase_cam_pos, 
                           pow(0.9f, ts.frames()));
       
       vec3 facing = normalize(cam_pos - chase_cam_pos);
       if(target_id != -1){
            MovementObject @char = ReadCharacterID(target_id);
            float dist = distance(char.position, this_mo.position);
            vec3 target_facing = (char.position - this_mo.position)/dist;
            mat4 rotation_y;
            float target_angle = max(0.2f, 1.2f / max(1.0f,dist)); 
            if(target_weight == 0.0f){
                angle = target_angle;
            } else {
                angle = mix(target_angle, angle, pow(0.98f, ts.frames()));
            }
            rotation_y.SetRotationY(angle);
            vec3 target_facing_right = rotation_y * target_facing;
            rotation_y.SetRotationY(-angle);
            vec3 target_facing_left = rotation_y * target_facing;

            if(dot(target_facing_left, facing) > dot(target_facing_right, facing)){
                target_facing = target_facing_left;
                if(target_weight == 0.0f){
                    target_side_weight = 0.0f;
                } else {
                    target_side_weight = mix(0.0f, target_side_weight, pow(0.95f, ts.frames()));
                }
            } else {
                if(target_weight == 0.0f){
                    target_side_weight = 1.0f;
                } else {
                    target_side_weight = mix(1.0f, target_side_weight, pow(0.95f, ts.frames()));
                }
            }
            target_facing = mix(target_facing_left, target_facing_right, target_side_weight);
            float target_target_weight = 1.0f/dist;
            target_target_weight = max(0.0f,min(1.0f,target_target_weight*3.0f));
            if(target_target_weight <= 0.3f){
                target_target_weight = 0.0f;
            }
            target_weight = mix(target_target_weight, target_weight, pow(0.98f, ts.frames()));
            if(target_weight < 0.01f && target_target_weight == 0.0f){
                target_weight = 0.0f;
            }
            facing = InterpDirections(facing, target_facing, target_weight);
       }
       target_rotation2 = mix(asin(facing.y)/3.14159265f * 180.0f,
                              target_rotation2,
                              pow(0.95f, ts.frames()));
       facing.y = 0.0f;
       if(length_squared(facing) > 0.01f){
            facing = normalize(facing);
            target_rotation = atan2(-facing.x,-facing.z)/3.14159265f * 180.0f;
       }
       while(target_rotation < cam_rotation - 180.0f){
            target_rotation += 360.0f;
       } 
       while(target_rotation > cam_rotation + 180.0f){
            target_rotation -= 360.0f;
       }

        target_rotation = mix(target_rotation, old_tr, min(1.0f,auto_cam_override));
        target_rotation2 = mix(target_rotation2, old_tr2, min(1.0f,auto_cam_override));

       //cam_pos = chase_cam_pos + camera.GetFacing() * _cam_follow_distance;
        if(cam_input){
            target_rotation -= GetLookXAxis(this_mo.controller_id);
            target_rotation2 -= GetLookYAxis(this_mo.controller_id); 
        }

        auto_cam_override *= pow(0.99f, ts.frames());
        if(cam_input){
            auto_cam_override += abs(GetLookXAxis(this_mo.controller_id))*0.05f + abs(GetLookYAxis(this_mo.controller_id))*0.05f;
        }
        auto_cam_override = min(2.5f, auto_cam_override);
    }

    target_rotation2 = max(-90,min(50,target_rotation2));

    if(shared_cam){
        MovementObject @char = ReadCharacterID(other_player_id);
        vec3 vec = normalize(char.position - this_mo.position);
        target_rotation = atan2(vec.x, vec.z) * 180.0f / 3.1415f + 90.0f;
        
       while(target_rotation < cam_rotation - 180.0f){
            target_rotation += 360.0f;
       } 
       while(target_rotation > cam_rotation + 180.0f){
            target_rotation -= 360.0f;
       }
       while(target_rotation < cam_rotation - 90.0f){
            target_rotation += 180.0f;
       } 
       while(target_rotation > cam_rotation + 90.0f){
            target_rotation -= 180.0f;
       }
       target_rotation2 = shared_cam_elevation;
       if(!char.VisibilityCheck(cam_pos - camera.GetFacing() * cam_distance)){
           target_shared_cam_elevation -= 1.0f;
       }
       if(!this_mo.VisibilityCheck(cam_pos - camera.GetFacing() * cam_distance)){
           target_shared_cam_elevation -= 1.0f;
       }
       shared_cam_elevation = mix(target_shared_cam_elevation, shared_cam_elevation, 0.99f);
       target_shared_cam_elevation = mix(0.0f, target_shared_cam_elevation, 0.99f);
    }

    if(!shared_cam){
        ApplyCameraCones(cam_pos);
    }

    float inertia = pow(_camera_rotation_inertia, ts.frames());
    cam_rotation = cam_rotation * inertia + 
               target_rotation * (1.0f - inertia);
    cam_rotation2 = cam_rotation2 * inertia + 
               target_rotation2 * (1.0f - inertia);



    if(old_cam_pos == vec3(0.0f)){
        old_cam_pos = camera.GetPos();
    }
    old_cam_pos += this_mo.velocity * ts.step();

    if(ragdoll_cam_recover_time > 0.0f){
        cam_pos = mix(cam_pos, ragdoll_cam_pos, ragdoll_cam_recover_time);
        ragdoll_cam_recover_time -= ts.step() * ragdoll_cam_recover_speed;
    }

    cam_pos = mix(cam_pos,old_cam_pos,0.8f);

    camera.SetVelocity(this_mo.velocity); 

    vec3 facing;
    {
        mat4 rotationY_mat,rotationX_mat;
        rotationY_mat.SetRotationY(cam_rotation*3.1415f/180.0f);
        rotationX_mat.SetRotationX(cam_rotation2*3.1415f/180.0f);
        mat4 rotation_mat = rotationY_mat * rotationX_mat;
        facing = rotation_mat * vec3(0.0f,0.0f,-1.0f);
    }

    col.GetSweptSphereCollision(cam_pos,
                                    cam_pos - facing * 
                                                _cam_follow_distance,
                                    _cam_collision_radius);
    
    float target_cam_distance = _cam_follow_distance;
    if(sphere_col.NumContacts() != 0){
        target_cam_distance = distance(cam_pos, sphere_col.position);
    }
    
    if(shared_cam){
        MovementObject @char = ReadCharacterID(other_player_id);
        target_cam_distance = length(char.position - this_mo.position) * 0.5f + _cam_follow_distance;
    }

    cam_distance = min(cam_distance, target_cam_distance);
    cam_distance = mix(target_cam_distance, cam_distance, 0.95f);
    
    
    if(!cam_rotation_set){        
        vec3 facing = this_mo.GetFacing();
        float cur_rotation = atan2(-facing.x, -facing.z)/(3.1415f/180.0f);
        cam_rotation = cur_rotation;
        target_rotation = cam_rotation;
        cam_rotation2 = -20.0f;
        target_rotation2 = cam_rotation2;
        cam_rotation_set = true;
    }

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
    if(this_mo.controller_id == 0){
        UpdateListener(camera.GetPos(),vec3(0,0,0),camera.GetFacing(),camera.GetUpVector());
    }

    camera.SetInterpSteps(ts.frames());
}

void ApplyCameraCones(vec3 cam_pos){
    bool debug_viz = false;
    float radius = 0.8f;
    if(debug_viz){
        DebugDrawWireSphere(cam_pos, radius, vec3(1.0f,0.0f,0.0f), _delete_on_update);
    }
    col.GetSlidingSphereCollision(cam_pos, radius);
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
        target_rotation2 = asin(facing.y)/3.14159265f * 180.0f;
        facing.y = 0.0f;
        facing = normalize(facing);
        target_rotation = atan2(-facing.x,-facing.z)/3.14159265f * 180.0f;
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
    DropWeapon();
    this_mo.DetachAllItems();
    this_mo.char_path = path;
    character_getter.Load(this_mo.char_path);
    this_mo.RecreateRiggedObject(this_mo.char_path);
    ApplyIdle(5.0f, true);
    SetState(_movement_state);
    Recover();
}

void Init(string character_path) {
    StartFootStance();
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
}

void Reset() {
    StartFootStance();
    DropWeapon(); 
    this_mo.ResetSoftAnimation();
    this_mo.DetachAllItems();
    if(state == _ragdoll_state){
        this_mo.UnRagdoll();
        ApplyIdle(5.0f,true);
        ragdoll_cam_recover_speed = 1000.0f;
        this_mo.SetRagdollFadeSpeed(1000.0f);
    }
    this_mo.SetTilt(vec3(0.0f,1.0f,0.0f));
    this_mo.SetFlip(vec3(0.0f,1.0f,0.0f),0.0f,0.0f);
    this_mo.CleanBlood();
    ClearTemporaryDecals();
    blood_amount = _max_blood_amount;
    ResetMind();
    reset_no_collide = 0.2f;
}

void StartFootStance() {
    foot.resize(2);
    foot[0].planted = true;
    foot[1].planted = false;
    for(int i=0; i<2; ++i){
         foot[i].pos = vec3(0.0f);
         foot[i].target_pos = this_mo.position;
         foot[i].old_pos = this_mo.position;
         foot[i].height = 0.0f;
         foot[i].progress = 0.0f;
    }
}

void HandleFootStance(const Timestep &in ts) {
    use_foot_plants = true;
    if(!old_use_foot_plants){
        StartFootStance();
    }

    vec3 temp_vel = this_mo.velocity + push_velocity;
    const float step_speed = max(2.0f,length(temp_vel)*1.5f + 1.0f);

    for(int i=0; i<2; ++i){
        foot[i].target_pos = this_mo.position;
    }
    vec3 diff = this_mo.GetIKTargetAnimPosition("right_leg") -
                this_mo.GetIKTargetAnimPosition("left_leg");
    if(length_squared(temp_vel) > 0.001f){
        vec3 n_diff = normalize(diff);
        vec3 n_vel = normalize(temp_vel);
        float val = dot(n_diff, n_vel);
        foot[0].target_pos += temp_vel * time_step * 1.0f * (-val+1.0f);
        foot[1].target_pos += temp_vel * time_step * 1.0f * (val+1.0f);
        for(int i=0; i<2; ++i){
            foot[i].target_pos += temp_vel * time_step * 60.0f / step_speed;
        }
    }
    if(foot[0].planted && foot[1].planted &&
        (distance_squared(foot[1].target_pos, foot[1].old_pos) > 0.01f ||
         distance_squared(foot[0].target_pos, foot[0].old_pos) > 0.01f))
    {
        if(dot(diff, temp_vel) > 0.0f){
            foot[1].planted = false;
        } else {
            foot[0].planted = false;
        }
    }

    for(int i=0; i<2; ++i){
        if(!foot[i].planted){
            foot[i].progress += ts.step() * step_speed;
            foot[i].height = min(0.1f,sin(foot[i].progress * 3.1415f) * length_squared(temp_vel)*0.005f);
        }
        if(foot[i].progress >= 1.0f){
            foot[i].old_pos = foot[i].target_pos;
            foot[i].progress = 0.0f;
            foot[i].planted = true;
            if(distance_squared(foot[1-i].target_pos, foot[1-i].old_pos) > 0.01f){
                foot[1-i].planted = false;
            }
            foot[i].height = 0.0f;
            string event_name;
            vec3 event_pos;
            if(i==0){
                event_pos = this_mo.GetIKTargetPosition("left_leg");
                event_name += "left";
            } else {
                event_pos = this_mo.GetIKTargetPosition("right_leg");
                event_name += "right";
            }
            if(length_squared(temp_vel) < 4.0f){
                event_name += "crouchwalk";
            } else if(length_squared(temp_vel) < 20.0f){
                event_name += "walk";
            } else {
                event_name += "run";
            }
            event_name += "step";

            HandleAnimationMaterialEvent(event_name, event_pos);
        }
        foot[i].pos = mix(foot[i].old_pos, foot[i].target_pos, foot[i].progress);
        foot[i].pos -= this_mo.position;
    }
    /*if(this_mo.controlled){
        PrintVec3(diff);
        Print("\n");
    }*/
}

void UpdateAnimation(const Timestep &in ts) {
    vec3 flat_velocity = vec3(this_mo.velocity.x,0,this_mo.velocity.z);

    float run_amount, walk_amount, idle_amount;
    float speed = length(flat_velocity);
    
    /*if(this_mo.controlled){
        DebugText("a","Tall coord: "+(1.0f-duck_amount), 0.5f);
        DebugText("b","Threat coord: "+max(0.0f,threat_amount-0.01f), 0.5f);
    }*/
    this_mo.SetBlendCoord("tall_coord",1.0f-duck_amount);
    this_mo.SetBlendCoord("threat_coord",threat_amount);
    idle_stance = false;

    if(on_ground){
        // rolling on the ground
        if(flip_info.UseRollAnimation()){
            int8 flags = 0;
            if(!mirrored_stance){
                flags |= _ANM_MIRRORED;
            }
            this_mo.SetCharAnimation("roll",7.0f,flags);
            float forwards_rollness = 1.0f-abs(dot(flip_info.GetAxis(),this_mo.GetFacing()));
            this_mo.SetBlendCoord("forward_roll_coord",forwards_rollness);
            this_mo.SetIKEnabled(false);
            roll_ik_fade = min(roll_ik_fade + 5.0f * ts.step(), 1.0f);
        } else {
            // running, walking and idle animation
            this_mo.SetIKEnabled(true);
            
            // when he's moving instead of idling, the character turns to the movement direction.
            // the different movement types are listed in XML files, and are blended together
            // by variables such as speed or crouching amount (blending values should be 0 and 1)
            // when there are more than two animations to blend, the XML file refers to another 
            // XML file which asks for another blending variable.
            stance_move = false;
            int force_look_target = IsAware()?situation.GetForceLookTarget():-1;
            if(force_look_target != -1 && speed < _stance_move_threshold && trying_to_get_weapon == 0){
                if(situation.NeedsCombatPose())
                {
                    stance_move = true;
                    stance_move_fade = 1.0f;
                }
            }
            if(tethered != _TETHERED_FREE){
                stance_move = true;

            }
            if((speed < _walk_threshold && GetTargetVelocity() != vec3(0.0f)) || 
                knife_layer_id != -1 || 
                throw_knife_layer_id != -1 && (speed < _walk_threshold * 2.0f)){
                stance_move = true;
            }
            if(WantsToWalkBackwards() && length_squared(flat_velocity) > 0.001f){
                stance_move = true;
                this_mo.SetRotationFromFacing(InterpDirections(this_mo.GetFacing(),
                                                               normalize(flat_velocity * -1.0f),
                                                               1.0 - pow(0.95f, ts.frames())));
            }

            if(speed > _walk_threshold && feet_moving && !stance_move){
                this_mo.SetRotationFromFacing(InterpDirections(this_mo.GetFacing(),
                                                               normalize(flat_velocity),
                                                               1.0 - pow(0.8f, ts.frames())));
                int8 flags = 0;
                if(left_handed){
                    flags |= _ANM_MIRRORED;
                }
                this_mo.SetCharAnimation("movement", 5.0f, flags);
                this_mo.SetBlendCoord("speed_coord",speed);
                this_mo.SetBlendCoord("ground_speed",speed);
                this_mo.SetAnimatedItemID(0, weapon_slots[primary_weapon_slot]);
                mirrored_stance = left_handed;
            } else {
                if(stance_move){
                    if(throw_knife_layer_id != -1 && force_look_target == -1){
                        force_look_target = target_id;
                    }
                    if(force_look_target != -1 && (speed > 1.0f || knife_layer_id != -1 || throw_knife_layer_id != -1) && tethered == _TETHERED_FREE){
                        MovementObject@ char = ReadCharacterID(force_look_target);
                        vec3 dir = char.position - this_mo.position;
                        dir.y = 0.0f;
                        dir = normalize(dir);
                        this_mo.SetRotationFromFacing(
                            InterpDirections(this_mo.GetFacing(), dir, 1.0 - pow(0.9f, ts.frames())));
                    } 
                    HandleFootStance(ts);
                }
                if(tethered == _TETHERED_FREE){
                    idle_stance = true;
                    ApplyIdle(5.0f, false);
                } else {
                    int8 flags = _ANM_MOBILE;
                    if(mirrored_stance){
                        flags = flags | _ANM_MIRRORED;
                    }
                    if(tethered == _TETHERED_REARCHOKE && !executing){
                        if(weapon_slots[primary_weapon_slot] == -1){
                            this_mo.SetAnimation("Data/Animations/r_rearchokestance.xml", 5.0f, flags);
                        } else {
                            this_mo.SetAnimation("Data/Animations/r_rearknifecapturestance.xml", 5.0f, flags);
                        }
                    } else if(tethered == _TETHERED_REARCHOKED){
                        MovementObject@ char = ReadCharacterID(tether_id);
                        int weap_id = GetCharPrimaryWeapon(char);
                        if(weap_id == -1){
                            this_mo.SetAnimation("Data/Animations/r_rearchokedstance.xml", 5.0f, flags);
                        } else {
                            if(being_executed != 2){
                                this_mo.SetAnimation("Data/Animations/r_rearknifecapturedstance.xml", 5.0f, flags);
                            } else {
                                this_mo.SetAnimation("Data/Animations/r_throatcuttee.anm", 10.0f, flags);
                            }
                        }
                    } else if(tethered == _TETHERED_DRAGBODY){
                        if(weapon_slots[_held_right] == -1 && weapon_slots[_held_left] == -1){
                            this_mo.SetAnimation("Data/Animations/r_dragstance.xml", 3.0f, flags);
                        } else {
                            flags = 0;
                            mirrored_stance = false;
                            if(weapon_slots[_held_right] == -1){
                                flags |= _ANM_MIRRORED;
                                mirrored_stance = true;
                            }
                            this_mo.SetAnimation("Data/Animations/r_dragstanceone.xml", 3.0f, flags);
                        }
                    }
                    this_mo.SetAnimatedItemID(0, weapon_slots[primary_weapon_slot]);
                }

                this_mo.SetIKEnabled(true);
            }
            roll_ik_fade = max(roll_ik_fade - 5.0f * ts.step(), 0.0f);
        }
    } else {
        jump_info.UpdateAirAnimation();
    }

    if(idle_stance){
        idle_stance_amount = mix(idle_stance_amount, 1.0f, pow(0.94f, ts.frames()));
    } else {
        idle_stance_amount = mix(idle_stance_amount, 0.0f, pow(0.98f, ts.frames()));
    }

    old_use_foot_plants = use_foot_plants;
    // center of mass offset
    this_mo.SetCOMOffset(com_offset, com_offset_vel);
}
    
vec3 GetLegTargetOffset(vec3 initial_pos, vec3 anim_pos){
    /*DebugDrawLine(initial_pos + vec3(0.0f,_check_up,0.0f),
                  initial_pos + vec3(0.0f,_check_down,0.0f),
                  vec3(1.0f),
                  _delete_on_draw);*/
    col.GetSweptSphereCollision(initial_pos + vec3(0.0f,_check_up,0.0f),
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

vec3 GetLimbTargetOffset(vec3 initial_pos, vec3 anim_pos){
    /*DebugDrawLine(initial_pos + vec3(0.0f,0.0f,0.0f),
                  initial_pos + vec3(0.0f,_check_down,0.0f),
                  vec3(1.0f),
                  _delete_on_draw);
    */
    col.GetSweptSphereCollision(initial_pos + vec3(0.0f,_check_up,0.0f),
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

int IsOnGround() {
    if(on_ground){
        return 1;
    } else {
        return 0;
    }
}

void MovementState_UpdateIKTargets(const Timestep &in ts) {
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

        vec3 l_foot_offset;
        vec3 r_foot_offset;

        l_foot_offset = foot[0].pos;
        r_foot_offset = foot[1].pos;

        l_foot_offset.y = 0.0f;
        r_foot_offset.y = 0.0f;

        left_leg_offset += GetLegTargetOffset(left_leg+left_leg_offset,left_leg_anim);
        right_leg_offset += GetLegTargetOffset(right_leg+right_leg_offset,right_leg_anim);
        
        l_foot_offset.y += foot[0].height;
        r_foot_offset.y += foot[1].height;
        
        this_mo.SetIKTargetOffset("left_leg",left_leg_offset*(1.0f-roll_ik_fade)-tilt_offset*0.5f + l_foot_offset);
        this_mo.SetIKTargetOffset("right_leg",right_leg_offset*(1.0f-roll_ik_fade)-tilt_offset*0.5f + r_foot_offset);
            
        if(tethered == _TETHERED_DRAGBODY){
            MovementObject@ char = ReadCharacterID(tether_id);
            vec3 target = char.GetIKChainPos(drag_body_part,drag_body_part_id);

            vec3 offset;
            if(weapon_slots[_held_left] != -1 || weapon_slots[_held_right] != -1){
                if(weapon_slots[_held_left] == -1){
                    offset = target - this_mo.GetIKTargetPosition("leftarm");
                } else if(weapon_slots[_held_right] == -1){
                    offset = target - this_mo.GetIKTargetPosition("rightarm");
                } 
                offset.y += 0.1f;
                vec3 facing = this_mo.GetFacing();
                vec3 right = vec3(facing.z, 0.0f, -facing.x);
                if(weapon_slots[_held_left] == -1){
                    offset += right * 0.05f;
                } else if(weapon_slots[_held_right] == -1){
                    offset -= right * 0.05f;
                } 
            } else {
                offset = target - ((this_mo.GetIKTargetPosition("leftarm") + this_mo.GetIKTargetPosition("rightarm"))*0.5f);
            }
            if(offset.y < -0.05f){
                offset.y = -0.05f;
            }

            if(weapon_slots[_held_left] == -1){
                this_mo.SetIKTargetOffset("leftarm",offset * drag_strength_mult);
            }
            if(weapon_slots[_held_right] == -1){
                this_mo.SetIKTargetOffset("rightarm",offset * drag_strength_mult);
            }
        } else {
            this_mo.SetIKTargetOffset("leftarm",vec3(0.0f,0.0f,0.0f));
            this_mo.SetIKTargetOffset("rightarm",vec3(0.0f,0.0f,0.0f));
        }

        vec3 body_offset(0.0f);
        if(idle_stance_amount > 0.0f){
            body_offset.y = sin(time*4.0f)*0.02f*idle_stance_amount;
            body_offset.x = sin(time*2.0f)*0.02f*idle_stance_amount;
            body_offset.z = sin(time*1.5f)*0.02f*idle_stance_amount;
        }

        //float curr_avg_offset_height = min(0.0f,
        //                          min(left_leg_offset.y, right_leg_offset.y));
        float avg_offset_height = (left_leg_offset.y + right_leg_offset.y) * 0.5f;
        float min_offset_height = min(0.0f, min(left_leg_offset.y, right_leg_offset.y));
        float mix_amount = 1.0f;//min(1.0f,length(this_mo.velocity));
        float curr_offset_height = mix(min_offset_height, avg_offset_height,mix_amount);
        offset_height = mix(offset_height, curr_offset_height, 1.0f-(pow(0.9f,ts.frames())));
        vec3 height_offset = vec3(0.0f,offset_height*(1.0f-roll_ik_fade)-0.1f*roll_ik_fade,0.0f);
        this_mo.SetIKTargetOffset("full_body",tilt_offset + height_offset + body_offset);

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

    /*vec3 item_pos;
    int num_items = GetNumItems();
    for(int i=0; i<num_items; i++){
        this_mo.ReadItem(i);
        vec3 pos = item_object_getter.GetPhysicsPosition();
        item_pos = pos;
    }
    this_mo.SetIKTargetOffset("rightarm",item_pos - this_mo.GetIKTargetPosition("rightarm"));*/
}

void UpdateIKTargets(int num_frames) {
    Timestep ts(time_step, num_frames);
    MovementState_UpdateIKTargets(ts);
}

void UpdateVelocity(const Timestep &in ts) {
    // GetTargetVelocitY() is defined in enemycontrol.as and playercontrol.as. Player target velocity depends on the camera and controls, AI's on player's position.
    this_mo.velocity += GetTargetVelocity() * _walk_accel * ts.step();
}

void ApplyPhysics(const Timestep &in ts) {
    if(!on_ground){
        this_mo.velocity += physics.gravity_vector * ts.step();
    }
    if(on_ground){
        //Print("Friction "+friction+"\n");
        if(!feet_moving){
            this_mo.velocity *= pow(0.95f,ts.frames());
        } else {
            const float e = 2.71828183f;
            float exp = _walk_accel*time_step*-1/max_speed;
            float current_movement_friction = pow(e,exp);
            this_mo.velocity *= pow(current_movement_friction, ts.frames());
        }
    }
}

void SetParameters() {
    weapon_slots.resize(_num_weap_slots);
    for(int i=0; i<_num_weap_slots; ++i){
        weapon_slots[i] = -1;       
    }
    //Print("Resizing weapon slots to "+_num_weap_slots+"\n");

    params.AddIntSlider("Lives",1,"min:1,max:4");
    p_lives = max(1, params.GetFloat("Lives"));
    lives = p_lives;

    params.AddFloatSlider("Aggression",0.5,"min:0,max:1,step:0.1,text_mult:100");
    p_aggression = min(1.0f, max(0.0f, params.GetFloat("Aggression")));

    params.AddFloatSlider("Damage Resistance",1,"min:0,max:2,step:0.1,text_mult:100");
    p_damage_multiplier = 1.0f / max(0.00001f,params.GetFloat("Damage Resistance"));

    params.AddFloatSlider("Block Skill",0.5,"min:0,max:1,step:0.1,text_mult:100");
    p_block_skill = min(1.0f, max(0.0f, params.GetFloat("Block Skill")));

    params.AddFloatSlider("Block Follow-up",0.5,"min:0,max:1,step:0.1,text_mult:100");
    p_block_followup = min(1.0f, max(0.0f, params.GetFloat("Block Follow-up")));

    params.AddFloatSlider("Attack Speed",1,"min:0,max:2,step:0.1,text_mult:100");
    p_attack_speed_mult = min(2.0f, max(0.1f, params.GetFloat("Attack Speed")));

    params.AddFloatSlider("Attack Damage",1,"min:0,max:2,step:0.1,text_mult:100");
    p_attack_damage_mult = max(0.0f, params.GetFloat("Attack Damage"));

    params.AddFloatSlider("Attack Knockback",1,"min:0,max:2,step:0.1,text_mult:100");
    p_attack_knockback_mult = max(0.0f, params.GetFloat("Attack Knockback"));

    params.AddFloatSlider("Movement Speed",1,"min:0.1,max:1.5,step:0.1,text_mult:100");
    p_speed_mult = min(100.0f, max(0.01f, params.GetFloat("Movement Speed")));
    run_speed = _base_run_speed * p_speed_mult;
    true_max_speed = _base_true_max_speed * p_speed_mult;
    
    params.AddIntCheckbox("Left handed",false);
    left_handed = (params.GetInt("Left handed") != 0);
    
    string team_str;
    character_getter.GetTeamString(team_str);
    params.AddString("Teams",team_str);

    mirrored_stance = left_handed;
    primary_weapon_slot = left_handed?_held_left:_held_right;
    secondary_weapon_slot = left_handed?_held_right:_held_left;
}
