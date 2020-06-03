#include "interpdirection.as"

const float _flip_accel = 50.0f;
const float _flip_vel_inertia = 0.89f;
const float _flip_tuck_inertia = 0.7f;
const float _flip_axis_inertia = 0.9f;
const float _flip_facing_inertia = 0.08f;
const float _flip_speed = 2.5f; 
	
class FlipInfo {
	float flip_angle;
	vec3 target_flip_axis;
	vec3 flip_axis;
	float flip_progress;
	bool flipping;
	bool flipped;
	float flip_vel;
	float target_flip_angle;
	float old_target_flip_angle;
	float target_flip_tuck;
	float flip_tuck;

	FlipInfo() {
		flip_angle = 1.0f;
		target_flip_angle = 1.0f;
		old_target_flip_angle = 0.0f;
		target_flip_tuck = 0.0f;
		flip_tuck = 0.0f;
		flipping = false;
	}

	bool IsFlipping() {
		return flipping;
	}

	float PrepareFlipAngle(const float old_angle) {
		// Set flip angle to be close to 0.0 so it can target 1.0, and
		// chain smoothly with other flips
		float new_angle = old_angle - floor(old_angle);
		if(new_angle > 0.5f){
			new_angle -= 1.0f;
		}
		return new_angle;
	}

	vec3 GetFlipDir(vec3 target_velocity){
		// Flip direction is based on target velocity, or facing if
		// target velocity is too small
		if(length_squared(target_velocity)>0.2f){
			return normalize(target_velocity);
		} else {
			return normalize(this_mo.GetFacing());
		}
	}

	
	vec3 AxisFromDir(vec3 dir) {
		vec3 up = vec3(0.0f,1.0f,0.0f);
		return normalize(cross(up,dir));
	}

	vec3 ChooseFlipAxis() {
		return AxisFromDir(GetFlipDir(GetTargetVelocity()));
	}

	bool NeedWindup(){
		// If not rotating, need wind up anticipation before flipping
		return abs(flip_vel)<0.1f;
	}

	void FlipRecover() {
		vec3 axis = this_mo.GetAvgAngularVelocity();
		axis.y = 0.0f;
		if(length(axis)>2.0f){
			axis = normalize(axis);
			flip_info.target_flip_axis = axis;
		} else {
			axis = flip_info.target_flip_axis;
		}

		quaternion rotation = this_mo.GetAvgRotation();
		vec3 facing = Mult(rotation,vec3(0,0,1));
		vec3 up = Mult(rotation,vec3(0,1,0));

		vec3 going_up_vec = normalize(cross(axis,up));
		bool going_up = going_up_vec.y > 0.0f;

		float rotation_amount = acos(up.y)/6.283185f;
		if(going_up){
			rotation_amount = 1.0f-rotation_amount;
		}
		
		if(rotation_amount > 0.7f){
			rotation_amount = 0.0f;
		}

		flip_info.flip_progress = rotation_amount;
		flip_info.flip_angle = rotation_amount;

		vec3 flat_facing = vec3(facing.x,0.0f,facing.z);
		if(rotation_amount > 0.5f){
			flat_facing *= -1.0f;
		}
		this_mo.SetRotationFromFacing(flat_facing);
	}

	void StartFlip(){
		flipping = true;
		flip_progress = 0.0f;
		flip_angle = PrepareFlipAngle(flip_angle);
		target_flip_axis = ChooseFlipAxis();
		if(NeedWindup()){
			flip_axis = target_flip_axis;
			flip_vel = -2.0f;
		}
	}

	void UpdateFlipProgress(){
		if(flipping){
			flip_progress += time_step * _flip_speed;
			if(flip_progress > 0.5f){
				flipped = true;
			}
			if(flip_progress > 1.0f){
				flipping = false;
			}
		}
	}

	void RotateTowardsCameraFacing() {
		if(flipping){
			vec3 facing = InterpDirections(this_mo.GetFacing(),
										   camera.GetFlatFacing(),
										   _flip_facing_inertia);
			this_mo.SetRotationFromFacing(facing);
		}
	}

