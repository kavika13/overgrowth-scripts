#include "fliproll.as"
#include "ledgegrab.as"

const float _jump_fuel_burn = 10.0f; // multiplier for amount of fuel lost per time_step
const float _jump_fuel = 5.0f; // used to set the amount of fuel available at the start of a jump
const float _air_control = 3.0f; // multiplier for the amount of directional control available while in the air
const float _jump_vel = 5.0f; // y-axis (up) velocity of jump used in GetJumpVelocity()
const float _jump_threshold_time = 0.1f; // time that must pass before a new jump, used in aschar.as
const float _jump_launch_decay = 2.0f;
const float _wall_run_friction = 0.1f; // used to let wall running pull the character up, uncomment code in UpdateWallRun() to enable

// at the end of this file, JumpInfo is instantiated as jump_info
// aschar.as uses jump_info to execute code in aircontrol.as

bool left_foot_jump = false;
bool to_jump_with_left = false;

class JumpInfo {
    array<vec3> jump_path;
    float jump_path_progress;
    bool follow_jump_path;
    vec3 jump_start_vel;

    float jetpack_fuel; // the amount of fuel available for acceleration
    float jump_launch; // used for the initial jump stretch pose

    bool has_hit_wall;
    bool hit_wall; // used to see if the character is wallrunning
    float wall_hit_time;
    vec3 wall_dir;
    vec3 wall_run_facing;

    float down_jetpack_fuel; // pushes the character down after upwards velocity of the jump has stopped

    LedgeInfo ledge_info;

    JumpInfo() {    
        jetpack_fuel = 0.0f;
        jump_launch = 0.0f;
        hit_wall = false;
    }

    bool ClimbedUp() {
        bool val = ledge_info.climbed_up;
        ledge_info.climbed_up = false;
        return val;
    }

    void SetFacingFromWallDir() {
        vec3 flat_dir = wall_dir;
        flat_dir.y = 0.0f;
        if(length_squared(flat_dir) > 0.0f){
            flat_dir = normalize(flat_dir);
            this_mo.SetRotationFromFacing(flat_dir); 
        }
    }

    void HitWall(vec3 dir) {
        if(has_hit_wall || dot(dir, this_mo.velocity) < 0.0f){
            return;
        }
        //string path = "Data/Sounds/concrete_foley/bunny_wallrun_concrete.xml";
        //this_mo.PlaySoundGroupAttached(path, this_mo.position);
        this_mo.MaterialEvent("leftwallstep", this_mo.position+dir*_leg_sphere_size);
    
        hit_wall = true;
        has_hit_wall = true;
        wall_hit_time = 0.0f;
        wall_dir = dir;
        //this_mo.velocity = vec3(0.0f);
        SetFacingFromWallDir();
    }

    void LostWallContact() {
        if(hit_wall){
            hit_wall = false;
            this_mo.SetRotationFromFacing(wall_run_facing);
        }
    }

    void UpdateFreeAirAnimation() {
        float up_coord = this_mo.velocity.y/_jump_vel + 0.5f;
        up_coord = min(1.5f,up_coord)+jump_launch*0.5f;
        up_coord *= -0.5f;
        up_coord += 0.5f;
        float flailing = min(1.0f,max(0.0f,(-this_mo.velocity.y-_shock_damage_threshold*0.75f)*_shock_damage_multiplier*0.75f));
        this_mo.SetBlendCoord("up_coord",up_coord);
        this_mo.SetBlendCoord("tuck_coord",flip_info.GetTuck());
        this_mo.SetBlendCoord("flail_coord",flailing);
        int8 flags = 0;
        if(left_foot_jump){
            flags = _ANM_MIRRORED;
        }
        this_mo.SetCharAnimation("jump",20.0f,flags);
        this_mo.SetIKEnabled(false);
    }

    void UpdateWallRunAnimation() {
        vec3 wall_right = wall_dir;
        float temp = wall_dir.x;
        wall_right.x = -wall_dir.z;
        wall_right.z = temp;
        float speed = length(this_mo.velocity);
        this_mo.SetCharAnimation("wall",5.0f);
        this_mo.SetBlendCoord("ground_speed",speed);
        this_mo.SetBlendCoord("speed_coord",speed*0.25f);
        this_mo.SetBlendCoord("dir_coord",dot(normalize(this_mo.velocity), wall_right));
        vec3 flat_vel = this_mo.velocity;
        flat_vel.y = 0.0f;
        wall_run_facing = normalize(this_mo.GetFacing() + flat_vel*0.25f);
        /*DebugDrawLine(this_mo.position,
                      this_mo.position + normalize(flat_vel),
                      vec3(1.0f),
                      _delete_on_update);
        */
    }

