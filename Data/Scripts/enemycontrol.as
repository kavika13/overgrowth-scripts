#include "aschar.as"
#include "situationawareness.as"
#include "enemycontroldebug.as"

Situation situation;

float startle_time;
float suspicious_amount;
float sound_time;
const float kSuspicionFadeSpeed = 0.2f;
const float kEnemySeenFadeSpeed = 0.2f;

bool has_jump_target = false;
vec3 jump_target_vel;

float awake_time = 0.0f;
const float AWAKE_NOTICE_THRESHOLD = 1.0f;

float enemy_seen = 0.0f;
float last_dodge_time = 0.0f;

bool hostile = true;
bool listening = true;
bool ai_attacking = false;
bool hostile_switchable = true;
int waypoint_target_id = -1;
int old_waypoint_target_id = -1;
const float _throw_counter_probability = 0.2f;
bool will_throw_counter;
int ground_punish_decision = -1;

float notice_target_aggression_delay = 0.0f;
int notice_target_aggression_id = 0.0f;

float target_attack_range = 0.0f;
float strafe_vel = 0.0f;
const float _block_reflex_delay_min = 0.1f;
const float _block_reflex_delay_max = 0.2f;
float block_delay;
bool going_to_block = false;
float dodge_delay;
bool going_to_dodge = false;
float roll_after_ragdoll_delay;
bool throw_after_active_block;
bool allow_active_block = true;
bool allow_throw = true;
bool always_unaware = false;
bool always_active_block = false;

bool combat_allowed = true;
bool chase_allowed = false;

bool woke_up = false;

class InvestigatePoint {
    vec3 pos;
    float seen_time;
};
array<InvestigatePoint> investigate_points;

const float kGetWeaponDelay = 0.4f;
float get_weapon_delay = kGetWeaponDelay;

enum AIGoal {_patrol, _attack, _investigate, _get_help, _escort, _get_weapon, _navigate, _struggle, _hold_still, _flee};
AIGoal goal = _patrol;

enum AISubGoal {_unknown = -1, _provoke_attack, _avoid_jump_kick, _knock_off_ledge, _wait_and_attack, _rush_and_attack, _defend, _surround_target, _escape_surround,
    _investigate_slow, _investigate_urgent, _investigate_body, _investigate_around};
AISubGoal sub_goal = _wait_and_attack; 
float attack_sub_goal_pick_time = 0.0;

AIGoal old_goal;
AISubGoal old_sub_goal;

int investigate_target_id = -1;
vec3 nav_target;
int ally_id = -1;
int escort_id = -1;
int chase_target_id = -1;
int weapon_target_id = -1;

float investigate_body_time;
float patrol_wait_until = 0.0f;

enum PathFindType {_pft_nav_mesh, _pft_climb, _pft_drop, _pft_jump};
PathFindType path_find_type = _pft_nav_mesh;
vec3 path_find_point;
float path_find_give_up_time;

float flee_update_time;
vec3 flee_dest;

enum ClimbStage {_nothing, _jump, _wallrun, _grab, _climb_up};
ClimbStage trying_to_climb = _nothing;
vec3 climb_dir;

void SetChaseTarget(int target){
    if(chase_target_id != target){
        chase_target_id = target;
        target_history.Initialize();
        if(target != -1){
            MovementObject@ char = ReadCharacterID(target);
            target_history.Update(char.position, char.velocity, time);
            situation.Notice(chase_target_id);
        }
    }
}

bool ActiveDodging(int attacker_id) { 
    if(startled){
        return false;
    }
    bool dodging = false;
    if(state == _movement_state && sub_goal == _provoke_attack && attack_getter2.GetFleshUnblockable() != 0){
        bool knife_attack = false;
        MovementObject@ char = ReadCharacterID(attacker_id);
        int enemy_primary_weapon_id = GetCharPrimaryWeapon(char);
        if(enemy_primary_weapon_id != -1){
            ItemObject@ weap = ReadItemID(enemy_primary_weapon_id);
            if(weap.GetLabel() == "knife"){
                knife_attack = true;
            }
        }
        if(knife_attack){
            dodging = (rand()%3==0);
        } else if(weapon_slots[primary_weapon_slot] == -1 || (rand()%10==0)){
            dodging = true;
        }
    } else {
        dodging = active_dodge_time > time - 0.2f;
    }

    if(dodging && the_time < last_dodge_time + 0.5f){
        dodging = false;
    }

    if(dodging){
        last_dodge_time = the_time;
    }
    return dodging;
}

bool ActiveBlocking() {
    return active_blocking;
}


void AIMovementObjectDeleted(int id) {
    situation.MovementObjectDeleted(id);
    if(ally_id == id){
        ally_id = -1;
        if(goal == _get_help){
            SetGoal(_patrol);
        }
    }
    if(investigate_target_id == id){
        investigate_target_id = -1;
        if(goal == _investigate){
            SetGoal(_patrol);
        }
    }
    if(escort_id == id){
        escort_id = -1;
        if(goal == _escort){
            SetGoal(_patrol);
        }
    }
    if(chase_target_id == id){
        SetChaseTarget(-1);
        if(goal == _attack){
            SetGoal(_patrol);
        }   
    }
    if(group_leader == id){
        group_leader = -1;
    }
}

int IsUnaware() {
    if(species == _wolf || species == _dog){
        return 0; // Cannot choke out wolves
    }
    return (goal == _patrol || startled || always_unaware)?1:0;
}

int IsAggro() {
    return (goal == _attack)?1:0;
}

int IsPassive() {
    return (goal == _patrol)?1:0;
}

bool WantsToDragBody(){
    return false;
}

void ResetMind() {
    goal = _patrol;
    situation.clear();
    path_find_type = _pft_nav_mesh;
    float awake_time = 0.0f;
}

int IsIdle() {
    if(goal == _patrol){
        return 1;
    } else {
        return 0;
    }
}

int IsAggressive() {
    return (knocked_out == _awake && (goal == _attack || goal == _get_help))?1:0;
}

class TargetHistoryElement {
    vec3 position;
    vec3 velocity;
    float time_stamp;
}

void DrawArrow(vec3 point, vec3 dir, float scale){
    vec3 right = cross(dir, vec3(0,1.01,0));
    DebugDrawLine(point, point+(right-dir)*scale, vec4(1.0), vec4(1.0), _delete_on_draw);
    DebugDrawLine(point, point-(right+dir)*scale, vec4(1.0), vec4(1.0), _delete_on_draw);                    
}

void DrawStealthDebug() {
    float ear_opac = min(1.0, max(0.0, suspicious_amount));
    float eye_opac = min(1.0, max(0.0, enemy_seen));
    if(knocked_out == _awake){
        if(goal == _patrol){
            if(ear_opac > eye_opac){
                DebugDrawBillboard("Data/Textures/ui/stealth_debug/ear.tga",
                            this_mo.position + vec3(0.0, 1.45, 0.0),
                                1.0f,
                                vec4(vec3(1.0f), ear_opac),
                              _delete_on_draw);
            } else {
                DebugDrawBillboard("Data/Textures/ui/eye_widget.tga",
                            this_mo.position + vec3(0.0, 1.45, 0.0),
                                1.0f,
                                vec4(vec3(1.0f), eye_opac),
                              _delete_on_draw);        
            }

            if(this_mo.GetWaypointTarget() != -1){
                int initial_waypoint = this_mo.GetWaypointTarget();
                int prev_waypoint = -1;
                int curr_waypoint = initial_waypoint;
                int next_waypoint = -1;
                while(next_waypoint != initial_waypoint)
                {
                    PathPointObject@ path_point_object = cast<PathPointObject>(ReadObjectFromID(curr_waypoint));
                    int num_connections = path_point_object.NumConnectionIDs();
                    next_waypoint = curr_waypoint;
                    for(int i=0; i<num_connections; ++i){
                        if(path_point_object.GetConnectionID(i) != prev_waypoint){
                            next_waypoint = path_point_object.GetConnectionID(i);
                            break;
                        }
                    }
                    vec3 start = ReadObjectFromID(curr_waypoint).GetTranslation()+vec3(0,0.1,0);
                    vec3 end = ReadObjectFromID(next_waypoint).GetTranslation()+vec3(0,0.1,0);
                    DebugDrawLine(start, end, vec4(1.0), vec4(1.0,1.0,1.0,1.0), _delete_on_draw);
                    int num_arrows = 4;
                    for(int i=0; i<num_arrows; ++i){
                        DrawArrow(mix(start, end, (i+1)/float(num_arrows+1)), normalize(end-start), 0.2);
                    }
                    prev_waypoint = curr_waypoint;
                    curr_waypoint = next_waypoint;
                }
            }

            float fov_opac_mult = 0.0;
            const float fade_time = 4.0;
            if(time - last_fov_change < fade_time){
                fov_opac_mult = max(fov_opac_mult, 1.0 - (time - last_fov_change) / fade_time);
            }
            if(fov_opac_mult > 0.0){
                mat4 transform = this_mo.rigged_object().GetAvgIKChainTransform(head_string);
                mat4 transform_offset;
                transform_offset.SetRotationX(-70);
                transform.SetRotationPart(transform.GetRotationPart()*transform_offset);  
                vec3 fov = fov_peripheral;
                array<vec3> points;
                GetFOVMesh(fov[0], fov[1], points);
                vec4 color = vec4(1.0, 0.0, 0.0, 0.2 * fov_opac_mult);
                for(int i=0; i<8; ++i){
                    vec3 temp_fov = fov;
                    temp_fov[2] = i/8.0f * fov[2];
                    vec3 prev_point;
                    for(int j=0, len=points.size(); j<len; ++j){
                        vec3 point = transform*(points[j] * temp_fov[2]);
                        if(j != 0 && j%7 != 1){
                            DebugDrawLine(transform*(points[j-1] * temp_fov[2]), point, color, color, _delete_on_draw);
                        }
                        if(j > 7){
                            DebugDrawLine(transform*(points[j-7] * temp_fov[2]), point, color, color, _delete_on_draw);
                        }
                        prev_point = point;
                    }
                    //DrawFrustumCurve(transform, temp_fov, vec4(1.0, 0.0, 0.0, 0.2));
                    //GetFOVMesh(transform, temp_fov[0], temp_fov[1], temp_fov[2], vec4(1.0, 0.0, 0.0, 0.2));
                }

                fov = fov_focus;
                color = vec4(1.0, 1.0, 1.0, 0.1 * fov_opac_mult);
                points.resize(0);            
                GetFOVMesh(fov[0], fov[1], points);

                for(int i=0; i<20; ++i){
                    vec3 temp_fov = fov;
                    temp_fov[2] = i/20.0f * fov[2];
                    for(int j=0, len=points.size(); j<len; ++j){
                        vec3 point = transform*(points[j] * temp_fov[2]);
                        if(j != 0 && j%7 != 1){
                            DebugDrawLine(transform*(points[j-1] * temp_fov[2]), point, color, color, _delete_on_draw);
                        }
                        if(j > 7){
                            DebugDrawLine(transform*(points[j-7] * temp_fov[2]), point, color, color, _delete_on_draw);
                        }
                    }
                    //DrawFrustumCurve(transform, temp_fov, vec4(1.0, 1.0, 1.0, 0.1));
                    //GetFOVMesh(transform, temp_fov[0], temp_fov[1], temp_fov[2], vec4(1.0, 1.0, 1.0, 0.1));
                }
                //DebugDrawWireMesh("Data/Models/fov.obj", transform, vec4(vec3(1.0f), 0.1f), _delete_on_draw);
            }
        } else if(goal == _attack){
            DebugDrawBillboard("Data/Textures/ui/stealth_debug/exclamation.tga",
                        this_mo.position + vec3(0.0, 1.45, 0.0),
                            1.0f,
                            vec4(vec3(1.0f), 1.0f),
                          _delete_on_draw);
        } else {
            DebugDrawBillboard("Data/Textures/ui/stealth_debug/question.tga",
                        this_mo.position + vec3(0.0, 1.45, 0.0),
                            1.0f,
                            vec4(vec3(1.0f), 1.0f),
                          _delete_on_draw);
        }
    } else if(knocked_out == _unconscious){
        DebugDrawBillboard("Data/Textures/ui/stealth_debug/zzzz.tga",
                    this_mo.position + vec3(0.0, 1.45, 0.0),
                        1.0f,
                        vec4(vec3(1.0f), 1.0f),
                      _delete_on_draw);
    } else if(knocked_out == _dead){
        DebugDrawBillboard("Data/Textures/ui/stealth_debug/poison.tga",
                    this_mo.position + vec3(0.0, 1.45, 0.0),
                        1.0f,
                        vec4(vec3(1.0f), 1.0f),
                      _delete_on_draw);

    }
}

