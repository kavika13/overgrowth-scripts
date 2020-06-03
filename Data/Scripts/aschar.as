#include "interpdirection.as"

bool limp = false;

float air_time = 0.0f;
bool attacking = false;
float attacking_time;

bool pre_jump = false;
float pre_jump_time;
const float _pre_jump_delay = 0.04f;

bool on_ground = false;
float on_ground_time = 0.0f;
float no_collide_time = 0.0f;
const float _off_ground_delay = 0.1f;

vec3 tilt(0.0f);
vec3 target_tilt(0.0f);
const float _tilt_inertia = 0.9f;

const float _duck_speed_mult = 0.5f;

const float _ground_normal_y_threshold = 0.7f;
const float _leg_sphere_size = 0.45f;
const float _bumper_size = 0.5f;

const float _run_speed = 8.0f;
float max_speed = _run_speed;

const float _tilt_transition_vel = 8.0f;

vec3 ground_normal(0,1,0);

bool feet_moving = false;

int run_phase = 1;

const float _run_threshold = 0.8f;
const float _walk_threshold = 0.6f;
const float _walk_accel = 35.0f;
float duck_amount = 0.0f;
float target_duck_amount = 0.0f;
float duck_vel = 0.0f;
const float _duck_accel = 120.0f;
const float _duck_vel_inertia = 0.89f;

const float _roll_speed = 2.0f;
const float _roll_accel = 50.0f;
const float _ragdoll_recovery_time = 5.0f;
const float _roll_ground_speed = 12.0f;
float recovery_time;
vec3 roll_direction;

vec3 com_offset;
vec3 com_offset_vel;

void EndAttack() {
	attacking = false;
}

void HandleAnimationEvent(string event, vec3 pos){
	Print("Angelscript received event: "+event+"\n");
	vec3 world_pos = pos+this_mo.position;
	if(event == "leftstep" || event == "rightstep"){
		this_mo.MaterialEvent(event, world_pos);
	}
}

#include "aircontrols.as"

vec3 flatten(vec3 vec){
	return vec3(vec.x,0.0,vec.z);
}

vec3 WorldToGroundSpace(vec3 world_space_vec){
	vec3 right = normalize(cross(ground_normal,vec3(0,0,1)));
	vec3 front = normalize(cross(right,ground_normal));
	vec3 ground_space_vec = right * world_space_vec.x +
							front * world_space_vec.z +
							ground_normal * world_space_vec.y;
	return ground_space_vec;
}

void UpdateGroundMovementControls() {
	vec3 target_velocity = GetTargetVelocity();
	if(length_squared(target_velocity)>0.0f){
		feet_moving = true;
	}

	if(WantsToCrouch()){
		target_duck_amount = 1.0f;
	} else {
		target_duck_amount = 0.0f;
	}
	
	if(WantsToRoll() && length_squared(target_velocity)>0.2f){
		if(!flip_info.IsFlipping()){
			flip_info.StartRoll(target_velocity);
		}
	}

	if(WantsToJump() && 
	   on_ground_time > _jump_threshold_time && 
	   !pre_jump)
	{
		pre_jump = true;
		pre_jump_time = _pre_jump_delay;
		duck_vel = 30.0f * (1.0f-duck_amount * 0.6f);

		vec3 target_jump_vel = jump_info.GetJumpVelocity(target_velocity);
		target_tilt = vec3(target_jump_vel.x, 0, target_jump_vel.z)*2.0f;
	}

	if(pre_jump){
		if(pre_jump_time <= 0.0f && !flip_info.IsFlipping()){
			jump_info.StartJump(target_velocity);
			SetOnGround(false);
			pre_jump = false;
		} else {
			pre_jump_time -= time_step;
		}
	}
	
	vec3 adjusted_vel = WorldToGroundSpace(target_velocity);

	// Adjust speed based on ground slope
	max_speed = _run_speed;
	if(adjusted_vel.y>0.0){
		max_speed *= 1.0 - adjusted_vel.y;
	} else if(adjusted_vel.y<0.0){
		max_speed *= 1.0 - adjusted_vel.y;
	}

	float speed = _walk_accel * run_phase;
	speed = mix(speed,speed*_duck_speed_mult,duck_amount);
	this_mo.velocity += adjusted_vel * time_step * speed;
}