    void UpdateLedgeAnimation() {
        this_mo.StartCharAnimation("idle");
    }

    void UpdateIKTargets() {
        if(ledge_info.on_ledge){
            ledge_info.UpdateIKTargets();
        } else {            
            vec3 no_offset(0.0f);
            this_mo.SetIKTargetOffset("leftarm",no_offset);
            this_mo.SetIKTargetOffset("rightarm",no_offset);
            this_mo.SetIKTargetOffset("left_leg",no_offset);
            this_mo.SetIKTargetOffset("right_leg",no_offset);
            this_mo.SetIKTargetOffset("full_body",no_offset);
        }
    }

    void UpdateAirAnimation() {
        if(ledge_info.on_ledge){
            ledge_info.UpdateLedgeAnimation();
        } else if(hit_wall){
            UpdateWallRunAnimation();
        } else {
            UpdateFreeAirAnimation();
        }
    }

    // returns ledge_dir rotated 90 degrees clockwise
    vec3 WallRight() {
        vec3 wall_right = wall_dir;
        float temp = wall_dir.x;
        wall_right.x = -wall_dir.z;
        wall_right.z = temp;
        return wall_right;        
    }

    void UpdateWallRun() {
        wall_hit_time += time_step * num_frames;
        if(wall_hit_time > 0.1f && this_mo.velocity.y < -1.0f && !ledge_info.on_ledge){
            LostWallContact();
        }

        // lets wall-running pull the character farther up, as affected by the _wall_run_friction
        /*this_mo.velocity -= physics.gravity_vector * 
                            time_step * 
                            _wall_run_friction;
        */
        this_mo.GetSlidingSphereCollision(this_mo.position, 
                                          _leg_sphere_size * 1.05f);
        if(sphere_col.NumContacts() == 0){
            LostWallContact();
        } else {
            wall_dir = normalize(sphere_col.GetContact(0).position -
                                 this_mo.position);
            /*DebugDrawWireSphere(this_mo.position,
                                _leg_sphere_size * 1.0f,
                                vec3(1.0f,0.0f,0.0f),
                                _delete_on_update);
            for(int i=0; i<sphere_col.NumContacts(); ++i){
                DebugDrawLine(this_mo.position,
                              sphere_col.GetContact(0).position,
                              vec3(0.0f,1.0f,0.0f),
                              _delete_on_update);
            }*/
            SetFacingFromWallDir();
        }
        if(WantsToJumpOffWall()){
            StartWallJump(wall_dir * -1.0f);
        }
        
        if(WantsToFlipOffWall()){
            StartWallJump(wall_dir * -1.0f);
            flip_info.StartWallFlip(wall_dir * -1.0f);
        }
    }

    void UpdateAirControls() {
        if(!follow_jump_path){
            if(WantsToAccelerateJump()){
                // if there's fuel left and character is not moving down, height can still be increased
                if(jetpack_fuel > 0.0 && this_mo.velocity.y > 0.0) {
                    jetpack_fuel -= time_step * _jump_fuel_burn * num_frames;
                    this_mo.velocity.y += time_step * _jump_fuel_burn * num_frames;
                }
            } else {
                // the character is pushed downwards to allow for smaller, controlled jumps
                if(down_jetpack_fuel > 0.0){
                    down_jetpack_fuel -= time_step * _jump_fuel_burn * num_frames;
                    this_mo.velocity.y -= time_step * _jump_fuel_burn * num_frames;
                }
            }
        }

        if(!hit_wall){
            if(WantsToFlip()){
                if(!flip_info.IsFlipping()){
                    flip_info.StartFlip();
                }
            }
        }

        if(hit_wall){
            UpdateWallRun();
        }

        if(WantsToGrabLedge()){
            ledge_info.CheckLedges(hit_wall, wall_dir);
            if(ledge_info.on_ledge && !hit_wall){
                has_hit_wall = false;
                HitWall(ledge_info.ledge_dir);
                this_mo.position.x = ledge_info.ledge_grab_pos.x;
                this_mo.position.z = ledge_info.ledge_grab_pos.z;
            }
        }

        // if not holding a ledge, the character is airborne and can get controlled by arrow keys
        if(ledge_info.on_ledge){
            ledge_info.UpdateLedge(hit_wall);
        } else {
            if(!follow_jump_path){
                vec3 target_velocity = GetTargetVelocity();
                this_mo.velocity += time_step * target_velocity * _air_control * num_frames;
            }
        }

        jump_launch -= _jump_launch_decay * time_step * num_frames;
        jump_launch = max(0.0f, jump_launch);
    }