const int kTargetHistorySize = 16;
class TargetHistory {
    private TargetHistoryElement[] elements;
    private int index;
    private bool first_update;
    private float last_updated;

    void Initialize() {
        elements.resize(kTargetHistorySize);
        index = 0;
        first_update = true;
    }
    void Update(const vec3 &in pos, const vec3 &in vel, float time_stamp){
        if(first_update){
            for(int i=0; i<kTargetHistorySize; ++i){
                elements[i].position = pos;
                elements[i].velocity = vel;
                elements[i].time_stamp = time_stamp;
            }
            first_update = false;
        }
        elements[index].position = pos;
        elements[index].velocity = vel;
        elements[index].time_stamp = time_stamp;
        index = (index + 1) % kTargetHistorySize;
        last_updated = time_stamp;
        /*for(int i=0; i<kTargetHistorySize; ++i){
            DebugDrawWireSphere(elements[i].position, 0.1f, vec3(1.0f), _delete_on_update);
        }*/
    }
    vec3 GetPos(float time_stamp){
        int prev_index, next_index;
        float t;
        GetInterp(time_stamp, prev_index, next_index, t);
        vec3 pos = mix(elements[prev_index].position, elements[next_index].position, t);// + elements[temp_index].velocity * elements[temp_index].time_elapsed;
        return pos;
    }
    vec3 GetVel(float time_stamp){
        int prev_index, next_index;
        float t;
        GetInterp(time_stamp, prev_index, next_index, t);
        vec3 vel = mix(elements[prev_index].velocity, elements[next_index].velocity, t);// + elements[temp_index].velocity * elements[temp_index].time_elapsed;
        return vel;
    }
    float LastUpdated(){
        return last_updated;
    }
    private void GetInterp(float time_stamp, int &out prev_index, int &out next_index, float &out t){
        prev_index = index;
        for(int i=0; i<kTargetHistorySize; ++i){
            next_index = prev_index;
            prev_index = (prev_index + kTargetHistorySize - 1)%kTargetHistorySize;
            if(elements[prev_index].time_stamp < time_stamp){
                break;
            }
        }
        t = 0.0f;
        float prev_time = elements[prev_index].time_stamp;
        float next_time = elements[next_index].time_stamp;
        if(next_time - prev_time != 0.0f){
            t = (time_stamp - prev_time)/(next_time - prev_time);
        }
        t = max(t, 0.0f);
    }
}

TargetHistory target_history;

void Startle() {
    startled = true;
    startle_time = 1.0f;    
}

void Notice(int character_id){
    MovementObject@ char = ReadCharacterID(character_id);
    if(!this_mo.OnSameTeam(char) && (goal != _attack || chase_target_id == -1)){
        switch(goal){
            case _patrol:
                if(!situation.KnowsAbout(character_id)){
                    Startle();
                    this_mo.PlaySoundGroupVoice("engage",0.0f);
                    AISound(this_mo.position, VERY_LOUD_SOUND_RADIUS, _sound_type_voice);
                }
                SetGoal(_attack);
                break;
            case _investigate:
                if(!situation.KnowsAbout(character_id)){
                    Startle();
                    this_mo.PlaySoundGroupVoice("engage",0.0f);
                    AISound(this_mo.position, VERY_LOUD_SOUND_RADIUS, _sound_type_voice);
                }
                SetGoal(_attack);
                break;
            case _escort:
                SetGoal(_attack);
                break;
        }
        if(goal == _attack && char.GetIntVar("species") == _wolf && (species != _wolf && species != _dog)){
            SetGoal(_flee);
        }
        SetChaseTarget(character_id);
    }
    situation.Notice(character_id);
}

void NotifySound(int created_by_id, vec3 pos, SoundType type) {
    if(!listening || static_char || 
       awake_time < AWAKE_NOTICE_THRESHOLD || knocked_out != _awake || 
       created_by_id == this_mo.GetID())
    {
        return;
    }
    if(goal == _patrol || goal == _investigate){
        bool same_team = false;
        character_getter.Load(this_mo.char_path);
        if(this_mo.OnSameTeam(ReadCharacterID(created_by_id)) && situation.KnowsAbout(created_by_id)){
            same_team = true;
        }
        bool ignore_sound = false;
        if(same_team && (type == _sound_type_foley || type == _sound_type_loud_foley)){
            ignore_sound = true;
        }
        if(same_team && goal == _investigate && sub_goal != _investigate_slow){
            ignore_sound = true;
        }
        if(!ignore_sound){
            if(type == _sound_type_foley){
                suspicious_amount += 0.3f;
            } else {
                suspicious_amount += 1.0f;
            }
            sound_time = time;
            if(suspicious_amount >= 1.0f){
                if(goal == _patrol){
                    this_mo.PlaySoundGroupVoice("suspicious",0.0f);
                    //AISound(this_mo.position, VERY_LOUD_SOUND_RADIUS, _sound_type_voice);
                    ai_look_target = pos;
                    ai_look_override_time = time+2.0;
                }
                nav_target = pos;
                if(type == _sound_type_foley || type == _sound_type_loud_foley) {
                    SetGoal(_investigate);
                    SetSubGoal(_investigate_slow);
                } else if(type == _sound_type_voice && ReadCharacterID(created_by_id).GetIntVar("knocked_out") == _awake){
                    SetGoal(_escort);
                    escort_id = created_by_id;
                } else {
                    SetGoal(_investigate);
                    SetSubGoal(_investigate_urgent);     
                }
                investigate_target_id = -1;
                if(chase_target_id == -1) {
                    //DebugText("Player "+this_mo.GetID()+" hear", "Player "+this_mo.GetID()+" says: I heard something!", 1.0f);
                }
            }
        }
    }
}

void HandleAIEvent(AIEvent event){
    switch(event){
    case _ragdolled:    
        roll_after_ragdoll_delay = RangedRandomFloat(0.1f,1.0f);
        break;
    case _jumped:
        has_jump_target = false;
        if(trying_to_climb == _jump){
            trying_to_climb = _wallrun;
        }   
        break;
    case _grabbed_ledge:
        if(trying_to_climb == _wallrun){
            trying_to_climb = _climb_up;
        }   
        break;
    case _climbed_up:
        if(trying_to_climb == _climb_up){
            trying_to_climb = _nothing;
            path_find_type = _pft_nav_mesh;
        }   
        break;
    case _thrown:
        will_throw_counter = RangedRandomFloat(0.0f,1.0f)<_throw_counter_probability;   
        break;
    case _can_climb:
        trying_to_climb = _jump;
        break;
    case _dodged: 
        throw_after_active_block = true;
        break;
    case _activeblocked: {
        float temp_block_followup = p_block_followup;
        if(sub_goal == _provoke_attack){
            temp_block_followup = 1.0 - (pow(1.0 - temp_block_followup, 2.0));
        }
        if(always_active_block){
            throw_after_active_block = true;
        } else if(RangedRandomFloat(0.0f, 1.0f) < temp_block_followup){
            if(allow_active_block){
                throw_after_active_block = RangedRandomFloat(0.0f,1.0f) > 0.7f;
            }else{
                throw_after_active_block = false;
            }
            if(!throw_after_active_block){
                throw_after_active_block = false;
                SetSubGoal(_rush_and_attack);
                attack_sub_goal_pick_time = time + 1.0;
            }
        }
        if(!allow_throw){
            throw_after_active_block = false;
        }
        } break;
    case _choking: {
        MovementObject@ char = ReadCharacterID(tether_id);
        if(GetCharPrimaryWeapon(char) == -1 || ReadItemID(GetCharPrimaryWeapon(char)).GetLabel() == "staff"){
            SetGoal(_struggle);
        } else {
            SetGoal(_hold_still);
        }
        } break;
    case _damaged:
        if(goal == _patrol && combat_allowed){
            Print("Damaged!\n");
            nav_target = this_mo.position;
            SetGoal(_investigate);
            SetSubGoal(_investigate_around);
            investigate_target_id = -1;
        }
    }
}

string GoalString(AIGoal goal) {
    switch(goal){
        case _patrol:      return "_patrol";
        case _attack:      return "_attack";
        case _investigate: return "_investigate";
        case _get_help:    return "_get_help";
        case _escort:      return "_escort";
        case _get_weapon:  return "_get_weapon";
        case _navigate:    return "_navigate";
        case _struggle:    return "_struggle";
        case _hold_still:  return "_hold_still";
    }
    return "unknown goal";
}

void SetGoal(AIGoal new_goal){
    if(asleep){
        if(tethered == _TETHERED_FREE){
            WakeUp(_wake_stand);
        }
        asleep = false;
        woke_up = true;
    }
    if(sitting){
        sitting = false;
        woke_up = true;
    }
    if(goal != new_goal){
        switch(new_goal){
        case _flee:
            flee_update_time = 0.0;
            break;
        case _attack:
            notice_target_aggression_delay = 0.0f;
            target_history.Initialize();
            SetSubGoal(PickAttackSubGoal());
            break;
        case _patrol:
            patrol_wait_until = 0.0f;
            break;
        }
        goal = new_goal;
    }
}

float move_delay = 0.0f;
float repulsor_delay = 0.0f;
float jump_delay = 0.0f;

