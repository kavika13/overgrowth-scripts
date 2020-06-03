const float _air_control = 3.0f;

bool limp = false;
bool attacking = false;
float attacking_time;
float jetpack_fuel = 0.0f;
bool on_ground = false;
float on_ground_time = 0.0f;
float no_collide_time = 0.0f;

vec3 tilt(0.0f);
vec3 target_tilt(0.0f);
const float _tilt_inertia = 0.9f;

const float _off_ground_delay = 0.1f;
float jump_launch = 0.0f;
float _jump_launch_decay = 2.0f;
const float _jump_vel = 5.0f;
const float _jump_fuel = 5.0f;
const float _jump_fuel_burn = 10.0f;
const float _duck_speed_mult = 0.5f;
const float _ground_normal_y_threshold = 0.7f;
const float _leg_sphere_size = 0.45f;
const float _bumper_size = 0.5f;
const float _jump_threshold_time = 0.1f;
float air_time = 0.0f;

bool pre_jump = false;
float pre_jump_time;
const float _pre_jump_delay = 0.04f;

const float _run_speed = 8.0f;
float max_speed = _run_speed;

const float _tilt_transition_vel = 8.0f;

vec3 ground_normal(0,1,0);

bool feet_moving = false;

int run_phase = 1;
float run_time;

const float _run_threshold = 0.8f;
const float _walk_threshold = 0.6f;
const float _walk_accel = 35.0f;
float duck_amount = 0.0f;
float target_duck_amount = 0.0f;
float duck_vel = 0.0f;
const float _duck_accel = 120.0f;
const float _duck_vel_inertia = 0.89f;

float flip_angle = 1.0f;
vec3 target_flip_axis;
vec3 flip_axis;
float flip_progress;
bool flipping;
bool flipped;
const float _flip_speed = 2.5f; 
float flip_vel;
const float _flip_accel = 50.0f;
const float _flip_vel_inertia = 0.89f;
float target_flip_angle = 1.0f;
float old_target_flip_angle = 0.0f;
float target_flip_tuck = 0.0f;
float flip_tuck = 0.0f;
const float _flip_tuck_inertia = 0.7f;
const float _flip_axis_inertia = 0.9f;

const float _roll_speed = 2.0f;
const float _roll_accel = 50.0f;
const float _ragdoll_recovery_time = 1.0f;
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
	vec3 world_pos = pos+this.position;
	if(event == "leftstep" || event == "rightstep"){
		this.MaterialEvent(event, world_pos);
	}
	//DebugDrawText(world_pos, event, _persistent);
}

vec3 GetTargetVelocity() {
	vec3 target_velocity(0.0f);
	
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
	
	return target_velocity;
}

void HandleAirControls() {
	vec3 target_velocity = GetTargetVelocity();
	
	/*DebugDrawLine(this.position,
				  this.position + this.GetFacing(),
				  vec3(1.0f),
				  _delete_on_update);
*/
	if(GetInputDown("jump")){
		if(jetpack_fuel > 0.0 && this.velocity.y > 0.0) {
			jetpack_fuel -= time_step * _jump_fuel_burn;
			this.velocity.y += time_step * _jump_fuel_burn;
		}
	}

	if(GetInputPressed("crouch")){
		if(!flipping) {
			flipping = true;
			flip_progress = 0.0f;
			flip_angle = flip_angle - floor(flip_angle);
			if(flip_angle > 0.5f){
				flip_angle -= 1.0f;
			}
			vec3 flip_dir = normalize(this.GetFacing());
			if(length_squared(target_velocity)>0.2f){
				flip_dir = normalize(target_velocity);
			}
			vec3 up = vec3(0.0f,1.0f,0.0f);
			target_flip_axis = normalize(cross(up,flip_dir));

			if(abs(flip_vel)<0.1f){
				flip_axis = target_flip_axis;
				flip_vel = -2.0f;
			}
		}
	}

	jump_launch -= _jump_launch_decay * time_step;
	jump_launch = max(0.0f, jump_launch);
	
	this.velocity += time_step * target_velocity * _air_control;
}

vec3 flatten(vec3 vec){
	return vec3(vec.x,0.0,vec.z);
}

