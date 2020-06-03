int count = 0;

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
		target_velocity.y -= 1.0;
	}
	
	if(length_squared(target_velocity)>1){
		target_velocity = normalize(target_velocity);
	}
	
	return target_velocity;
}

const float _inertia = 0.99f;

void update() {
	count++;
	Print("Angelscript updating! Count = "+count+"\n");
	//brightness = sin(count* time_step);
	//position += vec3(brightness,sin(brightness*0.5),0);
	//position.y += 0.1;

	velocity += GetTargetVelocity();

	velocity += physics.gravity_vector * time_step;

	velocity *= _inertia;
}

void init() {
	Print("Angelscript initializing!\n");
}