void MindReceiveMessage(string msg){
    TokenIterator token_iter;
    token_iter.Init();
    if(!token_iter.FindNextToken(msg)){
        return;
    }
    string token = token_iter.GetToken(msg);
    if(token == "escort_me"){
        token_iter.FindNextToken(msg);
        int id = atoi(token_iter.GetToken(msg));
        SetGoal(_escort);
        escort_id = id;
    } else if(token == "excuse_me"){
        move_delay = 1.0f;
    } else if(token == "jumping_to_attack_you") {
        token_iter.FindNextToken(msg);
        int id = atoi(token_iter.GetToken(msg));
        if(chase_target_id != -1){
            MovementObject@ char = ReadCharacterID(chase_target_id);
            if( xz_distance_squared(this_mo.position, char.position) < 100.0f ) {
                jump_delay = 10.0f;
            }
        }
    } else if(token == "set_hostile"){
        token_iter.FindNextToken(msg);
        string second_token = token_iter.GetToken(msg);
        if(second_token == "true"){
            SetHostile(true);
        } else if(second_token == "false"){
            SetHostile(false);
        }
    } else if(token == "set_combat_allowed"){
        token_iter.FindNextToken(msg);
        string second_token = token_iter.GetToken(msg);
        if(second_token == "true"){
            combat_allowed = true;
            SetGoal(_attack);
        } else if(second_token == "false"){
            combat_allowed = false;
        }
    } else if(token == "notice"){
        Print("Received notice message\n");
        token_iter.FindNextToken(msg);
        int id = atoi(token_iter.GetToken(msg));
        situation.Notice(id);
        Notice(id);
    } else if(token == "collided"){
    }/* else if(token == "collided"){
        token_iter.FindNextToken(msg);
        int id = atoi(token_iter.GetToken(msg));
        Notice(id);
    }*/ else if(token == "nearby_sound"){
        vec3 pos;
        float max_range;
        int id;
        SoundType type;
        for(int i=0; i<6; ++i){
            token_iter.FindNextToken(msg);
            switch(i){
            case 0: pos.x = atof(token_iter.GetToken(msg)); break;
            case 1: pos.y = atof(token_iter.GetToken(msg)); break;
            case 2: pos.z = atof(token_iter.GetToken(msg)); break;
            case 3: max_range = atof(token_iter.GetToken(msg)); break;
            case 4: id = atoi(token_iter.GetToken(msg)); break;
            case 5: type = SoundType(atoi(token_iter.GetToken(msg))); break;
            }
        }
        NotifySound(id, pos, type);
    }
}

float target_on_ground_time = 0.0;

AISubGoal PickAttackSubGoal() {
    AISubGoal target_goal = _rush_and_attack;
    if(species != _wolf){
        string weap_label;
        if(weapon_slots[primary_weapon_slot] != -1){
            ItemObject @item_obj = ReadItemID(weapon_slots[primary_weapon_slot]);
            weap_label = item_obj.GetLabel();
        }
        if(weap_label == "staff" || weap_label == "spear"){
        } else {
            if(chase_target_id != -1 && ObjectExists(chase_target_id)){
                MovementObject @char = ReadCharacterID(chase_target_id);
                bool enemy_using_knife = false;
                int enemy_primary_weapon_id = GetCharPrimaryWeapon(char);
                if(enemy_primary_weapon_id != -1){
                    ItemObject@ weap = ReadItemID(enemy_primary_weapon_id);
                    if(weap.GetLabel() != "knife"){
                        enemy_using_knife = true;
                    }
                }

                if(char.GetFloatVar("threat_amount") > 0.5 && char.controlled && !char.GetBoolVar("feinting")){
                    target_goal = _provoke_attack;
                }
            }
        }
    }
    if(chase_target_id != -1 && ObjectExists(chase_target_id)){
        MovementObject @target = ReadCharacterID(chase_target_id);
        if(target.GetIntVar("state") == _ragdoll_state){
            target_on_ground_time = the_time;
            if(ground_punish_decision == -1){
                if((RangedRandomFloat(0.0f,1.0f) < p_ground_aggression)){
                    ground_punish_decision = 1;
                } else {
                    ground_punish_decision = 0;
                }
            }
        } else {
            if(the_time > target_on_ground_time + 0.8){
                ground_punish_decision = -1;
            }
        }
        if(ground_punish_decision == 0 && target_goal == _rush_and_attack){
            target_goal = _provoke_attack;
        }
    }
    if(state == _ragdoll_state || state == _hit_reaction_state){
        target_goal = _defend;
    }
    if(target_goal == _rush_and_attack && group_leader != -1){
        target_goal = _defend;
    }

    return target_goal;
}

bool instant_range_change = true;

void SetSubGoal(AISubGoal sub_goal_) {
    if(sub_goal != sub_goal_){
        instant_range_change = true;
        if(sub_goal_ == _investigate_around){
            investigate_points.resize(0);
        }
    }
    sub_goal = sub_goal_;
}

bool CheckRangeChange(const Timestep &in ts) {
    bool change = false;
    if(instant_range_change || rand()%(150/ts.frames())==0){
        change = true;
    }
    instant_range_change = false;
    return change;
}

void SetHostile(bool val){
    hostile = val;
    if(hostile){
        ai_attacking = true;
        listening = true;
        static_char = false;
    } else {
        SetGoal(_patrol);
        ResetWaypointTarget();
        listening = false;
    }
}


int GetClosestKnownThreat() {
    int closest_enemy = -1;
    float closest_dist = 0.0f;
    for(uint i=0; i<situation.known_chars.size(); ++i){
        if(!situation.known_chars[i].friendly && situation.known_chars[i].knocked_out == _awake){
            MovementObject@ char = ReadCharacterID(situation.known_chars[i].id);
            float dist = distance_squared(situation.known_chars[i].last_known_position, this_mo.position);
            if(closest_enemy == -1 || dist < closest_dist){
                closest_dist = dist;
                closest_enemy = situation.known_chars[i].id;
            }
        }
    }
    return closest_enemy;
}

void CheckForNearbyWeapons() {
    if(species != _wolf){
        bool wants_to_get_weapon = false;
        if(weapon_slots[primary_weapon_slot] == -1 && hostile){
            /*int nearest_weapon = -1;
            float nearest_dist = 0.0f;
            const float _max_dist = 30.0f;
            for(int i=0, len=situation.known_items.size(); i<len; ++i){
                ItemObject @item_obj = ReadItemID(situation.known_items[i].id);
                if(item_obj.IsHeld() || item_obj.GetType() != _weapon){
                    continue;
                }
                vec3 pos = situation.known_items[i].last_known_position;
                float dist = distance_squared(pos, this_mo.position);
                if(dist > _max_dist * _max_dist){
                    continue;
                }
                //Verify that the item atelast is on a walkable surface.
                if(!IsOnNavMesh(item_obj,pos))
                {
                    continue;
                } 
                if(nearest_weapon == -1 || dist < nearest_dist){ 
                    nearest_weapon = item_obj.GetID();
                    nearest_dist = dist;
                }

            }*/
            int nearest_weapon = GetNearestPickupableWeapon(this_mo.position, 10.0);
            if(nearest_weapon != -1){
                ItemObject@ io = ReadItemID(nearest_weapon);
                int stuck_id = io.StuckInWhom();
                if(stuck_id == -1 || ReadCharacterID(stuck_id).GetIntVar("knocked_out") != _awake){
                    NavPath path = GetPath(this_mo.position, ReadItemID(nearest_weapon).GetPhysicsPosition());
                    if(path.success){
                        wants_to_get_weapon = true;
                        weapon_target_id = nearest_weapon;
                    }
                }
            }
        }
        if(wants_to_get_weapon){
            if(get_weapon_delay >= 0.0f){
                get_weapon_delay -= time_step;
            } else {
                old_goal = goal;
                old_sub_goal = sub_goal;
                SetGoal(_get_weapon);
            }
        } else {
            get_weapon_delay = kGetWeaponDelay;
        }
    }
}

float next_vision_check_time;

array<int> followers;

void AddFollower(int id){
    if(followers.size() == 0){
        SetSubGoal(_rush_and_attack);
        attack_sub_goal_pick_time = time + 1.0;
    }
    followers.push_back(id);
}

void RemoveFollower(int id){
    for(int i=0, len=followers.size(); i<len; ++i){
        if(followers[i] == id){
            followers[i] = followers[followers.size()-1];
            followers.resize(followers.size()-1);
            break;
        }
    }
}

void StopBeingGroupLeader(){
    for(int i=0, len=GetNumCharacters(); i<len; ++i){
        MovementObject@ char = ReadCharacter(i);
        if(char.GetID() != this_mo.GetID() && !char.controlled && this_mo.OnSameTeam(char) && char.QueryIntFunction("int IsAggro()") == 1 && char.GetIntVar("knocked_out") == _awake && char.GetIntVar("state") != _ragdoll_state){
            char.Execute("group_leader = -1; AddFollower("+this_mo.GetID()+");");
            group_leader = char.GetID();
            RemoveFollower(group_leader);
            break;
        }
    }
}

void AIEndAttack(){
    if(group_leader == -1 && followers.size() != 0 && rand()%2==0){
        StopBeingGroupLeader();
    }
}

void AllyInfo() {
    if(goal == _attack){
        if(group_leader == -1 && followers.size() == 0){
            for(int i=0, len=GetNumCharacters(); i<len; ++i){
                MovementObject@ char = ReadCharacter(i);
                if(char.GetID() != this_mo.GetID() && 
                  !char.controlled && 
                  this_mo.OnSameTeam(char) &&
                   char.QueryIntFunction("int IsAggro()") == 1 && 
                   char.GetIntVar("knocked_out") == _awake && 
                   char.GetIntVar("state") != _ragdoll_state &&
                   char.GetIntVar("group_leader") == -1 &&
                   distance_squared(char.position, ReadCharacterID(chase_target_id).position) < 9.0)
                {
                    char.Execute("AddFollower("+this_mo.GetID()+");");
                    group_leader = char.GetID();
                    break;
                }
            }
        } else if(group_leader != -1){
            MovementObject@ char = ReadCharacterID(group_leader);
            if(char.GetIntVar("knocked_out") != _awake || char.GetIntVar("state") == _ragdoll_state || char.GetIntVar("group_leader") != -1 || distance_squared(char.position, ReadCharacterID(chase_target_id).position) > 9.0){
                char.Execute("RemoveFollower("+this_mo.GetID()+");");
                group_leader = -1;
            }
        } else if(rand()%100==0){
            StopBeingGroupLeader();
        }
    } else {
        if(group_leader != -1){
            MovementObject@ char = ReadCharacterID(group_leader);
            char.Execute("RemoveFollower("+this_mo.GetID()+");");
            group_leader = -1;
        }
    }
}

