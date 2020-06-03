void init() {
}

vec3 old_position;
float speed = 0.0f;
float target_rotation = 0.0f;
float target_rotation2 = 0.0f;
float rotation = 0.0f;
float rotation2 = 0.0f;
float smooth_speed = 0.0f;

const float _camera_rotation_inertia = 0.8f;
const float _camera_inertia = 0.8f;
const float _acceleration = 20.0f;
const float _base_speed = 5.0f;

void update() {
	if(!co.controlled){
		return;
	}
	
	if(GetInputPressed("v") && !GetInputDown("ctrl")){
		vec3 sprite_pos = co.position + camera.GetFacing()*4.0f+vec3(0.0f,1.0f,0.0f);
		MakeParticle("Data/Particles/bigfire.xml",sprite_pos,vec3(0.0f));
		//vec3 sprite_pos = co.position + camera.GetFacing()*30.0f+vec3(0.0f,10.0f,0.0f);
		//MakeParticle("Data/Particles/bigexplosion.xml",sprite_pos,vec3(0.0f));
		//vec3 sprite_pos = co.position + camera.GetFacing()*8.0f+vec3(0.0f,0.0f,0.0f);
		//MakeParticle("Data/Particles/fireball.xml",sprite_pos,vec3(0.0f));
		//vec3 sprite_pos = co.position + camera.GetFacing()*5.0f+vec3(0.0f,0.0f,0.0f);
		//MakeParticle("Data/Particles/bulletwater.xml",sprite_pos,vec3(0.0f));
		//vec3 sprite_pos = co.position + camera.GetFacing()*5.0f+vec3(0.0f,0.0f,0.0f);
		//MakeParticle("Data/Particles/propane.xml",sprite_pos,vec3(0.0f));
		//vec3 sprite_pos = co.position + camera.GetFacing()*5.0f+vec3(0.0f,0.0f,0.0f);
		//MakeParticle("Data/Particles/molotovs.xml",sprite_pos,vec3(0.0f));
		//vec3 sprite_pos = co.position + camera.GetFacing()*5.0f+vec3(0.0f,0.0f,0.0f);
		//MakeParticle("Data/Particles/sparks.xml",sprite_pos,vec3(0.0f));
		//vec3 sprite_pos = co.position + camera.GetFacing()*5.0f+vec3(0.0f,0.0f,0.0f);
		//MakeParticle("Data/Particles/dustblast.xml",sprite_pos,vec3(0.0f));
		//vec3 sprite_pos = co.position + camera.GetFacing()*5.0f+vec3(0.0f,0.0f,0.0f);
		//MakeParticle("Data/Particles/dustpuff.xml",sprite_pos,vec3(0.0f));
		//vec3 sprite_pos = co.position + camera.GetFacing()*3.0f+vec3(0.0f,0.0f,0.0f);
		//MakeParticle("Data/Particles/bloodgush.xml",sprite_pos,vec3(0.0f));
		//vec3 sprite_pos = co.position + camera.GetFacing()*3.0f+vec3(0.0f,0.0f,0.0f);
		//MakeParticle("Data/Particles/bloodmist.xml",sprite_pos,vec3(0.0f));
	}


	if(GetInputPressed("o") && GetInputDown("ctrl")){
		camera_animation_reader.AttachTo("Data/Animations/test.canm");
		co.LoadParallaxScene("Data/Textures/twisted_paths.png",
						  "Data/Models/twisted_paths.obj");
	}
	if(camera_animation_reader.valid()){
		vec3 pos = camera_animation_reader.GetPosition();
		pos = vec3(pos.x, pos.z, -pos.y);
		co.position = pos;
		quaternion quat = camera_animation_reader.GetRotation();
		vec3 facing = Mult(quat, vec3(0.0f,0.0f,1.0f));
		facing = vec3(facing.x, facing.z, -facing.y);
		/*DebugDrawLine(pos,
					  pos+facing,
					  vec3(1.0f),
					  _delete_on_update);*/
		camera.LookAt(pos+facing);
		camera.SetPos(co.position);
		rotation = camera.GetYRotation();
		rotation2 = camera.GetXRotation();
		target_rotation = rotation;
		target_rotation2 = rotation2;
		vec3 vel;
		camera.SetVelocity(vel); 
		UpdateListener(camera.GetPos(),vel,camera.GetFacing(),camera.GetUpVector());			
		float lens = camera_animation_reader.GetLens();
		float angle = (2.0f * atan(16.0f/lens)) / 3.1415 * 180.0f;
		//Print(""+lens+"   "+angle+"\n");
		camera.SetFOV(angle*3/4*0.95f);
		camera_animation_reader.Update();
		SetAirWhoosh(0.0f,1.0f);
		if(!camera_animation_reader.valid()){
			co.UnloadParallaxScene();
		}
	}
	else {
		old_position = co.position;
		vec3 vel;
		
		if(!co.frozen){
			vec3 target_velocity;

			bool moving = false;

			vec3 flat_facing = camera.GetFlatFacing();
			vec3 flat_right = vec3(-flat_facing.z, 0.0f, flat_facing.x);

			if(GetInputDown("move_right")) {
				target_velocity += flat_right;
				moving = true;
			}
			
			if(GetInputDown("move_left")) {
				target_velocity -= flat_right;
				moving = true;
			}
		
			if(GetInputDown("move_down") && GetInputDown("crouch")) {
				target_velocity+=vec3(0,-1,0);
				moving = true;
			}
			else if(GetInputDown("move_down")) {
				target_velocity-=camera.GetFacing();
				moving = true;
			}
			
			if( GetInputDown("move_up") && GetInputDown("crouch")) {
				target_velocity+=vec3(0,1,0);
				moving = true;
			}
			else if(GetInputDown("move_up")) {
				target_velocity+=camera.GetFacing();
				moving = true;
			}
			
			if (moving) {
				speed += time_step * _acceleration;
			} else {
				speed = 1.0f;
			}
			speed = max(0.0f, speed);

			target_velocity = normalize(target_velocity);
			target_velocity *= sqrt(speed) * _base_speed;
			co.velocity = co.velocity * _camera_inertia + target_velocity * (1.0f - _camera_inertia);
			co.position += co.velocity * time_step;

			if(GetInputDown("mouse0") && !co.ignore_mouse_input){
				target_rotation -= GetLookXAxis();
				target_rotation2 -= GetLookYAxis();
			}
			SetGrabMouse(false);
		}
		
		/*if(scenegraph && Camera::Instance()->getCollisionDetection()){
			float _camera_collision_radius = 0.4f;
			vec3 old_new_position = position;
			position = scenegraph->bullet_world->CheckCapsuleCollisionSlide(old_position, position, _camera_collision_radius) ;
			velocity += (position - old_new_position)/Timer::Instance()->multiplier;
		}*/
		float _camera_collision_radius = 0.4f;
		vec3 old_new_position = co.position;
		co.position = col.GetSlidingCapsuleCollision(old_position, co.position, _camera_collision_radius) ;
		co.velocity += (co.position - old_new_position)/time_step;
	


		rotation = rotation * _camera_rotation_inertia + 
				   target_rotation * (1.0f - _camera_rotation_inertia);
		rotation2 = rotation2 * _camera_rotation_inertia + 
				   target_rotation2 * (1.0f - _camera_rotation_inertia);
			

		float smooth_inertia = 0.9f;
		smooth_speed = mix(length(co.velocity), smooth_speed, smooth_inertia);
		
		float move_speed = smooth_speed;
		SetAirWhoosh(move_speed*0.01f,min(2.0f,move_speed*0.01f+0.5f));
		
		float camera_vibration_mult = 0.001f;
		float camera_vibration = move_speed * camera_vibration_mult;
		rotation += RangedRandomFloat(-camera_vibration, camera_vibration);
		rotation2 += RangedRandomFloat(-camera_vibration, camera_vibration);

		camera.SetYRotation(rotation);	
		camera.SetXRotation(rotation2);
		camera.SetPos(co.position);

		camera.SetDistance(0);
		camera.SetVelocity(co.velocity); 
		camera.SetFOV(90.0f);

		UpdateListener(camera.GetPos(),vel,camera.GetFacing(),camera.GetUpVector());		
	
		camera.CalcFacing();
	}
}