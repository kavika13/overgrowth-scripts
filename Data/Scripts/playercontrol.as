#include "aschar.as"

float throw_key_time;
bool listening = false;

void NotifySound(int created_by_id, vec3 pos) {
}

void UpdateBrain(){
    if(GetInputDown("grab")){
        throw_key_time += time_step * num_frames;
    } else {
        throw_key_time = 0.0f;
    }
}

void ResetMind() {
}

int IsIdle() {
    return 0;
}

void HandleAIEvent(AIEvent event){
}

void ReceiveMessage(int source, int msg_type){
}

bool WantsToCrouch() {
    if(!this_mo.controlled) return false;
    return GetInputDown("crouch");
}

bool WantsToRoll() {
    if(!this_mo.controlled) return false;
    return GetInputPressed("crouch");
}

bool WantsToJump() {
    if(!this_mo.controlled) return false;
    return GetInputDown("jump");
}

bool WantsToAttack() {
    if(!this_mo.controlled) return false;
    return GetInputDown("attack");
}

bool WantsToRollFromRagdoll(){
    if(!this_mo.controlled) return false;
    return GetInputPressed("crouch");
}

bool WantsToFlip() {
    if(!this_mo.controlled) return false;
    return GetInputPressed("crouch");
}

bool WantsToGrabLedge() {
    if(!this_mo.controlled) return false;
    if(holding_weapon) return false;
    return GetInputDown("grab");
}

bool WantsToThrowEnemy() {
    if(!this_mo.controlled) return false;
    //if(holding_weapon) return false;
    return throw_key_time > 0.2f;
}

bool WantsToPickUpItem() {
    if(!this_mo.controlled) return false;
    return GetInputDown("item");
}

bool WantsToDropItem() {
    if(!this_mo.controlled) return false;
    return GetInputDown("drop");
}

bool WantsToStartActiveBlock(){
    if(!this_mo.controlled) return false;
    return GetInputPressed("grab");
}

bool WantsToFeint(){
    if(!this_mo.controlled) return false;
    return GetInputDown("grab");
}

bool WantsToCounterThrow(){
    if(!this_mo.controlled) return false;
    return GetInputDown("grab");
}

bool WantsToJumpOffWall() {
    if(!this_mo.controlled) return false;
    return GetInputPressed("jump");
}

bool WantsToFlipOffWall() {
    if(!this_mo.controlled) return false;
    return GetInputPressed("crouch");
}

bool WantsToAccelerateJump() {
    if(!this_mo.controlled) return false;
    return GetInputDown("jump");
}

bool WantsToDodge() {
    if(!this_mo.controlled) return false;

    bool movement_key_down = false;
    if(GetInputDown("move_up") ||
       GetInputDown("move_left") ||
       GetInputDown("move_down") ||
       GetInputDown("move_right"))
    {
        movement_key_down = true;
    }

    return movement_key_down;
}

bool WantsToCancelAnimation() {
    return GetInputDown("jump") || 
           GetInputDown("crouch") ||
           GetInputDown("grab") ||
           GetInputDown("attack") ||
           GetInputDown("move_up") ||
           GetInputDown("move_left") ||
           GetInputDown("move_right") ||
           GetInputDown("move_down");
}

// Converts the keyboard controls into a target velocity that is used for movement calculations in aschar.as and aircontrol.as.
vec3 GetTargetVelocity() {
    vec3 target_velocity(0.0f);
    if(!this_mo.controlled) return target_velocity;
    
    if(GetInputDown("move_up")){
        target_velocity += camera.GetFlatFacing();
    }
    if(GetInputDown("move_right")){
        vec3 temp = camera.GetFlatFacing();
        float side = temp.x;
        temp.x = -temp .z;
        temp.z = side;
        target_velocity += temp;
    }
    if(GetInputDown("move_left")){
        vec3 temp = camera.GetFlatFacing();
        float side = temp.x;
        temp.x = temp .z;
        temp.z = -side;
        target_velocity += temp;
    }
    if(GetInputDown("move_down")){
        target_velocity -= camera.GetFlatFacing();
    }
    if(length_squared(target_velocity)>1){
        target_velocity = normalize(target_velocity);
    }
    
    if(trying_to_get_weapon > 0){
        target_velocity = get_weapon_dir;
    }

    return target_velocity;
}

// Called from aschar.as, bool front tells if the character is standing still. Only characters that are standing still may perform a front kick.
void ChooseAttack(bool front) {
    curr_attack = "";
    if(on_ground){
        if(!WantsToCrouch()){
            if(front){
                curr_attack = "stationary";            
            } else {
                curr_attack = "moving";
            }
        } else {
            curr_attack = "low";
        }    
    } else {
        curr_attack = "air";
    }
}