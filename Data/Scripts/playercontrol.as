#include "aschar.as"
#include "situationawareness.as"

float throw_key_time;
bool listening = false;

Situation situation;

int IsUnaware() {
    return 0;
}

void NotifySound(int created_by_id, float max_dist, vec3 pos) {
}


void UpdateBrain(){
    if(GetInputDown(this_mo.controller_id, "grab")){
        throw_key_time += time_step * num_frames;
    } else {
        throw_key_time = 0.0f;
    }

    array<int> characters;
    GetVisibleCharacters(0, characters);
    for(uint i=0; i<characters.size(); ++i){
        situation.Notice(characters[i]);
    }

    situation.Update();
    force_look_target_id = situation.GetForceLookTarget();
}

void ResetMind() {
    situation.clear();
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
    return GetInputDown(this_mo.controller_id, "crouch");
}

bool WantsToRoll() {
    if(!this_mo.controlled) return false;
    return GetInputPressed(this_mo.controller_id, "crouch");
}

bool WantsToJump() {
    if(!this_mo.controlled) return false;
    return GetInputDown(this_mo.controller_id, "jump");
}

bool WantsToAttack() {
    if(!this_mo.controlled) return false;
    return GetInputDown(this_mo.controller_id, "attack");
}

bool WantsToRollFromRagdoll(){
    if(!this_mo.controlled) return false;
    return GetInputPressed(this_mo.controller_id, "crouch");
}

bool WantsToFlip() {
    if(!this_mo.controlled) return false;
    return GetInputPressed(this_mo.controller_id, "crouch");
}

bool WantsToGrabLedge() {
    if(!this_mo.controlled) return false;
    if(holding_weapon) return false;
    return GetInputDown(this_mo.controller_id, "grab");
}

bool WantsToThrowEnemy() {
    if(!this_mo.controlled) return false;
    //if(holding_weapon) return false;
    return throw_key_time > 0.2f;
}

bool WantsToDragBody() {
    if(!this_mo.controlled) return false;
    return GetInputDown(this_mo.controller_id, "grab");
}

bool WantsToPickUpItem() {
    if(!this_mo.controlled) return false;
    return GetInputDown(this_mo.controller_id, "item");
}

bool WantsToDropItem() {
    if(!this_mo.controlled) return false;
    return GetInputDown(this_mo.controller_id, "drop");
}

bool WantsToStartActiveBlock(){
    if(!this_mo.controlled) return false;
    return GetInputPressed(this_mo.controller_id, "grab");
}

bool WantsToFeint(){
    if(!this_mo.controlled) return false;
    return GetInputDown(this_mo.controller_id, "grab");
}

bool WantsToCounterThrow(){
    if(!this_mo.controlled) return false;
    return GetInputDown(this_mo.controller_id, "grab");
}

bool WantsToJumpOffWall() {
    if(!this_mo.controlled) return false;
    return GetInputPressed(this_mo.controller_id, "jump");
}

bool WantsToFlipOffWall() {
    if(!this_mo.controlled) return false;
    return GetInputPressed(this_mo.controller_id, "crouch");
}

bool WantsToAccelerateJump() {
    if(!this_mo.controlled) return false;
    return GetInputDown(this_mo.controller_id, "jump");
}

bool WantsToDodge() {
    if(!this_mo.controlled) return false;

    bool movement_key_down = false;
    if(length_squared(GetTargetVelocity()) > 0.1f)
    {
        movement_key_down = true;
    }

    return movement_key_down;
}

bool WantsToCancelAnimation() {
    return GetInputDown(this_mo.controller_id, "jump") || 
           GetInputDown(this_mo.controller_id, "crouch") ||
           GetInputDown(this_mo.controller_id, "grab") ||
           GetInputDown(this_mo.controller_id, "attack") ||
           GetInputDown(this_mo.controller_id, "move_up") ||
           GetInputDown(this_mo.controller_id, "move_left") ||
           GetInputDown(this_mo.controller_id, "move_right") ||
           GetInputDown(this_mo.controller_id, "move_down");
}

// Converts the keyboard controls into a target velocity that is used for movement calculations in aschar.as and aircontrol.as.
vec3 GetTargetVelocity() {
    vec3 target_velocity(0.0f);
    if(!this_mo.controlled) return target_velocity;
    
    vec3 right;
    {
        right = camera.GetFlatFacing();
        float side = right.x;
        right.x = -right .z;
        right.z = side;
    }

    target_velocity -= GetMoveYAxis(this_mo.controller_id)*camera.GetFlatFacing();
    target_velocity += GetMoveXAxis(this_mo.controller_id)*right;

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

bool WantsToWalkBackwards() {
    return false;
}

bool WantsReadyStance() {
    return true;
}

int CombatSong() {
    return situation.PlayCombatSong()?1:0;
}

int IsAggressive() {
    return 0;
}