vec3 GetJumpVelocity(vec3 target_velocity){
	vec3 jump_vel = target_velocity * _run_speed;
	jump_vel.y = _jump_vel;

	vec3 jump_dir = normalize(jump_vel);
	if(dot(jump_dir, ground_normal) < 0.3){
		vec3 ground_up = ground_normal;
		vec3 ground_front = target_velocity;
		if(length_squared(ground_front) == 0){
			ground_front = vec3(0,0,1);
		}
		vec3 ground_right = normalize(flatten(cross(ground_up, ground_front)));
		ground_front = normalize(cross(ground_right, ground_up));
		ground_up = normalize(cross(ground_front,ground_right));

		vec3 ground_space;
		ground_space.x = dot(ground_right, jump_vel);
		ground_space.y = dot(ground_up, jump_vel);
		ground_space.z = dot(ground_front, jump_vel);

		vec3 corrected_ground_space = vec3(0,_jump_vel,length(target_velocity)*_run_speed);
		ground_space = corrected_ground_space;

		jump_vel = ground_space.x * ground_right +
				   ground_space.y * ground_up +
				   ground_space.z * ground_front;
	}

	return jump_vel;
}

void StartJump(vec3 target_velocity) {
	vec3 jump_vel = GetJumpVelocity(target_velocity);

	SetOnGround(false);
	
	this.velocity = jump_vel;
	jetpack_fuel = _jump_fuel;

	run_time = 0.0f;

	flipped = false;
	jump_launch = 1.0f;
	flip_angle = 1.0f;

	string sound = "Data/Sounds/Impact-Grass3.wav";
	PlaySound(sound, this.position );

	if(length(target_velocity)>0.4f){
		this.SetRotationFromFacing(target_velocity);
	}

	pre_jump = false;
}

vec3 WorldToGroundSpace(vec3 world_space_vec){
	vec3 right = normalize(cross(ground_normal,vec3(0,0,1)));
	vec3 front = normalize(cross(right,ground_normal));
	vec3 ground_space_vec = right * world_space_vec.x +
							front * world_space_vec.z +
							ground_normal * world_space_vec.y;
	return ground_space_vec;
}

void HandleGroundMovementControls() {
	vec3 target_velocity = GetTargetVelocity();
	if(length_squared(target_velocity)>0.0f){
		run_time += time_step;
		feet_moving = true;
	} else {
		run_time = 0.0f;
	}


	if(GetInputDown("crouch")){
		target_duck_amount = 1.0f;
	} else {
		target_duck_amount = 0.0f;
	}
	
	if(GetInputPressed("crouch") && length_squared(target_velocity)>0.2f){
		if(!flipping) {
			flipping = true;
			flip_progress = 0.0f;
			flip_angle = flip_angle - floor(flip_angle);
			if(flip_angle > 0.5f){
				flip_angle -= 1.0f;
			}
			flip_vel = 0.0f;

			roll_direction = normalize(this.GetFacing());
			if(length_squared(target_velocity)>0.2f){
				roll_direction = normalize(target_velocity);
			}
			vec3 up = vec3(0.0f,1.0f,0.0f);
			flip_axis = normalize(cross(up,roll_direction));

			feet_moving = false;
		}
	}

	if(GetInputDown("jump") && 
	   on_ground_time > _jump_threshold_time && 
	   !pre_jump)
	{
		pre_jump = true;
		pre_jump_time = _pre_jump_delay;
		//duck_amount = max(duck_amount,0.5f);
		duck_vel = 30.0f;
		vec3 target_jump_vel = GetJumpVelocity(target_velocity);
		target_tilt = vec3(target_jump_vel.x, 0, target_jump_vel.z)*2.0f;
	}

	if(pre_jump){
		if(pre_jump_time <= 0.0f && !flipping){
			StartJump(target_velocity);
		} else {
			pre_jump_time -= time_step;
		}
	}

	/*
	run_phase = 1;
	if(run_time>1.0f){
		run_phase = 2;
	}
	if(run_time>2.0f){
		run_phase = 3;
	}*/
	
	vec3 adjusted_vel = WorldToGroundSpace(target_velocity);

	max_speed = _run_speed;
	if(adjusted_vel.y>0.0){
		max_speed *= 1.0 - adjusted_vel.y;
	} else if(adjusted_vel.y<0.0){
		max_speed *= 1.0 - adjusted_vel.y;
	}

	/*DebugDrawLine(this.position,
				  this.position + adjusted_vel,
				  vec3(1,0,0),
				  _delete_on_update);
*/
	float speed = _walk_accel * run_phase;
	speed = mix(speed,speed*_duck_speed_mult,duck_amount);
	this.velocity += adjusted_vel * time_step * speed;
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
	HandleGroundAttackControls();
	HandleGroundMovementControls();
}

