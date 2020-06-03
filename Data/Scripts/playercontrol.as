#include "aschar.as"

void AIUpdate(){
}

void ActiveBlocked(){
}

bool WantsToCrouch() {
	if(!controlled) return false;
	return GetInputDown("crouch");
}

bool WantsToRoll() {
	if(!controlled) return false;
	return GetInputPressed("crouch");
}

bool WantsToJump() {
	if(!controlled) return false;
	return GetInputDown("jump");
}

bool WantsToAttack() {
	if(!controlled) return false;
	return GetInputDown("attack");
}

bool WantsToRollFromRagdoll(){
	if(!controlled) return false;
	return GetInputPressed("crouch");
}

bool WantsToFlip() {
	if(!controlled) return false;
	return GetInputPressed("crouch");
}

bool WantsToGrabLedge() {
	if(!controlled) return false;
	return GetInputDown("grab");
}

bool WantsToThrowEnemy() {
	if(!controlled) return false;
	return GetInputDown("grab");
}

bool WantsToStartActiveBlock(){
	if(!controlled) return false;
	return GetInputDown("grab");
}

bool WantsToJumpOffWall() {
	if(!controlled) return false;
	return GetInputPressed("jump");
}

bool WantsToFlipOffWall() {
	if(!controlled) return false;
	return GetInputPressed("crouch");
}

bool WantsToAccelerateJump() {
	if(!controlled) return false;
	return GetInputDown("jump");
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
	if(!controlled) return target_velocity;
	
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