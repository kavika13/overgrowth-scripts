const float _ledge_move_speed = 10.0f;   // Multiplier for horz and vert movement speed on ledges
const float _ledge_move_damping = 0.95f; // Multiplier that damps velocity every timestep
const float _height_under_ledge = 1.05f; // Target vertical distance between leg sphere origin and ledge height
        
class MovingGrip {  // This class handles grip positions (IK targets) as they move from point to point
                    // A timer is constantly going from 0.0 to 1.0 on a timeline, and each MovingGrip
                    // class has a set window of time to get from the old position to the new one
    vec3 start_pos;
    vec3 end_pos;
    float start_time;
    float end_time;
    float move_time;
    vec3 offset;
    float time;
    float speed;
    int id;

    void Move(vec3 _start_pos, 
              vec3 _end_pos, 
              float _start_time,
              float _end_time,
              vec3 _offset)
    {
        start_pos = _start_pos;             // Where is grip moving from
        end_pos = _end_pos;                 // Where is grip moving to
        start_time = _start_time;           // When does movement start
        end_time = _end_time;               // When does movement end
        move_time = end_time - start_time;  // How long does movement last
        time = 0.0f;                        // Current time on timeline
        offset = _offset;                   // Which way does gripper move away from the surface while in transit
        speed = 2.0f;                       // How fast does timer go
    }

    void SetSpeed(float _speed){
        speed = _speed;
    }

    void SetEndPos(vec3 _pos) {
        if(time < end_time){
            end_pos = _pos + vec3(this_mo.velocity.x,                           // Target grip position leads character movement
                                  0.0f,
                                  this_mo.velocity.z)* 0.1f;
        }
    }

    void Update() {
        time += time_step * speed * num_frames;                                 // Timer increments based on speed
        if(time >= end_time){
            if(id < 2 && distance(start_pos, end_pos)>0.1f){                    // Hands play grip sound at the end of their movements
                if(id==0){
                    this_mo.MaterialEvent("edge_crawl", this_mo.GetIKTargetPosition("leftarm"));
                } else {
                    this_mo.MaterialEvent("edge_crawl", this_mo.GetIKTargetPosition("rightarm"));
                }
            }
            start_pos = end_pos;
            time -= 1.0f;
        }
    }

    float GetWeight(){                                                          // How much weight is placed on this grip?
        if(time <= start_time){                                                 // Grip is fully weight-bearing when not moving
            return 1.0f;
        }
        if(time >= end_time){
            return 1.0f;
        }
        float progress = (time - start_time)/move_time;                         // Weight-bearing follows a sin valley while moving
        float weight = 1.0f - sin(progress * 3.14f);
        return weight * weight;
    }

    vec3 GetPos() {
        if(time <= start_time){                                                 // If not moving, just return start or end pos
            return start_pos;
        }
        if(time >= end_time){
            return end_pos;
        }
        float progress = (time - start_time)/move_time;                         // If moving, position is straight line from start to end, plus 
        vec3 pos = mix(start_pos, end_pos, progress);                           // offset sin arc
        return pos;
    }

    vec3 GetOffset() {
        float progress = (time - start_time)/move_time;
        return offset * sin(progress * 3.14f) * distance(start_pos, end_pos);
    }

}

class ShimmyAnimation {     // Shimmy animation is composed of a MovingGrip for each hand and foot, as well as a body offset
    MovingGrip[] hand_pos;  // Animated hand grips
    MovingGrip[] foot_pos;  // Animated foot grips
    vec3 lag_vel;           // Lagged clone of character velocity, used to detect accelerations
    vec3 ledge_dir;         // Which direction is the ledge we are climbing relative to the character
    vec3 ik_shift;
    vec3[] last_grip_pos;
    vec3[] old_ik_offset;

    ShimmyAnimation() {
        hand_pos.resize(2);
        foot_pos.resize(2);
        hand_pos[0].id = 0;
        hand_pos[1].id = 1;
        foot_pos[0].id = 2;
        foot_pos[1].id = 3;
        lag_vel = vec3(0.0f);
        ik_shift = vec3(0.0f);
        last_grip_pos.resize(2);
        old_ik_offset.resize(2);
    }

