#include "interpdirection.as"

bool limp = false;

float air_time = 0.0f;

bool pre_jump = false;
float pre_jump_time;
const float _pre_jump_delay = 0.04f; // the time between a jump being initiated and the jumper getting upwards velocity, time available for pre-jump animation

bool on_ground = false;
float on_ground_time = 0.0f;

vec3 tilt(0.0f);
vec3 target_tilt(0.0f);
const float _tilt_inertia = 0.9f; // affects tilt, must be between 0 and 1

const float _duck_speed_mult = 0.5f;

const float _ground_normal_y_threshold = 0.5f;
const float _leg_sphere_size = 0.45f; // affects the size of a sphere collider used for leg collisions
const float _bumper_size = 0.5f;

const float _run_speed = 8.0f; // used to calculate movement and jump velocities, change this instead of max_speed
float max_speed = _run_speed; // this is recalculated constantly because actual max speed is affected by slopes

const float _tilt_transition_vel = 8.0f;

vec3 ground_normal(0,1,0);

bool feet_moving = false;
float getting_up_time;

int run_phase = 1;

string hit_reaction_event;

const int _movement_state = 0;
const int _ground_state = 1; 
const int _attack_state = 2; 
const int _hit_reaction_state = 3; 
int state;

bool attack_animation_set = false;
bool hit_reaction_anim_set = false;

const float _run_threshold = 0.8f; // when character is moving faster than this, it runs
const float _walk_threshold = 0.6f; // when character is moving slower than this, it's idling
const float _walk_accel = 35.0f; // how fast characters accelerate when moving
float duck_amount = 0.0f;
float target_duck_amount = 0.0f;
float duck_vel = 0.0f;
const float _duck_accel = 120.0f;
const float _duck_vel_inertia = 0.89f;

const float _roll_speed = 2.0f;
const float _roll_accel = 50.0f;
const float _ragdoll_recovery_time = 1.0f;
const float _roll_ground_speed = 12.0f;
float recovery_time;
vec3 roll_direction;

float leg_cannon_flip;

bool controlled = false;

vec3 com_offset;
vec3 com_offset_vel;

bool mirrored_stance = false;

float block_health = 1.0f;
float temp_health = 1.0f;
float permanent_health = 1.0f;
int knocked_out = 0;

vec3 old_vel;
vec3 accel_tilt;

float cancel_delay;

bool active_blocking = false;
float active_block_duration = 0.0f;
float active_block_recharge = 0.0f;

string curr_attack; 
int target_id = -1;
int self_id;

void EndAttack() {
	SetState(_movement_state);
	if(!on_ground){
		//StartWallJump(wall_dir * -1.0f);
		flip_info.StartLegCannonFlip(this_mo.GetFacing()*-1.0f, leg_cannon_flip);
	}
}

void EndHitReaction() {
	SetState(_movement_state);
}

void WasBlocked() {
	this_mo.SwapAnimation(attack_getter.GetBlockedAnimPath());
	if(attack_getter.GetSwapStance() != 0){
		mirrored_stance = !mirrored_stance;
	}
}

int WasHit(string type, string attack_path, vec3 dir, vec3 pos) {
	attack_getter2.Load(attack_path);

	if(type == "attackblocked")
	{
		string sound = "Data/Sounds/hit/hit_normal.xml";
		PlaySoundGroup(sound, pos);
		//MakeParticle("Data/Particles/bloodsplat.xml",pos,dir*5.0f);
		MakeParticle("Data/Particles/impactfast.xml",pos,vec3(0.0f));
		MakeParticle("Data/Particles/impactslow.xml",pos,vec3(0.0f));
		TimedSlowMotion(0.1f,0.3f, 0.05f);
	}
	if(type == "blockprepare")
	{
		if(state == _movement_state && limp == false){
			if(active_blocking){
				reaction_getter.Load(attack_getter2.GetReactionPath());
				SetState(_hit_reaction_state);
				hit_reaction_anim_set = false;
			
				hit_reaction_event = type;

				dir.y = 0.0f;
				dir = normalize(dir) * -1;
				if(length_squared(dir)>0.0f){
					this_mo.SetRotationFromFacing(dir);
				}
				ActiveBlocked();
				return 1;
			}
		}
	}
	if(type == "attackimpact")
	{
		if(attack_getter2.GetHeight() == _high &&
			duck_amount > 0.5f)
		{
			return 0;
		}
		if(attack_getter2.GetSpecial() == "legcannon"){
			block_health = 0.0f;
		}
	
		block_health -= attack_getter2.GetBlockDamage();
		block_health = max(0.0f, block_health);

		if(block_health <= 0.0f || state == _attack_state || !on_ground){
			MakeParticle("Data/Particles/impactfast.xml",pos,vec3(0.0f));
			MakeParticle("Data/Particles/impactslow.xml",pos,vec3(0.0f));
			float force = attack_getter2.GetForce()*(1.0f-temp_health*0.5f);
			GoLimp();
			
			vec3 impact_dir = attack_getter2.GetImpactDir();
			vec3 right;
			right.x = -dir.z;
			right.z = dir.x;
			right.y = dir.y;
			vec3 impact_dir_adjusted = impact_dir.x * right +
									   impact_dir.z * dir;
			impact_dir_adjusted.y += impact_dir.y;
			this_mo.ApplyForceToRagdoll(impact_dir_adjusted * force, pos);

			block_health = 0.0f;
			temp_health -= attack_getter2.GetDamage();
			permanent_health -= attack_getter2.GetDamage() * 0.4f;
			if(permanent_health <= 0.0f && knocked_out != 2){
				knocked_out = 2;
				string sound = "Data/Sounds/hit/hit_hard.xml";
				PlaySoundGroup(sound, pos);
			}
			if(temp_health <= 0.0f && knocked_out==0){
				knocked_out = 1;
				TimedSlowMotion(0.1f,0.7f, 0.05f);
				string sound = "Data/Sounds/hit/hit_medium.xml";
				PlaySoundGroup(sound, pos);
			} else {
				string sound = "Data/Sounds/hit/hit_medium.xml";
				PlaySoundGroup(sound, pos);
			}
			temp_health = max(0.0f, temp_health);
		} else {
			string sound = "Data/Sounds/hit/hit_normal.xml";
			PlaySoundGroup(sound, pos);
			//MakeParticle("Data/Particles/bloodsplat.xml",pos,dir*5.0f);
			MakeParticle("Data/Particles/impactfast.xml",pos,vec3(0.0f));
			MakeParticle("Data/Particles/impactslow.xml",pos,vec3(0.0f));
			
			reaction_getter.Load(attack_getter2.GetReactionPath());
			SetState(_hit_reaction_state);
			hit_reaction_anim_set = false;
		
			hit_reaction_event = type;

			dir.y = 0.0f;
			dir = normalize(dir) * -1;
			if(length_squared(dir)>0.0f){
				this_mo.SetRotationFromFacing(dir);
			}
		}
	}
	return 2;
}