void draw() {
	this_mo.DrawBody();
}

void ForceApplied(vec3 force) {
}

void UpdateGroundAttackControls() {
	/*if(WantsToAttack() && distance_squared(this_mo.position,target.position) < 1.0){
		attacking = true;
		attacking_time = 0.0;
		this_mo.StartAnimation("Data/Animations/kick.anm");
		this_mo.SetAnimationCallback("void EndAttack()");
	}*/
}

void UpdateGroundControls() {
	UpdateGroundAttackControls();
	UpdateGroundMovementControls();
}

void UpdateMovementControls() {
	if(on_ground){ 
		target_tilt = vec3(0.0f);
		if(!flip_info.HasControl()){
			UpdateGroundControls();
		}
		flip_info.UpdateRoll();
	} else {
		jump_info.UpdateAirControls();
		flip_info.UpdateFlip();
		
		target_tilt = vec3(this_mo.velocity.x, 0, this_mo.velocity.z)*2.0f;
		if(abs(this_mo.velocity.y)<_tilt_transition_vel && !flip_info.HasFlipped()){
			target_tilt *= pow(abs(this_mo.velocity.y)/_tilt_transition_vel,0.5);
		}
		if(this_mo.velocity.y<0.0f || flip_info.HasFlipped()){
			target_tilt *= -1.0f;
		}
	}
	
	tilt = tilt * _tilt_inertia +
		   target_tilt * (1.0f - _tilt_inertia);

	this_mo.SetTilt(tilt);
}

void SetOnGround(bool _on_ground){
	on_ground_time = 0.0f;
	air_time = 0.0f;
	on_ground = _on_ground;
}

void Land(vec3 vel) {
	if(flip_info.ShouldRagdollOnLanding()){
		GoLimp();
	}

	if(!limp){
		string sound = "Data/Sounds/Impact-Grass2.wav";
		PlaySound(sound, this_mo.position);
	}
	SetOnGround(true);

	
	float land_speed = 10.0f;//min(30.0f,max(10.0f, -vel.y));
	this_mo.SetAnimation("Data/Animations/idle.xml",land_speed);
	
	duck_amount = 1.0;
	target_duck_amount = 1.0;
	duck_vel = land_speed * 0.3f;
	if(WantsToCrouch()){
		duck_vel = max(6.0f,duck_vel);
	}

	feet_moving = false;

	flip_info.Land();
}

const float offset = 0.05f;