    void Start(vec3 pos, vec3 dir, vec3 vel){                                   // Set up the rhythm of the hand and foot grippers
        ledge_dir = dir;
        hand_pos[0].Move(pos, pos, 0.0f, 0.4f, vec3(0.0f,0.1f,0.0f));           // Initialize hands to offset up when moving
        hand_pos[1].Move(pos, pos, 0.5f, 0.9f, vec3(0.0f,0.1f,0.0f));
        foot_pos[0].Move(pos, pos, 0.1f, 0.5f, dir * -0.1f);                    // Initialize feet to offset away from wall when moving
        foot_pos[1].Move(pos, pos, 0.6f, 1.0f, dir * -0.1f);
        ik_shift = vec3(0.0f);
        lag_vel = vel;
        last_grip_pos[0] = vec3(0.0f);
        last_grip_pos[1] = vec3(0.0f);
        old_ik_offset[0] = vec3(0.0f);
        old_ik_offset[1] = vec3(0.0f);
    }

    void Update(vec3 _target_pos, vec3 dir){
        hand_pos[0].SetEndPos(_target_pos);                                     // Update gripper targets
        hand_pos[1].SetEndPos(_target_pos);
        foot_pos[0].SetEndPos(_target_pos);
        foot_pos[1].SetEndPos(_target_pos);
        hand_pos[0].Update();                                                   // Update gripper movement
        hand_pos[1].Update();
        foot_pos[0].Update();
        foot_pos[1].Update();

        float speed = sqrt(this_mo.velocity.x * this_mo.velocity.x              // Gripper speed is proportional to sqrt of
                          +this_mo.velocity.z * this_mo.velocity.z)*3.0f;       // character's horizontal velocity
        speed = min(3.0f,max(1.0f,speed));
        
        hand_pos[0].SetSpeed(speed);                                            // Update gripper speed
        hand_pos[1].SetSpeed(speed);
        foot_pos[0].SetSpeed(speed);
        foot_pos[1].SetSpeed(speed);

        lag_vel = mix(this_mo.velocity, lag_vel, pow(0.95f,num_frames));        // Update lagged velocity clone

        ledge_dir = dir;                                                        // Update ledge direction
    }