void HandleAnimationEvent(string event, vec3 world_pos){
	//Print("Angelscript received event: "+event+"\n");
	if(event == "golimp"){
		GoLimp();
	}
	
	
	if(event == "leftstep" ||
	   event == "leftwalkstep" ||
	   event == "leftwallstep" ||
	   event == "leftrunstep" ||
	   event == "leftcrouchwalkstep")
	{
		//this_mo.MaterialDecalAtBone("step", "left_leg");
		this_mo.MaterialParticleAtBone("step","left_leg");
		//this_mo.AddDecalAtBone("left_leg", "footstep");
		//PlaySoundGroup("Data/Sounds/footstep_mud.xml", world_pos);
		//MakeSplatParticle(world_pos);
	}
	if(event == "rightstep" ||
	   event == "rightwalkstep" ||
	   event == "rightwallstep" ||
	   event == "rightrunstep" ||
	   event == "rightcrouchwalkstep")
	{
		//this_mo.MaterialDecalAtBone("step", "right_leg");
		this_mo.MaterialParticleAtBone("step","right_leg");
		/*this_mo.AddDecalAtBone("right_leg", "footstep");
		PlaySoundGroup("Data/Sounds/footstep_mud.xml", world_pos);
		MakeSplatParticle(world_pos);*/
	}
	
	if(event == "leftstep" || event == "rightstep"){
		this_mo.MaterialEvent(event, world_pos);
	}
	if(event == "leftwallstep" || event == "rightwallstep"){
		this_mo.MaterialEvent(event, world_pos);
		//string path = "Data/Sounds/concrete_foley/bunny_wallrun_concrete.xml";
		//this_mo.PlaySoundGroupAttached(path, world_pos);
	}
	if(event == "leftrunstep" || event == "rightrunstep"){
		this_mo.MaterialEvent(event, world_pos);
		//string path = "Data/Sounds/concrete_foley/bunny_run_concrete.xml";
		//this_mo.PlaySoundGroupAttached(path, world_pos);
	}
	if(event == "leftwalkstep" || event == "rightwalkstep"){
		this_mo.MaterialEvent(event, world_pos);
		//string path = "Data/Sounds/concrete_foley/bunny_walk_concrete.xml";
		//this_mo.PlaySoundGroupAttached(path, world_pos);
	}
	if(event == "leftcrouchwalkstep" || event == "rightcrouchwalkstep"){
		this_mo.MaterialEvent(event, world_pos);
		//string path = "Data/Sounds/concrete_foley/bunny_crouchwalk_concrete.xml";
		//this_mo.PlaySoundGroupAttached(path, world_pos);
	}

	if(target_id == -1){
		return;
	}
	vec3 target_pos = this_mo.ReadCharacter(target_id).position;
	if((event == "attackblocked" ||
		event == "attackimpact" ||
		event == "blockprepare") && 
	   distance(this_mo.position, target_pos) < 1.6f){
		vec3 facing = this_mo.GetFacing();
		vec3 facing_right = vec3(-facing.z, facing.y, facing.x);
		vec3 dir = normalize(target_pos - this_mo.position);
		int return_val = this_mo.ReadCharacter(target_id).WasHit(
							   event, attack_getter.GetPath(), dir, world_pos);
		if(return_val == 1){
			WasBlocked();
		}
		if(return_val != 0 && attack_getter.GetSpecial() == "legcannon"){
			this_mo.velocity += dir * -10.0f;
		}
		if(event == "frontkick"){
			if(distance(this_mo.position, target_pos) < 1.0f){
				vec3 dir = normalize(target_pos - this_mo.position);
				this_mo.ReadCharacter(target_id).position = 
					this_mo.position + dir;
			}
		}
	}
	/*
	
	DebugDrawText(world_pos,
				  event,
				  _persistent);*/
}

#include "aircontrols.as"

vec3 flatten(vec3 vec){
	return vec3(vec.x,0.0,vec.z);
}

vec3 WorldToGroundSpace(vec3 world_space_vec){
	vec3 right = normalize(cross(ground_normal,vec3(0,0,1)));
	vec3 front = normalize(cross(right,ground_normal));
	vec3 ground_space_vec = right * world_space_vec.x +
							front * world_space_vec.z +
							ground_normal * world_space_vec.y;
	return ground_space_vec;
}

void UpdateGroundMovementControls() {
	vec3 target_velocity = GetTargetVelocity();
	if(length_squared(target_velocity)>0.0f){
		feet_moving = true;
	}

	if(WantsToCrouch()){
		target_duck_amount = 1.0f;
	} else {
		target_duck_amount = 0.0f;
	}
	
	if(WantsToRoll() && length_squared(target_velocity)>0.2f){
		if(!flip_info.IsFlipping()){
			flip_info.StartRoll(target_velocity);
		}
	}

	if(WantsToJump() && 
	   on_ground_time > _jump_threshold_time && 
	   !pre_jump)
	{
		pre_jump = true;
		pre_jump_time = _pre_jump_delay;
		duck_vel = 30.0f * (1.0f-duck_amount * 0.6f);

		vec3 target_jump_vel = jump_info.GetJumpVelocity(target_velocity);
		target_tilt = vec3(target_jump_vel.x, 0, target_jump_vel.z)*2.0f;
	}

	if(pre_jump){
		if(pre_jump_time <= 0.0f && !flip_info.IsFlipping()){
			jump_info.StartJump(target_velocity);
			SetOnGround(false);
			pre_jump = false;
		} else {
			pre_jump_time -= time_step;
		}
	}
	
	vec3 flat_ground_normal = ground_normal;
	flat_ground_normal.y = 0.0f;
	float flat_ground_length = length(flat_ground_normal);
	flat_ground_normal = normalize(flat_ground_normal);
	if(flat_ground_length > 0.9f){
		if(dot(target_velocity, flat_ground_normal)<0.0f){
			target_velocity -= dot(target_velocity, flat_ground_normal) *
							   flat_ground_normal;
		}
	}
	if(flat_ground_length > 0.6f){
		if(dot(this_mo.velocity, flat_ground_normal)>-0.8f){
			target_velocity -= dot(target_velocity, flat_ground_normal) *
							   flat_ground_normal;
			target_velocity += flat_ground_normal * flat_ground_length;
			feet_moving = true;
		}
		if(length(target_velocity)>1.0f){
			target_velocity = normalize(target_velocity);
		}
	}

	vec3 adjusted_vel = WorldToGroundSpace(target_velocity);

	// Adjust speed based on ground slope
	max_speed = _run_speed;
	float curr_speed = length(this_mo.velocity);
	if(adjusted_vel.y>0.0){
		max_speed *= 1.0 - adjusted_vel.y;
	} else if(adjusted_vel.y<0.0){
		max_speed *= 1.0 - adjusted_vel.y;
	}
	max_speed = max(curr_speed * 0.98f, max_speed);

	float speed = _walk_accel * run_phase;
	speed = mix(speed,speed*_duck_speed_mult,duck_amount);
	this_mo.velocity += adjusted_vel * time_step * speed;

}

void DrawIKTarget(string str) {
	vec3 pos = this_mo.GetIKTargetPosition(str);
	DebugDrawWireSphere(pos,
						0.1f,
						vec3(1.0f),
						_delete_on_draw);
}


void MoveIKTarget(string str, vec3 offset) {
	vec3 pos = this_mo.GetIKTargetPosition(str);
	DebugDrawLine(pos,
				  pos+offset,
				  vec3(1.0f),
				  _delete_on_draw);
	this_mo.SetIKTargetOffset(str, offset);

}

void draw() {
	this_mo.DrawBody();
}

void ForceApplied(vec3 force) {
}

int IsKnockedOut() {
	return knocked_out;
}

float GetTempHealth() {
	return temp_health;
}

