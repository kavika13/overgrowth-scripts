#include "fliproll.as"

const float _jump_fuel_burn = 10.0f;
const float _jump_fuel = 5.0f;
const float _air_control = 3.0f;
const float _jump_vel = 5.0f;
const float _jump_threshold_time = 0.1f;
const float _jump_launch_decay = 2.0f;
const float _wall_run_friction = 0.1f;
		
class JumpInfo {
	float jetpack_fuel;
	float jump_launch; // Used for the initial jump stretch pose

	bool has_hit_wall;
	bool hit_wall;
	float wall_hit_time;
	vec3 wall_dir;
	vec3 wall_run_facing;

	JumpInfo() {	
		jetpack_fuel = 0.0f;
		jump_launch = 0.0f;
		hit_wall = false;
	}

	void HitWall(vec3 dir) {
		if(has_hit_wall){
			return;
		}
		hit_wall = true;
		has_hit_wall = true;
		wall_hit_time = 0.0f;
		wall_dir = dir;
		//this_mo.velocity = vec3(0.0f);

		vec3 flat_dir = dir;
		flat_dir.y = 0.0f;
		if(length_squared(flat_dir) > 0.0f){
			flat_dir = normalize(flat_dir);
			this_mo.SetRotationFromFacing(flat_dir); 
		}
	}

	void LostWallContact() {
		hit_wall = false;
		this_mo.SetRotationFromFacing(wall_run_facing);
	}

	void UpdateAirAnimation() {
		if(!hit_wall){
			float up_coord = this_mo.velocity.y/_jump_vel + 0.5f;
			up_coord = min(1.5f,up_coord)+jump_launch*0.5f;
			this_mo.SetBlendCoord("up_coord",up_coord);
			this_mo.SetBlendCoord("tuck_coord",flip_info.GetTuck());
			this_mo.SetAnimation("Data/Animations/jump.xml",20.0f);
			this_mo.SetIKEnabled(false);
		} else {
			vec3 wall_right = wall_dir;
			float temp = wall_dir.x;
			wall_right.x = -wall_dir.z;
			wall_right.z = temp;
			float speed = length(this_mo.velocity);
			this_mo.SetAnimation("Data/Animations/wall.xml",5.0f);
			this_mo.SetBlendCoord("ground_speed",speed);
			this_mo.SetBlendCoord("speed_coord",speed*0.25f);
			this_mo.SetBlendCoord("dir_coord",dot(normalize(this_mo.velocity), wall_right));
			vec3 flat_vel = this_mo.velocity;
			flat_vel.y = 0.0f;
			wall_run_facing = normalize(this_mo.GetFacing() + flat_vel*0.25f);
			/*DebugDrawLine(this_mo.position,
						  this_mo.position + normalize(flat_vel),
						  vec3(1.0f),
						  _delete_on_update);
*/
		}
	}

	void UpdateAirControls() {
		if(WantsToAccelerateJump()){
			if(jetpack_fuel > 0.0 && this_mo.velocity.y > 0.0) {
				jetpack_fuel -= time_step * _jump_fuel_burn;
				this_mo.velocity.y += time_step * _jump_fuel_burn;
			}
		}

		if(hit_wall){
			wall_hit_time += time_step;
			if(wall_hit_time > 0.1f && this_mo.velocity.y < -1.0f){
				LostWallContact();
			}
			/*this_mo.velocity -= physics.gravity_vector * 
								time_step * 
								_wall_run_friction;
			*/
			this_mo.GetSlidingSphereCollision(this_mo.position, 
											  _leg_sphere_size * 1.1f);
			if(sphere_col.NumContacts() == 0){
				LostWallContact();
			}
			
			if(GetInputPressed("jump")){
				vec3 old_vel_flat = this_mo.velocity;
				old_vel_flat.y = 0.0f;

				StartJump(wall_dir * -1.0f);
				this_mo.velocity *= 0.5f;
				flip_info.StartWallFlip(wall_dir * -1.0f);
				
				this_mo.velocity += old_vel_flat;
			}
		} else {
			if(WantsToFlip()){
				if(!flip_info.IsFlipping()){
					flip_info.StartFlip();
				}
			}
		}

		jump_launch -= _jump_launch_decay * time_step;
		jump_launch = max(0.0f, jump_launch);
		
		vec3 target_velocity = GetTargetVelocity();
		this_mo.velocity += time_step * target_velocity * _air_control;
	}

	void StartJump(vec3 target_velocity) {
		StartFall();

		vec3 jump_vel = GetJumpVelocity(target_velocity);
		this_mo.velocity = jump_vel;
		jetpack_fuel = _jump_fuel;
		jump_launch = 1.0f;
		
		string sound = "Data/Sounds/Impact-Grass3.wav";
		PlaySound(sound, this_mo.position );
		
		if(length(target_velocity)>0.4f){
			this_mo.SetRotationFromFacing(target_velocity);
		}
	}

	void StartFall() {
		jetpack_fuel = 0.0f;
		jump_launch = 0.0f;
		hit_wall = false;
		has_hit_wall = false;
		flip_info.StartedJump();
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