    void UpdateIKTargets() {
        const float _dist_limit = 0.4f;
        const float _dist_limit_squared = _dist_limit*_dist_limit;

        vec3 transition_offset = ledge_grab_origin - this_mo.position;          // Offset used for transitioning into ledge climb
        vec3[] offset(4);
        offset[0] = hand_pos[0].GetPos() - this_mo.position;                    // Get gripper offsets relative to leg_sphere origin
        offset[1] = hand_pos[1].GetPos() - this_mo.position;
        offset[2] = foot_pos[0].GetPos() - this_mo.position;
        offset[3] = foot_pos[1].GetPos() - this_mo.position;

        offset[2].y *= leg_ik_mult;                                             // Flatten out foot positions if needed
        offset[3].y *= leg_ik_mult;

        vec3[] old_offset(2);
        old_offset[0] = offset[0];
        old_offset[1] = offset[1];

        vec3 check_pos = this_mo.GetIKTargetPosition("leftarm")+offset[0]+ledge_dir*0.1f;    
        vec3 check_dir = normalize(vec3(0.0f,-1.0f,0.0f)+ledge_dir*0.5f);
        this_mo.GetSweptSphereCollision(check_pos-check_dir*0.2f,
                                        check_pos+check_dir*0.4f,
                                        0.05f);
        if(sphere_col.NumContacts() != 0){
            last_grip_pos[0] = sphere_col.position + vec3(0.0f,-0.15f,0.0f);
            offset[0] += sphere_col.position - check_pos;
            offset[0].y -= 0.10f;
        } else {
            if(last_grip_pos[0] != vec3(0.0f)){
                offset[0] = last_grip_pos[0] - this_mo.GetIKTargetPosition("leftarm");   
            }
        }

        check_pos = this_mo.GetIKTargetPosition("rightarm")+offset[1]+ledge_dir*0.1f;    
        this_mo.GetSweptSphereCollision(check_pos-check_dir*0.2f,
                                        check_pos+check_dir*0.4f,
                                        0.05f); 
        if(sphere_col.NumContacts() != 0){
            last_grip_pos[1] = sphere_col.position + vec3(0.0f,-0.15f,0.0f);
            offset[1] += sphere_col.position - check_pos;
            offset[1].y -= 0.10f;
        } else {
            if(last_grip_pos[1] != vec3(0.0f)){
                offset[1] = last_grip_pos[1] - this_mo.GetIKTargetPosition("rightarm");   
            }
        }

        vec3 ik_offset;

        ik_offset = offset[0] - old_offset[0];
        old_ik_offset[0] = mix(ik_offset, old_ik_offset[0], 0.8f);
        offset[0] = old_offset[0] + old_ik_offset[0];

        ik_offset = offset[1] - old_offset[1];
        old_ik_offset[1] = mix(ik_offset, old_ik_offset[1], 0.8f);
        offset[1] = old_offset[1] + old_ik_offset[1];

        vec3 new_ik_shift = (offset[0]-old_offset[0] + offset[1]-old_offset[1])*0.5f;
        ik_shift = mix(new_ik_shift, ik_shift, 0.9f);
        offset[2].y += ik_shift.y;
        offset[3].y += ik_shift.y;
        
        offset[0] += hand_pos[0].GetOffset();
        offset[1] += hand_pos[1].GetOffset();
        offset[0] += foot_pos[0].GetOffset();
        offset[1] += foot_pos[1].GetOffset();


        float[] weight(4);
        weight[0] = hand_pos[0].GetWeight();                                    // Get weight bearing for each gripper
        weight[1] = hand_pos[1].GetWeight();
        weight[2] = foot_pos[0].GetWeight();
        weight[3] = foot_pos[1].GetWeight();
        float total_weight = weight[0] + weight[1] + weight[2] + weight[3];     
        vec3 weight_offset = vec3(0.0f);
        weight_offset += this_mo.GetIKTargetPosition("leftarm") * (weight[0] / total_weight);   // Get weighted average of gripper offsets
        weight_offset += this_mo.GetIKTargetPosition("rightarm") * (weight[1] / total_weight);
        weight_offset += this_mo.GetIKTargetPosition("left_leg") * (weight[2] / total_weight);
        weight_offset += this_mo.GetIKTargetPosition("right_leg") * (weight[3] / total_weight);
        weight_offset -= this_mo.position;
        weight_offset -= dot(ledge_dir,weight_offset) * ledge_dir;              // Flatten weighted offset against ledge plane
        float move_amount = sqrt(this_mo.velocity.x * this_mo.velocity.x
                                +this_mo.velocity.z * this_mo.velocity.z) * 0.4f; // Get constant multiplier for weight_offset based on movement
        weight_offset *= max(0.0f,min(1.0f,move_amount-0.1f))*0.5f;
        weight_offset.y = 0.0f;
        weight_offset += (lag_vel - this_mo.velocity) * 0.1f;                   // Add acceleration lag to weight offset
        //weight_offset += this_mo.velocity * 0.05f;
        weight_offset.y += 0.3f * move_amount;
        weight_offset += ledge_dir * move_amount * 0.3f;
        weight_offset.y += ik_shift.y;
        weight_offset.x += ik_shift.x*0.5f;
        weight_offset.z += ik_shift.z*0.5f;
        weight_offset -= ledge_dir * 0.1f;

        weight_offset *= ik_mult;     
   
        this_mo.SetIKTargetOffset("full_body",mix(transition_offset,weight_offset,transition_progress)); // Apply weight offset to torso

        for(int i=0; i<4; i++){
            offset[i] -= weight_offset;
            if(length_squared(offset[i]) > _dist_limit_squared){
                offset[i] = normalize(offset[i])*_dist_limit;
            }
            offset[i] += weight_offset;
        }

        for(int i=0; i<4; ++i){
            offset[i] *= ik_mult;
        }

        //Print("IK mult: " + ik_mult + "\n"); 

        this_mo.SetIKTargetOffset("leftarm",mix(transition_offset,offset[0],transition_progress));  // Set IK target offsets
        this_mo.SetIKTargetOffset("rightarm",mix(transition_offset,offset[1],transition_progress));
        this_mo.SetIKTargetOffset("left_leg",mix(transition_offset,offset[2],transition_progress));
        this_mo.SetIKTargetOffset("right_leg",mix(transition_offset,offset[3],transition_progress));
    }
}

