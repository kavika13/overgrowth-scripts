#include "ascharmovement.as"

bool limp = false;
float limp_delay;

vec3 GetTargetVelocity() {
	vec3 target_velocity(0.0);
	
	vec3 direction = target.position - this.position;
	direction.y = 0;
	float speed = length(direction);
	direction = normalize(direction);
	
	speed = min(1.0,max(0.0,speed - 1.0));
	
	target_velocity = direction * speed * 0.9;
	
	return target_velocity;
}

void draw() {
	this.DrawBody();
}

void ForceApplied(vec3 force) {
	if(!limp){
		PlaySound("Data/Sounds/Revolver.wav", this.position);
		velocity += force;
		this.GoLimp();
		velocity -= force;		
		limp = true;
		limp_delay = 1.0;
	}
}

void update() {	
	if(!limp){
		UpdateVelocity();
		SetAnimationFromVelocity();
		ApplyPhysics();
	} else {
		limp_delay -= time_step;
		if(limp_delay <= 0){
			limp = false;
			this.position = this.GetAvgPosition();
			velocity = this.GetAvgVelocity();
			this.ResolveCollisions();
		}
	}
}

void init() {
	Print("Angelscript initializing!\n");
}