const float _duck_inertia = 0.95f;
const float _air_control = 3.0f;

bool limp = false;
bool attacking = false;
float attacking_time;
float jetpack_fuel = 0.0;
bool on_ground = false;
float no_collide_time = 0.0;

const float _off_ground_delay = 0.1f;
const float _jump_vel = 5.0;
const float _jump_fuel = 5.0;
const float _jump_fuel_burn = 10.0;
const float _duck_speed_mult = 0.5;
const float _ground_normal_y_threshold = 0.7f;
const float _leg_sphere_size = 0.45f;
const float _bumper_size = 0.5f;

const float _tilt_transition_vel = 4.0f;

vec3 ground_normal(0,1,0);

int run_phase = 1;
float run_time;

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
	
	duck_amount = 1.0;
	
	this.velocity += time_step * target_velocity * _air_control;
}

void HandleGroundMovementControls() {
	vec3 target_velocity = GetTargetVelocity();
	if(length_squared(target_velocity)>0.0f){
		run_time += time_step;
	} else {
		run_time = 0.0f;
	}


	if(GetInputDown("crouch")){
		duck_amount = 1.0 * (1.0 - _duck_inertia) +
					   duck_amount * _duck_inertia;
	} else {
		duck_amount = 0.0 * (1.0 - _duck_inertia) +
					  duck_amount * _duck_inertia;
	}
	
	if(GetInputDown("jump")){
		on_ground = false;
		
		const float _walk_speed = _walk_accel * time_step * -1 / log(_inertia);
		this.velocity = target_velocity * _walk_speed;
		this.velocity.y = _jump_vel;
		jetpack_fuel = _jump_fuel;

		run_time = 0.0f;
	}

	/*
	run_phase = 1;
	if(run_time>1.0f){
		run_phase = 2;
	}
	if(run_time>2.0f){
		run_phase = 3;
	}*/
	
	vec3 right = cross(target_velocity,ground_normal);
	vec3 adjusted_vel = normalize(cross(ground_normal,right));
	adjusted_vel *= length(target_velocity);
	
	DebugDrawLine(this.position,
				  this.position + adjusted_vel,
				  vec3(1,0,0),
				  _delete_on_update);

	
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
}

void HandleGroundCollision() {
	if(on_ground){
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
			on_ground = false;
		} else {
			this.position = sphere_col.position;
		}
	} else {
		this.GetSlidingSphereCollision(this.position, _leg_sphere_size);
		this.position = sphere_col.adjusted_position;
		this.velocity += (sphere_col.adjusted_position - sphere_col.position) / time_step;
	}

//	DebugDrawWireSphere(this.position, _leg_sphere_size, vec3(1.0), _delete_on_update);
	
	for(int i=0; i<sphere_col.NumContacts(); i++){
		const CollisionPoint contact = sphere_col.GetContact(i);
		if(contact.normal.y > _ground_normal_y_threshold){
			on_ground = true;
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

const float _inertia = 0.95f;
const float _run_threshold = 0.8f;
const float _walk_threshold = 0.6f;
const float _walk_accel = 35.0f;
float duck_amount = 0.0f;

void HandleAnimation() {
	vec3 flat_velocity = vec3(this.velocity.x,0,this.velocity.z);
	
	if(!limp){
		float run_amount, walk_amount, idle_amount;
		float speed = length(flat_velocity);
		
		this.SetBlendCoord("tall_coord",1.0f-duck_amount);
		
		if(on_ground){
			this.SetRotationFromFacing(flat_velocity);
			if(speed > _walk_threshold){
				this.SetAnimation("Data/Animations/movement.xml");
				this.SetBlendCoord("speed_coord",speed);
				this.SetBlendCoord("ground_speed",speed);
			} else {
				this.SetAnimation("Data/Animations/idle.xml");
			}
		} else {
			this.SetBlendCoord("up_coord",this.velocity.y*0.2f + 0.5f);
			this.SetAnimation("Data/Animations/jump.xml");
		}
	}
}

void UpdateVelocity() {
	this.velocity += GetTargetVelocity() * time_step * _walk_accel;
}

void ApplyPhysics() {
	this.velocity += physics.gravity_vector * time_step;

	if(on_ground){
		this.velocity *= _inertia;
	}
}