#include "aschar.as"

bool hostile = true;
bool listening = true;
bool ai_attacking = false;
bool hostile_switchable = true;
int waypoint_target = -1;
int old_waypoint_target = -1;

void UpdateBrain(){
    if(GetInputDown("c") && !GetInputDown("ctrl")){
        if(hostile_switchable){
            hostile = !hostile;
            if(hostile){
                TargetClosest();
                ai_attacking = true;
                listening = true;
            } else {
                ResetWaypointTarget();
                ClearTarget();
                listening = false;
            }
        }
        hostile_switchable = false;
    } else {
        hostile_switchable = true;
    }
    if(hostile && rand()%(150/num_frames)==0){
        ai_attacking = !ai_attacking;
    }
    if(!hostile || target_id == -1){
        ai_attacking = false;
    }
    if(target_id == -1 && hostile){
        TargetClosest();
    }
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

void ActiveBlocked(){
    ai_attacking = true;
}

bool WantsToCrouch() {
    return false;
}

bool WantsToPickUpItem() {
    return false;
}

bool WantsToDropItem() {
    return false;
}


bool WantsToThrowEnemy() {
    return ai_attacking && (rand()%3 == 0);
}

bool WantsToRoll() {
    return false;
}

bool WantsToJump() {
    return false;
}

bool WantsToAttack() { 
    return ai_attacking;
}

bool WantsToRollFromRagdoll(){
    return false;
}

bool WantsToStartActiveBlock(){
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
    return false;
}

NavPath path;
int current_path_point = 0;
void GetPath(vec3 target_pos) {
    path = this_mo.GetPath(this_mo.position,
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
    

int last_seen_sphere = -1;
// Uses the position of the target character to calculate a target velocity (towards the target) that is used for movement calculations in aschar.as and aircontrol.as.
vec3 GetTargetVelocity() {
    if(target_id == -1){
        vec3 target_velocity;
        vec3 target_point = this_mo.position;
        if(waypoint_target == -1){
            old_waypoint_target = -1;
            //waypoint_target = path_script_reader.GetNearestPoint(this_mo.position);
            waypoint_target = this_mo.GetWaypointTarget();
            //Print("Waypoint target: " + waypoint_target + "\n");
        }
        if(waypoint_target != -1){
            target_point = path_script_reader.GetPointPosition(waypoint_target);
        }
        if(xz_distance_squared(this_mo.position, target_point) < 1.0f){
            int temp = waypoint_target;

            //Print("GetOtherConnectedPoint: "+waypoint_target+", " + old_waypoint_target + "\n");
            waypoint_target = path_script_reader.GetOtherConnectedPoint(
                waypoint_target, old_waypoint_target);
            old_waypoint_target = temp;
            
            if(waypoint_target == -1){
                waypoint_target = path_script_reader.GetConnectedPoint(old_waypoint_target);
                //Print("Wut\n");
            }
            //Print("Waypoint target: "+waypoint_target+"\n");
            //Print("Old waypoint target: "+old_waypoint_target+"\n");
        }
        target_velocity = target_point - this_mo.position;
        target_velocity.y = 0.0;
        float dist = length(target_velocity);
        float seek_dist = 1.0;
        dist = max(0.0, dist-seek_dist);
        target_velocity = normalize(target_velocity) * dist;
        float target_speed = 0.2f;
        if(length_squared(target_velocity) > target_speed){
            target_velocity = normalize(target_velocity) * target_speed;
        }
        return target_velocity;
    }
    //if(distance_squared(this_mo.position, target.position) < 9.0f){
        bool vis = false;
        last_seen_target_position += last_seen_target_velocity * time_step * num_frames;
        last_seen_target_velocity *= pow(0.995f, num_frames);
        vec3 real_target_pos = ReadCharacterID(target_id).position;
        //if(IsTargetInFOV(real_target_pos)){
            vec3 head_pos = this_mo.GetAvgIKChainPos("head");
            if(ReadCharacterID(target_id).VisibilityCheck(head_pos)){
                last_seen_target_position = real_target_pos;
                last_seen_target_velocity = ReadCharacterID(target_id).velocity;
                vis = true;
            }
        //}

        vec3 target_velocity;
        /*if(last_seen_sphere != -1){
            DebugDrawRemove(last_seen_sphere);
        }
        vec3 color;
        if(vis){
            color = vec3(0.0f,1.0f,0.0f);
        } else {
            color = vec3(1.0f,0.0f,0.0f);
        }
        last_seen_sphere = 
            DebugDrawWireSphere(last_seen_target_position, 0.5f, color, _persistent);*/
        vec3 target_point = last_seen_target_position;//ReadCharacterID(target_id).position;
        
        GetPath(target_point);
        vec3 next_path_point = GetNextPathPoint();
        if(next_path_point != vec3(0.0f)){
            target_point = next_path_point;
        }
        //DrawPath();
        
        target_velocity = target_point - this_mo.position;
        target_velocity.y = 0.0;
        float dist = length(target_velocity);
        float seek_dist = 1.0;
        dist = max(0.0, dist-seek_dist);
        target_velocity = normalize(target_velocity) * dist;
        if(length_squared(target_velocity) > 1.0){
            target_velocity = normalize(target_velocity);
        }
        return target_velocity;
    /*}

    NavPath temp = this_mo.GetPath(this_mo.position,
                                   target.position);
    int num_points = temp.NumPoints();
    for(int i=0; i<num_points-1; i++){
        DebugDrawLine(temp.GetPoint(i),
                      temp.GetPoint(i+1),
                      vec3(1.0f,1.0f,1.0f),
                      _delete_on_update);
    }
        
    if(num_points < 2){
        return vec3(0.0f);
    } else {
        vec3 target_vel = (temp.GetPoint(1)-this_mo.position);
        target_vel.y = 0.0f;
        return normalize(target_vel);
    }*/
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