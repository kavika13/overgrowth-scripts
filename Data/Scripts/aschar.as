#include "ascharmovement.as"

const float _duck_inertia = 0.95f;
const float _air_control = 3.0f;

bool limp = false;
bool attacking = false;
float attacking_time;
float jetpack_fuel = 0.0;

const float _jump_vel = 5.0;
const float _jump_fuel = 5.0;
const float _jump_fuel_burn = 10.0;
const float _duck_speed_mult = 0.5;

const float _tilt_transition_vel = 4.0f;

void EndAttack() {
	attacking = false;
}

void HandleAnimationEvent(string event, vec3 pos){
	Print("Angelscript received event: "+event+"\n");
	vec3 world_pos = pos+this.position;
	if(event == "leftstep" || event == "rightstep"){
		this.MaterialEvent(event, world_pos);
	}
}

void HandleAirControls() {
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
	if(length_squared(target_velocity)>1){
		target_velocity = normalize(target_velocity);
	}
	
	if(GetInputDown("jump")){
		if(jetpack_fuel > 0.0 && this.velocity.y > 0.0) {
			jetpack_fuel -= time_step * _jump_fuel_burn;
			this.velocity.y += time_step * _jump_fuel_burn;
		}
	}
	
	duck_amount = 1.0;
	
	this.velocity += time_step * target_velocity * _air_control;
}

vec3 GetTargetVelocity() {
	vec3 target_velocity(0.0);
	
	if(GetInputDown("crouch")){
		duck_amount = 1.0 * (1.0 - _duck_inertia) +
					   duck_amount * _duck_inertia;
	} else {
		duck_amount = 0.0 * (1.0 - _duck_inertia) +
					  duck_amount * _duck_inertia;
	}
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
		this.on_ground = false;
		
		const float _walk_speed = _walk_accel * time_step * -1 / log(_inertia);
		this.velocity = target_velocity * _walk_speed;
		this.velocity.y = _jump_vel;
		jetpack_fuel = _jump_fuel;
	}
	
	if(length_squared(target_velocity)>1){
		target_velocity = normalize(target_velocity);
	}
	
	return target_velocity;
}

void draw() {
	this.DrawBody();
}

void HandleGroundAttackControls() {
	if(GetInputDown("attack") && distance_squared(this.position,target.position) < 1.0){
		attacking = true;
		attacking_time = 0.0;
		this.StartAnimation("Data/Animations/kick.anm");
		this.SetAnimationCallback("void EndAttack()");
	}
}

void HandleGroundControls() {
	if(!attacking){
		HandleGroundAttackControls();
	}
}

void update() {
	if(this.on_ground){ 
		HandleGroundControls();
		this.velocity += GetTargetVelocity() * time_step * _walk_accel * (1.0f * (1.0f - duck_amount) + duck_amount * _duck_speed_mult);
		this.SetTilt(vec3(0.0f));
	} else {
		HandleAirControls();
		
		vec3 tilt = vec3(this.velocity.x, 0, this.velocity.z)*2.0f;
		if(abs(this.velocity.y)<_tilt_transition_vel){
			tilt *= abs(this.velocity.y)/_tilt_transition_vel;
		}
		if(this.velocity.y<0.0f){
			tilt *= -1.0f;
		}
		this.SetTilt(tilt);
	}
	
	if(!attacking){ 
		SetAnimationFromVelocity();
		ApplyPhysics();
	}
	
	if(GetInputDown("z")){		
		limp = true;
		this.Ragdoll();
		//target_velocity.y -= 1.0;
	} else {
		if(limp == true){
			this.UnRagdoll();
		}
		limp = false;
	}

	
	if(attacking){
		this.velocity *= 0.95f;
		vec3 direction = target.position - this.position;
		direction.y = 0.0f;
		direction = normalize(direction);
		this.SetRotationFromFacing(direction);
		float old_attacking_time = attacking_time;
		attacking_time += time_step;
		if(attacking_time > 0.25f && old_attacking_time <= 0.25f){
			target.ApplyForce(direction*20);
			TimedSlowMotion(0.1f,0.7f);
		}
	}
}

void init() {
	Print("Angelscript initializing!\n");
}