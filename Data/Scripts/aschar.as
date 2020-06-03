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
const float _jump_vel = 5.0f;
const float _jump_fuel = 5.0f;
const float _jump_fuel_burn = 10.0f;
const float _duck_speed_mult = 0.5f;
const float _ground_normal_y_threshold = 0.7f;
const float _leg_sphere_size = 0.45f;
const float _bumper_size = 0.5f;
const float _jump_threshold_time = 0.1f;
float air_time = 0.0f;

const float _run_speed = 8.0f;
float max_speed = _run_speed;

const float _tilt_transition_vel = 4.0f;

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
	
	if(GetInputDown("jump")){
		if(jetpack_fuel > 0.0 && this.velocity.y > 0.0) {
			jetpack_fuel -= time_step * _jump_fuel_burn;
			this.velocity.y += time_step * _jump_fuel_burn;
		}
	}
	
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

	string sound = "Data/Sounds/Impact-Grass3.wav";
	PlaySound(sound, this.position );

	if(length(target_velocity)>0.4f){
		this.SetRotationFromFacing(target_velocity);
	}
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
	
	if(GetInputDown("jump") && on_ground_time > _jump_threshold_time){
		StartJump(target_velocity);
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

void HandleMovementControls() {
	if(on_ground){ 
		HandleGroundControls();
		target_tilt = vec3(0.0f);
	} else {
		HandleAirControls();
		
		target_tilt = vec3(this.velocity.x, 0, this.velocity.z)*2.0f;
		if(abs(this.velocity.y)<_tilt_transition_vel){
			target_tilt *= pow(abs(this.velocity.y)/_tilt_transition_vel,0.5);
		}
		if(this.velocity.y<0.0f){
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
	string sound = "Data/Sounds/Impact-Grass2.wav";
	PlaySound(sound, this.position);
	SetOnGround(true);

	duck_amount = 1.0;
	target_duck_amount = 1.0;
	duck_vel = 1.0;

	float land_speed = min(30.0f,max(10.0f, -vel.y));
	this.SetAnimation("Data/Animations/idle.xml",land_speed);
	feet_moving = false;
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
		}
		this.position.y += offset;
	} else {
		this.GetSlidingSphereCollision(this.position, _leg_sphere_size);
		this.position = sphere_col.adjusted_position;
		this.velocity += (sphere_col.adjusted_position - sphere_col.position) / time_step;
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

	float whoosh_amount = length(this.velocity)*0.05f;
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
	
	if(GetInputDown("z")){		
		limp = true;
		this.Ragdoll();
	} else {
		if(limp == true){
			this.UnRagdoll();
			this.GetSlidingSphereCollision(this.position, _leg_sphere_size);
			this.position = sphere_col.adjusted_position;
		}
		limp = false;
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
			this.SetRotationFromFacing(flat_velocity);
			if(speed > _walk_threshold && feet_moving){
				this.SetAnimation("Data/Animations/movement.xml");
				this.SetBlendCoord("speed_coord",speed);
				this.SetBlendCoord("ground_speed",speed);
			} else {
				this.SetAnimation("Data/Animations/idle.xml");
			}
			this.SetIKEnabled(true);
		} else {
			this.SetBlendCoord("up_coord",this.velocity.y*0.2f + 0.5f);
			this.SetAnimation("Data/Animations/jump.xml", 20.0f);
			this.SetIKEnabled(false);
		}
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