void UpdateGroundAttackControls() {
	if(WantsToAttack()){
		TargetClosest();
	}
	if(target_id == -1){
		return;
	}
	if(WantsToAttack() && distance(this_mo.position,this_mo.ReadCharacter(target_id).position) <= 1.6f){
		SetState(_attack_state);
		//Print("Starting attack\n");
		attack_animation_set = false;
		/*if(target.GetTempHealth() <= 0.4f && target.IsKnockedOut()==0){
			TimedSlowMotion(0.2f,0.4f, 0.15f);
		}*/
	}
}

void UpdateAirAttackControls() {
	if(WantsToAttack()){
		TargetClosest();
	}
	if(target_id == -1){
		return;
	}
	if(WantsToAttack() && !flip_info.IsFlipping() &&
		distance(this_mo.position + this_mo.velocity * 0.3f,
				 this_mo.ReadCharacter(target_id).position + this_mo.ReadCharacter(target_id).velocity * 0.3f) <= 1.6f)
	{
		SetState(_attack_state);
		attack_animation_set = false;
	}
}

void UpdateGroundControls() {
	UpdateGroundAttackControls();
	UpdateGroundMovementControls();
}

void HandleAccelTilt() {
	if(on_ground){
		if(feet_moving && state == _movement_state){
			target_tilt = this_mo.velocity * 0.5f;
			accel_tilt = mix(accel_tilt, (this_mo.velocity - old_vel)*120.0f, 0.05f);
		} else {
			target_tilt = vec3(0.0f);
			accel_tilt *= 0.8f;
		}
		target_tilt += accel_tilt;
		target_tilt.y = 0.0f;
		old_vel = this_mo.velocity;
	} else {
		accel_tilt = vec3(0.0f);
		old_vel = vec3(0.0f);
	}
}

void UpdateMovementControls() {
	if(on_ground){ 
		if(!flip_info.HasControl()){
			UpdateGroundControls();
		}
		flip_info.UpdateRoll();
	} else {
		jump_info.UpdateAirControls();
		UpdateAirAttackControls();
		if(jump_info.ClimbedUp()){
			SetOnGround(true);
			duck_amount = 1.0f;
			duck_vel = 2.0f;
			target_duck_amount = 1.0f;
			this_mo.StartAnimation(character_getter.GetAnimPath("idle"),20.0f);
			HandleBumperCollision();
			HandleStandingCollision();
			this_mo.position = sphere_col.position;
			this_mo.velocity = vec3(0.0f);
			feet_moving = false;
			this_mo.MaterialEvent("land_soft", this_mo.position);
			//string path = "Data/Sounds/concrete_foley/bunny_jump_land_soft_concrete.xml";
			//this_mo.PlaySoundGroupAttached(path, this_mo.position);
		} else {
			flip_info.UpdateFlip();
			
			target_tilt = vec3(this_mo.velocity.x, 0, this_mo.velocity.z)*2.0f;
			if(abs(this_mo.velocity.y)<_tilt_transition_vel && !flip_info.HasFlipped()){
				target_tilt *= pow(abs(this_mo.velocity.y)/_tilt_transition_vel,0.5);
			}
			if(this_mo.velocity.y<0.0f || flip_info.HasFlipped()){
				target_tilt *= -1.0f;
			}
		}
	}
}

void SetOnGround(bool _on_ground){
	on_ground_time = 0.0f;
	air_time = 0.0f;
	on_ground = _on_ground;
}

void TargetClosest(){
	int num = this_mo.GetNumCharacters();
	int closest_id = -1;
	float closest_dist;

	for(int i=0; i<num; ++i){
		vec3 target_pos = this_mo.ReadCharacter(i).position;
		if(this_mo.position == target_pos){
			continue;
		}
		if(this_mo.ReadCharacter(i).IsKnockedOut() != 0){
			continue;
		}
		
		if(closest_id == -1 || 
		   distance_squared(this_mo.position, target_pos) < closest_dist)
	   {
		   closest_dist = distance_squared(this_mo.position, target_pos);
		   closest_id = i;
	   }
	}
	target_id = closest_id;
}

// this is called when the character lands in a non-ragdoll mode
void Land(vec3 vel) {
	// this is true when the character initiated a flip during jump and isn't finished yet
	if(flip_info.ShouldRagdollOnLanding()){
		GoLimp();
		return;
	}

	SetOnGround(true);
	
	float land_speed = 10.0f;//min(30.0f,max(10.0f, -vel.y));
	this_mo.StartAnimation(character_getter.GetAnimPath("idle"),land_speed);

	if(dot(this_mo.velocity*-1.0f, ground_normal)>0.3f){
		if(dot(normalize(this_mo.velocity*-1.0f), normalize(ground_normal))>0.6f){
			this_mo.MaterialEvent("land", this_mo.position - vec3(0.0f,_leg_sphere_size, 0.0f));
			//string path = "Data/Sounds/concrete_foley/bunny_jump_land_concrete.xml";
			//this_mo.PlaySoundGroupAttached(path, this_mo.position);
		} else {
			this_mo.MaterialEvent("land_slide", this_mo.position - vec3(0.0f,_leg_sphere_size, 0.0f));
			//string path = "Data/Sounds/concrete_foley/bunny_jump_land_slide_concrete.xml";
			//this_mo.PlaySoundGroupAttached(path, this_mo.position);
		}

		duck_amount = 1.0;
		target_duck_amount = 1.0;
		duck_vel = land_speed * 0.3f;
	} else {
		this_mo.MaterialEvent("land_soft", this_mo.position - vec3(0.0f,_leg_sphere_size, 0.0f));
		//string path = "Data/Sounds/concrete_foley/bunny_jump_land_soft_concrete.xml";
		//this_mo.PlaySoundGroupAttached(path, this_mo.position);
	}

	if(WantsToCrouch()){
		duck_vel = max(6.0f,duck_vel);
	}

	feet_moving = false;

	flip_info.Land();
}

const float offset = 0.05f;

vec3 HandleBumperCollision(){
	this_mo.GetSlidingSphereCollision(this_mo.position+vec3(0,0.3f,0), _bumper_size);
	this_mo.position = sphere_col.adjusted_position-vec3(0,0.3f,0);
	return (sphere_col.adjusted_position - sphere_col.position);
}

bool HandleStandingCollision() {
	vec3 upper_pos = this_mo.position+vec3(0,0.1f,0);
	vec3 lower_pos = this_mo.position+vec3(0,-0.2f,0);
	this_mo.GetSweptSphereCollision(upper_pos,
								 lower_pos,
								 _leg_sphere_size);
	return (sphere_col.position == lower_pos);
}