void HandleGroundCollision() {
	vec3 air_vel = this_mo.velocity;
	if(on_ground){
		this_mo.position.y -= offset;
		this_mo.GetSlidingSphereCollision(this_mo.position+vec3(0,0.3f,0), _bumper_size);
		this_mo.position = sphere_col.adjusted_position-vec3(0,0.3f,0);
		this_mo.velocity += (sphere_col.adjusted_position - sphere_col.position) / time_step;

		if(sphere_col.NumContacts() != 0 && flip_info.ShouldRagdollIntoWall()){
			GoLimp();	
		}

		vec3 upper_pos = this_mo.position+vec3(0,0.1f,0);
		vec3 lower_pos = this_mo.position+vec3(0,-0.1f,0);
		this_mo.GetSweptSphereCollision(upper_pos,
									 lower_pos,
									 _leg_sphere_size);
		if(sphere_col.position == lower_pos){
			SetOnGround(false);
		} else {
			for(int i=0; i<sphere_col.NumContacts(); i++){
				const CollisionPoint contact = sphere_col.GetContact(i);
				ground_normal = ground_normal * 0.9f +
								contact.normal * 0.1f;
				ground_normal = normalize(ground_normal);
			}
			this_mo.position = sphere_col.position;

			
			if(flip_info.ShouldRagdollIntoSteepGround() &&
			   dot(this_mo.GetFacing(),ground_normal) < -0.6f){
				GoLimp();	
			}
		}
		this_mo.position.y += offset;
	} else {
		this_mo.GetSlidingSphereCollision(this_mo.position, _leg_sphere_size);
		this_mo.position = sphere_col.adjusted_position;
		this_mo.velocity += (sphere_col.adjusted_position - sphere_col.position) / time_step;
		if(sphere_col.NumContacts() != 0 && flip_info.IsFlipping()){
			GoLimp();	
		}
	}

	for(int i=0; i<sphere_col.NumContacts(); i++){
		const CollisionPoint contact = sphere_col.GetContact(i);
		if(contact.normal.y > _ground_normal_y_threshold){
			if(!on_ground && air_time > 0.1f){
				Land(air_vel);
				ground_normal = contact.normal;
			}
			no_collide_time = 0;
			ground_normal = ground_normal * 0.9f +
							contact.normal * 0.1f;
			ground_normal = normalize(ground_normal);
		}
	}
}

void GoLimp() {
	limp = true;
	this_mo.Ragdoll();
	recovery_time = _ragdoll_recovery_time;
	pose_handler.clear();
	pose_handler.AddLayer("Data/Animations/run.pos",
						  0.000f,
						  false);
	//pose_handler.AddLayer("Data/Animations/test.pos",
	//					  1.0f,
	//					  false);
}

void UpdateDuckAmount() {
	duck_vel += (target_duck_amount - duck_amount) * time_step * _duck_accel;
	duck_amount += duck_vel * time_step;
	duck_vel *= _duck_vel_inertia;
}

void UpdateGroundAndAirTime() {
	if(on_ground){
		on_ground_time += time_step;
	} else {
		air_time += time_step;
	}
}

void UpdateAirWhooshSound() {
	float whoosh_amount = length(this_mo.velocity)*0.05f;
	if(!limp){
		whoosh_amount += flip_info.WhooshAmount();
	}
	float whoosh_pitch = min(2.0f,whoosh_amount*0.5f + 0.5f);
	if(!on_ground){
		whoosh_amount *= 1.5f;
	}
	SetAirWhoosh(whoosh_amount,whoosh_pitch);
}

void UpdateAttacking() {
	this_mo.velocity *= 0.95f;
	vec3 direction = target.position - this_mo.position;
	direction.y = 0.0f;
	direction = normalize(direction);
	this_mo.SetRotationFromFacing(direction);
	float old_attacking_time = attacking_time;
	attacking_time += time_step;
	if(attacking_time > 0.25f && old_attacking_time <= 0.25f){
		target.ApplyForce(direction*20);
		TimedSlowMotion(0.1f,0.7f);
	}
}

const int _wake_stand = 0;
const int _wake_flip = 1;
const int _wake_roll = 2;

void WakeUp(int how) {
	this_mo.UnRagdoll();
	this_mo.GetSlidingSphereCollision(this_mo.position, _leg_sphere_size);
	this_mo.position = sphere_col.adjusted_position;
	limp = false;
	duck_amount = 1.0f;
	duck_vel = 0.0f;
	target_duck_amount = 1.0f;
	if(how == _wake_stand){
		SetOnGround(true);
		flip_info.Land();
		this_mo.StartAnimation("Data/Animations/idle.xml");
	} else if (how == _wake_flip) {
		SetOnGround(false);
		flip_info.StartFlip();
		flip_info.FlipRecover();
		this_mo.StartAnimation("Data/Animations/jump.xml");
	} else if (how == _wake_roll) {
		SetOnGround(true);
		this_mo.StartAnimation("Data/Animations/idle.xml");
		vec3 roll_dir = GetTargetVelocity();
		vec3 flat_vel = vec3(this_mo.velocity.x, 0.0f, this_mo.velocity.z);
		if(length(flat_vel)>1.0f){
			roll_dir = normalize(flat_vel);
		}
		flip_info.StartRoll(roll_dir);
	}
}