void UpdateBrain(const Timestep &in ts){   
    EnterTelemetryZone("UpdateDebugSettings"); 
    UpdateDebugSettings();
    LeaveTelemetryZone();

    if(knocked_out != _awake){
        return;
    }
    awake_time += ts.step();

    if(static_char){
        return;
    }

    if(DebugKeysEnabled() && GetInputDown(this_mo.controller_id, "c") && !GetInputDown(this_mo.controller_id, "ctrl")){
        if(hostile_switchable){
            SetHostile(!hostile);
        }
        hostile_switchable = false;
    } else {
        hostile_switchable = true;
    }

    if(startled){
        startle_time -= ts.step();
        if(startle_time <= 0.0f){
            startled = false;
            AchievementEvent("enemy_alerted");
        }
    }

    AllyInfo();

    suspicious_amount = max(0.0f, suspicious_amount - ts.step() * kSuspicionFadeSpeed);
    move_delay = max(0.0f, move_delay - ts.step());
    jump_delay = max(0.0f, jump_delay - ts.step());
    repulsor_delay = max(0.0f, repulsor_delay - ts.step());

    if(hostile && awake_time > AWAKE_NOTICE_THRESHOLD && !asleep){
        if(time > next_vision_check_time){
            next_vision_check_time = time + RangedRandomFloat(0.2f,0.3f);
            bool print_visible_chars = false;
            if(print_visible_chars) {
                array<int> characters;
                GetVisibleCharacters(0, characters);
                for(int i=0, len=characters.size(); i<len; ++i){
                    string desc;
                    MovementObject@ char = ReadCharacterID(characters[i]);
                    if(char.GetIntVar("knocked_out") == _awake){
                        desc += "awake";
                    } else {
                        desc += "unconscious";
                    }
                    desc += " ";
                    if(this_mo.OnSameTeam(char)){
                        desc += "ally";
                    } else {
                        desc += "enemy";
                    }
                    DebugText(this_mo.getID()+"visible_character"+i, this_mo.getID()+" sees character "+characters[i]+" ("+desc+")", 0.5f);
                }
            }

            array<int> visible_characters;
            if(!omniscient){
                GetVisibleCharacters(0, visible_characters);                
            } else {
                for(int i=0, len=GetNumCharacters(); i<len; ++i){
                    if(ReadCharacter(i).GetID() != this_mo.GetID()){
                        visible_characters.push_back(ReadCharacter(i).GetID());
                    }
                }
            }
            int num_enemies_visible = 0;
            for(int i=0, len=visible_characters.size(); i<len; ++i){
                int id = visible_characters[i];
                MovementObject@ char = ReadCharacterID(id);
                if(id == chase_target_id){    
                    target_history.Update(char.position, char.velocity, time);
                    situation.Notice(id);
                }
                if(this_mo.OnSameTeam(char)){
                    if(char.GetIntVar("knocked_out") != _awake && goal == _patrol){
                        // Check if we already know that this character is unconscious 
                        bool already_known = false;
                        int known_id = situation.KnownID(id);
                        if(known_id != -1 && situation.known_chars[known_id].knocked_out != _awake){
                            already_known = true;
                        }        
                        if(!already_known){
                            // Investigate body of ally                
                            Startle();
                            this_mo.PlaySoundGroupVoice("suspicious",0.0f);
                            AISound(this_mo.position, VERY_LOUD_SOUND_RADIUS, _sound_type_voice);
                            random_look_delay = 1.0f;
                            random_look_dir = char.position - this_mo.position;
                            SetGoal(_investigate);
                            SetSubGoal(_investigate_urgent);
                            investigate_target_id = id;
                        }
                    }
                    Notice(id);
                } else {
                    if(char.GetIntVar("knocked_out") == _awake && (char.GetIntVar("invisible_when_stationary") == 0 || length_squared(char.velocity) > 0.1 || char.GetFloatVar("duck_amount") < 0.5 || distance_squared(this_mo.position, char.position) < 4.0)){
                        ++num_enemies_visible;
                        if(goal == _patrol || goal == _investigate){
                            ai_look_target = char.position + char.velocity * (next_vision_check_time - time);
                            ai_look_override_time = time+2.0;
                        }
                        float amount;
                        if(fov_focus[2] != 0.0){
                            amount = mix(0.5f, 0.1f, distance(this_mo.position, char.position)/fov_focus[2]);
                        } else {
                            amount = 0.1f;
                        }
                        if(goal != _patrol){
                            amount *= 3.0;
                        }
                        if(char.GetIntVar("invisible_when_stationary") == 1){
                            amount *= 0.3;
                        }
                        enemy_seen += amount;
                    }
                }
                if(situation.KnowsAbout(id)){
                    situation.Notice(id);
                }
            }
            if(num_enemies_visible == 0){
                enemy_seen = max(0.0f, enemy_seen - 0.25f * kEnemySeenFadeSpeed);
            }
            // Notice enemy if alerted above threshold
            if(enemy_seen >= 1.0f){
                array<int> enemies;
                GetMatchingCharactersInArray(visible_characters, enemies, _TC_ENEMY | _TC_CONSCIOUS);
                int closest_id = GetClosestCharacterInArray(this_mo.position, enemies, 0.0f);
                if(closest_id != -1){
                    Notice(closest_id);
                }
                enemy_seen = 1.0f;
            } else if(enemy_seen > 0.5f){
                array<int> enemies;
                GetMatchingCharactersInArray(visible_characters, enemies, _TC_ENEMY | _TC_CONSCIOUS);
                int closest_id = GetClosestCharacterInArray(this_mo.position, enemies, 0.0f);
                if(closest_id != -1 && goal == _patrol){
                    MovementObject@ target = ReadCharacterID(closest_id);
                    nav_target = this_mo.position + normalize(target.position-this_mo.position)*3.0f;
                    SetGoal(_investigate);
                    SetSubGoal(_investigate_slow);
                    investigate_target_id = -1;
                }
            }
            //DebugText("a", "num_enemies_visible: "+num_enemies_visible, 0.5f);
            //DebugText("b", "enemy_seen: "+enemy_seen, 0.5f);
        }
    } else {
        SetChaseTarget(-1);
        force_look_target_id = -1;
    }

    if(chase_target_id != -1){
        vec3 head_pos = this_mo.rigged_object().GetAvgIKChainPos(head_string);
        MovementObject@ chase_target = ReadCharacterID(chase_target_id);
        if(VisibilityCheck(head_pos, chase_target)){
            target_history.Update(chase_target.position, chase_target.velocity, time);
            situation.Notice(chase_target_id);
        }
    }

    switch(goal){
    case _patrol:
    case _escort:
        ai_attacking = false;
        break;
    case _flee:
        break;
    case _investigate:  {
        ai_attacking = false;
        GetPath(GetInvestigateTargetPos());
        if(path.NumPoints() > 0){
            vec3 path_end = path.GetPoint(path.NumPoints()-1);
            if(distance_squared(GetNavPointPos(this_mo.position), path_end) < 1.0f){
                if(sub_goal == _investigate_slow){
                    SetGoal(_patrol);
                } else if(sub_goal == _investigate_urgent){
                    SetSubGoal(_investigate_body);
                    investigate_body_time = time + RangedRandomFloat(2.0f, 4.0f);
                }
            }      
        }
        if(sub_goal == _investigate_body && time > investigate_body_time){
            sub_goal = _investigate_around;
            investigate_target_id = -1;
            SetSubGoal(_investigate_around);
            investigate_points.resize(0);
        }
        if(sub_goal == _investigate_around){
            if(investigate_points.size() == 0){
                float range = 8.0f;
                investigate_points.resize(0);
                for(int i=-3; i<3; ++i){
                    for(int j=-3; j<3; ++j){
                        vec3 rand_offset(i*range + RangedRandomFloat(-range*0.5f,range*0.5f), RangedRandomFloat(-range, range), j*range + RangedRandomFloat(-range*0.5f,range*0.5f));
                        vec3 investigate = GetNavPointPos(this_mo.position + rand_offset);
                        col.GetSlidingSphereCollision(investigate, _leg_sphere_size);
                        if(sphere_col.NumContacts() > 0){ // Sanity check whether investigate points are actually on the surface
                            if(investigate != vec3(0.0f)){
                                NavPath path = GetPath(this_mo.position, investigate);
                                if(path.success){
                                    InvestigatePoint point;
                                    investigate.y += _leg_sphere_size;
                                    point.pos = investigate;
                                    point.seen_time = 0.0f;
                                    investigate_points.push_back(point);
                                }
                            }
                        }
                    }
                }
            }
            mat4 transform = this_mo.rigged_object().GetAvgIKChainTransform("head");
            vec3 head_pos = transform * vec4(0.0f,0.0f,0.0f,1.0f);
            vec3 head_facing = normalize(transform * vec4(0.0f,0.8f,0.2f,0.0f));
            for(int i=investigate_points.size()-1; i>=0; --i){
                if(distance_squared(this_mo.position, investigate_points[i].pos) < 1.0f){
                    investigate_points[i].seen_time += ts.step() * 3.0f;
                } else if(dot(normalize(investigate_points[i].pos-head_pos), head_facing) > 0.5f){
                    if(col.GetRayCollision(head_pos, investigate_points[i].pos) == investigate_points[i].pos){
                        investigate_points[i].seen_time += ts.step() * 3.0f;
                    }
                }
                if(investigate_points[i].seen_time >= 1.0f){
                    investigate_points.removeAt(i);
                    move_delay = RangedRandomFloat(0.2,0.6);
                }
            }
            if(move_delay <= 0.1){
                float closest_dist = 0.0f;
                int closest_point_id = -1;
                for(int i=0, len=investigate_points.size(); i<len; ++i){
                    if(_debug_draw_investigate){
                        DebugDrawWireSphere(investigate_points[i].pos, 1.0f, vec3(1.0f), _fade);
                    }
                    NavPath path = GetPath(this_mo.position, investigate_points[i].pos);
                    float dist = 0.0f;
                    for(int j=0, len2=path.NumPoints()-1; j<len2; ++j){
                        dist += distance(path.GetPoint(j), path.GetPoint(j+1));
                    }
                    if(closest_point_id == -1 || dist < closest_dist){
                        closest_point_id = i;
                        closest_dist = dist;
                    }
                }
                if(closest_point_id != -1){
                    ai_look_target = investigate_points[closest_point_id].pos;
                    ai_look_override_time = time+1.0;

                    nav_target = investigate_points[closest_point_id].pos;
                    if(_debug_draw_investigate){
                        DebugDrawLine(this_mo.position, nav_target, vec3(1.0f), _fade);
                        NavPath path = GetPath(this_mo.position, nav_target);
                        if(path.success){
                            for(int i=0, len=path.NumPoints()-1; i<len; ++i){
                                DebugDrawLine(path.GetPoint(i), path.GetPoint(i+1), vec3(0.0f, 1.0f, 0.0f), _fade);
                            }
                        } else {
                            for(int i=0, len=path.NumPoints()-1; i<len; ++i){
                                DebugDrawLine(path.GetPoint(i), path.GetPoint(i+1), vec3(1.0f, 0.0f, 0.0f), _fade);
                            }
                        }
                    }
                }
            }
            CheckForNearbyWeapons();
        }
        break;}
    case _attack:{
        SetChaseTarget(GetClosestKnownThreat());
        if(!hostile || chase_target_id == -1){
            SetGoal(_patrol);
            break;
        }
        MovementObject@ target = ReadCharacterID(chase_target_id);

        if(notice_target_aggression_id != chase_target_id){
            notice_target_aggression_delay = 0.0f;
        }
        notice_target_aggression_id = chase_target_id;
        float target_threat_amount = target.GetFloatVar("threat_amount");
        if(target_threat_amount > 0.6f && length_squared(target.velocity) < 1.0){
            notice_target_aggression_delay += ts.step();
        } else {
            notice_target_aggression_delay = 0.0f;   
        }
                
        AISubGoal target_goal = _unknown;
            
        if(attack_sub_goal_pick_time < time){
            switch(sub_goal){
                case _wait_and_attack:
                case _rush_and_attack:
                case _defend:
                case _provoke_attack:
                    target_goal = PickAttackSubGoal();
                    break;
            }
         }

        
        if(!combat_allowed && chase_allowed){
            target_goal = _provoke_attack;
        } else if(!combat_allowed){
            target_goal = _defend;
        }

        if(!target.GetBoolVar("on_ground") && species != _wolf){
            if(target.QueryIntFunction("int IsOnLedge()") == 1){
                target_goal = _knock_off_ledge;
            } else {                
                target_goal = _avoid_jump_kick;
            }
        } else if(sub_goal == _avoid_jump_kick || sub_goal == _knock_off_ledge){
            target_goal = PickAttackSubGoal();
        } 
                               
        if(target_goal != _unknown){
            SetSubGoal(target_goal);
        }
                
        switch(sub_goal){
        case _wait_and_attack:
            if(CheckRangeChange(ts)){
                target_attack_range = RangedRandomFloat(1.5f, 3.0f);
            }
            ai_attacking = true;
            break;
        case _rush_and_attack:
            if(CheckRangeChange(ts)){
                string weap_label;
                if(weapon_slots[primary_weapon_slot] != -1){
                    ItemObject @item_obj = ReadItemID(weapon_slots[primary_weapon_slot]);
                    weap_label = item_obj.GetLabel();
                }
                if(weap_label == "staff" || weap_label == "spear"){
                    target_attack_range = 2.0f;
                } else {                    
                    target_attack_range = 0.0f;
                }
            }
            ai_attacking = true;
            break;
        case _defend:
            if(CheckRangeChange(ts)){
                if(!combat_allowed){
                    target_attack_range = RangedRandomFloat(3.0f, 5.0f);
                } else {
                    target_attack_range = RangedRandomFloat(1.5f, 3.0f);
                }
            }
            ai_attacking = false;
            break;
        case _provoke_attack:
            if(CheckRangeChange(ts)){
                target_attack_range = 0.0f;
            }
            ai_attacking = false;
            break;
        case _avoid_jump_kick:
            if(CheckRangeChange(ts)){
                target_attack_range = RangedRandomFloat(3.0f, 4.0f);
            }
            ai_attacking = false;
            break;
        case _knock_off_ledge:
            if(CheckRangeChange(ts)){
                target_attack_range = 0.0f;
            }
            ai_attacking = true;
            break;
        }
        if(rand()%(150/ts.frames())==0){
            strafe_vel = RangedRandomFloat(-0.2f, 0.2f);
        }

        bool kSeekHelpEnabled = false;
        if(kSeekHelpEnabled){
            if(temp_health < 0.5f){
                ally_id = GetClosestCharacterID(1000.0f, _TC_ALLY | _TC_CONSCIOUS | _TC_IDLE | _TC_KNOWN );
                //TODO: make sure that ally is not also an ally of attacker
                if(ally_id != -1){
                    //DebugDrawLine(this_mo.position, ReadCharacterID(ally_id).position, vec3(0.0f,1.0f,0.0f), _fade);
                    SetGoal(_get_help);
                }
            }
        }

        bool print_potential_allies = false;
        if(print_potential_allies){
            array<int> characters;
            GetCharacters(characters);
            array<int> matching_characters;
            GetMatchingCharactersInArray(characters, matching_characters, _TC_ALLY | _TC_CONSCIOUS | _TC_IDLE | _TC_KNOWN);
            string allies;
            for(int i=0, len=matching_characters.size(); i<len; ++i){
                allies += matching_characters[i] + " ";
            }
            DebugText(this_mo.getID()+"Known allies: ", this_mo.getID()+" Known allies: "+allies, 0.5f);
        }

        CheckForNearbyWeapons();
        break;}
    case _get_help: {
        if(ally_id == -1){
            SetGoal(_patrol);
            break;
        }
        MovementObject@ char = ReadCharacterID(ally_id);
        if(distance_squared(this_mo.position, char.position) < 5.0f){
            SetGoal(_attack);
            char.ReceiveMessage("escort_me "+this_mo.getID());
        }
        CheckForNearbyWeapons();
        break; }
    case _get_weapon:
        if(weapon_slots[primary_weapon_slot] != -1 || 
           !ObjectExists(weapon_target_id) || 
           !IsItemPickupable(ReadItemID(weapon_target_id)) || 
           distance_squared(ReadItemID(weapon_target_id).GetPhysicsPosition(), this_mo.position) > 15.0*15.0)
        {
            SetGoal(old_goal);
            SetSubGoal(old_sub_goal);
        }
        break;
    case _struggle:
        if(tethered == _TETHERED_FREE){
            SetGoal(_patrol);
        }
        struggle_change_time = max(0.0f, struggle_change_time - ts.step());
        if(struggle_change_time <= 0.0f){
            struggle_dir = normalize(vec3(RangedRandomFloat(-1.0f,1.0f), 
                                     0.0f, 
                                     RangedRandomFloat(-1.0f,1.0f)));
            struggle_change_time = RangedRandomFloat(0.1f,0.3f);
        }
        struggle_crouch_change_time = max(0.0f,  struggle_crouch_change_time - ts.step());
        if(struggle_crouch_change_time <= 0.0f){
            struggle_crouch = (rand()%2==0);
            struggle_crouch_change_time = RangedRandomFloat(0.1f,0.3f);
        }
        break;
    case _hold_still:
        if(tethered == _TETHERED_FREE){
            SetGoal(_patrol);
        }
        break;
    }

    if(path_find_type != _pft_nav_mesh){
        path_find_give_up_time -= ts.step();
        if(path_find_give_up_time <= 0.0f){
            path_find_type = _pft_nav_mesh;
        }
    }

    if( _debug_mouse_path_test )
    {
        MouseControlPathTest();
    }
    //HandleDebugRayDraw();

    if(hostile){
        force_look_target_id = situation.GetForceLookTarget();
        if(goal == _attack && chase_target_id != -1){
            force_look_target_id = chase_target_id;
        }
    }

    DebugDrawAIState();
    DebugDrawAIPath();
}