vec3 ledge_grab_origin;             // Where was leg sphere origin when ledge grab started
float transition_speed;             // How fast to transition to new position
float transition_progress;          // How far along the transition is (0-1)
float leg_ik_mult;                  // How much we are allowing vertical leg IK displacement
float ik_mult;
bool ghost_movement;

class LedgeInfo {
    bool on_ledge;                  // Grabbing ledge or not
    float ledge_height;             // Height of the ledge in world coords
    vec3 ledge_grab_pos;            // Where did we first grab the ledge
    vec3 ledge_dir;                 // Direction to the ledge from the character
    bool climbed_up;                // Did we just climb up something? Queried by main movement update
    bool playing_animation;         // Are we currently playing an animation?
    bool allow_ik;
    vec3 disp_ledge_dir;
    
    ShimmyAnimation shimmy_anim;    // Hand and foot animation class

    LedgeInfo() {    
        on_ledge = false;
        climbed_up = false;
        playing_animation = false;
        allow_ik = true;
        ghost_movement = false;
    }

    void UpdateLedgeAnimation() {
        if(!playing_animation){     // If not playing a special animation, adopt ledge pose
            this_mo.SetCharAnimation("ledge",5.0f);
        }
    }

    void UpdateIKTargets() {
        /*if(playing_animation){
            vec3 offset = (ledge_grab_origin - this_mo.position)*(1.0f-transition_progress);
            this_mo.SetIKTargetOffset("leftarm",offset);
            this_mo.SetIKTargetOffset("rightarm",offset);
            this_mo.SetIKTargetOffset("left_leg",offset);
            this_mo.SetIKTargetOffset("right_leg",offset);
            this_mo.SetIKTargetOffset("full_body",offset);
            return;
        }*/
        shimmy_anim.UpdateIKTargets();
    }

    vec3 WallRight() {              // Get the vector that points right when facing the ledge
        vec3 wall_right = ledge_dir;
        float temp = ledge_dir.x;
        wall_right.x = -ledge_dir.z;
        wall_right.z = temp;
        return wall_right;        
    }
    
    vec3 CalculateGrabPos() {       // Sweep a cylinder to get the closest position a cylinder can be to the ledge
        vec3 test_end = this_mo.position+ledge_dir*1.0f;
        vec3 test_start = test_end+ledge_dir*-2.0f;
        test_end.y = ledge_height;
        test_start.y = ledge_height;
        this_mo.GetSweptCylinderCollision(test_start,
                                          test_end,
                                          _leg_sphere_size,
                                          1.0f);


        const bool _debug_draw_sweep_test = false;
        if(_debug_draw_sweep_test){
            DebugDrawWireCylinder(test_start,
                                  _leg_sphere_size,
                                  1.0f,
                                  vec3(1.0f,0.0f,0.0f),
                                  _delete_on_update);

            DebugDrawWireCylinder(test_end,
                                  _leg_sphere_size,
                                  1.0f,
                                  vec3(0.0f,1.0f,0.0f),
                                  _delete_on_update);

            DebugDrawWireCylinder(sphere_col.position,
                                  _leg_sphere_size,
                                  1.0f,
                                  vec3(0.0f,0.0f,1.0f),
                                  _delete_on_update);
        }

        return sphere_col.position - vec3(0.0f, _height_under_ledge, 0.0f);
    }