    void StartWallJump(vec3 target_velocity) {
        vec3 old_vel_flat = this_mo.velocity;
        old_vel_flat.y = 0.0f;

        LostWallContact();
        StartFall();

        vec3 jump_vel = GetJumpVelocity(target_velocity);
        this_mo.velocity = jump_vel * 0.5f;
        jetpack_fuel = _jump_fuel;
        jump_launch = 1.0f;
        down_jetpack_fuel = _jump_fuel * 0.5f;
        
        //string sound = "Data/Sounds/Impact-Grass3.wav";
        //PlaySound(sound, this_mo.position );
        //string path = "Data/Sounds/concrete_foley/bunny_jump_concrete.xml";
        //this_mo.PlaySoundGroupAttached(path, this_mo.position);
        this_mo.MaterialEvent("jump",this_mo.position + wall_dir * _leg_sphere_size);
        this_mo.velocity += old_vel_flat;
        tilt = this_mo.velocity * 5.0f;
    }

    void StartJump(vec3 target_velocity, bool follow_path) {
        this_mo.GetSlidingSphereCollision(this_mo.position, _leg_sphere_size);
        this_mo.position = sphere_col.adjusted_position;
        follow_jump_path = follow_path;
        
        StartFall();

        vec3 jump_vel;
        if(follow_path){
            jump_vel = target_velocity;
            target_velocity = vec3(target_velocity.x, 0.0f, target_velocity.z);
        } else {
            jump_vel = GetJumpVelocity(target_velocity);
        }
        this_mo.velocity = jump_vel;
        jetpack_fuel = _jump_fuel;
        jump_launch = 1.0f;
        down_jetpack_fuel = _jump_fuel*0.5f;
        
        //string sound = "Data/Sounds/Impact-Grass3.wav";
        //PlaySound(sound, this_mo.position );
        //string path = "Data/Sounds/concrete_foley/bunny_jump_concrete.xml";
        //this_mo.PlaySoundGroupAttached(path, this_mo.position);
        this_mo.MaterialEvent("jump",this_mo.position - vec3(0.0f, _leg_sphere_size, 0.0f));
        
        if(length(target_velocity)>0.4f){
            this_mo.SetRotationFromFacing(target_velocity);
        }

        left_foot_jump = to_jump_with_left;
        to_jump_with_left = !to_jump_with_left;
    }

    void StartFall() {
        jetpack_fuel = 0.0f;
        jump_launch = 0.0f;
        hit_wall = false;
        has_hit_wall = false;
        flip_info.StartedJump();

        this_mo.SetIKTargetOffset("left_leg",vec3(0.0f));
        this_mo.SetIKTargetOffset("right_leg",vec3(0.0f));
        this_mo.SetIKTargetOffset("full_body",vec3(0.0f));
    }

    // adjusts the velocity of jumps and wall jumps based on ground_normal
    vec3 GetJumpVelocity(vec3 target_velocity){
        vec3 jump_vel = target_velocity * _run_speed;
        jump_vel.y = _jump_vel;

        vec3 jump_dir = normalize(jump_vel);
        if(dot(jump_dir, ground_normal) < 0.3f){
            vec3 ground_up = ground_normal;
            vec3 ground_front = target_velocity;
            if(length_squared(ground_front) == 0){
                ground_front = vec3(0,0,1);
            }
            vec3 ground_right = normalize(flatten(cross(ground_up, ground_front)));
            ground_front = normalize(cross(ground_right, ground_up));
            ground_up = normalize(cross(ground_front,ground_right));

            vec3 ground_space;
            ground_space.x = dot(ground_right, jump_vel);
            ground_space.y = dot(ground_up, jump_vel);
            ground_space.z = dot(ground_front, jump_vel);

            vec3 corrected_ground_space = vec3(0,_jump_vel,length(target_velocity)*_run_speed);
            ground_space = corrected_ground_space;

            jump_vel = ground_space.x * ground_right +
                       ground_space.y * ground_up +
                       ground_space.z * ground_front;
        }

        return jump_vel;
    }
};

JumpInfo jump_info;