bool IsAware(){
    return hostile;
}

array<int> ray_lines;
void HandleDebugRayDraw() {
    for(int i=0; i<int(ray_lines.length()); ++i){
        DebugDrawRemove(ray_lines[i]);
    }
    ray_lines.resize(0);
    
    if(hostile){
        vec3 front = this_mo.GetFacing();
        vec3 right;
        right.x = front.z;
        right.z = -front.x;
        vec3 ray;
        float ray_len;
        for(int i = -90; i <= 90; i += 10){
            float angle = float(i)/180.0f * 3.1415f;
            ray = front * cos(angle) + right * sin(angle);
            //Print(""+ray.x+" "+ray.y+" "+ray.z+"\n");
            ray_len = GetVisionDistance(this_mo.position+ray); 
            //Print(""+ray_len+"\n");
            vec3 head_pos = this_mo.rigged_object().GetAvgIKChainPos("head");
            head_pos += vec3(0.0f,0.06f,0.0f);
            int line = DebugDrawLine(head_pos, 
                                     head_pos + ray * ray_len,
                                     vec3(1.0f),
                                     _persistent);
            ray_lines.insertLast(line);
        }
    }
}

bool WantsToSheatheItem() {
    return false;
}

bool WantsToUnSheatheItem(int &out src) {
    if(startled || goal != _attack || weapon_slots[primary_weapon_slot] != -1){
        return false;
    }
    src = -1; 
    if(weapon_slots[_sheathed_right] != -1 && ReadItemID(weapon_slots[_sheathed_right]).GetType() == _weapon && ReadItemID(weapon_slots[_sheathed_right]).GetLabel() != "scabbard"){
        src = _sheathed_right;
    } else if(weapon_slots[_sheathed_left] != -1 && ReadItemID(weapon_slots[_sheathed_left]).GetType() == _weapon && ReadItemID(weapon_slots[_sheathed_left]).GetLabel() != "scabbard"){
        src = _sheathed_left;
    }
    return true;
}

bool struggle_crouch = false;
float struggle_crouch_change_time = 0.0f;

bool WantsToCrouch() {
    if(goal == _struggle){
        return struggle_crouch;
    }
    if(goal == _investigate && sub_goal == _investigate_body){
        return true;
    }
    return false;
}

bool WantsToPickUpItem() {
    return goal == _get_weapon;
}

bool WantsToDropItem() {
    if(species == _wolf){
        return true;
    }
    return false;
}

bool WantsToThrowItem() {
    return false;
}

bool WantsToThrowEnemy() {
    return throw_after_active_block;
}

bool WantsToCounterThrow(){
    return will_throw_counter;    
}

bool WantsToRoll() {
    return false;
}

bool WantsToFeint(){
    return false;
}

vec3 GetTargetJumpVelocity() {
    return vec3(jump_target_vel);
}

bool TargetedJump() {
    return has_jump_target;
}

bool WantsToJump() {
    if(species == _wolf){
        return false;
    } else {
        return has_jump_target || trying_to_climb == _jump;
    }
}

bool WantsToAttack() { 
    if(species == _wolf && block_stunned > 0.5){
        return false;
    }
    if(ai_attacking && !startled && combat_allowed){
        return true;
    } else {
        return false;
    }
}

bool WantsToRollFromRagdoll(){
    if(ragdoll_time > roll_after_ragdoll_delay && combat_allowed && !startled && goal == _attack){
        return true;
    } else {
        return false;
    }
}

enum BlockOrDodge{BLOCK, DODGE};

bool ShouldDefend(BlockOrDodge bod){
    float recharge;
    if(bod == BLOCK){
        recharge = active_block_recharge;
    } else if(bod == DODGE){
        recharge = active_dodge_recharge_time - time + 0.2;
    }
    if(goal != _attack || startled || recharge > 0.0f || 
       chase_target_id == -1 || !hostile)
    {
        return false;
    }
    MovementObject @char = ReadCharacterID(chase_target_id);
    if((bod == BLOCK && char.GetIntVar("state") == _attack_state) || 
       (bod == DODGE && char.GetIntVar("knife_layer_id") != -1))
    {
        return true;
    } else {
        return false;
    }
}

