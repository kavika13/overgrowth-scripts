#include "ascharmovement.as"

int count = 0;
bool limp = false;

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