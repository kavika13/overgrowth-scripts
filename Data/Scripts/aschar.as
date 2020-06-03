#include "ascharmovement.as"

bool limp = false;
bool attacking = false;
float attacking_time;

void EndAttack() {
	attacking = false;
}

vec3 GetTargetVelocity() {
	vec3 target_velocity(0.0);
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
	if(GetInputDown("jump")){
		target_velocity.y += 1.0;
	}
	
	if(length_squared(target_velocity)>1){
		target_velocity = normalize(target_velocity);
	}
	
	return target_velocity;
}

void draw() {
	this.DrawBody();
}

void update() {
	if(!attacking){
		if(GetInputDown("attack") && distance_squared(this.position,target.position) < 1.0){
			attacking = true;
			attacking_time = 0.0;
			this.StartAnimation("Data/Animations/kick.anm");
			this.SetAnimationCallback("void EndAttack()");
		}
		if(GetInputDown("crouch")){		
			limp = true;
			this.Ragdoll();
			//target_velocity.y -= 1.0;
		} else {
			if(limp == true){
				this.UnRagdoll();
			}
			limp = false;
		}
	}
	
	if(!attacking){
		UpdateVelocity();
		SetAnimationFromVelocity();
		ApplyPhysics();
	} else {
		velocity *= 0.95;
		vec3 direction = target.position - this.position;
		direction.y = 0.0;
		direction = normalize(direction);
		this.SetRotationFromFacing(direction);
		float old_attacking_time = attacking_time;
		attacking_time += time_step;
		if(attacking_time > 0.25 && old_attacking_time <= 0.25){
			target.ApplyForce(direction*20);
			TimedSlowMotion(0.1,0.7);
		}
	}
}

void init() {
	Print("Angelscript initializing!\n");
}