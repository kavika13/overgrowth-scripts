#include "aschar.as"
#include "situationawareness.as"

Situation situation;

float startle_time;

bool has_jump_target = false;
vec3 jump_target_vel;

bool hostile = true;
bool listening = true;
bool ai_attacking = false;
bool hostile_switchable = true;
int waypoint_target = -1;
int old_waypoint_target = -1;
const float _view_distance = 90.0f;
const float _throw_counter_probability = 0.2f;
bool will_throw_counter;

float target_attack_range = 0.0f;
float strafe_vel = 0.0f;
const float _block_reflex_delay_min = 0.1f;
const float _block_reflex_delay_max = 0.2f;
float block_delay;
bool going_to_block = false;
float roll_after_ragdoll_delay;
bool throw_after_active_block;

enum AIGoal {_patrol, _attack, _investigate, _get_help, _escort, _get_weapon, _navigate, _struggle, _hold_still};
AIGoal goal = _patrol;

vec3 nav_target;
int ally_id = -1;
int escort_id = -1;
int weapon_target_id = -1;

enum PathFindType {_pft_nav_mesh, _pft_climb, _pft_drop, _pft_jump};
PathFindType path_find_type = _pft_nav_mesh;
vec3 path_find_point;
float path_find_give_up_time;

enum ClimbStage {_nothing, _jump, _wallrun, _grab, _climb_up};
ClimbStage trying_to_climb = _nothing;
vec3 climb_dir;

int IsUnaware() {
    return (goal == _patrol || startled)?1:0;
}

bool WantsToDragBody(){
    return false;
}