const float _flip_facing_inertia = 0.08f;

void HandleFlip() {
	if(flipping){
		flip_progress += time_step * _flip_speed;
		if(flip_progress > 0.5f){
			flipped = true;
		}
		if(flip_progress > 1.0f){
			flipping = false;
		}
	}
	if(flipping){
		vec3 facing = this.GetFacing();
		vec3 target_facing = camera.GetFlatFacing();

		facing = normalize(facing + target_facing * _flip_facing_inertia);

		if(dot(facing, target_facing) < -0.8f){
			vec3 break_axis = cross(vec3(0.0f,1.0f,0.0f),facing);
			if(dot(break_axis,target_facing)<0.0f){
				break_axis *= -1.0f;
			}
			facing = normalize(facing + break_axis * _flip_facing_inertia);
		}

		this.SetRotationFromFacing(facing);
	}
	target_flip_tuck = min(1.0f,max(0.0f,flip_vel));
	if(flipping){
		target_flip_tuck = max(sin(flip_progress*3.1417),target_flip_tuck);
	}
	flip_tuck = mix(target_flip_tuck,flip_tuck,_flip_tuck_inertia);
	
	flip_vel += (target_flip_angle - flip_angle) * time_step * _flip_accel;
	flip_angle += flip_vel * time_step;
	flip_vel *= _flip_vel_inertia;

	flip_axis = normalize(flip_axis * _flip_axis_inertia +
						  target_flip_axis * (1.0f - _flip_axis_inertia));
	
	if(dot(flip_axis, target_flip_axis) < -0.8f){
		vec3 break_axis = cross(vec3(0.0f,1.0f,0.0f),flip_axis);
		if(dot(break_axis,target_flip_axis)<0.0f){
			break_axis *= -1.0f;
		}
		flip_axis = normalize(flip_axis * _flip_axis_inertia +
						  break_axis * (1.0f - _flip_axis_inertia));
	
	}

	this.SetFlip(flip_axis, flip_angle*6.2832, flip_vel*6.2832);
}

void HandleRoll() {
	if(flipping){
		flip_progress += time_step * _roll_speed;
		if(flip_progress > 0.5f){
			flipped = true;
		}
		if(flip_progress > 1.0f){
			flipping = false;
		}

		if(flip_progress < 0.95f){
			vec3 adjusted_vel = WorldToGroundSpace(roll_direction);
			this.velocity = mix(this.velocity, 
								adjusted_vel * _roll_ground_speed,
								0.05f);
		}

		target_flip_angle = flip_progress;
		if(flip_progress < 0.8){
			target_duck_amount = 1.0;
		}
		if(flip_progress < 0.95f){
			duck_vel = 2.5f;
		}
	} else {
		target_flip_angle = 1.0f;
	}

	float old_flip_angle = flip_angle;
	flip_angle = mix(flip_angle, target_flip_angle, 0.2f);
	flip_vel = (flip_angle - old_flip_angle)/time_step;

	this.SetFlip(flip_axis, flip_angle*6.2832, flip_vel*6.2832);
}


void HandleMovementControls() {
	if(on_ground){ 
		target_tilt = vec3(0.0f);
		if(!flipping || flip_progress > 0.7f){
			HandleGroundControls();
		}
		HandleRoll();
	} else {
		HandleAirControls();
		HandleFlip();
		
		target_tilt = vec3(this.velocity.x, 0, this.velocity.z)*2.0f;
		if(abs(this.velocity.y)<_tilt_transition_vel && !flipped){
			target_tilt *= pow(abs(this.velocity.y)/_tilt_transition_vel,0.5);
		}
		if(this.velocity.y<0.0f || flipped){
			target_tilt *= -1.0f;
		}
	}
	
	tilt = tilt * _tilt_inertia +
		   target_tilt * (1.0f - _tilt_inertia);

	this.SetTilt(tilt);
}