bool DeflectWeapon() {
    if(goal == _attack){
        float kKnifeCatchProbability = 0.7f;
        if(species == _wolf){
            kKnifeCatchProbability = 0.3f;
        }
        if(RangedRandomFloat(0.0f,1.0f) > kKnifeCatchProbability){
            return false;
        } else {
            return true;
        }
    } else {
        return false;
    }
}

bool WantsToStartActiveBlock(const Timestep &in ts){
    bool should_block = ShouldDefend(BLOCK);
    if(should_block && !going_to_block){
        MovementObject @char = ReadCharacterID(chase_target_id);
        block_delay = char.rigged_object().anim_client().GetTimeUntilEvent("blockprepare");
        if(block_delay != -1.0f){
            going_to_block = true;
        }
        float temp_block_skill = p_block_skill;
        float temp_block_skill_power = 0.5 * pow(4.0, char.GetFloatVar("attack_predictability"));
        //DebugText("temp_block_skill_power", "temp_block_skill_power: "+temp_block_skill_power, 2.0f);
        if(sub_goal == _provoke_attack){
            temp_block_skill_power += 1.0;
        }
        temp_block_skill = 1.0 - pow((1.0 - temp_block_skill),temp_block_skill_power);
        if(group_leader != -1){
            temp_block_skill *= 0.5;
        }
        //DebugText("temp_block_skill", "temp_block_skill: "+temp_block_skill, 2.0f);
        if(RangedRandomFloat(0.0f,1.0f) > temp_block_skill){
            block_delay += 0.4f;
        }
    }
    if(going_to_block){
        block_delay -= ts.step();
        block_delay = min(1.0f, block_delay);
        if(block_delay <= 0.0f){
            going_to_block = false;
            return true;
        }
    }
    return false;
}

bool WantsToDodge(const Timestep &in ts){
    bool should_block = ShouldDefend(DODGE);
    if(should_block && !going_to_dodge){
        MovementObject @char = ReadCharacterID(chase_target_id);
        dodge_delay = char.rigged_object().anim_client().GetTimeUntilEvent("blockprepare");
        if(dodge_delay != -1.0f){
            going_to_dodge = true;
        }
        float temp_block_skill = p_block_skill;
        float temp_block_skill_power = 0.5 * pow(4.0, char.GetFloatVar("attack_predictability"));
        if(sub_goal == _provoke_attack){
            temp_block_skill_power += 1.0;
        }
        temp_block_skill = 1.0 - pow((1.0 - temp_block_skill),temp_block_skill_power);
        if(RangedRandomFloat(0.0f,1.0f) > temp_block_skill){
            dodge_delay += 0.4f;
        }
    }
    if(going_to_dodge){
        dodge_delay -= ts.step();
        dodge_delay = min(1.0f, dodge_delay);
        if(dodge_delay <= 0.0f){
            going_to_dodge = false;
            return true;
        }
    }
    return false;
}

bool WantsToFlip() {
    return false;
}

bool WantsToAccelerateJump() {
    return trying_to_climb == _wallrun;
}

bool WantsToGrabLedge() {
    return trying_to_climb == _wallrun || trying_to_climb == _climb_up;
}

bool WantsToJumpOffWall() {
    return false;
}

bool WantsToFlipOffWall() {
    return false;
}

bool WantsToCancelAnimation() {
    return true;
}

NavPath path;
int current_path_point = 0;
void GetPath(vec3 target_pos) {
    path = GetPath(this_mo.position,
                   target_pos,
                   POLYFLAGS_ALL,
                   POLYFLAGS_NONE);
    current_path_point = 0;
}



vec3 GetNextPathPoint() {
    int num_points = path.NumPoints();
    if(num_points < current_path_point-1){
        return vec3(0.0f);
    }

    vec3 next_point;
    for(int i=1; i<num_points; ++i){   
        next_point = path.GetPoint(i);
        if(xz_distance_squared(this_mo.position, next_point) > 1.0f){
             //Print("Next path point\n "+i);
            break;
        }
    }
    return next_point;
}

bool IsCloseToJumpNode()
{
    int num_points = path.NumPoints();
    for(int i=1; i<num_points; ++i)
    {   
        vec3 next_point = path.GetPoint(i);
        uint32 flag = path.GetFlag(i);
        if(xz_distance_squared(this_mo.position, next_point) < 10.0f)
        {
            if( DT_STRAIGHTPATH_OFFMESH_CONNECTION & flag != 0 )
            {
                return true; 
            }
        }
    }
    return false;
}

vec3 GetJumpNodeDestination()
{
    int num_points = path.NumPoints();
    for(int i=1; i<num_points; ++i)
    {
        vec3 next_point = path.GetPoint(i);
        uint32 flag = path.GetFlag(i);
        if(xz_distance_squared(this_mo.position, next_point) < 10.0f)
        {
            if( DT_STRAIGHTPATH_OFFMESH_CONNECTION & flag != 0 )
            {
                if( i+1 < num_points )
                {
                    return path.GetPoint(i+1);
                }
            }
        }
    }

    return this_mo.position;
}

class WaypointInfo {
    bool success;
    vec3 target_point;
    bool following_friend;
}

// id could be id of a waypoint or of another character
WaypointInfo GetWaypointInfo(int id){
    WaypointInfo info;
    info.success = false;

    if(id != -1 && ObjectExists(id)){
        Object@ object = ReadObjectFromID(id);
        if(object.GetType() == _path_point_object){
            info.target_point = object.GetTranslation();
            info.success = true;
            info.following_friend = false;
        } else if(object.GetType() == _movement_object) {
            if(situation.KnowsAbout(id)){
                info.target_point = ReadCharacterID(id).position;
                info.success = true;
                info.following_friend = true;
            }
        }
    }
    return info;
}

string patrol_idle_override;
   
string GetIdleOverride(){
    if(goal == _patrol && time < patrol_wait_until){
        return patrol_idle_override;
    } else {
        return "";
    }
}

vec3 GetCheckedRepulsorForce() {
    vec3 repulsor_force = GetRepulsorForce();
    if(length_squared(repulsor_force) > 0.0f){
        vec3 raycast_point = NavRaycast(this_mo.position, this_mo.position + repulsor_force);
        raycast_point.y = this_mo.position.y;
        repulsor_force *= distance(raycast_point, this_mo.position)/length(repulsor_force);
    }
    return repulsor_force;
}

vec3 GetPatrolMovement(){
    if(time < patrol_wait_until){
        return vec3(0.0f);
    }

    WaypointInfo waypoint_info = GetWaypointInfo(waypoint_target_id);
    if(!waypoint_info.success){
        // current target is invalid, go to waypoint that character
        // is directly attached to
        old_waypoint_target_id = -1;
        waypoint_target_id = this_mo.GetWaypointTarget();
        waypoint_info = GetWaypointInfo(waypoint_target_id);
    }
    bool following_friend = false;
    vec3 target_point = this_mo.position;
    if(waypoint_info.success){
        target_point = waypoint_info.target_point;
        following_friend = waypoint_info.following_friend;
    }

    if( xz_distance_squared(this_mo.position, target_point) < 1.0f ){
        // we have reached target point
        if(waypoint_target_id != -1 && ObjectExists(waypoint_target_id)){
            Object@ object = ReadObjectFromID(waypoint_target_id);
            if(object.GetType() == _path_point_object){
                // Check for wait command
                ScriptParams@ script_params = object.GetScriptParams();
                if(script_params.HasParam("Wait")){
                    float wait_time = script_params.GetFloat("Wait");
                    patrol_wait_until = time + wait_time;
                }
                if(script_params.HasParam("Type")){
                    string type = script_params.GetString("Type");
                    if(type == "Stand" || woke_up){
                        patrol_idle_override = "";
                    } else if(type == "Sit"){
                        patrol_idle_override = "Data/Animations/r_sit_cross_legged.anm";          
                        sitting = true;                           
                    } else if(type == "Sleep"){
                        patrol_idle_override = "Data/Animations/r_sleep.anm";           
                        asleep = true;             
                    } else if(type == "Wounded"){
                        patrol_idle_override = "Data/Animations/r_sit_injuredneck.anm";           
                        asleep = true;             
                    }
                } else {
                    patrol_idle_override = "";
                }
                int temp_waypoint_target_id = waypoint_target_id;
                PathPointObject@ path_point_object = cast<PathPointObject>(object);
                int num_connections = path_point_object.NumConnectionIDs();
                if(num_connections != 0){
                    waypoint_target_id = path_point_object.GetConnectionID(0);
                }
                for(int i=0; i<num_connections; ++i){
                    if(path_point_object.GetConnectionID(i) != old_waypoint_target_id){
                        waypoint_target_id = path_point_object.GetConnectionID(i);
                        break;
                    }
                }
                old_waypoint_target_id = temp_waypoint_target_id;
                // Find next waypoint and set that to be the target
                /*int temp = waypoint_target_id;
                waypoint_target_id = path_script_reader.GetOtherConnectedPoint(
                    waypoint_target_id, old_waypoint_target_id);
                old_waypoint_target_id = temp; 
                if(waypoint_target_id == -1){ 
                    // Double back if we've reached the end of the path
                    waypoint_target_id = path_script_reader.GetConnectedPoint(old_waypoint_target_id);
                }*/
            }
        }
    }

    if(move_delay > 0.0f){
        target_point = this_mo.position;
    }
    vec3 target_velocity;
    if(following_friend) {
        target_velocity = GetMovementToPoint(target_point, 1.0f, 1.0f, 0.0f);
    } else {
        if(target_point != this_mo.position){
            target_velocity = GetMovementToPoint(target_point, 0.0f);
            float target_speed = 0.2f;
            if(length_squared(target_velocity) > target_speed){
                target_velocity = normalize(target_velocity) * target_speed;
            }
        }
    }

    target_velocity += GetCheckedRepulsorForce();

    if(length_squared(target_velocity) > 1.0){
        target_velocity = normalize(target_velocity);
    }

    return target_velocity;
}

vec3 GetMovementToPoint(vec3 point, float slow_radius){
    return GetMovementToPoint(point, slow_radius, 0.0f, 0.0f);
}

