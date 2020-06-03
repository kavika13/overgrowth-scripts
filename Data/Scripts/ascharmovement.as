const float _inertia = 0.95f;
const float _run_threshold = 0.8f;
const float _walk_threshold = 0.2f;
const float _walk_speed = 30.0f;

void SetAnimationFromVelocity() {
	vec3 flat_velocity = vec3(velocity.x,0,velocity.z);
	this.SetRotationFromFacing(flat_velocity);
	
	this.ClearAnimations();
	
	if(!limp){
		float run_amount, walk_amount, idle_amount;
		float speed = length(flat_velocity);
		run_amount = speed - _run_threshold;
		run_amount = max(0.0,min(1.0,run_amount));
		walk_amount = speed - _walk_threshold;
		walk_amount = max(0.0,min(1.0-run_amount,walk_amount));
		idle_amount = max(0.0,1.0-run_amount-walk_amount);
		this.AddAnimation("Data/Animations/walk.anm",walk_amount);
		this.AddAnimation("Data/Animations/run.anm",run_amount);
		this.AddAnimation("Data/Animations/idle.anm",idle_amount);
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