void SetOnGround(bool _on_ground){
	on_ground_time = 0.0f;
	air_time = 0.0f;
	on_ground = _on_ground;
}

void Land(vec3 vel) {
	if(abs(flip_angle - 0.5f)<0.3f){
		GoLimp();
	}

	if(!limp){
		string sound = "Data/Sounds/Impact-Grass2.wav";
		PlaySound(sound, this.position);
	}
	SetOnGround(true);

	
	float land_speed = 10.0f;//min(30.0f,max(10.0f, -vel.y));
	this.SetAnimation("Data/Animations/idle.xml",land_speed);
	
	duck_amount = 1.0;
	target_duck_amount = 1.0;
	duck_vel = land_speed * 0.3f;
	if(GetInputDown("crouch")){
		duck_vel = max(6.0f,duck_vel);
	}

	feet_moving = false;

	flip_angle = 1.0f;
	flip_vel = 0.0f;
	this.SetFlip(flip_axis, flip_angle*6.2832, 0.0f);
	flipping = false;
}

const float offset = 0.05;

void HandleGroundCollision() {
	vec3 air_vel = this.velocity;
	if(on_ground){
		this.position.y -= offset;
		//DebugDrawWireSphere(this.position+vec3(0,0.1,0), _bumper_size, vec3(0,1,0), _delete_on_update);
		this.GetSlidingSphereCollision(this.position+vec3(0,0.3,0), _bumper_size);
		this.position = sphere_col.adjusted_position-vec3(0,0.3,0);
		this.velocity += (sphere_col.adjusted_position - sphere_col.position) / time_step;

		if(sphere_col.NumContacts() != 0 && flipping && flip_progress > 0.1f){
			GoLimp();	
		}

		//DebugDrawWireSphere(this.position, _leg_sphere_size, vec3(1,0,0), _delete_on_update);
	
		vec3 upper_pos = this.position+vec3(0,0.1,0);
		vec3 lower_pos = this.position+vec3(0,-0.1,0);
		this.GetSweptSphereCollision(upper_pos,
									 lower_pos,
									 _leg_sphere_size);
		if(sphere_col.position == lower_pos){
			SetOnGround(false);
		} else {
			for(int i=0; i<sphere_col.NumContacts(); i++){
				const CollisionPoint contact = sphere_col.GetContact(i);
				ground_normal = ground_normal * 0.9 +
								contact.normal * 0.1;
				ground_normal = normalize(ground_normal);
			}
			this.position = sphere_col.position;

			
			if(flipping && flip_progress > 0.4f &&
			   dot(this.GetFacing(),ground_normal) < -0.6f){
				GoLimp();	
			}
		}
		this.position.y += offset;
	} else {
		this.GetSlidingSphereCollision(this.position, _leg_sphere_size);
		this.position = sphere_col.adjusted_position;
		this.velocity += (sphere_col.adjusted_position - sphere_col.position) / time_step;
		if(sphere_col.NumContacts() != 0 && flipping){
			GoLimp();	
		}
	}

//	DebugDrawWireSphere(this.position, _leg_sphere_size, vec3(1.0), _delete_on_update);
	
	for(int i=0; i<sphere_col.NumContacts(); i++){
		const CollisionPoint contact = sphere_col.GetContact(i);
		if(contact.normal.y > _ground_normal_y_threshold){
			if(!on_ground && air_time > 0.1f){
				Land(air_vel);
				ground_normal = contact.normal;
			}
			no_collide_time = 0;
			ground_normal = ground_normal * 0.9 +
							contact.normal * 0.1;
			ground_normal = normalize(ground_normal);
		}
		/*DebugDrawLine(contact.position,
					  contact.position + contact.normal,
					  vec3(1,0,0),
					  _delete_on_update);
		DebugDrawLine(contact.position,
					  contact.position + ground_normal,
					  vec3(0,1,0),
					  _delete_on_update);*/
	}
	
	//no_collide_time += time_step;
	//if(no_collide_time > _off_ground_delay) {
	//	on_ground = false;
	//}
}