void HandleGroundCollision() {
	/*vec3 ground_vel;
	if(on_ground) {
		vec3 y_vec = ground_normal;
		vec3 x_vec = normalize(cross(y_vec,vec3(0,0,1)));
		vec3 z_vec = cross(y_vec, x_vec);
		ground_vel = vec3(dot(x_vec, this_mo.velocity),
						  dot(y_vec, this_mo.velocity),
						  dot(z_vec, this_mo.velocity));
	}*/

	vec3 air_vel = this_mo.velocity;
	if(on_ground){
		this_mo.velocity += HandleBumperCollision() / time_step;

		if(sphere_col.NumContacts() != 0 && flip_info.ShouldRagdollIntoWall()){
			//GoLimp();	
		}

		if((sphere_col.NumContacts() != 0 ||
			ground_normal.y < _ground_normal_y_threshold)
			&& this_mo.velocity.y > 0.2f){
			SetOnGround(false);
			jump_info.StartFall();
		}

		bool in_air = HandleStandingCollision();
		if(in_air){
			SetOnGround(false);
			jump_info.StartFall();
		} else {
			this_mo.position = sphere_col.position;
			/*DebugDrawWireSphere(sphere_col.position,
								sphere_col.radius,
								vec3(1.0f,0.0f,0.0f),
								_delete_on_update);*/
			for(int i=0; i<sphere_col.NumContacts(); i++){
				const CollisionPoint contact = sphere_col.GetContact(i);
				if(distance(contact.position, this_mo.position)<=_leg_sphere_size+0.01f){
					ground_normal = ground_normal * 0.9f +
									contact.normal * 0.1f;
					ground_normal = normalize(ground_normal);
					/*DebugDrawLine(sphere_col.position,
								  sphere_col.position-contact.normal,
								  vec3(1.0f,0.0f,0.0f),
								  _delete_on_update);*/
				}
			}/*
			DebugDrawLine(sphere_col.position,
							  sphere_col.position-ground_normal,
							  vec3(0.0f,1.0f,0.0f),
							  _delete_on_update);
			*/
			
			if(flip_info.ShouldRagdollIntoSteepGround() &&
			   dot(this_mo.GetFacing(),ground_normal) < -0.6f){
				//GoLimp();	
			}
		}
	} else {
		this_mo.GetSlidingSphereCollision(this_mo.position, _leg_sphere_size);
		this_mo.position = sphere_col.adjusted_position;
		this_mo.velocity += (sphere_col.adjusted_position - sphere_col.position) / time_step;
		for(int i=0; i<sphere_col.NumContacts(); i++){
			const CollisionPoint contact = sphere_col.GetContact(i);
			if(contact.normal.y < _ground_normal_y_threshold){
				jump_info.HitWall(normalize(contact.position-this_mo.position));
			}
		}	
			
		if(sphere_col.NumContacts() != 0 && flip_info.RagdollOnImpact()){
			//GoLimp();	
		}
		
		for(int i=0; i<sphere_col.NumContacts(); i++){
			const CollisionPoint contact = sphere_col.GetContact(i);
			if(contact.normal.y > _ground_normal_y_threshold ||
			   (this_mo.velocity.y < 0.0f && contact.normal.y > 0.2f)){
				if(air_time > 0.1f){
					ground_normal = contact.normal;
					Land(air_vel);
					SetState(_movement_state);
				}
			}
		}
	}
/*
	if(on_ground){
		vec3 y_vec = ground_normal;
		vec3 x_vec = normalize(cross(y_vec,vec3(0,0,1)));
		vec3 z_vec = cross(y_vec, x_vec);
		this_mo.velocity = x_vec * ground_vel.x +
						   y_vec * ground_vel.y +
						   z_vec * ground_vel.z;
	}*/
}

void GoLimp() {
	//return;
	SetState(_movement_state);
	limp = true;
	this_mo.Ragdoll();
	recovery_time = _ragdoll_recovery_time;
	//pose_handler.clear();
	//pose_handler.AddLayer("Data/Animations/run.pos",
	//					  0.000f,
	//					  false);
	//pose_handler.AddLayer("Data/Animations/test.pos",
	//					  1.0f,
	//					  false);
}

void UpdateDuckAmount() {
	duck_vel += (target_duck_amount - duck_amount) * time_step * _duck_accel;
	duck_amount += duck_vel * time_step;
	duck_vel *= _duck_vel_inertia;
}

void UpdateGroundAndAirTime() {
	if(on_ground){
		on_ground_time += time_step;
	} else {
		air_time += time_step;
	}
}

void UpdateAirWhooshSound() {
	float whoosh_amount = length(this_mo.velocity)*0.05f;
	if(!limp){
		whoosh_amount += flip_info.WhooshAmount();
	}
	float whoosh_pitch = min(2.0f,whoosh_amount*0.5f + 0.5f);
	if(!on_ground){
		whoosh_amount *= 1.5f;
	}
	SetAirWhoosh(whoosh_amount*0.5f,whoosh_pitch);
}

void UpdateAttacking() {	
	flip_info.UpdateRoll();

	vec3 direction = this_mo.ReadCharacter(target_id).position - this_mo.position;
	direction.y = 0.0f;
	direction = normalize(direction);
	if(on_ground){
		this_mo.velocity *= 0.95f;
	} else {
		ApplyPhysics();
	}
	this_mo.SetRotationFromFacing(InterpDirections(this_mo.GetFacing(),
												   direction,
												   0.1f));

	vec3 right_direction;
	right_direction.x = direction.z;
	right_direction.z = -direction.x;
	if(!on_ground){
		float rel_height = normalize(this_mo.ReadCharacter(target_id).position - this_mo.position).y;
		float leg_cannon_target_flip = -1.4f - rel_height;
		leg_cannon_flip = mix(leg_cannon_flip, leg_cannon_target_flip, 0.1f);
		this_mo.SetFlip(right_direction,leg_cannon_flip,0.0f);
	}
	
	bool mirrored;
	if(!mirrored_stance){
		mirrored = (dot(right_direction, GetTargetVelocity())>0.1f);
	} else {
		mirrored = (dot(right_direction, GetTargetVelocity())>-0.1f);
	}
	bool front = //(dot(direction, GetTargetVelocity())>0.7f) || 
				 length_squared(GetTargetVelocity())<0.1f;

	

	if(attack_animation_set &&
	   this_mo.GetStatusKeyValue("cancel")>=1.0f && 
	   WantsToCancelAnimation())
	{
		if(cancel_delay <= 0.0f){
			EndAttack();
		}
		cancel_delay -= time_step;
	} else {
		cancel_delay = 0.01f;
	}

	if(!attack_animation_set){
		ChooseAttack(front);
		string attack_path;
		if(curr_attack == "stationary"){
			attack_path = character_getter.GetAttackPath("stationary");
		} else if(curr_attack == "moving"){
			attack_path = character_getter.GetAttackPath("moving");
		} else if(curr_attack == "low"){
			attack_path = character_getter.GetAttackPath("low");
		} else if(curr_attack == "air"){
			attack_path = character_getter.GetAttackPath("air");
		}
		attack_getter.Load(attack_path);
		if(attack_getter.GetSpecial() == "legcannon"){	
			leg_cannon_flip = 0.0f;
		}

		bool flipped = false;
		if(attack_getter.GetDirection() != _front) {
			flipped = mirrored;
		} else {
			flipped = !mirrored_stance;
		}
		if(flipped){
			attack_path += " m";
		}
		attack_getter.Load(attack_path);

		if(attack_getter.GetHeight() == _low){
			duck_amount = 1.0f;
		} else {
			duck_amount = 0.0f;
		}
		if(attack_getter.GetDirection() == _right){
			if(!mirrored){
				this_mo.StartAnimation(attack_getter.GetUnblockedAnimPath());
				mirrored_stance = false;
			} else {
				this_mo.StartMirroredAnimation(attack_getter.GetUnblockedAnimPath());
				mirrored_stance = true;
			}
		} else {
			if(mirrored_stance){
				this_mo.StartMirroredMobileAnimation(attack_getter.GetUnblockedAnimPath());
			} else {
				this_mo.StartMobileAnimation(attack_getter.GetUnblockedAnimPath());
			}
		}
		string material_event = attack_getter.GetMaterialEvent();
		if(material_event.length() > 0){
			Print(material_event);
			this_mo.MaterialEvent(material_event,
						this_mo.position-vec3(0.0f,_leg_sphere_size, 0.0f));
		}
		if(attack_getter.GetSwapStance() != 0){
			mirrored_stance = !mirrored_stance;
		}
		this_mo.SetAnimationCallback("void EndAttack()");
		attack_animation_set = true;
	}

	/*float old_attacking_time = attacking_time;
	attacking_time += time_step;
	if(attacking_time > 0.25f && old_attacking_time <= 0.25f){
		target.ApplyForce(direction*20);
		TimedSlowMotion(0.1f,0.7f);
	}*/
}