    void CheckLedges() {                            // Get info about the ledge if there is one,
        vec3 possible_ledge_dir;                                                // and grab on if not already grabbing
        
        this_mo.GetSlidingSphereCollision(this_mo.position,                 // Otherwise try to detect the wall by colliding an enlarged 
                                              _leg_sphere_size*1.5f);           // player sphere with the scene, and finding the closest 
        if(sphere_col.NumContacts() == 0){                                  // collision
            return;
        } else {
            float closest_dist = 0.0f;
            float dist;
            int closest_point = -1;
            int num_contacts = sphere_col.NumContacts();
            for(int i=0; i<num_contacts; ++i){
                dist = distance_squared(
                    sphere_col.GetContact(i).position, this_mo.position);
                if(closest_point == -1 || dist < closest_dist){
                    closest_dist = dist;
                    closest_point = i;
                }
            }
            possible_ledge_dir = sphere_col.GetContact(closest_point).position - this_mo.position;
            possible_ledge_dir = normalize(possible_ledge_dir);
            const bool _debug_draw_sphere_check = false;
            if(_debug_draw_sphere_check){
                DebugDrawWireSphere(this_mo.position, _leg_sphere_size*1.5f, vec3(1.0f), _delete_on_update);
            }
            if(possible_ledge_dir.y < -0.7f){
                if(on_ledge){
                    Print("Letting go because nearest surface is downwards\n");
                }
                on_ledge = false;
                return;
                if(_debug_draw_sphere_check){
                    DebugDrawLine(sphere_col.GetContact(closest_point).position,
                                  this_mo.position,
                                  vec3(1.0f,0.0f,0.0f),
                                  _delete_on_update);
                }
            } else {
                if(_debug_draw_sphere_check){
                    DebugDrawLine(sphere_col.GetContact(closest_point).position,
                                  this_mo.position,
                                  vec3(0.0f,1.0f,0.0f),
                                  _delete_on_update);
                }
            }
            possible_ledge_dir.y = 0.0f;
            possible_ledge_dir = normalize(possible_ledge_dir);
        }

        float cyl_height = 1.0f;                                                // Get ledge height by sweeping a cylinder downwards onto the ledge
        vec3 test_start = this_mo.position+vec3(0.0f,5.0f,0.0f)+possible_ledge_dir * 0.5f;
        vec3 test_end = this_mo.position+vec3(0.0f,0.5f,0.0f)+possible_ledge_dir * 0.5f;
        
        this_mo.GetSweptCylinderCollision(test_start,
                                          test_end,
                                          _leg_sphere_size,
                                          1.0f);

        if(sphere_col.NumContacts() == 0){
            if(on_ledge){
                Print("Let go because no height collision found\n");
            }
            on_ledge = false;
            return;                                                             // Return if there is no ledge detected
        }

        const bool _debug_draw_sweep_test = false;
        if(_debug_draw_sweep_test){
            DebugDrawWireCylinder(test_start,
                                  _leg_sphere_size,
                                  1.0f,
                                  vec3(1.0f,0.0f,0.0f),
                                  _delete_on_update);
            DebugDrawWireCylinder(test_end,
                                  _leg_sphere_size,
                                  1.0f,
                                  vec3(0.0f,1.0f,0.0f),
                                  _delete_on_update);
            
            DebugDrawWireCylinder(sphere_col.position,
                                  _leg_sphere_size,
                                  1.0f,
                                  vec3(0.0f,0.0f,1.0f),
                                  _delete_on_update);
        }

        float edge_height = sphere_col.position.y - cyl_height * 0.5f;

        if(on_ledge && edge_height > ledge_height + 0.5f){
            return;
        } else {
            ledge_height = edge_height;
        }

        vec3 surface_pos = sphere_col.position;

        this_mo.GetCylinderCollision(surface_pos + vec3(0.0f,0.07f,0.0f),       // Make sure that top surface is clear, i.e. player could stand on it
                                    _leg_sphere_size,
                                    1.0f);


        const bool _debug_draw_top_surface_clear = false;
        if(sphere_col.NumContacts() != 0){
            if(_debug_draw_top_surface_clear){
                DebugDrawWireCylinder(surface_pos + vec3(0.0f,0.07f,0.0f),
                                      _leg_sphere_size,
                                      1.0f,
                                      vec3(1.0f,0.0f,0.0f),
                                      _delete_on_update);
            }
            if(on_ledge){
                Print("Let go because top is not clear\n");
            }
            on_ledge = false;
            return;                                                             // Return if surface is obstructed
        }

        if(_debug_draw_top_surface_clear){
            DebugDrawWireCylinder(surface_pos + vec3(0.0f,0.07f,0.0f),
                                  _leg_sphere_size,
                                  1.0f,
                                  vec3(0.0f,1.0f,0.0f),
                                  _delete_on_update);
        }

        ledge_dir = possible_ledge_dir;
        if(on_ledge){
            return;                                                             // The rest of this function is only useful for
        }                                                                       // determining whether or not we can grab the ledge


        test_end = this_mo.position+possible_ledge_dir*1.0f;                             // Use a swept cylinder to detect the distance
        test_end.y = ledge_height;                                              // of the ledge from the player sphere origin
        test_start = test_end+possible_ledge_dir*-1.0f;
        this_mo.GetSweptCylinderCollision(test_start,
                                          test_end,
                                          _leg_sphere_size,
                                          1.0f);
        
        const bool _debug_draw_depth_test = false;
        if(_debug_draw_depth_test){
            DebugDrawWireCylinder(sphere_col.position,
                                  _leg_sphere_size,
                                  1.0f,
                                  vec3(0.0f,0.0f,1.0f),
                                  _delete_on_update);
        }

        if(sphere_col.NumContacts() == 0){
            return;                                                             // Return if swept cylinder detects no ledge
        }

        float char_height = this_mo.position.y;                                 // Start checking if the ledge is within vertical
        const float _base_grab_height = 1.0f;                                   // reach of the player. Vertical reach is extended
        float grab_height = _base_grab_height;                                  // to allow one-armed scramble grabs if velocity is
        if(this_mo.velocity.y < 1.5f){                                          // below a threshold.
            if(this_mo.velocity.y > 0.0f){
                grab_height += 1.5f;
            } else {
                grab_height += 0.5f;
            }
        }

        if(char_height > ledge_height - grab_height){                           // If ledge is within reach, grab it
            if(char_height < ledge_height - _base_grab_height){                 // If height difference requires the scramble grab, then
                playing_animation = true;                                       // play the animation
                int flags = 0;
                if(rand()%2 == 0){
                    flags = _ANM_MIRRORED;
                }
                this_mo.StartAnimation("Data/Animations/r_ledge_barely_reach.anm",8.0f,flags);
                this_mo.SetAnimationCallback("void EndClimbAnim()");
                leg_ik_mult = 0.0f;
            } else {
                playing_animation = false;                                      // Otherwise go straight into ledge pose
                leg_ik_mult = 1.0f;
            }
            ik_mult = 1.0f;

            ledge_grab_origin = this_mo.position;                               // Record current position for smooth transition
            transition_progress = 0.0f;
            transition_speed = 10.0f/(abs(ledge_height - char_height)+0.05f);
            
            allow_ik = true;
            on_ledge = true;                                                    // Set up ledge grab starting conditions
            disp_ledge_dir = this_mo.GetFacing();
            climbed_up = false;
            this_mo.velocity = vec3(0.0f);
            ledge_grab_pos = CalculateGrabPos();
            shimmy_anim.Start(ledge_grab_pos, possible_ledge_dir, this_mo.velocity);
            ghost_movement = false;

            this_mo.MaterialEvent("edge_grab", this_mo.position + ledge_dir * _leg_sphere_size);
        }
    }