	void UpdateFlipTuckAmount() {
		target_flip_tuck = min(1.0f,max(0.0f,flip_vel));
		if(flipping){
			target_flip_tuck = max(sin(flip_progress*3.1417f),target_flip_tuck);
		}
		flip_tuck = mix(target_flip_tuck,flip_tuck,_flip_tuck_inertia);
	}

	void UpdateFlipAngle() {
		flip_vel += (target_flip_angle - flip_angle) * time_step * _flip_accel;
		flip_angle += flip_vel * time_step;
		flip_vel *= _flip_vel_inertia;
	}

	void UpdateFlip() {
		if(!flipping && !flipped){
			return;
		}
		UpdateFlipProgress();
		RotateTowardsCameraFacing();
		UpdateFlipTuckAmount();
		UpdateFlipAngle();
		
		flip_axis = InterpDirections(flip_axis,
									 target_flip_axis,
									 1.0f-_flip_axis_inertia);

		this_mo.SetFlip(flip_axis, flip_angle*6.2832f, flip_vel*6.2832f);
	}

	void StartedJump() {
		flipped = false;
		flip_angle = 1.0f;
		flip_tuck = 0.0f;
	}

	float GetTuck() {
		return flip_tuck;
	}

	void StartRoll(vec3 target_velocity) {
		flipping = true;
		flip_progress = 0.0f;
		flip_angle = PrepareFlipAngle(flip_angle);
		flip_vel = 0.0f;

		roll_direction = GetFlipDir(target_velocity);
		flip_axis = AxisFromDir(roll_direction);

		feet_moving = false;
	}

	void UpdateRollProgress(){
		flip_progress += time_step * _roll_speed;
		if(flip_progress > 1.0f){
			flipping = false;
		}
	}

	void UpdateRollVelocity(){
		if(flip_progress < 0.95f){
			vec3 adjusted_vel = WorldToGroundSpace(roll_direction);
			this_mo.velocity = mix(this_mo.velocity, 
								adjusted_vel * _roll_ground_speed,
								0.05f);
		}
	}

	void UpdateRollDuckAmount(){
		if(flip_progress < 0.8f){
			target_duck_amount = 1.0f;
		}
		if(flip_progress < 0.95f){
			duck_vel = 2.5f;
		}
	}

	void UpdateRollAngle() {
		float old_flip_angle = flip_angle;
		flip_angle = mix(flip_angle, target_flip_angle, 0.2f);
		flip_vel = (flip_angle - old_flip_angle)/time_step;
	}

	void UpdateRoll() {
		if(flipping){
			UpdateRollProgress();
			UpdateRollVelocity();
			UpdateRollDuckAmount();
			target_flip_angle = flip_progress;
		} else {
			target_flip_angle = 1.0f;
		}

		UpdateRollAngle();		

		this_mo.SetFlip(flip_axis, flip_angle*6.2832f, flip_vel*6.2832f);
	}

	bool HasControl() {
		return flipping && flip_progress < 0.7f;
	}

	bool UseRollAnimation() {
		return flipping && flip_progress < 0.8f;
	}

	float WhooshAmount() {
		return abs(flip_vel)*0.2f;
	}

	void Land() {
		flip_angle = 1.0f;
		flip_vel = 0.0f;
		this_mo.SetFlip(flip_axis, flip_angle*6.2832f, 0.0f);
		flipping = false;
	}

	bool HasFlipped(){
		return flipped;
	}

	bool ShouldRagdollOnLanding(){
		return abs(flip_info.flip_angle - 0.5f)<0.3f;
	}

	bool ShouldRagdollIntoWall(){
		return flip_info.flipping && flip_info.flip_progress > 0.1f;
	}
	
	bool ShouldRagdollIntoSteepGround() {
		return flip_info.flipping && flip_info.flip_progress > 0.4f;
	}

	vec3 GetAxis() {
		return flip_axis;
	}
};

FlipInfo flip_info;