bool JumpToTarget(vec3 jump_target, vec3 &out vel, const float _success_threshold){
    float r_time; 
    vec3 start_vel = GetVelocityForTarget(this_mo.position, jump_target, run_speed*1.5f, _jump_vel*1.7f, 0.55f, r_time);
    if(start_vel.y != 0.0f){
        bool low_success = false;
        bool med_success = false;
        bool high_success = false;
        //const float _success_threshold = 0.1f;
        vec3 end;
        vec3 low_vel = GetVelocityForTarget(this_mo.position, jump_target, run_speed*1.5f, _jump_vel*1.7f, 0.15f, r_time);
        jump_info.jump_start_vel = low_vel;
        JumpTestEq(this_mo.position, jump_info.jump_start_vel, jump_info.jump_path); 
        end = jump_info.jump_path[jump_info.jump_path.size()-1];
        if(_debug_draw_jump_path){
            for(int i=0; i<int(jump_info.jump_path.size())-1; ++i){
                DebugDrawLine(jump_info.jump_path[i] - vec3(0.0f, _leg_sphere_size, 0.0f), 
                    jump_info.jump_path[i+1] - vec3(0.0f, _leg_sphere_size, 0.0f), 
                    vec3(1.0f,0.0f,0.0f), 
                    _delete_on_update);
            }
        }
        if(jump_info.jump_path.size() != 0){
            vec3 land_point = jump_info.jump_path[jump_info.jump_path.size()-1];
            if(_debug_draw_jump_path){
                DebugDrawWireSphere(land_point, _leg_sphere_size, vec3(1.0f,0.0f,0.0f), _delete_on_update);
            }
            if(distance_squared(land_point, jump_target) < _success_threshold){
                low_success = true;
            }
        } 
        vec3 med_vel = GetVelocityForTarget(this_mo.position, jump_target, run_speed*1.5f, _jump_vel*1.7f, 0.55f, r_time);
        jump_info.jump_start_vel = med_vel;
        JumpTestEq(this_mo.position, jump_info.jump_start_vel, jump_info.jump_path); 
        end = jump_info.jump_path[jump_info.jump_path.size()-1];
        if(_debug_draw_jump_path){
            for(int i=0; i<int(jump_info.jump_path.size())-1; ++i){
                DebugDrawLine(jump_info.jump_path[i] - vec3(0.0f, _leg_sphere_size, 0.0f), 
                    jump_info.jump_path[i+1] - vec3(0.0f, _leg_sphere_size, 0.0f), 
                    vec3(0.0f,0.0f,1.0f), 
                    _delete_on_update);
            }
        }
        if(jump_info.jump_path.size() != 0){
            vec3 land_point = jump_info.jump_path[jump_info.jump_path.size()-1];
            if(_debug_draw_jump_path){
                DebugDrawWireSphere(land_point, _leg_sphere_size, vec3(1.0f,0.0f,0.0f), _delete_on_update);
            }
            if(distance_squared(land_point, jump_target) < _success_threshold){
                med_success = true;
            }
        } 
        vec3 high_vel = GetVelocityForTarget(this_mo.position, jump_target, run_speed*1.5f, _jump_vel*1.7f, 1.0f, r_time);
        jump_info.jump_start_vel = high_vel;
        JumpTestEq(this_mo.position, jump_info.jump_start_vel, jump_info.jump_path); 
        end = jump_info.jump_path[jump_info.jump_path.size()-1];
        if(_debug_draw_jump_path){
            for(int i=0; i<int(jump_info.jump_path.size())-1; ++i){
                DebugDrawLine(jump_info.jump_path[i] - vec3(0.0f, _leg_sphere_size, 0.0f), 
                    jump_info.jump_path[i+1] - vec3(0.0f, _leg_sphere_size, 0.0f), 
                    vec3(0.0f,1.0f,0.0f), 
                    _delete_on_update);
            }
        }
        if(jump_info.jump_path.size() != 0){
            vec3 land_point = jump_info.jump_path[jump_info.jump_path.size()-1];
            if(_debug_draw_jump_path){
                DebugDrawWireSphere(land_point, _leg_sphere_size, vec3(0.0f,1.0f,0.0f), _delete_on_update);
            }
            if(distance_squared(land_point, jump_target) < _success_threshold){
                high_success = true;
            }
        }
        jump_info.jump_path.resize(0);

        if(low_success){
            vel = low_vel;
            return true;
        } else if(med_success){
            vel = med_vel;
            return true;
        } else if(high_success){
            vel = high_vel;
            return true;
        } else {
            vel = vec3(0.0f);
            return false;
        }

        /*
        if(GetInputPressed(this_mo.controller_id, "mouse0") && start_vel.y != 0.0f){
            jump_info.StartJump(start_vel, true);
            SetOnGround(false);
        }*/
    }
    return false;
}

// Pathfinding options
// Find ground path on nav mesh
// Run straight towards target (fall off edge)
// Run straight towards target and climb up wall
// Jump towards target (and possibly climb wall)

vec3 GetMovementToPoint(vec3 point, float slow_radius, float target_dist, float strafe_vel){
    if(path_find_type == _pft_nav_mesh){
        //Print("NAV MESH\n");
        return GetNavMeshMovement(point, slow_radius, target_dist, strafe_vel);
    } else if(path_find_type == _pft_climb){
        //Print("CLIMB\n");
        vec3 dir = path_find_point - this_mo.position;
        dir.y = 0.0f;
        if(trying_to_climb != _nothing && trying_to_climb != _jump && on_ground){
            trying_to_climb = _nothing;
            path_find_type = _pft_nav_mesh;
        }
        if(length_squared(dir) < 0.5f && trying_to_climb == _nothing){
            trying_to_climb = _jump;
        }
        if(trying_to_climb != _nothing){
            return climb_dir;
        }
        dir = normalize(dir);
        return dir;
    } else if(path_find_type == _pft_drop){
        //Print("DROP\n");
        vec3 dir = path_find_point - this_mo.position;
        dir.y = 0.0f;
        dir = normalize(dir);
        if(!on_ground){
            path_find_type = _pft_nav_mesh;
        }
        return dir;
    }

    return vec3(0.0f);
}

vec3 GetNavMeshMovement(vec3 point, float slow_radius, float target_dist, float strafe_vel){
    // Get path to estimated target position
    vec3 target_velocity;
    vec3 target_point = point;

    //First, if far away, get a point on the navmesh close to the intended position.
    if(distance_squared(target_point, this_mo.position) > 0.2f)
    {
        NavPoint np = GetNavPoint(point);

        if( np.IsSuccess() )
        {
            target_point =  np.GetPoint();
        }
    }
    //Pathfind to the target point on the navmesh.
    GetPath(target_point);
    
    //See if we're close to a jumping node.
    if( IsCloseToJumpNode() )
    {
        if( jump_delay == 0.0f ) {
            vec3 pos = GetJumpNodeDestination();
            vec3 vel;
            if(JumpToTarget(pos, vel, 0.5f)){
                has_jump_target = true;
                jump_target_vel = vel;
            }
            else
            {
                //Print( "Unable to find jump path, maybe i should avoid this node" );
            }
        }
    }
    {
        vec3 next_path_point = GetNextPathPoint();
        if(next_path_point != vec3(0.0f)){
            target_point = next_path_point;
        }
    }
    //for(int i=0; i<path.NumPoints()-1; ++i){
    //    DebugDrawLine(path.GetPoint(i), path.GetPoint(i+1), vec3(1.0f), _fade);
    //}

    if(path.NumPoints() > 0 && on_ground){
       // If path cannot reach target point, check if we can climb or drop to it 
       if(distance_squared(path.GetPoint(path.NumPoints()-1), GetNavPointPos(point)) > 1.0f){
           PredictPathOutput predict_path_output = PredictPath(this_mo.position, point);
           if(predict_path_output.type == _ppt_climb){
               path_find_type = _pft_climb;
               path_find_point = predict_path_output.start_pos;
               climb_dir = predict_path_output.normal;
               path_find_give_up_time = 2.0f;
           } else if(predict_path_output.type == _ppt_drop){
               path_find_type = _pft_drop;
               path_find_point = predict_path_output.start_pos;
               path_find_give_up_time = 2.0f;
           }
       }
       // If pathfind failed, then check for jump path
       /*if(distance_squared(path.GetPoint(path.NumPoints()-1), GetNavPointPos(point)) > 1.0f){
            NavPath back_path;
            back_path = GetPath(GetNavPointPos(point), this_mo.position); 
            if(back_path.NumPoints() > 0){
                vec3 targ_point = back_path.GetPoint(back_path.NumPoints()-1);
                targ_point = NavRaycast(targ_point, targ_point + vec3(RangedRandomFloat(-3.0f,3.0f),
                                                                      0.0f,
                                                                      RangedRandomFloat(-3.0f,3.0f)));
                targ_point.y += _leg_sphere_size;
                //DebugDrawWireSphere(targ_point, 1.0f, vec3(1.0f), _delete_on_update);
                vec3 vel;
                if(JumpToTarget(targ_point, vel)){
                    //Print("Jump target success\n");
                    has_jump_target = true;
                    jump_target_vel = vel;
                } else {
                    //Print("Jump target fail\n");
                }
            //    DebugDrawWireSphere(back_path.GetPoint(back_path.NumPoints()-1), 1.0f, vec3(1.0f), _fade);    
            }
            for(int i=0; i<back_path.NumPoints()-1; ++i){
            //    DebugDrawLine(back_path.GetPoint(i), back_path.GetPoint(i+1), vec3(1.0f), _fade);
            }
            
            //has_jump_target = true;

            //jump_target_vel = vec3(0.0f,10.0f,0.0f);
       }*/
    }

    // Get flat direction to next point
    vec3 rel_dir = point - this_mo.position;
    rel_dir.y = 0.0f;
    rel_dir = normalize(rel_dir);

    // If target point is closer than we want to be, then project it backwards (staying within walkable bounds)
    if(distance_squared(target_point, point) < target_dist*target_dist){
        vec3 right_dir(rel_dir.z, 0.0f, -rel_dir.x);
        vec3 raycast_point = NavRaycast(point, point - rel_dir * target_dist + right_dir * strafe_vel);
        if(raycast_point != vec3(0.0f)){                    
            target_point = raycast_point;
            GetPath(target_point);
            vec3 next_path_point = GetNextPathPoint();
            if(next_path_point != vec3(0.0f)){
                target_point = next_path_point;
            }
        }
    } 

    // Set target velocity to flat vector from character to target
    target_velocity = target_point - this_mo.position;
    target_velocity.y = 0.0;

    // Decompose target_vel into components going towards target, and perpendicular
    vec3 target_vel_indirect = target_velocity - dot(rel_dir, target_velocity) * rel_dir;
    vec3 target_vel_direct = target_velocity - target_vel_indirect;
 
    // 
    float dist = length(target_vel_direct);
    float seek_dist = slow_radius;
    dist = max(0.0, dist-seek_dist);
    target_velocity = normalize(target_vel_direct) * dist + target_vel_indirect;

    target_velocity += GetCheckedRepulsorForce();

    if(length_squared(target_velocity) > 1.0){
        target_velocity = normalize(target_velocity);
    }
    return target_velocity;

    // Test direct running
    /*vec3 direct_move = point - this_mo.position;
    direct_move.y = 0.0f;
    if(length(direct_move) > 0.6f){
        return normalize(direct_move);
    } else {
        return vec3(0.0f);
    }*/
}

vec3 GetDodgeDirection() {
    if( chase_target_id != -1 )
    {
        MovementObject @char = ReadCharacterID(chase_target_id);
        return normalize(this_mo.position - char.position);
    }
    else
    {
        Log( error, "Trying to dodge non-existant chase target attack" );
        return vec3(1,0,0);
    }
}