    void EndClimbAnim(){
        if(ghost_movement){
            on_ledge = false;    
            climbed_up = true;
            jump_info.hit_wall = false;
            this_mo.velocity = vec3(0.0f);
        }
        playing_animation = false; 
        allow_ik = true;
        ghost_movement = false;
    }
    
    void UpdateLedge() {
        if(allow_ik){
            ik_mult = min(1.0f, ik_mult + time_step * num_frames * 5.0f);
        } else {
            ik_mult = max(0.0f, ik_mult - time_step * num_frames * 5.0f);
        }

        if(transition_progress < 1.0f){
            transition_progress += time_step * num_frames * transition_speed;   // Update transition to ledge grab
            transition_progress = min(1.0f, transition_progress); 
            cam_pos_offset = (ledge_grab_origin - this_mo.position)*(1.0f-transition_progress);
        }

        if(ghost_movement){
            this_mo.velocity = vec3(0.0f,0.1f,0.0f);
            /*DebugDrawWireSphere(this_mo.position,
                                _leg_sphere_size,
                                vec3(1.0f),
                                _delete_on_update);*/
            return;
        }

        CheckLedges();
        /*DebugDrawWireSphere(this_mo.position,
                            _leg_sphere_size,
                            vec3(1.0f),
                            _delete_on_update);*/

        if(!WantsToGrabLedge()){
            on_ledge = false;    // If let go or not in contact with wall, 
                                 // not on ledge
        }

        this_mo.velocity += ledge_dir * 0.1f * num_frames;                      // Pull towards wall

        float target_height = ledge_height - _height_under_ledge;
        this_mo.velocity.y += (target_height - this_mo.position.y) * 0.8f;      // Move height towards ledge height
        this_mo.velocity.y *= pow(0.92f, num_frames);
        
        this_mo.position.y = min(this_mo.position.y, target_height + 0.5f);
        this_mo.position.y = max(this_mo.position.y, target_height - 0.1f);
        
        if(!playing_animation){
            leg_ik_mult = min(1.0f, leg_ik_mult + time_step * num_frames * 5.0f);
        }

        vec3 target_velocity = GetTargetVelocity();
        float ledge_dir_dot = dot(target_velocity, ledge_dir);
        vec3 horz_vel = target_velocity - (ledge_dir * ledge_dir_dot);
        vec3 real_velocity = horz_vel;
        if(ledge_dir_dot > 0.0f){                                               // Climb up if moving towards ledge
            real_velocity.y += ledge_dir_dot * time_step * num_frames * _ledge_move_speed * 70.0f;
        }    

        if(playing_animation){
            real_velocity.y = 0.0f;
        }

        this_mo.velocity += real_velocity * time_step * num_frames * _ledge_move_speed; // Apply target velocity
        this_mo.velocity.x *= pow(_ledge_move_damping, num_frames);             // Damp horizontal movement
        this_mo.velocity.z *= pow(_ledge_move_damping, num_frames);

        vec3 new_ledge_grab_pos = CalculateGrabPos();                           
        shimmy_anim.Update(new_ledge_grab_pos, ledge_dir);                      // Update hand and foot animation

        //DebugDrawWireSphere(this_mo.position, _leg_sphere_size, vec3(1.0f), _delete_on_update); 

        /*if(dot(disp_ledge_dir, ledge_dir) > 0.90f){
            disp_ledge_dir = ledge_dir;
        }*/
        float val = dot(ledge_dir, disp_ledge_dir)*0.5f+0.5f;
        float inertia = mix(0.95f,0.8f,pow(val,4.0));
        disp_ledge_dir= InterpDirections(ledge_dir,
                         disp_ledge_dir,
                         pow(inertia,num_frames));
        this_mo.SetRotationFromFacing(disp_ledge_dir); 
        if(this_mo.velocity.y >= 0.0f && this_mo.position.y > target_height + 0.4f){ // Climb up ledge if above threshold
            if(this_mo.velocity.y >= 3.0f){
                on_ledge = false;    
                climbed_up = true;
                jump_info.hit_wall = false;
                this_mo.velocity = vec3(0.0f);
                this_mo.position.y = ledge_height + _leg_sphere_size * 0.7f;
                this_mo.position += ledge_dir * 0.7f;
            } else {
                this_mo.position.y = target_height;
                playing_animation = true;
                allow_ik = false;
                int flags = _ANM_SUPER_MOBILE;
                this_mo.StartAnimation("Data/Animations/r_ledge_climb_fast.anm",8.0f,flags);
                this_mo.SetAnimationCallback("void EndClimbAnim()");
                ghost_movement = true;
            }
        }
    }
};

void EndClimbAnim(){
    ledge_info.EndClimbAnim();
}