void ResetMind() {
    goal = _patrol;
    target_id = -1;
    situation.clear();
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

void Notice(int character_id){
    situation.Notice(character_id);
    target_id = character_id;
    last_seen_target_position = ReadCharacterID(character_id).position;
    last_seen_target_velocity = ReadCharacterID(character_id).velocity;
    switch(goal){
        case _patrol:
            startled = true;
            startle_time = 1.0f;
            SetGoal(_attack);
            break;
        case _investigate:
            startled = true;
            startle_time = 1.0f;
            SetGoal(_attack);
            break;
        case _escort:
            SetGoal(_attack);
            break;
    }
}

void NotifySound(int created_by_id, float max_dist, vec3 pos) {
    if(!listening){
        return;
    }
    if(goal == _patrol || goal == _investigate){
        bool same_team = false;
        character_getter.Load(this_mo.char_path);
        if(this_mo.OnSameTeam(ReadCharacterID(created_by_id))){
            same_team = true;
        }
        if(!same_team){
            nav_target = pos;
            SetGoal(_investigate);
        }
    }
}

void HandleAIEvent(AIEvent event){
    if(event == _ragdolled){
        roll_after_ragdoll_delay = RangedRandomFloat(0.1f,1.0f);
    }
    if(event == _jumped){
        has_jump_target = false;
        if(trying_to_climb == _jump){
            trying_to_climb = _wallrun;
        }   
    }
    if(event == _grabbed_ledge){
        if(trying_to_climb == _wallrun){
            trying_to_climb = _climb_up;
        }   
    }
    if(event == _climbed_up){
        if(trying_to_climb == _climb_up){
            trying_to_climb = _nothing;
            path_find_type = _pft_nav_mesh;
        }   
    }
    if(event == _thrown){
        will_throw_counter = RangedRandomFloat(0.0f,1.0f)<_throw_counter_probability;        
    }
    if(event == _can_climb){
        trying_to_climb = _jump;
        Print("Trying to climb = jump\n");
    }
    if(event == _activeblocked){
        if(RangedRandomFloat(0.0f, 1.0f) < p_block_followup){
            throw_after_active_block = RangedRandomFloat(0.0f,1.0f) > 0.5f;
            if(!throw_after_active_block){
                ai_attacking = true;
            }
        }
    }
    if(event == _choking){
        MovementObject@ char = ReadCharacterID(tether_id);
        if(GetCharPrimaryWeapon(char) == -1){
            SetGoal(_struggle);
        } else {
            SetGoal(_hold_still);
        }
    }
}

void SetGoal(AIGoal _goal){
    goal = _goal;
}

float move_delay = 0.0f;

enum MsgType {_escort_me = 0, _excuse_me = 1};

void ReceiveMessage(int source_id, int _msg_type){
    MsgType type = MsgType(_msg_type);
    //Print("Message received: Character " + source_id + " says \"");
    if(type == _escort_me){
        //Print("Escort me!");
    }
    if(type == _excuse_me){
        //Print("Excuse me!");
    }
    //Print("\"\n");
    
    if(type == _escort_me && goal == _patrol){
        SetGoal(_escort);
        escort_id = source_id;
    }
    if(type == _excuse_me && (goal == _patrol || goal == _investigate)){
        //Print("\"Ok, I'll wait a second before continuing my goal.\"\n");
        move_delay = 1.0f;
    }
}

void UpdateBrain(){
    if(GetInputDown(this_mo.controller_id, "c") && !GetInputDown(this_mo.controller_id, "ctrl")){
        if(hostile_switchable){
            hostile = !hostile;
            if(hostile){
                ai_attacking = true;
                listening = true;
            } else {
                SetGoal(_patrol);
                ResetWaypointTarget();
                listening = false;
            }
        }
        hostile_switchable = false;
    } else {
        hostile_switchable = true;
    }

    if(startled){
        ai_attacking = false;
        startle_time -= time_step * num_frames;
        if(startle_time <= 0.0f){
            startled = false;
            AchievementEvent("enemy_alerted");
        }
        return;
    }

    if(weapon_slots[primary_weapon_slot] == -1 && goal != _struggle && goal != _hold_still && hostile){
        int num_items = GetNumItems();
        int nearest_weapon = -1;
        float nearest_dist = 0.0f;
        const float _max_dist = 30.0f;
        for(int i=0; i<num_items; i++){
            ItemObject @item_obj = ReadItem(i);
            if(item_obj.IsHeld() || item_obj.GetType() != _weapon){
                continue;
            }
            vec3 pos = item_obj.GetPhysicsPosition();
            float dist = distance_squared(pos, this_mo.position);
            if(dist > _max_dist * _max_dist){
                continue;
            }
            if(nearest_weapon == -1 || dist < nearest_dist){ 
                nearest_weapon = item_obj.GetID();
                nearest_dist = dist;
            }
        }
        if(nearest_weapon != -1){
            goal = _get_weapon;
            weapon_target_id = nearest_weapon;
        }
    }

    if(hostile){
        int closest_id = GetClosestVisibleCharacterID(_TC_ENEMY | _TC_CONSCIOUS);
        if(closest_id != -1){
            Notice(closest_id);
        }
    } else {
        target_id = -1;
        force_look_target_id = -1;
    }

    if(!hostile &&  goal == _attack){
        SetGoal(_patrol);
    }

    switch(goal){
        case _patrol:
        case _escort:
            ai_attacking = false;
            break;
        case _investigate:
            ai_attacking = false;
            {
                GetPath(nav_target);
                if(path.NumPoints() > 0){
                    vec3 path_end = path.GetPoint(path.NumPoints()-1);
                    if(distance_squared(NavPoint(this_mo.position), path_end) < 1.0f){
                        SetGoal(_patrol);
                    }      
                } else {
                    SetGoal(_patrol);
                }
            }
            break;
        case _attack:
            {
                MovementObject@ target = ReadCharacterID(target_id);
                if(target.GetIntVar("knocked_out") != _awake){
                    SetGoal(_patrol);
                }
                if(rand()%(150/num_frames)==0){
                    float rand_val = RangedRandomFloat(0.0f,1.0f);
                    //Print(rand_val + " < " + p_aggression + "?\n");
                    ai_attacking = (RangedRandomFloat(0.0f,1.0f) < p_aggression);
                }
                if(rand()%(150/num_frames)==0){
                    target_attack_range = RangedRandomFloat(0.0f, 3.0f);
                }
                if(rand()%(150/num_frames)==0){
                    strafe_vel = RangedRandomFloat(-0.2f, 0.2f);
                }
                if(temp_health < 0.5f){
                    ally_id = GetClosestCharacterID(100.0f, _TC_ALLY | _TC_CONSCIOUS | _TC_IDLE);
                    if(ally_id != -1){
                        //DebugDrawLine(this_mo.position, ReadCharacterID(ally_id).position, vec3(0.0f,1.0f,0.0f), _fade);
                        SetGoal(_get_help);
                    }
                }
            }
            break;
        case _get_help:
            {
                MovementObject@ char = ReadCharacterID(ally_id);
                if(distance_squared(this_mo.position, char.position) < 5.0f){
                    SetGoal(_attack);
                    char.ReceiveMessage(this_mo.getID(), int(_escort_me));
                }
            }
            break;
        case _get_weapon:
            if(weapon_slots[primary_weapon_slot] != -1 || !ObjectExists(weapon_target_id) || ReadItemID(weapon_target_id).IsHeld()){
                if(target_id == -1){
                    SetGoal(_patrol);           
                } else {
                    SetGoal(_attack);
                }
            }
            break;
        case _struggle:
            if(tethered == _TETHERED_FREE){
                SetGoal(_patrol);
            }
            break;
        case _hold_still:
            if(tethered == _TETHERED_FREE){
                SetGoal(_patrol);
            }
            break;
    }

    if(path_find_type != _pft_nav_mesh){
        path_find_give_up_time -= time_step * num_frames;
        if(path_find_give_up_time <= 0.0f){
            path_find_type = _pft_nav_mesh;
        }
    }


    //MouseControlPathTest();
    //HandleDebugRayDraw();

    situation.Update();
    if(hostile){
        force_look_target_id = situation.GetForceLookTarget();
    }
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
            vec3 head_pos = this_mo.GetAvgIKChainPos("head");
            head_pos += vec3(0.0f,0.06f,0.0f);
            int line = DebugDrawLine(head_pos, 
                                     head_pos + ray * ray_len,
                                     vec3(1.0f),
                                     _persistent);
            ray_lines.insertLast(line);
        }
    }
}

