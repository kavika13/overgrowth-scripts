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

bool WantsToGrabLedge() {
	return false;
}

bool WantsToJumpOffWall() {
	return false;
}

bool WantsToFlipOffWall() {
	return false;
}

vec3 GetTargetVelocity() {
	//if(distance_squared(this_mo.position, target.position) < 9.0f){
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