const float _inertia = 0.95f;
const float _run_threshold = 0.8f;
const float _walk_threshold = 0.2f;
const float _walk_speed = 30.0f;

void SetAnimationFromVelocity() {
	vec3 flat_velocity = vec3(velocity.x,0,velocity.z);
	this.SetRotationFromFacing(flat_velocity);
	
	//this.ClearAnimations();
	
	if(!limp){
		float run_amount, walk_amount, idle_amount;
		float speed = length(flat_velocity);
		
		if(speed > _walk_threshold){
			this.SetAnimation("Data/Animations/movement.xml");
			this.SetBlendCoord("speed_coord",speed);
		} else {
			this.SetAnimation("Data/Animations/idle.anm");
		}
	}
}

void UpdateVelocity() {
	velocity += GetTargetVelocity() * time_step * _walk_speed;
}

void ApplyPhysics() {
	velocity += physics.gravity_vector * time_step;

	velocity.x *= _inertia;
	velocity.z *= _inertia;
}