bool WantsToDodge() {
    return false;
}

bool WantsToSheatheItem() {
    return false;
}

bool WantsToUnSheatheItem() {
    if(startled || goal != _attack || weapon_slots[primary_weapon_slot] != -1){
        return false;
    }
    return true;
}

bool struggle_crouch = false;
float struggle_crouch_change_time = 0.0f;

bool WantsToCrouch() {
    if(goal == _struggle){
        if(struggle_crouch_change_time <= 0.0f){
            struggle_crouch = (rand()%2==0);
            struggle_crouch_change_time = RangedRandomFloat(0.1f,0.3f);
        }
        struggle_crouch_change_time = max(0.0f, 
            struggle_crouch_change_time - time_step * num_frames);
        return struggle_crouch;
    }
    return false;
}

bool WantsToPickUpItem() {
    return goal == _get_weapon;
}

bool WantsToDropItem() {
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
    return has_jump_target || trying_to_climb == _jump;
}

bool WantsToAttack() { 
    return ai_attacking;
}

bool WantsToRollFromRagdoll(){
    if(ragdoll_time > roll_after_ragdoll_delay){
        return true;
    } else {
        return false;
    }
}

bool ShouldBlock(){
    if(goal != _attack || startled || active_block_recharge > 0.0f || 
       target_id == -1 || !hostile)
    {
        return false;
    }
    MovementObject @char = ReadCharacterID(target_id);
    if(char.GetIntVar("state") == _attack_state){
        return true;
    } else {
        return false;
    }
}

