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

vec3 tilt(0.0f);
vec3 target_tilt(0.0f);
const float _tilt_inertia = 0.9f;

const float _duck_speed_mult = 0.5f;

const float _ground_normal_y_threshold = 0.5f;
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
const float _ragdoll_recovery_time = 1.0f;
const float _roll_ground_speed = 12.0f;
float recovery_time;
vec3 roll_direction;

bool controlled = false;

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
	
	vec3 flat_ground_normal = ground_normal;
	flat_ground_normal.y = 0.0f;
	float flat_ground_length = length(flat_ground_normal);
	flat_ground_normal = normalize(flat_ground_normal);
	if(flat_ground_length > 0.9f){
		if(dot(target_velocity, flat_ground_normal)<0.0f){
			target_velocity -= dot(target_velocity, flat_ground_normal) *
							   flat_ground_normal;
		}
	}
	if(flat_ground_length > 0.6f){
		if(dot(this_mo.velocity, flat_ground_normal)>-0.8f){
			target_velocity -= dot(target_velocity, flat_ground_normal) *
							   flat_ground_normal;
			target_velocity += flat_ground_normal * flat_ground_length;
			feet_moving = true;
		}
		if(length(target_velocity)>1.0f){
			target_velocity = normalize(target_velocity);
		}
	}

	vec3 adjusted_vel = WorldToGroundSpace(target_velocity);

	// Adjust speed based on ground slope
	max_speed = _run_speed;
	float curr_speed = length(this_mo.velocity);
	if(adjusted_vel.y>0.0){
		max_speed *= 1.0 - adjusted_vel.y;
	} else if(adjusted_vel.y<0.0){
		max_speed *= 1.0 - adjusted_vel.y;
	}
	max_speed = max(curr_speed * 0.98f, max_speed);

	float speed = _walk_accel * run_phase;
	speed = mix(speed,speed*_duck_speed_mult,duck_amount);
	this_mo.velocity += adjusted_vel * time_step * speed;

}

void DrawIKTarget(string str) {
	vec3 pos = this_mo.GetIKTargetPosition(str);
	DebugDrawWireSphere(pos,
						0.1f,
						vec3(1.0f),
						_delete_on_draw);
}


void MoveIKTarget(string str, vec3 offset) {
	vec3 pos = this_mo.GetIKTargetPosition(str);
	DebugDrawLine(pos,
				  pos+offset,
				  vec3(1.0f),
				  _delete_on_draw);
	this_mo.SetIKTargetOffset(str, offset);

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
		if(jump_info.ClimbedUp()){
			SetOnGround(true);
			duck_amount = 1.0f;
			duck_vel = 2.0f;
			target_duck_amount = 1.0f;
			this_mo.StartAnimation("Data/Animations/idle.xml",20.0f);
			HandleBumperCollision();
			HandleStandingCollision();
			this_mo.position = sphere_col.position;
			this_mo.velocity = vec3(0.0f);
			feet_moving = false;
		} else {
			flip_info.UpdateFlip();
			
			target_tilt = vec3(this_mo.velocity.x, 0, this_mo.velocity.z)*2.0f;
			if(abs(this_mo.velocity.y)<_tilt_transition_vel && !flip_info.HasFlipped()){
				target_tilt *= pow(abs(this_mo.velocity.y)/_tilt_transition_vel,0.5);
			}
			if(this_mo.velocity.y<0.0f || flip_info.HasFlipped()){
				target_tilt *= -1.0f;
			}
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
		return;
	}

	SetOnGround(true);
	
	float land_speed = 10.0f;//min(30.0f,max(10.0f, -vel.y));
	this_mo.SetAnimation("Data/Animations/idle.xml",land_speed);
	
	if(dot(this_mo.velocity*-1.0f, ground_normal)>0.3f){
		string sound = "Data/Sounds/Impact-Grass2.wav";
		PlaySound(sound, this_mo.position);
		duck_amount = 1.0;
		target_duck_amount = 1.0;
		duck_vel = land_speed * 0.3f;
	}

	if(WantsToCrouch()){
		duck_vel = max(6.0f,duck_vel);
	}

	feet_moving = false;

	flip_info.Land();
}

const float offset = 0.05f;

vec3 HandleBumperCollision(){
	this_mo.GetSlidingSphereCollision(this_mo.position+vec3(0,0.3f,0), _bumper_size);
	this_mo.position = sphere_col.adjusted_position-vec3(0,0.3f,0);
	return (sphere_col.adjusted_position - sphere_col.position);
}