vec3 GetAttackMovement() {
    if(combat_allowed || chase_allowed){
        float target_react_time = 0.1f; // How slow AI is to react to changes
        vec3 target_react_pos = target_history.GetPos(time-target_react_time);
        vec3 target_react_vel = target_history.GetVel(time-target_react_time);

        //sphere_ids.push_back(DebugDrawWireSphere(target_react_pos + target_react_vel*target_react_time, _leg_sphere_size, vec3(0.0f, 1.0f, 0.0f), _fade));
        float predict_dist = distance(target_react_pos, this_mo.position);
        float estimated_run_speed = run_speed * 0.8f;
        float predict_time = (predict_dist / estimated_run_speed); // How long it will take to reach target
        // Update predicted time to take into account velocity
        vec3 nav_target_react_pos = GetNavPointPos(target_react_pos);
        vec3 target_point = target_react_pos;

        if(nav_target_react_pos != vec3(0.0)){
            vec3 predict_pos = NavRaycastSlide(nav_target_react_pos, nav_target_react_pos + target_react_vel * min(8.0, (predict_time + target_react_time + time - target_history.LastUpdated())), 4);
            
            for(int i=0; i<3; ++i){
                predict_dist = distance(predict_pos, this_mo.position);
                predict_time = (predict_dist / estimated_run_speed); // How long it will take to reach target
                predict_pos = NavRaycastSlide(nav_target_react_pos, nav_target_react_pos + target_react_vel * min(8.0, (predict_time + target_react_time + time - target_history.LastUpdated())), 4);
            }

            target_point = predict_pos;
        }

        if(sub_goal == _knock_off_ledge && distance_squared(target_react_pos, this_mo.position) < 7.0){
            return normalize(target_react_pos - this_mo.position);
        }

        vec3 ret = GetMovementToPoint(target_point, max(0.2f,1.0f-target_attack_range), target_attack_range, strafe_vel);

        MovementObject@ char = ReadCharacterID(chase_target_id);
        //If we are chasing someone and decide to jump to attack them, tell them we're-a coming 
        if( char.controlled == false && has_jump_target && jump_delay == 0.0f ) {
            char.ReceiveMessage("jumping_to_attack_you "+this_mo.getID());
        }

        return ret;
    } else {
        return vec3(0.0f);
    }
    //CheckJumpTarget(last_seen_target_position);
}


void MouseControlPathTest() {
    vec3 start = camera.GetPos();
    vec3 end = camera.GetPos() + camera.GetMouseRay()*400.0f;
    col.GetSweptSphereCollision(start, end, _leg_sphere_size);
    //DebugDrawWireSphere(sphere_col.position, _leg_sphere_size, vec3(0.0f,1.0f,0.0f), _delete_on_update);
    
    if(GetInputDown(this_mo.controller_id, "g") ){
        goal = _navigate;
        nav_target = sphere_col.position;
        path_find_type = _pft_nav_mesh;
    }
}

float struggle_change_time = 0.0f;
vec3 struggle_dir;

vec3 GetInvestigateTargetPos(){
    if(investigate_target_id == -1){
        return nav_target;
    } else {
        return ReadCharacterID(investigate_target_id).position; 
    }    
}

int last_seen_sphere = -1;
vec3 GetBaseTargetVelocity() {
    if(startled){
        return vec3(0.0f);
    } else if(goal == _patrol){
        return GetPatrolMovement();
    } else if(goal == _flee){
        if(chase_target_id != -1){
            if(flee_update_time < the_time){
                MovementObject@ char = ReadCharacterID(chase_target_id);
                vec3 dir = this_mo.position - char.position;
                dir.y = 0.0f;
                dir = normalize(dir);
                vec3 start_pos = GetNavPointPos(this_mo.position);
                vec3 predict_pos = NavRaycastSlide(start_pos, start_pos + dir * 1000.0, 4);
                //DebugDrawWireSphere(predict_pos, 1.0, vec3(1.0), _fade);
                flee_dest = predict_pos;
                flee_update_time = the_time + RangedRandomFloat(0.2f,2.0f);
            }
            return GetMovementToPoint(flee_dest, 0.0f);
        } else {
            return vec3(0.0f);
        }
    } else if(goal == _attack){
        return GetAttackMovement(); 
    } else if(goal == _get_help){
        return GetMovementToPoint(ReadCharacterID(ally_id).position, 1.0f); 
    } else if(goal == _get_weapon){
        vec3 pos = ReadItemID(weapon_target_id).GetPhysicsPosition();
        return GetMovementToPoint(pos, 0.0f); 
    } else if(goal == _escort){
        return GetMovementToPoint(ReadCharacterID(escort_id).position, 2.0f); 
    } else if(goal == _navigate){
        DebugDrawWireSphere(nav_target, 0.2f, vec3(1.0f), _fade);
        return GetMovementToPoint(nav_target, 1.0f); 
    } else if(goal == _investigate){
        float speed = 0.2f;
        if(sub_goal == _investigate_urgent || sub_goal == _investigate_body){
            speed = 1.0f;
        }
        if(sub_goal == _investigate_urgent || sub_goal == _investigate_body){
            speed = 0.7f;
        }
        if(sub_goal == _investigate_around){
            speed = 0.4f;
        }
        if(sub_goal == _investigate_body){
            speed = 0.0f;
        }
        float slow_radius = 0.0f;
        if(sub_goal == _investigate_urgent){
            slow_radius = 1.0f;
        }
        if(move_delay <= 0.0f){
            return GetMovementToPoint(GetInvestigateTargetPos(), slow_radius) * speed;
        } else {
            return GetMovementToPoint(this_mo.position, 0.0f) * speed;
        }
    } else if(goal == _struggle){
        return struggle_dir * 0.5; 
    } else {
        return vec3(0.0f);
    }
}

vec3 GetRepulsorForce(){
    array<int> nearby_characters;
    const float _avoid_range = 1.5f;
    GetCharactersInSphere(this_mo.position, _avoid_range, nearby_characters);

    vec3 repulsor_total;

    for(uint i=0; i<nearby_characters.size(); ++i){
        if(this_mo.getID() == nearby_characters[i]){
            continue;
        }
        MovementObject@ char = ReadCharacterID(nearby_characters[i]);
        if(!this_mo.OnSameTeam(char)){
            continue;
        }
        float dist = length(this_mo.position - char.position);
        if(dist == 0.0f || dist > _avoid_range){
            continue;
        }
        vec3 repulsion = (this_mo.position - char.position)/dist * (_avoid_range - dist) / _avoid_range;
        if(length_squared(repulsion) > 0.0f && move_delay <= 0.0f){
            char.ReceiveMessage("excuse_me "+this_mo.getID());
            repulsor_delay = 1.0f;
        }
        repulsor_total += repulsion;
    }

    return repulsor_total;
}

vec3 GetTargetVelocity(){
    vec3 base_target_velocity = GetBaseTargetVelocity();
    vec3 target_vel = base_target_velocity;

    if(static_char){
        target_vel = vec3(0.0);
    }
    return target_vel;
}

bool WantsToThroatCut() {
    return true;
}

// Called from aschar.as, bool front tells if the character is standing still. 
void ChooseAttack(bool front, string& out attack_str) {
    attack_str = "";
    if(on_ground){
        int choice = rand()%3;
        if(sub_goal == _knock_off_ledge){
            choice = 0;
        }
        if(choice==0){
            attack_str = "stationary";            
        } else if(choice == 1){
            attack_str = "moving";
        } else {
            attack_str = "low";
        }    
    } else {
        attack_str = "air";
    }
}

void ResetWaypointTarget() {
    waypoint_target_id = -1;
    old_waypoint_target_id = -1;
}

WalkDir WantsToWalkBackwards() {
    if(goal == _patrol && waypoint_target_id == -1){
        if(repulsor_delay > 0){
            return WALK_BACKWARDS;
        } else {
            return STRAFE;
        }
    } else {
        return FORWARDS;
    }
}

bool WantsReadyStance() {
    return (goal != _patrol);
}


void CheckJumpTarget(vec3 target) {
    NavPath old_path;
    old_path = GetPath(this_mo.position, target);
    float old_path_length = 0.0f;
    for(int i=0; i<old_path.NumPoints() - 1; ++i){
        old_path_length += distance(old_path.GetPoint(i), old_path.GetPoint(i+1));
    }

    float max_horz = run_speed * 1.5f;
    float max_vert = _jump_vel * 1.7f;

    vec3 jump_vel(RangedRandomFloat(-max_horz,max_horz),
                  RangedRandomFloat(3.0f,max_vert),
                  RangedRandomFloat(-max_horz,max_horz));
    JumpTestEq(this_mo.position, jump_vel, jump_info.jump_path); 
    vec3 end = jump_info.jump_path[jump_info.jump_path.size()-1];
    if(_debug_draw_jump){
        for(int i=0; i<int(jump_info.jump_path.size())-1; ++i){
            DebugDrawLine(jump_info.jump_path[i] - vec3(0.0f, _leg_sphere_size, 0.0f), 
                jump_info.jump_path[i+1] - vec3(0.0f, _leg_sphere_size, 0.0f), 
                vec3(1.0f,0.0f,0.0f), 
                _delete_on_update);
        }
    }
    if(jump_info.jump_path.size() != 0){
        vec3 land_point = jump_info.jump_path[jump_info.jump_path.size()-1];
        if(_debug_draw_jump){
            DebugDrawWireSphere(land_point, _leg_sphere_size, vec3(1.0f,0.0f,0.0f), _fade);
        }
        
        bool old_path_fail = false;
        if(old_path.NumPoints() == 0 ||
           distance_squared(old_path.GetPoint(old_path.NumPoints()-1), GetNavPointPos(target)) > 1.0f){
            old_path_fail = true;
        }

        NavPath new_path;
        new_path = GetPath(land_point, target);

        bool new_path_fail = false;
        if(new_path.NumPoints() == 0 ||
           distance_squared(new_path.GetPoint(new_path.NumPoints()-1), GetNavPointPos(target)) > 1.0f){
            new_path_fail = true;
        }

        float new_path_length = 0.0f;
        for(int i=0; i<new_path.NumPoints() - 1; ++i){
            new_path_length += distance(new_path.GetPoint(i), new_path.GetPoint(i+1));
        }

        if(new_path_fail){
            return;
        }
        if(!old_path_fail && !new_path_fail && new_path_length >= old_path_length){
            return;
        }
        Print("Old path fail: "+old_path_fail+"\nNew path fail: "+new_path_fail+"\n");
        Print("Old path length: "+old_path_length+"\nNew path length: "+new_path_length+"\n");
        Print("Path ok!\n");
        has_jump_target = true;
        jump_target_vel = jump_vel;
    } 
}

int IsThreatToCharacter(int char_id){
    if(chase_target_id == char_id && goal == _attack){
        return 1;
    } else {
        return 0;
    }
}

bool IsOnNavMesh(ItemObject @item_object, vec3 percieved_position)
{
    NavPoint np = GetNavPoint(percieved_position);

    if( np.IsSuccess() )
    {
        if( distance_squared(percieved_position, np.GetPoint()) < 1.0f )
        {
           return true;
        }
        else
        {
            return false;
        }
    }
    else
    {
        return false;
    }
}
