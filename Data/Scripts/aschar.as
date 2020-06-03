int count = 0;

bool limp = false;

vec3 GetTargetVelocity() {
	vec3 target_velocity(0.0);
	if(GetInputDown("move_up")){
		target_velocity += camera.GetFacing();
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
		target_velocity -= camera.GetFacing();
	}
	if(GetInputDown("jump")){
		target_velocity.y += 1.0;
	}
	if(GetInputDown("crouch")){		
		limp = true;
		this.GoLimp();
		//target_velocity.y -= 1.0;
	} else {
		limp = false;
	}
	
	if(length_squared(target_velocity)>1){
		target_velocity = normalize(target_velocity);
	}
	
	return target_velocity;
}

void draw() {
	this.DrawBody();
}

const float _inertia = 0.95f;
const float _walk_threshold = 0.2f;
const float _walk_speed = 30.0f;

void update() {
	count++;
	Print("Angelscript updating! Count = "+count+"\n");
	//brightness = sin(count* time_step);
	//position += vec3(brightness,sin(brightness*0.5),0);
	//position.y += 0.1;

	vec3 flat_velocity = vec3(velocity.x,0,velocity.z);
	this.SetRotationFromFacing(flat_velocity);
	
	if(!limp){
		if(length(flat_velocity) > _walk_threshold){
			this.SetAnimation("Data/Animations/walk.anm");
		} else {
			this.SetAnimation("Data/Animations/idle.anm");
		}
	}
	
	velocity += GetTargetVelocity() * time_step * _walk_speed;

	velocity += physics.gravity_vector * time_step;

	velocity.x *= _inertia;
	velocity.z *= _inertia;
}

void init() {
	Print("Angelscript initializing!\n");
}