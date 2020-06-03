#include "aschar.as"

bool WantsToCrouch() {
	return GetInputDown("crouch");
}

bool WantsToRoll() {
	return GetInputPressed("crouch");
}

bool WantsToJump() {
	return GetInputDown("jump");
}

bool WantsToAttack() {
	return GetInputDown("attack");
}

bool WantsToRollFromRagdoll(){
	return GetInputPressed("crouch");
}

bool WantsToFlip() {
	return GetInputPressed("crouch");
}

bool WantsToGrabLedge() {
	return GetInputDown("grab");
}

bool WantsToJumpOffWall() {
	return GetInputPressed("jump");
}

bool WantsToFlipOffWall() {
	return GetInputPressed("crouch");
}

bool WantsToAccelerateJump() {
	return GetInputDown("jump");
}

vec3 GetTargetVelocity() {
	vec3 target_velocity(0.0f);
	
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