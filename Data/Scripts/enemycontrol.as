#include "aschar.as"

float startle_time;

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

enum AIGoal {_patrol, _attack, _investigate, _get_help, _escort, _get_weapon, _navigate, _struggle};
AIGoal goal = _patrol;

vec3 nav_target;
int ally_id = -1;
int escort_id = -1;
int weapon_target_id = -1;

int IsUnaware() {
    return (goal == _patrol || startled)?1:0;
}

bool WantsToDragBody(){
    return false;
}

void ResetMind() {
    goal = _patrol;
    target_id = -1;
}

int IsIdle() {
    if(goal == _patrol){
        return 1;
    } else {
        return 0;
    }
}

void Notice(int character_id){
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
        if(character_getter.OnSameTeam(ReadCharacterID(created_by_id).char_path) == 1){
            same_team = true;
        }
        if(!same_team){
            nav_target = pos;
            SetGoal(_investigate);
            //Notice(created_by_id);
        }
    }
}

void HandleAIEvent(AIEvent event){
    if(event == _ragdolled){
        roll_after_ragdoll_delay = RangedRandomFloat(0.1f,1.0f);
    }
    if(event == _thrown){
        will_throw_counter = RangedRandomFloat(0.0f,1.0f)<_throw_counter_probability;        
    }
    if(event == _activeblocked){
        throw_after_active_block = RangedRandomFloat(0.0f,1.0f) > 0.5f;
        if(!throw_after_active_block){
            ai_attacking = true;
        }
    }
    if(event == _choking){
        SetGoal(_struggle);
    }
}

void SetGoal(AIGoal _goal){
    goal = _goal;
}

enum MsgType {_escort_me = 0};

void ReceiveMessage(int source_id, int _msg_type){
    MsgType type = MsgType(_msg_type);
    Print("Message received: Character " + source_id + " says \"");
    if(type == _escort_me){
        Print("Escort me!");
    }
    Print("\"\n");
    
    if(type == _escort_me && goal == _patrol){
        SetGoal(_escort);
        escort_id = source_id;
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
        }
        return;
    }

    if(!holding_weapon && goal != _struggle){
        int num_items = GetNumItems();
        int nearest_weapon = -1;
        float nearest_dist = 0.0f;
        const float _max_dist = 30.0f;
        for(int i=0; i<num_items; i++){
            ItemObject @item_obj = ReadItem(i);
            if(item_obj.IsHeld()){
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
                    //DebugDrawWireSphere(path_end, 1.0f, vec3(1.0f,0.0f,0.0f), _delete_on_update);
                    //DebugDrawWireSphere(nav_target, 1.0f, vec3(0.0f,1.0f,0.0f), _delete_on_update);
                    //Print("Dist: "+distance_squared(this_mo.position, path_end)+"\n");
                    if(distance_squared(NavPoint(this_mo.position), path_end) < 1.0f){
                        SetGoal(_patrol);
                    }      
                }
            }
            break;
        case _attack:
            {
                MovementObject@ target = ReadCharacterID(target_id);
                if(target.QueryIntFunction("int IsKnockedOut()") == 1){
                    SetGoal(_patrol);
                }
                if(rand()%(150/num_frames)==0){
                    ai_attacking = !ai_attacking;
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
            if(holding_weapon || !ObjectExists(weapon_target_id) || ReadItemID(weapon_target_id).IsHeld()){
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
    }
    //MouseControlPathTest();
    //HandleDebugRayDraw();
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


bool WantsToJump() {
    return false;
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
    if(char.QueryIntFunction("int GetState()") == _attack_state){
        return true;
    } else {
        return false;
    }
}

bool WantsToStartActiveBlock(){
    bool should_block = ShouldBlock();
    if(should_block && !going_to_block){
        going_to_block = true;
        block_delay = RangedRandomFloat(_block_reflex_delay_min,_block_reflex_delay_max);
    }
    if(going_to_block){
        block_delay -= time_step * num_frames;
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
    return false;
}

bool WantsToGrabLedge() {
    return false;
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

vec3 GetMovementToPoint(vec3 point, float slow_radius, float target_dist, float strafe_vel){
    // Get path to estimated target position
    vec3 target_velocity;
    vec3 target_point = point;
    GetPath(target_point);
    vec3 next_path_point = GetNextPathPoint();
    if(next_path_point != vec3(0.0f)){
        target_point = next_path_point;
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
    if(length_squared(target_velocity) > 1.0){
        target_velocity = normalize(target_velocity);
    }
    return target_velocity;
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
    
    return move_vel;    
}


void MouseControlPathTest() {
    vec3 start = camera.GetPos();
    vec3 end = camera.GetPos() + camera.GetMouseRay()*400.0f;
    col.GetSweptSphereCollision(start, end, _leg_sphere_size);
    DebugDrawWireSphere(sphere_col.position, _leg_sphere_size, vec3(0.0f,1.0f,0.0f), _delete_on_update);
    
    if(GetInputDown(this_mo.controller_id, "mouse0")){
        goal = _navigate;
        nav_target = sphere_col.position;
    }
}

float struggle_change_time = 0.0f;
vec3 struggle_dir;

int last_seen_sphere = -1;
vec3 GetTargetVelocity() {
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
        return GetMovementToPoint(nav_target, 1.0f); 
    } else if(goal == _investigate){
        return GetMovementToPoint(nav_target, 0.0f) * 0.2f; 
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