bool HandleStandingCollision() {
	vec3 upper_pos = this_mo.position+vec3(0,0.1f,0);
	vec3 lower_pos = this_mo.position+vec3(0,-0.2f,0);
	this_mo.GetSweptSphereCollision(upper_pos,
								 lower_pos,
								 _leg_sphere_size);
	return (sphere_col.position == lower_pos);
}

void HandleGroundCollision() {
	/*vec3 ground_vel;
	if(on_ground) {
		vec3 y_vec = ground_normal;
		vec3 x_vec = normalize(cross(y_vec,vec3(0,0,1)));
		vec3 z_vec = cross(y_vec, x_vec);
		ground_vel = vec3(dot(x_vec, this_mo.velocity),
						  dot(y_vec, this_mo.velocity),
						  dot(z_vec, this_mo.velocity));
	}*/

	vec3 air_vel = this_mo.velocity;
	if(on_ground){
		this_mo.velocity += HandleBumperCollision() / time_step;

		if(sphere_col.NumContacts() != 0 && flip_info.ShouldRagdollIntoWall()){
			GoLimp();	
		}

		if((sphere_col.NumContacts() != 0 ||
			ground_normal.y < _ground_normal_y_threshold)
			&& this_mo.velocity.y > 0.2f){
			SetOnGround(false);
			jump_info.StartFall();
		}

		bool in_air = HandleStandingCollision();
		if(in_air){
			SetOnGround(false);
			jump_info.StartFall();
		} else {
			this_mo.position = sphere_col.position;
			/*DebugDrawWireSphere(sphere_col.position,
								sphere_col.radius,
								vec3(1.0f,0.0f,0.0f),
								_delete_on_update);*/
			for(int i=0; i<sphere_col.NumContacts(); i++){
				const CollisionPoint contact = sphere_col.GetContact(i);
				if(distance(contact.position, this_mo.position)<=_leg_sphere_size+0.01f){
					ground_normal = ground_normal * 0.9f +
									contact.normal * 0.1f;
					ground_normal = normalize(ground_normal);
					/*DebugDrawLine(sphere_col.position,
								  sphere_col.position-contact.normal,
								  vec3(1.0f,0.0f,0.0f),
								  _delete_on_update);*/
				}
			}/*
			DebugDrawLine(sphere_col.position,
							  sphere_col.position-ground_normal,
							  vec3(0.0f,1.0f,0.0f),
							  _delete_on_update);
			*/
			
			if(flip_info.ShouldRagdollIntoSteepGround() &&
			   dot(this_mo.GetFacing(),ground_normal) < -0.6f){
				GoLimp();	
			}
		}
	} else {
		this_mo.GetSlidingSphereCollision(this_mo.position, _leg_sphere_size);
		this_mo.position = sphere_col.adjusted_position;
		this_mo.velocity += (sphere_col.adjusted_position - sphere_col.position) / time_step;
		for(int i=0; i<sphere_col.NumContacts(); i++){
			const CollisionPoint contact = sphere_col.GetContact(i);
			if(contact.normal.y < _ground_normal_y_threshold){
				jump_info.HitWall(normalize(contact.position-this_mo.position));
			}
		}	
			
		if(sphere_col.NumContacts() != 0 && flip_info.RagdollOnImpact()){
			GoLimp();	
		}
		
		for(int i=0; i<sphere_col.NumContacts(); i++){
			const CollisionPoint contact = sphere_col.GetContact(i);
			if(contact.normal.y > _ground_normal_y_threshold ||
			   (this_mo.velocity.y < 0.0f && contact.normal.y > 0.2f)){
				if(air_time > 0.1f){
					ground_normal = contact.normal;
					Land(air_vel);
				}
			}
		}
	}
/*
	if(on_ground){
		vec3 y_vec = ground_normal;
		vec3 x_vec = normalize(cross(y_vec,vec3(0,0,1)));
		vec3 z_vec = cross(y_vec, x_vec);
		this_mo.velocity = x_vec * ground_vel.x +
						   y_vec * ground_vel.y +
						   z_vec * ground_vel.z;
	}*/
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
	
	HandleBumperCollision();
	HandleStandingCollision();
	this_mo.position = sphere_col.position;

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
		jump_info.StartFall();
		flip_info.StartFlip();
		flip_info.FlipRecover();
		this_mo.StartAnimation("Data/Animations/jump.xml");
	} else if (how == _wake_roll) {
		SetOnGround(true);
		flip_info.Land();
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
					//this_mo.position = roll_point + 
					//z				   vec3(0.0f,_leg_sphere_size,0.0f);
				}
			}
			return;
		}
	}
}


