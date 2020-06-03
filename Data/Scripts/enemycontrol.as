#include "aschar.as"

bool WantsToCrouch() {
	return false;
}

bool WantsToRoll() {
	return false;
}

bool WantsToJump() {
	return false;
}

bool WantsToAttack() {
	return false;
}

bool WantsToRollFromRagdoll(){
	return false;
}

bool WantsToFlip() {
	return false;
}

bool WantsToAccelerateJump() {
	return false;
}

vec3 GetTargetVelocity() {
	vec3 target_velocity;
	target_velocity = target.position - this_mo.position;
	target_velocity.y = 0.0;
	float dist = length(target_velocity);
	float seek_dist = 3.0;
	dist = max(0.0, dist-seek_dist);
	target_velocity = normalize(target_velocity) * dist;
	if(length_squared(target_velocity) > 1.0){
		target_velocity = normalize(target_velocity);
	}

	return target_velocity;
}