void UpdateHitReaction() {
	if(!hit_reaction_anim_set){
		if(hit_reaction_event == "blockprepare"){
			bool right = (attack_getter2.GetDirection() != _left);
			if(attack_getter2.GetMirrored() != 0){
				right = !right;
			}
			if(mirrored_stance){
				right = !right;
			}
			string block_string;
			if(attack_getter2.GetHeight() == _high){
				block_string += "high";
			} else if(attack_getter2.GetHeight() == _medium){
				block_string += "med";
			} else if(attack_getter2.GetHeight() == _low){
				block_string += "low";
			}		
			if(right){
				block_string += "right";
			} else {
				block_string += "left";
			}
			block_string += "block";
			if(mirrored_stance){
				this_mo.StartMirroredAnimation(character_getter.GetAnimPath(block_string),40.0f);
			} else {
				this_mo.StartAnimation(character_getter.GetAnimPath(block_string),40.0f);
			}
		} else if(hit_reaction_event == "attackimpact") {
			if(reaction_getter.GetMirrored() == 0){
				this_mo.StartMobileAnimation(reaction_getter.GetAnimPath(1.0f-block_health),20.0f);
				mirrored_stance = false;
			} else {
				this_mo.StartMobileMirroredAnimation(reaction_getter.GetAnimPath(1.0f-block_health),20.0f);
				mirrored_stance = true;
			}
		}
		this_mo.SetAnimationCallback("void EndHitReaction()");
		hit_reaction_anim_set = true;
		this_mo.SetFlip(vec3(1.0f,0.0f,0.0f),0.0f,0.0f);
	}
	this_mo.velocity *= 0.95f;
	if(this_mo.GetStatusKeyValue("cancel")>=1.0f && WantsToCancelAnimation()){
		EndHitReaction();
	}
}

void SetState(int _state) {
	state = _state;
	if(state == _ground_state){
		Print("Setting state to ground state");
		//this_mo.StartAnimation("Data/Animations/kipup.anm");
		if(!mirrored_stance){
			this_mo.StartAnimation(character_getter.GetAnimPath("idle"));
		} else {
			this_mo.StartMirroredAnimation(character_getter.GetAnimPath("idle"));
		}
		this_mo.SetAnimationCallback("void EndGetUp()");
		getting_up_time = 0.0f;	
	}
	if(state != _attack_state){
		curr_attack = "";
	}
}

const int _wake_stand = 0;
const int _wake_flip = 1;
const int _wake_roll = 2;
const int _wake_fall = 3;


void WakeUp(int how) {
	SetState(_movement_state);
	this_mo.UnRagdoll();
	
	HandleBumperCollision();
	HandleStandingCollision();
	this_mo.position = sphere_col.position;

	// No standing up animations yet
	if(how == _wake_stand){
		how = _wake_fall;
	}

	limp = false;
	duck_amount = 1.0f;
	duck_vel = 0.0f;
	target_duck_amount = 1.0f;
	if(how == _wake_stand){
		SetOnGround(true);
		flip_info.Land();
		SetState(_ground_state);
	} else if(how == _wake_fall){
		SetOnGround(true);
		flip_info.Land();
		if(!mirrored_stance){
			this_mo.StartAnimation(character_getter.GetAnimPath("idle"));
		} else {
			this_mo.StartMirroredAnimation(character_getter.GetAnimPath("idle"));
		}
	} else if (how == _wake_flip) {
		SetOnGround(false);
		jump_info.StartFall();
		flip_info.StartFlip();
		flip_info.FlipRecover();
		this_mo.StartAnimation(character_getter.GetAnimPath("jump"));
	} else if (how == _wake_roll) {
		SetOnGround(true);
		flip_info.Land();
		if(!mirrored_stance){
			this_mo.StartAnimation(character_getter.GetAnimPath("idle"));
		} else {
			this_mo.StartMirroredAnimation(character_getter.GetAnimPath("idle"));
		}
		vec3 roll_dir = GetTargetVelocity();
		vec3 flat_vel = vec3(this_mo.velocity.x, 0.0f, this_mo.velocity.z);
		if(length(flat_vel)>1.0f){
			roll_dir = normalize(flat_vel);
		}
		flip_info.StartRoll(roll_dir);
	}
}

bool CanRoll() {
	vec3 sphere_center = this_mo.position;
	float radius = 1.0f;
	this_mo.GetSlidingSphereCollision(sphere_center, radius);
	bool can_roll = true;
	vec3 roll_point;
	if(sphere_col.NumContacts() == 0){
		can_roll = false;
	} else {
		can_roll = false;
		roll_point = sphere_col.GetContact(0).position;
		for(int i=0; i<sphere_col.NumContacts(); i++){
			const CollisionPoint contact = sphere_col.GetContact(i);
			if(contact.position.y < roll_point.y){
				roll_point = contact.position;
			}
			if(contact.normal.y > 0.5f){
				can_roll = true;
			}
		}
	}
	return can_roll;
}

void UpdateRagDoll() {
	if(GetInputDown("z")){		
		GoLimp();
	}
	if(GetInputDown("x")){		
		//if(knocked_out != 0){
			knocked_out = 0;
			block_health = 1.0f;
			temp_health = 1.0f;
			permanent_health = 1.0f;
			recovery_time = 0.0f;
			//this_mo.UnRagdoll();
		//}
	}
	if(limp == true && knocked_out==0){
		recovery_time -= time_step;
		if(recovery_time <= 0.0f){
			bool can_roll = CanRoll();
			if(can_roll){
				WakeUp(_wake_stand);
			} else {
				WakeUp(_wake_fall);
			}
		} else {
			if(WantsToRollFromRagdoll()){
				bool can_roll = CanRoll();
				if(!can_roll){
					WakeUp(_wake_flip);
				} else {
					WakeUp(_wake_roll);
					//this_mo.position = roll_point + 
					//z				   vec3(0.0f,_leg_sphere_size,0.0f);
				}
			}
			return;
		}
	}
}


bool testing_mocap = false;
void TestMocap(){
	//this_mo.SetAnimation("Data/Animations/mocapsit.anm");
	this_mo.SetAnimation(character_getter.GetAnimPath("idle"));
	this_mo.SetAnimationCallback("void EndTestMocap()");
	testing_mocap = true;
	this_mo.velocity = vec3(0.0f);
	this_mo.position += vec3(0.0f,-0.1f,0.0f);
	this_mo.position = vec3(16.23, 109.45, 11.71);
	this_mo.SetRotationFromFacing(vec3(0.0f,0.0f,1.0f));
}