void UpdateRagDoll() {
	if(GetInputDown("z")){		
		GoLimp();
	}
	if(limp == true){
		recovery_time -= time_step;
		if(recovery_time < 0.0f){
			WakeUp(_wake_stand);
		} else {
			if(WantsToRollFromRagdoll()){
				vec3 sphere_center = this_mo.position;
				float radius = 1.0f;
				this_mo.GetSlidingSphereCollision(sphere_center, radius);
				bool can_roll = true;
				vec3 roll_point;
				if(sphere_col.NumContacts() == 0){
					can_roll = false;
				} else {
					can_roll = false;
					roll_point = sphere_col.GetContact(0).position;
					for(int i=0; i<sphere_col.NumContacts(); i++){
						const CollisionPoint contact = sphere_col.GetContact(i);
						if(contact.position.y < roll_point.y){
							roll_point = contact.position;
						}
						if(contact.normal.y > 0.5f){
							can_roll = true;
						}
					}
				}
				if(!can_roll){
					WakeUp(_wake_flip);
				} else {
					WakeUp(_wake_roll);
					this_mo.position = roll_point + 
									   vec3(0.0f,_leg_sphere_size,0.0f);
				}
			}
			return;
		}
	}
}

void update() {
	UpdateAirWhooshSound();
	UpdateRagDoll();
	UpdateDuckAmount();
	UpdateGroundAndAirTime();

	if(!attacking){ 
		UpdateMovementControls();
		UpdateAnimation();
		ApplyPhysics();
	} else {
		UpdateAttacking();
	}
	
	HandleGroundCollision();
}

void init() {
}

void UpdateAnimation() {
	vec3 flat_velocity = vec3(this_mo.velocity.x,0,this_mo.velocity.z);

	float run_amount, walk_amount, idle_amount;
	float speed = length(flat_velocity);
	
	this_mo.SetBlendCoord("tall_coord",1.0f-duck_amount);
	
	if(on_ground){
		if(flip_info.UseRollAnimation()){
			this_mo.SetAnimation("Data/Animations/roll.xml",7.0f);
			float forwards_rollness = 1.0f-abs(dot(flip_info.GetAxis(),this_mo.GetFacing()));
			this_mo.SetBlendCoord("forward_roll_coord",forwards_rollness);
			this_mo.SetIKEnabled(false);
		} else {
			this_mo.SetIKEnabled(true);
			if(speed > _walk_threshold && feet_moving){
				this_mo.SetRotationFromFacing(InterpDirections(this_mo.GetFacing(),
															   normalize(flat_velocity),
															   0.3f));
				this_mo.SetAnimation("Data/Animations/movement.xml");
				this_mo.SetBlendCoord("speed_coord",speed);
				this_mo.SetBlendCoord("ground_speed",speed);
			} else {
				this_mo.SetAnimation("Data/Animations/idle.xml");
				this_mo.SetIKEnabled(true);
			}
		}
	} else {
		jump_info.UpdateAirAnimation();
	}

	this_mo.SetCOMOffset(com_offset, com_offset_vel);
}

void UpdateVelocity() {
	this_mo.velocity += GetTargetVelocity() * time_step * _walk_accel;
}

void ApplyPhysics() {
	if(!on_ground){
		this_mo.velocity += physics.gravity_vector * time_step;
	}
	if(on_ground){
		if(feet_moving){
			const float e = 2.71828183f;
			float exp = _walk_accel*time_step*-1/max_speed;
			float current_movement_friction = pow(e,exp);
			this_mo.velocity *= current_movement_friction;
		} else {
			this_mo.velocity *= 0.95f;
		}
	}
}