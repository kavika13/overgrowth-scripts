#include "ascharmovement.as"

bool limp = false;
bool attacking = false;
float attacking_time;

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
	if(GetInputDown("attack")){
		//vec3 direction = normalize(target.position - this.position);
		attacking = true;
		attacking_time = 0.0;
		/*if(this.HasTarget()){
			target.ApplyForce(direction*20);
		}*/
	}
	if(GetInputDown("crouch")){		
		limp = true;
		this.GoLimp();
		//target_velocity.y -= 1.0;
	} else {
		if(limp == true){
			this.UnRagdoll();
		}
		limp = false;
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
		UpdateVelocity();
		SetAnimationFromVelocity();
		ApplyPhysics();
	} else {
		vec3 direction = normalize(target.position - this.position);
		this.SetRotationFromFacing(direction);
		this.ClearAnimations();
		this.AddAnimation("Data/Animations/kick.anm",1.0);
		attacking_time += time_step;
		if(attacking_time > 0.3){
			target.ApplyForce(direction*20);
		}
		if(attacking_time > 0.6){
			attacking = false;
		}
	}
}

void init() {
	Print("Angelscript initializing!\n");
}