void EndTestMocap() {
	testing_mocap = false;
}

int count = 0;

void EndGetUp(){
	state = _movement_state;
	duck_amount = 1.0f;
	duck_vel = 0.0f;
	target_duck_amount = 1.0f;
}

void HandleGroundStateCollision() {
	HandleBumperCollision();
	HandleStandingCollision();
	this_mo.position = sphere_col.position;
	if(sphere_col.NumContacts() == 0){
		this_mo.position.y -= 0.1f;
	}
	for(int i=0; i<sphere_col.NumContacts(); i++){
		const CollisionPoint contact = sphere_col.GetContact(i);
		if(distance(contact.position, this_mo.position)<=_leg_sphere_size+0.01f){
			ground_normal = ground_normal * 0.9f +
							contact.normal * 0.1f;
			ground_normal = normalize(ground_normal);
		}
	}
}

void Nothing() {
}

void UpdateGroundState() {
	this_mo.velocity = vec3(0.0f);
	
	/*this_mo.SetAnimation("Data/Animations/onback.anm");
	this_mo.SetAnimationCallback("void Nothing()");
	this_mo.velocity += GetTargetVelocity() * time_step * _walk_accel;
	*/
	HandleGroundStateCollision();
	getting_up_time += time_step;
}

float time = 0;

const float _smear_time_threshold = 0.3f;
float smear_sound_time = 0.0f;
float left_smear_time = 0.0f;
float right_smear_time = 0.0f;
float _dist_threshold = 0.1f;
vec3 left_decal_pos;
vec3 right_decal_pos;
void DecalCheck(){
	/*DebugDrawWireSphere(left_decal_pos,
						0.1f,
						vec3(1.0f),
						_delete_on_update);*/
	if(!feet_moving || length_squared(this_mo.velocity) < 0.3f){
		vec3 curr_left_decal_pos = this_mo.GetIKTargetPosition("left_leg");
		vec3 curr_right_decal_pos = this_mo.GetIKTargetPosition("right_leg");
		/*DebugDrawWireSphere(curr_left_decal_pos,
						0.1f,
						vec3(1.0f),
						_delete_on_update);*/
		if(distance(curr_left_decal_pos, left_decal_pos) > _dist_threshold){
			if(left_smear_time < _smear_time_threshold){
				//this_mo.ChangeLastMaterialDecalDirection("left_leg",curr_left_decal_pos - left_decal_pos);
			} 
			/*if(smear_sound_time > 0.1f){
				PlaySoundGroup("Data/Sounds/footstep_mud.xml", curr_left_decal_pos);
				smear_sound_time = 0.0f;
			}*/
			//this_mo.MaterialDecalAtBone("step","left_leg");
			this_mo.MaterialParticleAtBone("skid","left_leg");
			//MakeSplatParticle(curr_left_decal_pos);
			left_decal_pos = curr_left_decal_pos;
			left_smear_time = 0.0f;
		}
		if(distance(curr_right_decal_pos, right_decal_pos) > _dist_threshold){
			if(right_smear_time < _smear_time_threshold){
				//this_mo.ChangeLastMaterialDecalDirection("right_leg",curr_right_decal_pos - right_decal_pos);
			}
			/*if(smear_sound_time > 0.1f){
				PlaySoundGroup("Data/Sounds/footstep_mud.xml", curr_left_decal_pos);
				smear_sound_time = 0.0f;
			}*/
			right_decal_pos = curr_right_decal_pos;
			//this_mo.MaterialDecalAtBone("step","right_leg");
			this_mo.MaterialParticleAtBone("skid","right_leg");
			//MakeSplatParticle(curr_right_decal_pos);
			right_smear_time = 0.0f;
		}
	}
}

void HandleActiveBlock() {
	if(WantsToStartActiveBlock()){
		if(active_block_recharge <= 0.0f){
			active_blocking = true;
			active_block_duration = 0.2f;
		}
		active_block_recharge = 0.2f;
	} 
	if(active_blocking){
		active_block_duration -= time_step;
		if(active_block_duration <= 0.0f){
			active_blocking = false;
		}
	} else {
		if(active_block_recharge > 0.0f){
			active_block_recharge -= time_step;
		}
	}
	if(!controlled){
		active_blocking = (rand()%4)==0;
	}
}

void HandleCollisionsBetweenTwoCharacters(int which){
	if(this_mo.position == this_mo.ReadCharacter(which).position){
		return;
	}

	if(knocked_out == 0 && this_mo.ReadCharacter(which).IsKnockedOut() == 0){
		float distance_threshold = 0.7f;
		vec3 this_com = this_mo.GetCenterOfMass()*0.33;
		vec3 other_com = this_mo.ReadCharacter(which).GetCenterOfMass()*0.33;
		this_com.y = this_mo.position.y;
		other_com.y = this_mo.ReadCharacter(which).position.y;
		if(distance_squared(this_com, other_com) < distance_threshold*distance_threshold){
			vec3 dir = other_com - this_com;
			float dist = length(dir);
			dir /= dist;
			dir *= distance_threshold - dist;
			if(on_ground || this_mo.ReadCharacter(which).IsOnGround()==1){
				this_mo.ReadCharacter(which).position += dir * 0.5f;
				this_mo.position -= dir * 0.5f;
			} else {
				this_mo.ReadCharacter(which).velocity += dir * 0.5f / time_step;
				this_mo.velocity -= dir * 0.5f / time_step;
			}
		}	
	}
}

void HandleCollisionsBetweenCharacters() {
	int num_chars = this_mo.GetNumCharacters();

	for(int i=0; i<num_chars; ++i){
		HandleCollisionsBetweenTwoCharacters(i);
	}
}

