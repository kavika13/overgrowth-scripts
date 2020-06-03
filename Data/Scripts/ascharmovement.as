const float _inertia = 0.95f;
const float _run_threshold = 0.8f;
const float _walk_threshold = 0.6f;
const float _walk_accel = 35.0f;
float duck_amount = 0.0f;

void SetAnimationFromVelocity() {
	vec3 flat_velocity = vec3(this.velocity.x,0,this.velocity.z);
	
	//this.ClearAnimations();
	
	if(!limp){
		float run_amount, walk_amount, idle_amount;
		float speed = length(flat_velocity);
		
		this.SetBlendCoord("tall_coord",1.0f-duck_amount);
		
		if(this.on_ground){
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
	
	//Print("Inertia: "+_inertia+"\n");
	//Print("Inertia: "+_walk_speed*log(_inertia)*-1+"\n");
}

void UpdateVelocity() {
	this.velocity += GetTargetVelocity() * time_step * _walk_accel;
}

void ApplyPhysics() {
	this.velocity += physics.gravity_vector * time_step;

	if(this.on_ground){
		this.velocity.x *= _inertia;
		this.velocity.z *= _inertia;
	}
}