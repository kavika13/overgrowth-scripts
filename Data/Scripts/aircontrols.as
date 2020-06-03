#include "targetvel.as"
#include "fliproll.as"

const float _jump_fuel_burn = 10.0f;
const float _jump_fuel = 5.0f;
const float _air_control = 3.0f;
const float _jump_vel = 5.0f;
const float _jump_threshold_time = 0.1f;
const float _jump_launch_decay = 2.0f;
		
class JumpInfo {
	float jetpack_fuel;
	float jump_launch; // Used for the initial jump stretch pose

	JumpInfo() {	
		jetpack_fuel = 0.0f;
		jump_launch = 0.0f;
	}

	void UpdateAirAnimation() {
		float up_coord = this_mo.velocity.y/_jump_vel + 0.5f;
		up_coord = min(1.5f,up_coord)+jump_launch*0.5f;
		this_mo.SetBlendCoord("up_coord",up_coord);
		this_mo.SetBlendCoord("tuck_coord",flip_info.GetTuck());
		this_mo.SetAnimation("Data/Animations/jump.xml",20.0f);
		this_mo.SetIKEnabled(false);
	}

	void UpdateAirControls() {
		if(GetInputDown("jump")){
			if(jetpack_fuel > 0.0 && this_mo.velocity.y > 0.0) {
				jetpack_fuel -= time_step * _jump_fuel_burn;
				this_mo.velocity.y += time_step * _jump_fuel_burn;
			}
		}

		if(GetInputPressed("crouch")){
			if(!flip_info.IsFlipping()){
				flip_info.StartFlip();
			}
		}

		jump_launch -= _jump_launch_decay * time_step;
		jump_launch = max(0.0f, jump_launch);
		
		vec3 target_velocity = GetTargetVelocity();
		this_mo.velocity += time_step * target_velocity * _air_control;
	}

	void StartJump(vec3 target_velocity) {
		vec3 jump_vel = GetJumpVelocity(target_velocity);
		this_mo.velocity = jump_vel;
		jetpack_fuel = _jump_fuel;
		jump_launch = 1.0f;
		flip_info.StartedJump();
		
		string sound = "Data/Sounds/Impact-Grass3.wav";
		PlaySound(sound, this_mo.position );
		
		if(length(target_velocity)>0.4f){
			this_mo.SetRotationFromFacing(target_velocity);
		}
	}

	vec3 GetJumpVelocity(vec3 target_velocity){
		vec3 jump_vel = target_velocity * _run_speed;
		jump_vel.y = _jump_vel;

		vec3 jump_dir = normalize(jump_vel);
		if(dot(jump_dir, ground_normal) < 0.3f){
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
};

JumpInfo jump_info;