void update(bool _controlled) {	
	HandleActiveBlock();

	AIUpdate();
	time += time_step;
	//this_mo.SetMorphTargetWeight("fist_l",min(1,max(0,sin(time*3))),0.0f);
	/*this_mo.SetMorphTargetWeight("wink_r",sin(time*3),1.0f);
	this_mo.SetMorphTargetWeight("wink_l",sin(time*2+0.3),1.0f);
	this_mo.SetMorphTargetWeight("squint_l",sin(time*3),1.0f);
	this_mo.SetMorphTargetWeight("squint_r",sin(time*2),1.0f);
	this_mo.SetMorphTargetWeight("oh",sin(time*3),1.0f);
	this_mo.SetMorphTargetWeight("mouth_open",sin(time*4),1.0f);
	this_mo.SetMorphTargetWeight("sniff",sin(time*20)*0.5+0.5,1.0f);*/

	if(testing_mocap) {
		this_mo.cam_rotation += 0.05f;
		return;
	}
	controlled = _controlled;

	if(controlled){
		UpdateAirWhooshSound();
	}
	UpdateRagDoll();	
	if(limp){
		return;
	}

	/*vec3 vel(RangedRandomFloat(-20.0f,20.0f),
			 RangedRandomFloat(0.0f,100.0f),
			 RangedRandomFloat(-20.0f,20.0f));
	vel *= 0.05;*/
	//MakeParticle("Data/Particles/spark.xml",this_mo.position + vec3(0.0,0.7,0.0), vel);
	//MakeParticle("Data/Particles/smoke.xml",this_mo.position + vec3(0.0,0.7,0.0), vel);
	//MakeParticle("Data/Particles/heavysand.xml",this_mo.position + vec3(0.0,0.7,0.0), vel);
	//MakeParticle("Data/Particles/heavydirt.xml",this_mo.position + vec3(0.0,0.7,0.0), vel);
	//MakeParticle("Data/Particles/bloodsplat.xml",this_mo.position + vec3(0.0,0.7,0.0), vel);
	//MakeParticle("Data/Particles/impactfast.xml",this_mo.position + vec3(0.0,0.7,0.0), vel);
	//MakeParticle("Data/Particles/impactslow.xml",this_mo.position + vec3(0.0,0.7,0.0), vel);

	//MakeImpactParticle(this_mo.position);

	block_health += time_step * 0.3f;
	block_health = min(temp_health, block_health);
	temp_health += time_step * 0.05f;
	temp_health = min(permanent_health, temp_health);

	if(state == _movement_state){
		UpdateDuckAmount();
		UpdateGroundAndAirTime();
		HandleAccelTilt();
		UpdateMovementControls();
		UpdateAnimation();
		ApplyPhysics();
		
		HandleGroundCollision();
	} else if(state == _ground_state){
		HandleAccelTilt();
		UpdateGroundState();
	} else if(state == _attack_state){
		HandleAccelTilt();
		UpdateAttacking();
		HandleGroundCollision();
	} else if(state == _hit_reaction_state){
		UpdateHitReaction();
		HandleAccelTilt();
		HandleGroundCollision();
	}
/*
	if(GetInputPressed("x")){
		NavPath temp = this_mo.GetPath(this_mo.position,
										this_mo.ReadCharacter(target_id).position);
		int num_points = temp.NumPoints();
		for(int i=0; i<num_points-1; i++){
			DebugDrawLine(temp.GetPoint(i),
						  temp.GetPoint(i+1),
						  vec3(1.0f,1.0f,1.0f),
						  _persistent);
		}
	}*/
	if(controlled && GetInputPressed("1")){	
		character_getter.Load("Data/Characters/guard.xml");
		this_mo.RecreateRiggedObject(character_getter.GetObjPath(),
									 character_getter.GetSkeletonPath());
		this_mo.StartAnimation(character_getter.GetAnimPath("idle"));
		SetState(_movement_state);
	}
	if(controlled && GetInputPressed("2")){
		character_getter.Load("Data/Characters/guard2.xml");
		this_mo.RecreateRiggedObject(character_getter.GetObjPath(),
									 character_getter.GetSkeletonPath());
		this_mo.StartAnimation(character_getter.GetAnimPath("idle"));
		SetState(_movement_state);
	}
	if(controlled && GetInputPressed("3")){
		character_getter.Load("Data/Characters/turner.xml");
		this_mo.RecreateRiggedObject(character_getter.GetObjPath(),
									 character_getter.GetSkeletonPath());
		this_mo.StartAnimation(character_getter.GetAnimPath("idle"));
		SetState(_movement_state);
	}
	if(controlled && GetInputPressed("4")){
		character_getter.Load("Data/Characters/civ.xml");
		this_mo.RecreateRiggedObject(character_getter.GetObjPath(),
									 character_getter.GetSkeletonPath());
		this_mo.StartAnimation(character_getter.GetAnimPath("idle"));
		SetState(_movement_state);
	}
	if(controlled && GetInputPressed("5")){
		
		character_getter.Load("Data/Characters/wolf.xml");
		this_mo.RecreateRiggedObject(character_getter.GetObjPath(),
									 character_getter.GetSkeletonPath());
		this_mo.StartAnimation(character_getter.GetAnimPath("idle"));
		SetState(_movement_state);
	}
	/*
	if(GetInputPressed("c")){
		if(state == _movement_state){
			SetState(_ground_state);
		} else {
			SetState(_movement_state);
		}
//		TestMocap();
	}*/

	HandleCollisionsBetweenCharacters();

	float terminal_velocity = 50.0f;
	if(length_squared(this_mo.velocity) > terminal_velocity*terminal_velocity){
		this_mo.velocity *= 0.99f;
	}	
	
	tilt = tilt * _tilt_inertia +
		   target_tilt * (1.0f - _tilt_inertia);

	//tilt = vec3(sin(time*2.0f)*20.0f,0.0f,0.0f);

	this_mo.SetTilt(tilt);

	
	if(on_ground && state == _movement_state){
		DecalCheck();
	}
	left_smear_time += time_step;
	right_smear_time += time_step;
	smear_sound_time += time_step;
}

void init(string character_path) {
	character_getter.Load(character_path);
	this_mo.RecreateRiggedObject(character_getter.GetObjPath(),
								 character_getter.GetSkeletonPath());
	for(int i=0; i<5; ++i){
		HandleBumperCollision();
		HandleStandingCollision();
		this_mo.position = sphere_col.position;
	}
}

void UpdateAnimation() {
	vec3 flat_velocity = vec3(this_mo.velocity.x,0,this_mo.velocity.z);

	float run_amount, walk_amount, idle_amount;
	float speed = length(flat_velocity);
	
	this_mo.SetBlendCoord("tall_coord",1.0f-duck_amount);
	
	if(on_ground){
		// rolling on the ground
		if(flip_info.UseRollAnimation()){
			this_mo.SetAnimation(character_getter.GetAnimPath("roll"),7.0f);
			float forwards_rollness = 1.0f-abs(dot(flip_info.GetAxis(),this_mo.GetFacing()));
			this_mo.SetBlendCoord("forward_roll_coord",forwards_rollness);
			this_mo.SetIKEnabled(false);
			roll_ik_fade = min(roll_ik_fade + time_step * 5.0f, 1.0f);
		} else {
			// running, walking and idle animation
			this_mo.SetIKEnabled(true);
			
			// when he's moving instead of idling, the character turns to the movement direction.
			// the different movement types are listed in XML files, and are blended together
			// by variables such as speed or crouching amount (blending values should be 0 and 1)
			// when there are more than two animations to blend, the XML file refers to another 
			// XML file which asks for another blending variable.
			if(speed > _walk_threshold && feet_moving){
				this_mo.SetRotationFromFacing(InterpDirections(this_mo.GetFacing(),
															   normalize(flat_velocity),
															   0.2f));
				this_mo.SetAnimation(character_getter.GetAnimPath("movement"));
				this_mo.SetBlendCoord("speed_coord",speed);
				this_mo.SetBlendCoord("ground_speed",speed);
			} else {
				if(!mirrored_stance){
					this_mo.SetAnimation(character_getter.GetAnimPath("idle"));
				} else {
					this_mo.SetMirroredAnimation(character_getter.GetAnimPath("idle"));
				}
				this_mo.SetIKEnabled(true);
			}
			roll_ik_fade = max(roll_ik_fade - time_step * 5.0f, 0.0f);
		}
	} else {
		jump_info.UpdateAirAnimation();
	}

	this_mo.SetCOMOffset(com_offset, com_offset_vel);
}

const float _check_up = 1.0f;
const float _check_down = -1.0f;
	
