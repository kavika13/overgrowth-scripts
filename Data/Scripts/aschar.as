#include "ascharmovement.as"

int count = 0;
bool limp = false;

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
	if(GetInputDown("crouch")){		
		limp = true;
		this.GoLimp();
		//target_velocity.y -= 1.0;
	} else {
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
	count++;
	Print("Angelscript updating! Count = "+count+"\n");
	
	SetAnimationFromVelocity();
	UpdateVelocity();
	ApplyPhysics();
}

void init() {
	Print("Angelscript initializing!\n");
}