void GoLimp() {
	limp = true;
	this.Ragdoll();
	recovery_time = _ragdoll_recovery_time;
}

void update() {
	duck_vel += (target_duck_amount - duck_amount) * time_step * _duck_accel;
	duck_amount += duck_vel * time_step;
	duck_vel *= _duck_vel_inertia;
	/*DebugDrawLine(this.position + vec3(1,0,0),
				  this.position + vec3(1,duck_amount,0),
				  vec3(1,0,0),
				  _delete_on_update);
	
	DebugDrawLine(this.position + vec3(1.5,0,0),
				  this.position + vec3(1.5,target_duck_amount,0),
				  vec3(0,1,0),
				  _delete_on_update);
	
	DebugDrawLine(this.position + vec3(2,0,0),
				  this.position + vec3(2,duck_vel,0),
				  vec3(0,0,1),
				  _delete_on_update);*/
	
	if(on_ground){
		on_ground_time += time_step;
	} else {
		air_time += time_step;
	}

	float whoosh_amount = length(this.velocity)*0.05f+abs(flip_vel)*0.2f;
	float whoosh_pitch = min(2.0f,whoosh_amount*0.5f + 0.5f);
	if(!on_ground){
		whoosh_amount *= 1.5f;
	}
	SetAirWhoosh(whoosh_amount,whoosh_pitch);

	if(!attacking){ 
		HandleMovementControls();
		HandleAnimation();
		ApplyPhysics();
	} else {
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

	if(limp == true){
		recovery_time -= time_step;
	}

	if(GetInputDown("z")){		
		GoLimp();
	} else {
		if(limp == true && recovery_time < 0.0f){
			this.UnRagdoll();
			this.GetSlidingSphereCollision(this.position, _leg_sphere_size);
			this.position = sphere_col.adjusted_position;
			limp = false;
		}
	}
	
	HandleGroundCollision();
}

void init() {
	Print("Angelscript initializing!\n");
}

void HandleAnimation() {
	vec3 flat_velocity = vec3(this.velocity.x,0,this.velocity.z);
	
	if(!limp){
		float run_amount, walk_amount, idle_amount;
		float speed = length(flat_velocity);
		
		this.SetBlendCoord("tall_coord",1.0f-duck_amount);
		
		if(on_ground){
			if(flipping && flip_progress < 0.8f){
				this.SetAnimation("Data/Animations/roll.xml",7.0f);
				float forwards_rollness = 1.0f-abs(dot(flip_axis,this.GetFacing()));
				this.SetBlendCoord("forward_roll_coord",forwards_rollness);
				//com_offset = mix(vec3(0.0f,-0.5f,0.0f),com_offset,0.9f);
				this.SetIKEnabled(false);
			} else {
				//com_offset *= 0.9f;
				this.SetIKEnabled(true);
				if(speed > _walk_threshold && feet_moving){
					this.SetRotationFromFacing(flat_velocity);
					this.SetAnimation("Data/Animations/movement.xml");
					this.SetBlendCoord("speed_coord",speed);
					this.SetBlendCoord("ground_speed",speed);
				} else {
					this.SetAnimation("Data/Animations/idle.xml");
					this.SetIKEnabled(true);
				}
			}
		} else {
			float up_coord = this.velocity.y/_jump_vel + 0.5f;
			up_coord = min(1.5f,up_coord)+jump_launch*0.5f;
			this.SetBlendCoord("up_coord",up_coord);
			this.SetBlendCoord("tuck_coord",flip_tuck);
			this.SetAnimation("Data/Animations/jump.xml",20.0f);
			this.SetIKEnabled(false);
		}

		this.SetCOMOffset(com_offset, com_offset_vel);
	}
}

void UpdateVelocity() {
	this.velocity += GetTargetVelocity() * time_step * _walk_accel;
}

void ApplyPhysics() {
	if(!on_ground){
		this.velocity += physics.gravity_vector * time_step;
	}
	if(on_ground){
		if(feet_moving){
			const float e = 2.71828183;
			float exp = _walk_accel*time_step*-1/max_speed;
			float current_movement_friction = pow(e,exp);
			this.velocity *= current_movement_friction;
		} else {
			this.velocity *= 0.95;
		}
	}
}