vec3 GetLegTargetOffset(vec3 initial_pos){
	/*DebugDrawLine(initial_pos + vec3(0.0f,_check_up,0.0f),
				  initial_pos + vec3(0.0f,_check_down,0.0f),
				  vec3(1.0f),
				  _delete_on_draw);*/
	this_mo.GetSweptSphereCollision(initial_pos + vec3(0.0f,_check_up,0.0f),
								    initial_pos + vec3(0.0f,_check_down,0.0f),
								    0.05f);

	if(sphere_col.NumContacts() == 0){
		return vec3(0.0f);
	}

	float target_y_pos = sphere_col.position.y;
	float height = initial_pos.y - this_mo.position.y + _leg_sphere_size - 0.05f;
	target_y_pos += height;
	/*DebugDrawWireSphere(sphere_col.position,
				  0.05f,
				  vec3(1.0f),
				  _delete_on_draw);*/
	
	float offset_amount = target_y_pos - initial_pos.y;
	offset_amount /= max(0.0f,height)+1.0f;

	//offset_amount = max(-0.15f,min(0.15f,offset_amount));

	return vec3(0.0,offset_amount, 0.0f);
}

float offset_height = 0.0f;


vec3 GetLimbTargetOffset(vec3 initial_pos, vec3 anim_pos){
	/*DebugDrawLine(initial_pos + vec3(0.0f,0.0f,0.0f),
				  initial_pos + vec3(0.0f,_check_down,0.0f),
				  vec3(1.0f),
				  _delete_on_draw);
	*/
	this_mo.GetSweptSphereCollision(initial_pos + vec3(0.0f,_check_up,0.0f),
								    initial_pos + vec3(0.0f,_check_down,0.0f),
								    0.05f);

	if(sphere_col.NumContacts() == 0){
		return vec3(0.0f);
	}

	float target_y_pos = sphere_col.position.y;
	float height = anim_pos.y + 0.8f;// _leg_sphere_size;
	target_y_pos += height;
	/*DebugDrawWireSphere(sphere_col.position,
				  0.05f,
				  vec3(1.0f),
				  _delete_on_draw);
	*/
	float offset_amount = target_y_pos - initial_pos.y;
	//offset_amount /= max(0.0f,height)+1.0f;

	offset_amount = max(-0.3f,min(0.3f,offset_amount));

	return vec3(0.0,offset_amount, 0.0f);
}

void SetLimbTargetOffset(string name){
	vec3 pos = this_mo.GetIKTargetPosition(name);
	vec3 anim_pos = this_mo.GetIKTargetAnimPosition(name);
	vec3 offset = GetLimbTargetOffset(pos, anim_pos);
	this_mo.SetIKTargetOffset(name,offset);
}

void GroundState_UpdateIKTargets() {
	vec3 offset = vec3(0.0f,0.0f,0.0f);

	SetLimbTargetOffset("left_leg");
	SetLimbTargetOffset("right_leg");
	SetLimbTargetOffset("leftarm");
	SetLimbTargetOffset("rightarm");
	this_mo.SetIKTargetOffset("full_body", vec3(0.0f,-0.1f,0.0f));
	//this_mo.SetIKTargetOffset("full_body", ground_normal * 0.05);
	
	vec3 axis = cross(ground_normal, vec3(0.0f,1.0f,0.0f));

	float x_amount = ground_normal.y;
	float y_amount = length(vec3(ground_normal.x, 0.0f, ground_normal.z));
	float angle = atan2(y_amount, x_amount);

	angle *= min(1.0f,max(0.0f,1.0f - (getting_up_time-0.3f) * 2.0f));
	this_mo.SetFlip(axis,-angle,0.0f);
}

float roll_ik_fade = 0.0f;

int IsOnGround() {
	if(on_ground){
		return 1;
	} else {
		return 0;
	}
}

void MovementState_UpdateIKTargets() {
	if(!on_ground){
		jump_info.UpdateIKTargets();
	} else {
		vec3 tilt_offset = tilt * -0.005f;
		float left_ik_weight = this_mo.GetIKWeight("left_leg");
		float right_ik_weight = this_mo.GetIKWeight("right_leg");

		vec3 left_leg = this_mo.GetIKTargetPosition("left_leg");
		vec3 right_leg = this_mo.GetIKTargetPosition("right_leg");

		vec3 foot_apart = right_leg - left_leg;
		foot_apart.y = 0.0f;
		float bring_feet_together = min(0.4f,max(0.0f,1.0f-ground_normal.y)*2.0f);

		float two_feet_on_ground;
		if(left_ik_weight > right_ik_weight){
			two_feet_on_ground = right_ik_weight / left_ik_weight;
		} else if(right_ik_weight > left_ik_weight){
			two_feet_on_ground = left_ik_weight / right_ik_weight;
		} else {
			two_feet_on_ground = 1.0f;
		}

		bring_feet_together *= two_feet_on_ground;

		vec3 left_leg_offset = foot_apart * bring_feet_together * 0.5f;
		vec3 right_leg_offset = foot_apart * bring_feet_together * -0.5f;

		left_leg_offset += GetLegTargetOffset(left_leg+left_leg_offset);
		right_leg_offset += GetLegTargetOffset(right_leg+right_leg_offset);
		
		this_mo.SetIKTargetOffset("left_leg",left_leg_offset*(1.0f-roll_ik_fade)-tilt_offset*0.5f);
		this_mo.SetIKTargetOffset("right_leg",right_leg_offset*(1.0f-roll_ik_fade)-tilt_offset*0.5f);
			
		//float curr_avg_offset_height = min(0.0f,
		//						  min(left_leg_offset.y, right_leg_offset.y));
		float avg_offset_height = (left_leg_offset.y + right_leg_offset.y) * 0.5f;
		float min_offset_height = min(0.0f, min(left_leg_offset.y, right_leg_offset.y));
		float mix_amount = 1.0f;//min(1.0f,length(this_mo.velocity));
		float curr_offset_height = mix(min_offset_height, avg_offset_height,mix_amount);
		offset_height = mix(offset_height, curr_offset_height, 0.1f);
		vec3 height_offset = vec3(0.0f,offset_height*(1.0f-roll_ik_fade)-0.1f*roll_ik_fade,0.0f);
		this_mo.SetIKTargetOffset("full_body",tilt_offset + height_offset);

		float ground_conform = this_mo.GetStatusKeyValue("groundconform");
		//Print(""+ground_conform+"\n");
		if(ground_conform > 0.0f){
			ground_conform = min(1.0f, ground_conform);
			vec3 axis = cross(ground_normal, vec3(0.0f,1.0f,0.0f));

			float x_amount = ground_normal.y;
			float y_amount = length(vec3(ground_normal.x, 0.0f, ground_normal.z));
			float angle = atan2(y_amount, x_amount);

			this_mo.SetFlip(axis,-angle*ground_conform,0.0f);
			this_mo.SetIKTargetOffset("full_body", vec3(0.0f,offset_height*(1.0f-ground_conform),0.0f));
		}
	}
}

void UpdateIKTargets() {
	if(state == _ground_state){
		GroundState_UpdateIKTargets();
	} else {
		MovementState_UpdateIKTargets();
	}
}

void UpdateVelocity() {
	this_mo.velocity += GetTargetVelocity() * time_step * _walk_accel;
}

void ApplyPhysics() {
	if(!on_ground){
		this_mo.velocity += physics.gravity_vector * time_step;
	}
	if(on_ground){
		if(feet_moving){
			const float e = 2.71828183f;
			float exp = _walk_accel*time_step*-1/max_speed;
			float current_movement_friction = pow(e,exp);
			this_mo.velocity *= current_movement_friction;
		} else {
			this_mo.velocity *= 0.95f;
		}
	}
}