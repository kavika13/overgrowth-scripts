#include "aschar.as"

bool hostile = false;
bool ai_attacking = false;
bool hostile_switchable = true;

void AIUpdate(){
	if(GetInputDown("c")){
		if(hostile_switchable){
			hostile = !hostile;
		}
		hostile_switchable = false;
	} else {
		hostile_switchable = true;
	}
	if(hostile && rand()%150==0){
		ai_attacking = !ai_attacking;
	}
	if(!hostile){
		ai_attacking = false;
	}
}

void ActiveBlocked(){
	ai_attacking = true;
}

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

vec3 GetTargetVelocity() {
	if(target_id == -1){
		return vec3(0.0f);
	}
	//if(distance_squared(this_mo.position, target.position) < 9.0f){
		vec3 target_velocity;
		target_velocity = this_mo.ReadCharacter(target_id).position - this_mo.position;
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