bool testing_mocap = false;
void TestMocap(){
	this_mo.SetAnimation("Data/Animations/mocapsit.anm");
	this_mo.SetAnimationCallback("void EndTestMocap()");
	testing_mocap = true;
	this_mo.velocity = vec3(0.0f);
	this_mo.position += vec3(0.0f,-0.1f,0.0f);
	this_mo.position = vec3(16.23, 109.45, 11.71);
	this_mo.SetRotationFromFacing(vec3(0.0f,0.0f,1.0f));
}

void EndTestMocap() {
	testing_mocap = false;
}

int count = 0;

void update(bool _controlled) {
	if(testing_mocap) {
		this_mo.cam_rotation += 0.05f;
		return;
	}
	controlled = _controlled;

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

	if(GetInputPressed("x")){
		NavPath temp = this_mo.GetPath(this_mo.position,
										target.position);
		int num_points = temp.NumPoints();
		for(int i=0; i<num_points-1; i++){
			DebugDrawLine(temp.GetPoint(i),
						  temp.GetPoint(i+1),
						  vec3(1.0f,1.0f,1.0f),
						  _persistent);
		}
	}

	if(GetInputPressed("c")){
//		TestMocap();
	}

	/*count++;
	if(count % 300 == 0){
		Print(""+this_mo.position.x + ", "+
			     this_mo.position.y + ", "+
				 this_mo.position.z + "\n");
	}*/
/*
	vec3 dimensions(1.0f,1.0f,1.0f);
	this_mo.GetSlidingScaledSphereCollision(this_mo.position,
							  1.0f,
							  dimensions);

	DebugDrawWireScaledSphere(this_mo.position,
						1.0f,
						dimensions,
						vec3(1.0f,0.0f,0.0f),
						_delete_on_update);

	vec3 slid = sphere_col.adjusted_position;
	vec3 new_pos = ApplyScaledSphereSlide(this_mo.position,
									1.0f,
									dimensions);
	DebugDrawWireScaledSphere(new_pos,
						1.0f,
						dimensions,
						vec3(1.0f,1.0f,1.0f),
						_delete_on_update);*/

	//this_mo.velocity += (new_pos-this_mo.position)/time_step;
	//this_mo.position = new_pos;
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

const float _check_up = 1.0f;
const float _check_down = -1.0f;
	
vec3 GetLegTargetOffset(vec3 initial_pos){
	/*DebugDrawLine(initial_pos + vec3(0.0f,_check_up,0.0f),
				  initial_pos + vec3(0.0f,_check_down,0.0f),
				  vec3(1.0f),
				  _delete_on_draw);*/
	this_mo.GetSweptSphereCollision(initial_pos + vec3(0.0f,_check_up,0.0f),
								    initial_pos + vec3(0.0f,_check_down,0.0f),
								    0.05f);

	if(sphere_col.NumContacts() == 0){
		return vec3(0.0f);
	}

	float target_y_pos = sphere_col.position.y;
	float height = initial_pos.y - this_mo.position.y + _leg_sphere_size;
	target_y_pos += height;
	/*DebugDrawWireSphere(sphere_col.position,
				  0.05f,
				  vec3(1.0f),
				  _delete_on_draw);*/
	
	float offset_amount = target_y_pos - initial_pos.y;
	offset_amount /= max(0.0f,height)+1.0f;

	offset_amount = max(-0.15f,min(0.15f,offset_amount));

	return vec3(0.0,offset_amount, 0.0f);
}

float offset_height = 0.0f;

void UpdateIKTargets() {
	if(!on_ground){
		jump_info.UpdateIKTargets();
	} else {
		vec3 left_leg = this_mo.GetIKTargetPosition("left_leg");
		vec3 left_leg_offset = GetLegTargetOffset(left_leg);
		this_mo.SetIKTargetOffset("left_leg",left_leg_offset);

		vec3 right_leg = this_mo.GetIKTargetPosition("right_leg");
		vec3 right_leg_offset = GetLegTargetOffset(right_leg);
		this_mo.SetIKTargetOffset("right_leg",right_leg_offset);

		//float curr_avg_offset_height = min(0.0f,
		//						  min(left_leg_offset.y, right_leg_offset.y));
		float avg_offset_height = (left_leg_offset.y + right_leg_offset.y) * 0.5f;
		float min_offset_height = min(0.0f, min(left_leg_offset.y, right_leg_offset.y));
		float mix_amount = min(1.0f,length(this_mo.velocity));
		float curr_offset_height = mix(min_offset_height, avg_offset_height,mix_amount);
		offset_height = mix(offset_height, curr_offset_height, 0.1f);
		this_mo.SetIKTargetOffset("full_body", vec3(0.0f,offset_height,0.0f));
	}
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