bool WantsToStartActiveBlock(){
    bool should_block = ShouldBlock();
    if(should_block && !going_to_block){
        MovementObject @char = ReadCharacterID(target_id);
        block_delay = char.GetTimeUntilEvent("blockprepare");
        if(block_delay != -1.0f){
            going_to_block = true;
        }
        if(RangedRandomFloat(0.0f,1.0f) > p_block_skill){
            block_delay += 0.4f;
        }
    }
    if(going_to_block){
        block_delay -= time_step * num_frames;
        block_delay = min(1.0f, block_delay);
        if(block_delay <= 0.0f){
            going_to_block = false;
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
                   target_pos);
    current_path_point = 0;
}


array<int> path_lines;
void DrawPath() {
    for(int i=0; i<int(path_lines.length()); ++i){
        DebugDrawRemove(path_lines[i]);
    }
    path_lines.resize(0);
    int num_points = path.NumPoints();
    for(int i=0; i<num_points-1; i++){
        int line = DebugDrawLine(path.GetPoint(i),
                                 path.GetPoint(i+1),
                                 vec3(1.0f,1.0f,1.0f),
                                 _persistent);
        path_lines.insertLast(line);
    }
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
   
vec3 GetPatrolMovement(){
    vec3 target_velocity;
    vec3 target_point = this_mo.position;
    if(waypoint_target == -1){
        old_waypoint_target = -1;
        waypoint_target = this_mo.GetWaypointTarget();
    }
    if(waypoint_target != -1){
        target_point = path_script_reader.GetPointPosition(waypoint_target);
    }
    if(xz_distance_squared(this_mo.position, target_point) < 1.0f){
        int temp = waypoint_target;

        waypoint_target = path_script_reader.GetOtherConnectedPoint(
            waypoint_target, old_waypoint_target);
        old_waypoint_target = temp;
        
        if(waypoint_target == -1){
            waypoint_target = path_script_reader.GetConnectedPoint(old_waypoint_target);
        }
    }
    if(move_delay > 0.0f){
        target_point = this_mo.position;
    }
    target_velocity = GetMovementToPoint(target_point, 0.0f);
    float target_speed = 0.2f;
    if(length_squared(target_velocity) > target_speed){
        target_velocity = normalize(target_velocity) * target_speed;
    }
    return target_velocity;
}

vec3 GetMovementToPoint(vec3 point, float slow_radius){
    return GetMovementToPoint(point, slow_radius, 0.0f, 0.0f);
}

const bool _debug_draw_jump_path = false;

bool JumpToTarget(vec3 jump_target, vec3 &out vel){
    vec3 start_vel = GetVelocityForTarget(this_mo.position, jump_target, run_speed*1.5f, _jump_vel*1.7f, 0.55f, time);
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
        vec3 med_vel = GetVelocityForTarget(this_mo.position, jump_target, run_speed*1.5f, _jump_vel*1.7f, 0.55f, time);
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
        vec3 high_vel = GetVelocityForTarget(this_mo.position, jump_target, run_speed*1.5f, _jump_vel*1.7f, 1.0f, time);
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
    if(distance_squared(target_point, this_mo.position) > 0.2f){
        target_point = NavPoint(point);
    }
    GetPath(target_point);
    vec3 next_path_point = GetNextPathPoint();
    if(next_path_point != vec3(0.0f)){
        target_point = next_path_point;
    }

    //for(int i=0; i<path.NumPoints()-1; ++i){
    //    DebugDrawLine(path.GetPoint(i), path.GetPoint(i+1), vec3(1.0f), _fade);
    //}

    if(path.NumPoints() > 0 && on_ground){
       if(distance_squared(path.GetPoint(path.NumPoints()-1), NavPoint(point)) > 1.0f){
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
       /*if(distance_squared(path.GetPoint(path.NumPoints()-1), NavPoint(point)) > 1.0f){
            NavPath back_path;
            back_path = GetPath(NavPoint(point), this_mo.position); 
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

    vec3 rel_dir = point - this_mo.position;
    rel_dir.y = 0.0f;
    rel_dir = normalize(rel_dir);

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

    // Set target velocity to approach target position
    target_velocity = target_point - this_mo.position;
    target_velocity.y = 0.0;
    vec3 target_vel_indirect = target_velocity - dot(rel_dir, target_velocity) * rel_dir;
    vec3 target_vel_direct = target_velocity - target_vel_indirect;
 
    float dist = length(target_vel_direct);
    float seek_dist = slow_radius;
    dist = max(0.0, dist-seek_dist);
    target_velocity = normalize(target_vel_direct) * dist + target_vel_indirect;



    vec3 repulsor_force = GetRepulsorForce();
    if(length_squared(repulsor_force) > 0.0f){
        vec3 raycast_point = NavRaycast(this_mo.position, this_mo.position + repulsor_force);
        repulsor_force *= distance(raycast_point, this_mo.position)/length(repulsor_force);
    }
    target_velocity += repulsor_force;

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

vec3 GetAttackMovement() {
    // Assume target is moving in a straight line at slowly-decreasing velocity
    last_seen_target_position += last_seen_target_velocity * time_step * num_frames;
    last_seen_target_velocity *= pow(0.995f, num_frames);

    // If ray check is successful, update knowledge of target position and velocity
    vec3 real_target_pos = ReadCharacterID(target_id).position;
    vec3 head_pos = this_mo.GetAvgIKChainPos("head");
    if(ReadCharacterID(target_id).VisibilityCheck(head_pos)){
        last_seen_target_position = real_target_pos;
        last_seen_target_velocity = ReadCharacterID(target_id).velocity;
    }

    vec3 move_vel = GetMovementToPoint(last_seen_target_position, max(0.2f,1.0f-target_attack_range), target_attack_range, strafe_vel);
    
    //CheckJumpTarget(last_seen_target_position);

    return move_vel;    
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

int last_seen_sphere = -1;
vec3 GetBaseTargetVelocity() {
    move_delay = max(0.0f, move_delay - time_step * num_frames);
    if(startled){
        return vec3(0.0f);
    } else if(goal == _patrol){
        return GetPatrolMovement();
    } else if(goal == _attack){
        return GetAttackMovement(); 
    } else if(goal == _get_help){
        return GetMovementToPoint(ReadCharacterID(ally_id).position, 1.0f); 
    } else if(goal == _get_weapon){
        vec3 pos = ReadItemID(weapon_target_id).GetPhysicsPosition();
        return GetMovementToPoint(pos, 0.0f); 
    } else if(goal == _escort){
        return GetMovementToPoint(ReadCharacterID(escort_id).position, 1.0f); 
    } else if(goal == _navigate){
        DebugDrawWireSphere(nav_target, 0.2f, vec3(1.0f), _fade);
        return GetMovementToPoint(nav_target, 1.0f); 
    } else if(goal == _investigate){
        if(move_delay <= 0.0f){
            return GetMovementToPoint(nav_target, 0.0f) * 0.2f;
        } else {
            return GetMovementToPoint(this_mo.position, 0.0f) * 0.2f;
        }
    } else if(goal == _struggle){
        if(struggle_change_time <= 0.0f){
            struggle_dir = normalize(vec3(RangedRandomFloat(-1.0f,1.0f), 
                                     0.0f, 
                                     RangedRandomFloat(-1.0f,1.0f)));
            struggle_change_time = RangedRandomFloat(0.1f,0.3f);
        }
        struggle_change_time = max(0.0f, 
            struggle_change_time - time_step * num_frames);
        return struggle_dir; 
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
            char.ReceiveMessage(this_mo.getID(), int(_excuse_me));
        }
        repulsor_total += repulsion;
    }

    return repulsor_total;
}

vec3 GetTargetVelocity(){
    vec3 base_target_velocity = GetBaseTargetVelocity();
    vec3 target_vel = base_target_velocity;

    return target_vel;
}

// Called from aschar.as, bool front tells if the character is standing still. 
void ChooseAttack(bool front) {
    curr_attack = "";
    if(on_ground){
        int choice = rand()%3;
        if(choice==0){
            curr_attack = "stationary";            
        } else if(choice == 1){
            curr_attack = "moving";
        } else {
            curr_attack = "low";
        }    
    } else {
        curr_attack = "air";
    }
}

void ResetWaypointTarget() {
    waypoint_target = -1;
    old_waypoint_target = -1;
}

bool WantsToWalkBackwards() {
    return (goal == _patrol && waypoint_target == -1);
}

bool WantsReadyStance() {
    return (goal != _patrol);
}

bool _debug_draw_jump = false;

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
           distance_squared(old_path.GetPoint(old_path.NumPoints()-1), NavPoint(target)) > 1.0f){
            old_path_fail = true;
        }

        NavPath new_path;
        new_path = GetPath(land_point, target);

        bool new_path_fail = false;
        if(new_path.NumPoints() == 0 ||
           distance_squared(new_path.GetPoint(new_path.NumPoints()-1), NavPoint(target)) > 1.0f){
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