#include "aschar.as"

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