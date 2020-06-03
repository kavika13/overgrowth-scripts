#include "interpdirection.as"

bool limp = false; // true if ragdoll is enabled

float air_time = 0.0f;

// Pre-jump happens after jump key is pressed and before the character gets upwards velocity. The time available for the jump animation that happens on the ground. 
bool pre_jump = false;
float pre_jump_time;
const float _pre_jump_delay = 0.04f; // the time between a jump being initiated and the jumper getting upwards velocity, time available for pre-jump animation

// whether the character is in the ground or in the air, and how long time has passed since the status changed. 
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

// feet are moving if character isn't standing still, defined by targetvelocity being larger than 0.0 in UpdateGroundMovementControls()
bool feet_moving = false;
float getting_up_time;

int run_phase = 1;

string hit_reaction_event;

// states are used to differentiate between various widely different situations
const int _movement_state = 0; // character is moving on the ground
const int _ground_state = 1; // character has fallen down or is raising up, ATM ragdolls handle most of this
const int _attack_state = 2; // character is performing an attack
const int _hit_reaction_state = 3; // character was hit or dealt damage to and has to react to it in some manner
int state;

bool attack_animation_set = false;
bool hit_reaction_anim_set = false;
bool attacking_with_throw;

const float _attack_range = 1.6f;
const float _close_attack_range = 1.0f;

// running and movement
const float _run_threshold = 0.8f; // when character is moving faster than this, it runs
const float _walk_threshold = 0.6f; // when character is moving slower than this, it's idling
const float _walk_accel = 35.0f; // how fast characters accelerate when moving
float duck_amount = 0.0f; // duck_amount is changed incrementally to animate crouching or standing up from a crouch
float target_duck_amount = 0.0f; // this is 1.0 when the character crouches down,  0.0 otherwise. Used in UpdateDuckAmount() 
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

// The 'controlled' variable is true when the character is controlled by a human, false when the character is controlled by AI. 
// It's changed in the update(bool _controlled) function.
bool controlled = false;

// center of mass offset that will eventually be used for animation, but is probably used yet.
vec3 com_offset;
vec3 com_offset_vel;

bool mirrored_stance = false;

float block_health = 1.0f;
float temp_health = 1.0f;
float permanent_health = 1.0f;
int knocked_out = 0; // zero means conscious, 1 unconscious

vec3 old_vel;
vec3 accel_tilt;
vec3 last_col_pos;

float cancel_delay;

bool active_blocking = false;
float active_block_duration = 0.0f;
float active_block_recharge = 0.0f;

string curr_attack; 
int target_id = -1;
int self_id;

int num_frames;

const float _ragdoll_static_threshold = 0.4f;
float ragdoll_static_time;
float ragdoll_time;
bool frozen;
bool no_freeze = false;
bool holding_weapon = false;
float injured_mouth_open;
int weapon_id = -1;

const int _RGDL_FALL = 0;
const int _RGDL_LIMP = 1;
const int _RGDL_INJURED = 2;

int ragdoll_type;
int ragdoll_layer_fetal;
int ragdoll_layer_catchfallfront;
float ragdoll_limp_stun;

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

// WasBlocked() is executed if this character's attack was blocked by a different character
void WasBlocked() {
	this_mo.SwapAnimation(attack_getter.GetBlockedAnimPath());
	if(attack_getter.GetSwapStance() != attack_getter.GetSwapStanceBlocked()){
		mirrored_stance = !mirrored_stance;
	}
}

// Handles what happens if a character was hit.  Includes blocking enemies' attacks, hit reactions, taking damage, going ragdoll and applying forces to ragdoll.
// Type is a string that identifies the action and thus the reaction, dir is the vector from the attacker to the defender, and pos is the impact position.
int WasHit(string type, string attack_path, vec3 dir, vec3 pos) {
	attack_getter2.Load(attack_path);

	if(type == "grabbed"){
		if(limp){
			return 0;
		}
		this_mo.position = pos;
		this_mo.SetRotationFromFacing(dir);
		int8 flags = _ANM_MOBILE;
		if(attack_getter2.GetMirrored() == 0){
			flags = flags | _ANM_MIRRORED;
		}
		this_mo.StartAnimation(attack_getter2.GetThrownAnimPath(),1000.0f,flags);
		SetState(_hit_reaction_state);
		hit_reaction_anim_set = true;
		if(!controlled){
			this_mo.PlaySoundGroupVoice("surprise", 0.3f);
			this_mo.PlaySoundGroupVoice("land_hit", 0.6f);
		}
	}
	if(type == "attackblocked")
	{
		string sound = "Data/Sounds/hit/hit_block.xml";
		PlaySoundGroup(sound, pos);
		//MakeParticle("Data/Particles/bloodsplat.xml",pos,dir*5.0f);
		MakeParticle("Data/Particles/impactfast.xml",pos,vec3(0.0f));
		MakeParticle("Data/Particles/impactslow.xml",pos,vec3(0.0f));
		TimedSlowMotion(0.1f,0.3f, 0.05f);
		if(controlled){
			camera.AddShake(0.5f);
		}
		return 3;
	}
	if(type == "blockprepare")
	{
		if(state == _movement_state && limp == false && on_ground && !flip_info.IsFlipping()){
			if(active_blocking && attack_getter2.GetUnblockable() == 0){
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
		if(controlled){
			camera.AddShake(1.0f);
		}
		if(attack_getter2.GetHeight() == _high &&
			duck_amount > 0.5f)
		{
			return 0;
		}
		if(attack_getter2.GetSpecial() == "legcannon"){
			block_health = 0.0f;
		}
	
		if(!controlled){
			this_mo.PlaySoundGroupVoice("hit",0.0f);
		}

		block_health -= attack_getter2.GetBlockDamage();
		block_health = max(0.0f, block_health);

		if(block_health <= 0.0f || state == _attack_state || !on_ground){
			MakeParticle("Data/Particles/impactfast.xml",pos,vec3(0.0f));
			MakeParticle("Data/Particles/impactslow.xml",pos,vec3(0.0f));
			float force = attack_getter2.GetForce()*(1.0f-temp_health*0.5f);
			GoLimp();
			ragdoll_limp_stun = 0.9f;

			vec3 impact_dir = attack_getter2.GetImpactDir();
			//Print(""+impact_dir.x + "\n" + impact_dir.y + "\n" + impact_dir.z + "\n\n");
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
				if(!controlled){
					this_mo.PlaySoundGroupVoice("death",0.4f);
					//sound = "Data/Sounds/voice/torikamal/sleeping.xml";
					//this_mo.PlaySoundGroupVoice(sound,1.5f);
				}
			} else {
				string sound = "Data/Sounds/hit/hit_medium.xml";
				PlaySoundGroup(sound, pos);
			}
			temp_health = max(0.0f, temp_health);
		} else {
			string sound = "Data/Sounds/hit/hit_normal.xml";
			PlaySoundGroup(sound, pos);
			/*if(!controlled && rand()%2==0){
				string sound = "Data/Sounds/voice/torikamal/was_hit_taunt.xml";
				this_mo.PlaySoundGroupVoice(sound,0.2f);
			}*/
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
		return 2;
	}
	return 4;
}

// Animation events are created by the animation files themselves. For example, when the run animation is played, it calls HandleAnimationEvent( "leftrunstep", left_foot_pos ) when the left foot hits the ground.
void HandleAnimationEvent(string event, vec3 world_pos){
	//Print("Angelscript received event: "+event+"\n");
	if(event == "golimp"){
		if(attack_getter2.IsThrow() == 1){
			temp_health -= attack_getter2.GetDamage();
			if(temp_health <= 0.0f && knocked_out==0){
				knocked_out = 1;
				TimedSlowMotion(0.1f,1.0f, 0.05f);
			}
		}
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
	   distance(this_mo.position, target_pos) < _attack_range){
		vec3 facing = this_mo.GetFacing();
		vec3 facing_right = vec3(-facing.z, facing.y, facing.x);
		vec3 dir = normalize(target_pos - this_mo.position);
		int return_val = this_mo.ReadCharacter(target_id).WasHit(
							   event, attack_getter.GetPath(), dir, world_pos);
		if(return_val == 1){
			WasBlocked();
		}
		if((return_val == 2 || return_val ==3) && controlled){
			camera.AddShake(0.5f);
		}
		if((return_val == 2) && !controlled){
			//if(this_mo.ReadCharacter(target_id).IsKnockedOut() == 0){
			/*if(rand()%2==0){
				string sound = "Data/Sounds/voice/torikamal/hit_taunt.xml";
				this_mo.PlaySoundGroupVoice(sound,0.2f);
			}*/
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

// remove Y component, the up component, from a vector. 
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

// WantsToDoSomething functions are called by the player or the AI in playercontrol.as or enemycontrol.as
// For the player, they return true when the appopriate control key is down.
void UpdateGroundMovementControls() {
	// GetTargetVelocitY() is defined in enemycontrol.as and playercontrol.as. Player target velocity depends on the camera and controls, AI's on player's position.
	vec3 target_velocity = GetTargetVelocity();
	if(length_squared(target_velocity)>0.0f){
		feet_moving = true;
	}

	// target_duck_amount is used in UpdateDuckAmount() 
	if(WantsToCrouch()){
		target_duck_amount = 1.0f;
	} else {
		target_duck_amount = 0.0f;
	}
	
	if(WantsToRoll() && length_squared(target_velocity)>0.2f){
		// flip_info handles actions in the air, including jump flips
		if(!flip_info.IsFlipping()){
			flip_info.StartRoll(target_velocity);
		}
	}

	// If the characters has been touching the ground for longer than _jump_threshold_time and isn't already jumping, update variables 
	// Actual jump is activated after the if(pre_jump) clause below.
	if(WantsToJump() && 
	   on_ground_time > _jump_threshold_time && 
	   !pre_jump)
	{
		pre_jump = true;
		pre_jump_time = _pre_jump_delay;
		// the character crouches down, getting ready for the jump
		duck_vel = 30.0f * (1.0f-duck_amount * 0.6f);

		vec3 target_jump_vel = jump_info.GetJumpVelocity(target_velocity);
		target_tilt = vec3(target_jump_vel.x, 0, target_jump_vel.z)*2.0f;
	}

	// preparing for the jump
	if(pre_jump){
		if(pre_jump_time <= 0.0f && !flip_info.IsFlipping()){
			jump_info.StartJump(target_velocity);
			SetOnGround(false);
			pre_jump = false;
		} else {
			pre_jump_time -= time_step * num_frames;
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

	max_speed *= 1.0 - adjusted_vel.y;
	max_speed = max(curr_speed * 0.98f, max_speed);

	float speed = _walk_accel * run_phase;
	speed = mix(speed,speed*_duck_speed_mult,duck_amount);

	this_mo.velocity += adjusted_vel * time_step * num_frames * speed;
}

// Draws a sphere on the position of the bone's IK target. Useful for understanding what the IK targets do, or are supposed to do.
// Useful strings:  leftarm, rightarm, left_leg, right_leg
void DrawIKTarget(string str) {
	vec3 pos = this_mo.GetIKTargetPosition(str);
	DebugDrawWireSphere(pos,
						0.1f,
						vec3(1.0f),
						_delete_on_draw);
}

// sets IK target and draws a debugging line between the old and new positions of the IK target.
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

// knocked_out 0 means conscious, 1 unconscious
int IsKnockedOut() {
	return knocked_out;
}

float GetTempHealth() {
	return temp_health;
}

// Executed only when the  character is in _movement_state. Called by UpdateGroundControls() 
void UpdateGroundAttackControls() {
	if(WantsToAttack()||WantsToThrowEnemy()){
		TargetClosest();
	}
	if(target_id == -1){
		return;
	}
	if(WantsToAttack() && distance(this_mo.position,this_mo.ReadCharacter(target_id).position) <= _attack_range){
		SetState(_attack_state);
		//Print("Starting attack\n");
		attack_animation_set = false;
		attacking_with_throw = false;
		if(!controlled){
			this_mo.PlaySoundGroupVoice("attack",0.0f);
		}

		/*if(target.GetTempHealth() <= 0.4f && target.IsKnockedOut()==0){
			TimedSlowMotion(0.2f,0.4f, 0.15f);
		}*/
	} else if(WantsToThrowEnemy() && distance(this_mo.position,this_mo.ReadCharacter(target_id).position) <= _attack_range){
		SetState(_attack_state);
		//Print("Starting attack\n");
		attack_animation_set = false;
		attacking_with_throw = true;
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
				 this_mo.ReadCharacter(target_id).position + this_mo.ReadCharacter(target_id).velocity * 0.3f) <= _attack_range)
	{
		SetState(_attack_state);
		attack_animation_set = false;
		attacking_with_throw = false;
	}
}

// Executed only when the  character is in _movement_state.  Called by UpdateMovementControls() .
void UpdateGroundControls() {
	UpdateGroundAttackControls();
	UpdateGroundMovementControls();
}

// handles tilting caused by accelerating when moving on the ground.
void HandleAccelTilt() {
	if(on_ground){
		if(feet_moving && state == _movement_state){
			target_tilt = this_mo.velocity * 0.5f;
			accel_tilt = mix((this_mo.velocity - old_vel)*120.0f/num_frames, accel_tilt, pow(0.95f,num_frames));
		} else {
			target_tilt = vec3(0.0f);
			accel_tilt *= pow(0.8f,num_frames);
		}
		target_tilt += accel_tilt;
		target_tilt.y = 0.0f;
		old_vel = this_mo.velocity;
	} else {
		accel_tilt = vec3(0.0f);
		old_vel = vec3(0.0f);
	}
}

// Executed only when the  character is in _movement_state.  Called from the update() function.
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

// Used when the character starts or stops touching the ground. The timer affects how quickly a character can jump after landing, and other things. 
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
		character_getter.Load(this_mo.char_path);
		if(character_getter.OnSameTeam(this_mo.ReadCharacter(i).char_path) == 1){
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
		float slide_amount = 1.0f - (dot(normalize(this_mo.velocity*-1.0f), normalize(ground_normal)));
		Print("Slide amount: "+slide_amount+"\n");
		Print("Slide vel: "+slide_amount*length(this_mo.velocity)+"\n");
		this_mo.MaterialEvent("land", this_mo.position - vec3(0.0f,_leg_sphere_size, 0.0f), 1.0f);
		if(slide_amount > 0.0f){
			float slide_vel = slide_amount*length(this_mo.velocity);
			float vol = min(1.0f,slide_amount * slide_vel * 0.2f);
			if(vol > 0.2f){
				this_mo.MaterialEvent("slide", this_mo.position - vec3(0.0f,_leg_sphere_size, 0.0f), vol);
			}
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
	// the value of sphere_col.adjusted_position variable was set by the GetSlidingSphereCollision() called on the previous line.
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
	vec3 air_vel = this_mo.velocity;
	if(on_ground){
		this_mo.velocity += HandleBumperCollision() / (time_step * num_frames);

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
		vec3 offset = this_mo.position - last_col_pos; 
		this_mo.position = last_col_pos;
		bool landing = false;
		vec3 landing_normal;
		for(int i=0; i<num_frames; ++i){
			if(on_ground){
				break;
			}
			this_mo.position += offset/num_frames;
			this_mo.GetSlidingSphereCollision(this_mo.position, _leg_sphere_size);
			this_mo.position = sphere_col.adjusted_position;
			this_mo.velocity += (sphere_col.adjusted_position - sphere_col.position) / (time_step);
			offset += (sphere_col.adjusted_position - sphere_col.position) * (num_frames);
			for(int i=0; i<sphere_col.NumContacts(); i++){
				const CollisionPoint contact = sphere_col.GetContact(i);
				if(contact.normal.y < _ground_normal_y_threshold){
					jump_info.HitWall(normalize(contact.position-this_mo.position));
				}
			}	
			for(int i=0; i<sphere_col.NumContacts(); i++){
				if(landing){
					break;
				}
				const CollisionPoint contact = sphere_col.GetContact(i);
				if(contact.normal.y > _ground_normal_y_threshold ||
				   (this_mo.velocity.y < 0.0f && contact.normal.y > 0.2f))
				{
					if(air_time > 0.1f){
						landing = true;
						landing_normal = contact.normal;
					}
				}
			}
		}
		if(landing){
			ground_normal = landing_normal;
			Land(air_vel);
			SetState(_movement_state);
		}
	}
	last_col_pos = this_mo.position;
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

void Ragdoll(int type){
	recovery_time = _ragdoll_recovery_time;
	
	if(limp){
		return;
	}
	
	SetState(_movement_state);
	limp = true;
	this_mo.Ragdoll();
	ragdoll_static_time = 0.0f;
	ragdoll_time = 0.0f;
	ragdoll_limp_stun = 0.0f;
	frozen = false;
	no_freeze = false;

	ragdoll_type = type;

	if(ragdoll_type == _RGDL_LIMP){
		this_mo.EnableSleep();
		this_mo.SetRagdollStrength(0.0);
		this_mo.StartAnimation("Data/Animations/r_idle.anm",4.0f);
	}

	if(ragdoll_type == _RGDL_FALL) {
		this_mo.EnableSleep();
		no_freeze = true;
		//this_mo.StartAnimation("Data/Animations/r_idle.anm");
		//int layer = this_mo.AddLayer("Data/Animations/r_catchfallright.anm",20.0f,_ANM_MIRRORED);
		//this_mo.SetLayerOpacity(layer, 1.0);
		//this_mo.SetFrozenRagdollStrength(0.0);
		this_mo.SetRagdollStrength(1.0);
		this_mo.StartAnimation("Data/Animations/r_flail.anm",4.0f);
		ragdoll_layer_catchfallfront = 
			this_mo.AddLayer("Data/Animations/r_catchfallfront.anm",4.0f,0);
		ragdoll_layer_fetal = 
			this_mo.AddLayer("Data/Animations/r_fetal.anm",4.0f,0);
		//this_mo.StartAnimation("Data/Animations/r_ragdollbase.anm",0.1f);
		//this_mo.AddLayer("Data/Animations/r_protecthead.anm",4.0f,0.0f);
		//this_mo.AddLayer("Data/Animations/r_grabface.anm",20.0f,0);
		//this_mo.AddLayer("Data/Animations/r_protecthead.anm",20.0f,0);
		//this_mo.AddLayer("Data/Animations/r_bow.anm",4.0f,0);
	}

	if(ragdoll_type == _RGDL_INJURED) {
		this_mo.DisableSleep();
		no_freeze = true;
		this_mo.SetRagdollStrength(1.0);
		this_mo.StartAnimation("Data/Animations/r_writhe.anm",4.0f);
		//ragdoll_layer_fetal = 
		//	this_mo.AddLayer("Data/Animations/r_grabface.anm",4.0f,0);
		injured_mouth_open = 0.0f;
	}
}

void GoLimp() {
	Ragdoll(_RGDL_FALL);
}

// target_duck_amount is 1.0 when the character should crouch down, and 0.0 when it should stand straight.
void UpdateDuckAmount() {
	duck_vel += (target_duck_amount - duck_amount) * time_step * num_frames * _duck_accel;
	duck_vel *= pow(_duck_vel_inertia,num_frames);
	duck_amount += duck_vel * time_step * num_frames;
}

// tells how long the character has been touching the ground, or been in the air
void UpdateGroundAndAirTime() {
	if(on_ground){
		on_ground_time += time_step * num_frames;
	} else {
		air_time += time_step * num_frames;
	}
}

// air whoosh sounds get louder at higher speed.
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

// called when state equals _attack_state
void UpdateAttacking() {	
	flip_info.UpdateRoll();

	vec3 direction = this_mo.ReadCharacter(target_id).position - this_mo.position;
	float attack_distance = length(direction);
	direction.y = 0.0f;
	direction = normalize(direction);
	if(on_ground){
		this_mo.velocity *= pow(0.95f,num_frames);
	} else {
		ApplyPhysics();
	}
	if(attack_animation_set){
		if(attack_getter.IsThrow() == 0){
			this_mo.SetRotationFromFacing(InterpDirections(this_mo.GetFacing(),
														   direction,
														   1.0-pow(0.9f,num_frames)));
		} else {
			this_mo.ReadCharacter(target_id).velocity = this_mo.velocity;
			//this_mo.ReadCharacter(target_id).position = this_mo.position;
			//this_mo.ReadCharacter(target_id).position -= 
			//	this_mo.ReadCharacter(target_id).GetFacing() * 0.2f;
			//this_mo.ReadCharacter(target_id).SetRotationFromFacing(this_mo.GetFacing());
		}
	}
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
		// GetTargetVelocitY() is defined in enemycontrol.as and playercontrol.as. Player target velocity depends on the camera and controls, AI's on player's position.
		mirrored = (dot(right_direction, GetTargetVelocity())>0.1f);
	} else {
		mirrored = (dot(right_direction, GetTargetVelocity())>-0.1f);
	}
	// Checks if the character is standing still. Used in ChooseAttack() to see if the character should perform a front kick.
	bool front = //(dot(direction, GetTargetVelocity())>0.7f) || 
				 length_squared(GetTargetVelocity())<0.1f;

	

	if(attack_animation_set &&
	   this_mo.GetStatusKeyValue("cancel")>=1.0f && 
	   WantsToCancelAnimation())
	{
		if(cancel_delay <= 0.0f){
			EndAttack();
		}
		cancel_delay -= time_step * num_frames;
	} else {
		cancel_delay = 0.01f;
	}

	if(!attack_animation_set){
		// Defined in playercontrol.as and enemycontrol.as. Boolean front tells if the character is standing still, and if it's true a front kick may be performed.
		// ChooseAttack() sets the value of the curr_attack variable.
		string attack_path;
		if(attacking_with_throw){
			attack_path="Data/Attacks/throw.xml";
		} else {
			ChooseAttack(front);
			attack_path;
			if(curr_attack == "stationary"){
				if(attack_distance < _close_attack_range){
					attack_path = character_getter.GetAttackPath("stationary_close");
				} else {
					attack_path = character_getter.GetAttackPath("stationary");
				}
			} else if(curr_attack == "moving"){
				if(attack_distance < _close_attack_range){
					attack_path = character_getter.GetAttackPath("moving_close");
				} else {
					attack_path = character_getter.GetAttackPath("moving");
				}
			} else if(curr_attack == "low"){
				attack_path = character_getter.GetAttackPath("low");
			} else if(curr_attack == "air"){
				attack_path = character_getter.GetAttackPath("air");
			}
		}
		attack_getter.Load(attack_path);
		if(attack_getter.GetSpecial() == "legcannon"){	
			leg_cannon_flip = 0.0f;
		}

		if(attack_getter.GetDirection() == _left) {
			mirrored = !mirrored;
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
		bool mirror = false;
		if(attack_getter.GetDirection() != _front){
			mirror = mirrored;
			mirrored_stance = mirrored;
		} else {
			mirror = mirrored_stance;
		}

		int8 flags = 0;
		if(attack_getter.GetMobile() == 1){
			flags = flags | _ANM_MOBILE;
		}
		if(mirror){
			flags = flags | _ANM_MIRRORED;
		}
		if(attack_getter.GetFlipFacing() == 1){
			flags = flags | _ANM_FLIP_FACING;
		}


		string anim_path;
		if(attack_getter.IsThrow() == 0){
			anim_path = attack_getter.GetUnblockedAnimPath();
		} else {
			anim_path = attack_getter.GetThrowAnimPath();
			int hit = this_mo.ReadCharacter(target_id).WasHit(
				"grabbed", attack_getter.GetPath(), direction, this_mo.position);		
			if(hit == 0){
				EndAttack();
				return;
			}
			this_mo.SetRotationFromFacing(direction);
		}

		this_mo.StartAnimation(anim_path, 20.0f, flags);

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

// the animations referred here are mostly blocks, and they're defined in the character-specific XML files.
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
				this_mo.StartAnimation(character_getter.GetAnimPath(block_string),40.0f, _ANM_MIRRORED);
			} else {
				this_mo.StartAnimation(character_getter.GetAnimPath(block_string),40.0f);
			}
		} else if(hit_reaction_event == "attackimpact") {
			if(reaction_getter.GetMirrored() == 0){
				this_mo.StartAnimation(reaction_getter.GetAnimPath(1.0f-block_health),20.0f,_ANM_MOBILE);
				mirrored_stance = false;
			} else {
				this_mo.StartAnimation(reaction_getter.GetAnimPath(1.0f-block_health),20.0f,_ANM_MOBILE|_ANM_MIRRORED);
				mirrored_stance = true;
			}
		}
		this_mo.SetAnimationCallback("void EndHitReaction()");
		hit_reaction_anim_set = true;
		this_mo.SetFlip(vec3(1.0f,0.0f,0.0f),0.0f,0.0f);
	}
	this_mo.velocity *= pow(0.95f,num_frames);
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
			this_mo.StartAnimation(character_getter.GetAnimPath("idle"),5.0f,_ANM_MIRRORED);
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

// WakeUp is called when a character gets out of the ragdoll mode. 
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
			this_mo.StartAnimation(character_getter.GetAnimPath("idle"),5.0f,_ANM_MIRRORED);
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
			this_mo.StartAnimation(character_getter.GetAnimPath("idle"),5.0f,_ANM_MIRRORED);
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

// UpdateRagDoll() is called every time update() is called, regardless of if the character is in ragdoll mode or not
void UpdateRagDoll() {
	if(GetInputDown("z")){
		GoLimp();
	}
	if(GetInputDown("n")){				
		if(!limp){
			string sound = "Data/Sounds/hit/hit_hard.xml";
			PlaySoundGroup(sound, this_mo.position);
		}
		Ragdoll(_RGDL_INJURED);
	}
	if(GetInputDown("m")){		
		Ragdoll(_RGDL_LIMP);
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
	if(!limp){
		return;
	}

	/*mat4 torso_transform = this_mo.GetAvgIKChainTransform("torso");
	vec3 torso_vec = torso_transform.GetColumn(1);//(torso_transform * vec4(0.0f,0.0f,1.0f,0.0));
	Print(""+torso_vec.x +" "+torso_vec.y+" "+torso_vec.z+"\n");
	DebugDrawLine(this_mo.position,
				  this_mo.position + torso_vec,
				  vec3(1.0f),
				  _delete_on_update);*/

	ragdoll_time += time_step * num_frames;
	ragdoll_limp_stun -= time_step * num_frames;
	ragdoll_limp_stun = max(0.0, ragdoll_limp_stun);

	if(ragdoll_type == _RGDL_FALL){
		const float radius = 4.0f;
		this_mo.GetSlidingSphereCollision(this_mo.position, radius);
		vec3 hazard_dir = normalize(this_mo.position - sphere_col.adjusted_position);
		float penetration = distance(this_mo.position, sphere_col.adjusted_position);
		float protect_amount = min(1.0f,max(0.0f,(penetration / radius)*4.0f-2.0));
		this_mo.SetLayerOpacity(ragdoll_layer_fetal, protect_amount);
		mat4 torso_transform = this_mo.GetAvgIKChainTransform("torso");
		vec3 torso_vec = torso_transform.GetColumn(1);//(torso_transform * vec4(0.0f,0.0f,1.0f,0.0));
		float front_protect_amount = max(0.0f,dot(torso_vec, hazard_dir) * protect_amount);
		this_mo.SetLayerOpacity(ragdoll_layer_catchfallfront, front_protect_amount);

		float ragdoll_strength = length(this_mo.GetAvgVelocity())*0.1f;
		ragdoll_strength = min(0.8f, ragdoll_strength);
		ragdoll_strength = max(0.0f, ragdoll_strength - ragdoll_limp_stun);
		this_mo.SetRagdollStrength(ragdoll_strength);
	}
	if(ragdoll_type == _RGDL_INJURED){
		float ragdoll_strength = min(1.0f,max(0.2f,2.0f-length(this_mo.GetAvgVelocity())*0.3));
		ragdoll_strength *= 1.2f - ragdoll_time * 0.1f;
		ragdoll_strength = min(0.9f, ragdoll_strength);
		ragdoll_strength = max(0.0f, ragdoll_strength - ragdoll_limp_stun);
		this_mo.SetRagdollStrength(ragdoll_strength);
		injured_mouth_open = mix(injured_mouth_open, sin(time*4)*0.5f+sin(time*6.3)*0.5, ragdoll_strength);
		this_mo.SetMorphTargetWeight("mouth_open",injured_mouth_open,1.0f);
		if(ragdoll_time > 12.0f){
			Print("Ragdoll time up: "+ragdoll_time+"\n");
			ragdoll_type = _RGDL_LIMP;
			no_freeze = false;
			ragdoll_static_time = 0.0f;
			this_mo.EnableSleep();
			this_mo.SetRagdollStrength(0.0f);
		}
	}
	//this_mo.SetRagdollStrength(max(0.0,0.9-ragdoll_time));
	if(!frozen){
		vec3 color;
		if(length(this_mo.GetAvgVelocity())<_ragdoll_static_threshold)
		{
			color = vec3(1.0f,0.0f,0.0f);
			ragdoll_static_time += time_step * num_frames;
		} else {
			color = vec3(1.0f,1.0f,1.0f);
			ragdoll_static_time = 0.0f;
		}

		/*DebugDrawLine(this_mo.position,
					  this_mo.position + this_mo.GetAvgVelocity(),
					  color,
					  _delete_on_update);*/
		
		if(!no_freeze){
			float damping = min(1.0f,ragdoll_static_time*0.5f);
			this_mo.SetRagdollDamping(damping);
			if(damping >= 1.0f){
				frozen = true;
			}
		} else {
			this_mo.SetRagdollDamping(0.0f);
		}
	}
	if(knocked_out==0){
		recovery_time -= time_step * num_frames;
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


// motion capture test functions
bool testing_mocap = false;
void TestMocap(){
	//this_mo.SetAnimation("Data/Animations/mocapsit.anm");
	//this_mo.SetAnimation("Data/Animations/r_bow.anm");
	this_mo.AddLayer("Data/Animations/r_bow.anm",4.0f,0);
	//this_mo.SetAnimationCallback("void EndTestMocap()");
	//testing_mocap = true;
	//this_mo.velocity = vec3(0.0f);
	
	//this_mo.position += vec3(0.0f,-0.1f,0.0f);
	//this_mo.position = vec3(16.23, 109.45, 11.71);
	//this_mo.SetRotationFromFacing(vec3(0.0f,0.0f,1.0f));
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

// Nothing() does nothing.
void Nothing() {
}

// Called only when state equals _ground_state
void UpdateGroundState() {
	this_mo.velocity = vec3(0.0f);
	
	/*this_mo.SetAnimation("Data/Animations/onback.anm");
	this_mo.SetAnimationCallback("void Nothing()");
	this_mo.velocity += GetTargetVelocity() * time_step * _walk_accel;
	*/
	HandleGroundStateCollision();
	getting_up_time += time_step * num_frames;
}

// the main timer of the script, used whenever anything has to know how much time has passed since something else happened.
float time = 0;

// The following variables and function affect the track decals foots make on the ground, when that feature is enabled
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

// blocking actions for combat, including a quick hack for the AI
void HandleActiveBlock() {
	if(WantsToStartActiveBlock()){
		if(active_block_recharge <= 0.0f){
			active_blocking = true;
			active_block_duration = 0.2f;
		}
		active_block_recharge = 0.2f;
	} 
	if(active_blocking){
		active_block_duration -= time_step * num_frames;
		if(active_block_duration <= 0.0f){
			active_blocking = false;
		}
	} else {
		if(active_block_recharge > 0.0f){
			active_block_recharge -= time_step * num_frames;
		}
	}
	// the AI blocks randomly
	if(!controlled){
		active_blocking = (rand()%4)==0;
	}
}

void HandleCollisionsBetweenTwoCharacters(int which){
	if(this_mo.position == this_mo.ReadCharacter(which).position){
		return;
	}

	if(state == _attack_state && attack_getter.IsThrow() == 1){
		return;
	}
	if(state == _hit_reaction_state && attack_getter2.IsThrow() == 1){
		return;
	}

	if(knocked_out == 0 && this_mo.ReadCharacter(which).IsKnockedOut() == 0){
		float distance_threshold = 0.7f;
		vec3 this_com = this_mo.GetCenterOfMass();
		vec3 other_com = this_mo.ReadCharacter(which).GetCenterOfMass();
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
				this_mo.ReadCharacter(which).velocity += dir * 0.5f / (time_step * num_frames);
				this_mo.velocity -= dir * 0.5f / (time_step * num_frames);
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

void HandlePickUp() {
	if(WantsToPickUpItem()){
		int num_items = this_mo.GetNumItems();
		
		if(!holding_weapon){
			for(int i=0; i<num_items; i++){
				this_mo.ReadItem(i);
				vec3 pos = item_object_getter.GetPhysicsPosition();
				vec3 hand_pos = this_mo.GetIKTargetTransform("rightarm").GetTranslationPart();
				if(distance(hand_pos, pos)<0.9f){ 
					holding_weapon = true;
					weapon_id = i;
					this_mo.AttachItem(i);
					break;
				}
			}
		}
		if(holding_weapon){
			this_mo.SetMorphTargetWeight("fist_r",1.0f,1.0f);
			/*this_mo.ReadItem(weapon_id);
			vec3 pos = item_object_getter.GetPhysicsPosition();
			mat4 transform = this_mo.GetIKTargetTransform("rightarm");
			mat4 transform_rot = transform;
			transform_rot.SetTranslationPart(vec3(0.0f));
			mat4 new_transform;
			new_transform.SetColumn(0, transform.GetColumn(0));
			new_transform.SetColumn(1, transform.GetColumn(2)*-1.0f);
			new_transform.SetColumn(2, transform.GetColumn(1));
			new_transform.SetTranslationPart(
				transform.GetTranslationPart() + transform_rot * vec3(0.03f,0.15f,0.09f));
			item_object_getter.SetPhysicsTransform(new_transform);*/
		}
	} else {
		if(holding_weapon){
			this_mo.SetMorphTargetWeight("fist_r",1.0f,0.0f);
			this_mo.DetachItem(weapon_id);
			item_object_getter.ActivatePhysics();
			holding_weapon = false;
		}
	}
}

vec3 old_cam_pos;
float target_rotation = 0.0f;
float target_rotation2 = 0.0f;
float cam_rotation = 0.0f;
float cam_rotation2 = 0.0f;


void ApplyCameraControls() {
	if(!controlled){
		return;
	}
	const float _camera_rotation_inertia = 0.5f;
	const float _cam_follow_distance = 2.0f;
	const float _cam_collision_radius = 0.15f;

	SetGrabMouse(true);

	target_rotation -= GetLookXAxis();
	target_rotation2 -= GetLookYAxis();	

	target_rotation2 = max(-90,min(50,target_rotation2));

	cam_rotation = cam_rotation * _camera_rotation_inertia + 
			   target_rotation * (1.0f - _camera_rotation_inertia);
	cam_rotation2 = cam_rotation2 * _camera_rotation_inertia + 
			   target_rotation2 * (1.0f - _camera_rotation_inertia);

	mat4 rotationY_mat,rotationX_mat;
	rotationY_mat.SetRotationY(cam_rotation*3.1415/180.0f);
	rotationX_mat.SetRotationX(cam_rotation2*3.1415/180.0f);
	mat4 rotation_mat = rotationY_mat * rotationX_mat;
	vec3 facing = rotation_mat * vec3(0.0f,0.0f,-1.0f);

	vec3 cam_pos = this_mo.position;

	//vec3 facing = camera.GetFacing();
	vec3 right = normalize(vec3(-facing.z,facing.y,facing.x));

	//camera.SetZRotation(0.0f);
	//camera.SetZRotation(dot(right,this_mo.velocity+accel_tilt)*-0.1f);
	
	if(!limp){
		cam_pos += vec3(0.0f,0.35f,0.0f);
	} else {
		cam_pos += vec3(0.0f,0.1f,0.0f);
	}

	if(old_cam_pos == vec3(0.0f)){
		old_cam_pos = camera.GetPos();
	}
	old_cam_pos += this_mo.velocity * time_step * num_frames;
	cam_pos = mix(cam_pos,old_cam_pos,0.8f);

	camera.SetVelocity(this_mo.velocity); 

	this_mo.GetSweptSphereCollision(cam_pos,
								    cam_pos - facing * 
												_cam_follow_distance,
									_cam_collision_radius);
	
	float new_follow_distance = _cam_follow_distance;
	if(sphere_col.NumContacts() != 0){
		new_follow_distance = distance(cam_pos, sphere_col.position);
	}
/*
	if(new_follow_distance<5.0f){
		new_follow_distance = 5.0f;
		vec3 temp_pos = 
			cam_pos - facing * new_follow_distance;
		this_mo.GetSweptSphereCollision(temp_pos + vec3(0.0f,5.0f,0.0f),
										temp_pos,
										_cam_collision_radius);
		vec3 new_pos = sphere_col.position;
		vec3 new_dir = normalize(new_pos - cam_pos);
		cam_rotation2 = asin(new_dir.y)*-180/3.1415 - 2.0f;
		//Print(""+cam_rotation2.x+" "+cam_rotation2.y+" "+cam_rotation2.z+"\n");
		Print(""+cam_rotation2+"\n");
	}*/
	
	camera.SetYRotation(cam_rotation);	
	camera.SetXRotation(cam_rotation2);

	camera.SetFOV(90);
	camera.SetPos(cam_pos);

	/*camera.SetFOV(30);
	cam_pos.y+=0.05f;
	camera.SetPos(cam_pos);
	*/

	old_cam_pos = cam_pos;
	camera.CalcFacing();

	camera.SetDistance(new_follow_distance);
	UpdateListener(camera.GetPos(),vec3(0,0,0),camera.GetFacing(),camera.GetUpVector());
}

const float _target_look_threshold_sqrd = 7.0f * 7.0f;
const float _head_inertia = 0.8f;
vec3 head_dir;
vec3 target_head_dir;

void UpdateHeadLook() {
	bool look_at_target = false;
	vec3 target_dir;
	if(target_id != -1){
		vec3 target_pos = this_mo.ReadCharacter(target_id).position;
		if(distance_squared(this_mo.position,target_pos) < _target_look_threshold_sqrd){
			look_at_target = true;
			target_dir = normalize(target_pos - this_mo.position);
		}
	}
	if(controlled){
		if(!look_at_target){
			target_head_dir = camera.GetFacing();
		} else {
			target_head_dir = target_dir;
		}
	} else {
		if(!look_at_target){
			target_head_dir = this_mo.GetFacing();
		} else {
			target_head_dir = target_dir;
		}
	}

	head_dir = normalize(mix(target_head_dir, head_dir, _head_inertia));
	this_mo.SetIKTargetOffset("head",head_dir);
}

vec3 eye_dir;
vec3 target_eye_dir;
const float _eye_inertia = 0.85f;
const float _eye_min_delay = 0.5f;
const float _eye_max_delay = 2.0f;
float eye_delay = 0.0f;

void UpdateEyeLook(){
	if(eye_delay <= 0.0f){
		eye_delay = RangedRandomFloat(_eye_min_delay,_eye_max_delay);
		target_eye_dir.x = RangedRandomFloat(-1.0f, 1.0f);		
		target_eye_dir.y = RangedRandomFloat(-1.0f, 1.0f);		
		target_eye_dir.z = RangedRandomFloat(-1.0f, 1.0f);	
		normalize(target_eye_dir);
	}
	eye_delay -= time_step * num_frames;
	eye_dir = normalize(mix(target_eye_dir, eye_dir, _eye_inertia));

	// Set weights for carnivore
	this_mo.SetMorphTargetWeight("look_r",max(0.0f,eye_dir.x),1.0f);
	this_mo.SetMorphTargetWeight("look_l",max(0.0f,-eye_dir.x),1.0f);
	this_mo.SetMorphTargetWeight("look_u",max(0.0f,eye_dir.y),1.0f);
	this_mo.SetMorphTargetWeight("look_d",max(0.0f,-eye_dir.y),1.0f);

	// Set weights for herbivore
	this_mo.SetMorphTargetWeight("look_u",max(0.0f,eye_dir.y),1.0f);
	this_mo.SetMorphTargetWeight("look_d",max(0.0f,-eye_dir.y),1.0f);
	this_mo.SetMorphTargetWeight("look_f",max(0.0f,eye_dir.z),1.0f);
	this_mo.SetMorphTargetWeight("look_b",max(0.0f,-eye_dir.z),1.0f);

	// Set weights for independent-eye herbivoe
	this_mo.SetMorphTargetWeight("look_u_l",max(0.0f,eye_dir.y),1.0f);
	this_mo.SetMorphTargetWeight("look_u_r",max(0.0f,eye_dir.y),1.0f);
	this_mo.SetMorphTargetWeight("look_d_l",max(0.0f,-eye_dir.y),1.0f);
	this_mo.SetMorphTargetWeight("look_d_r",max(0.0f,-eye_dir.y),1.0f);

	float right_front = eye_dir.z;
	float left_front = eye_dir.z;
	this_mo.SetMorphTargetWeight("look_f_r",max(0.0f,right_front),1.0f);
	this_mo.SetMorphTargetWeight("look_b_r",max(0.0f,-right_front),1.0f);
	this_mo.SetMorphTargetWeight("look_f_l",max(0.0f,left_front),1.0f);
	this_mo.SetMorphTargetWeight("look_b_l",max(0.0f,-left_front),1.0f);
}

const float _blink_speed = 5.0f;
const float _blink_min_delay = 1.0f;
const float _blink_max_delay = 5.0f;
bool blinking = false;
float blink_progress = 0.0f;
float blink_delay = 0.0f;
float blink_amount = 0.0f;
void UpdateBlink() {
	bool unconscious = (limp && ragdoll_type == _RGDL_LIMP);
	if(!unconscious){
		if(blink_delay < 0.0f){
			blink_delay = RangedRandomFloat(_blink_min_delay,
											_blink_max_delay);
			blinking = true;
			blink_progress = 0.0f;
		}
		if(blinking){
			blink_progress += time_step * num_frames * 5.0f;
			blink_amount = sin(blink_progress*3.14);
			if(blink_progress > 1.0f){
				blink_amount = 0.0f;
				blinking = false;
			}
		} else {
			blink_amount = 0.0f;
		}
		blink_delay -= time_step * num_frames;
	} else {
		blink_amount = mix(blink_amount, 1.0f, 0.1f);
	}
	this_mo.SetMorphTargetWeight("wink_r",blink_amount,1.0f);
	this_mo.SetMorphTargetWeight("wink_l",blink_amount,1.0f);
}

// THIS IS WHERE THE MAGIC HAPPENS.
// update() function is called once per every time unit for every player and AI character, and most things that must be constantly updated will be called from this function.
// the bool _controlled is true when character is controlled by a human, false when it's controlled by AI.
void update(bool _controlled, int _num_frames) {
	UpdateHeadLook();
	UpdateBlink();
	UpdateEyeLook();

	if(controlled && GetInputPressed("v")){
		//string sound = "Data/Sounds/voice/kill_intent.xml";
		string sound = "Data/Sounds/voice/torikamal/kill_intent.xml";
		this_mo.ForceSoundGroupVoice(sound, 0.0f);
	}

	num_frames = _num_frames;

	HandleActiveBlock();

	ControlUpdate();
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
		return;
	}
	controlled = _controlled;

	if(controlled){
		UpdateAirWhooshSound();
	}
	UpdateRagDoll();	
	if(limp){
		HandlePickUp();
		ApplyCameraControls();
		return;
	}
/*
	vec3 vel(RangedRandomFloat(-20.0f,20.0f),
			 RangedRandomFloat(0.0f,100.0f),
			 RangedRandomFloat(-20.0f,20.0f));
	vel *= 0.05;
	vec3 pos = this_mo.GetAvgIKChainTransform("head") * vec3(0.0f,0.0f,0.0f);
	MakeParticle("Data/Particles/spark.xml",pos, vel)*/;
	//MakeParticle("Data/Particles/smoke.xml",this_mo.position + vec3(0.0,0.7,0.0), vel);
	//MakeParticle("Data/Particles/heavysand.xml",this_mo.position + vec3(0.0,0.7,0.0), vel);
	//MakeParticle("Data/Particles/heavydirt.xml",this_mo.position + vec3(0.0,0.7,0.0), vel);
	//MakeParticle("Data/Particles/bloodsplat.xml",this_mo.position + vec3(0.0,0.7,0.0), vel);
	//MakeParticle("Data/Particles/impactfast.xml",this_mo.position + vec3(0.0,0.7,0.0), vel);
	//MakeParticle("Data/Particles/impactslow.xml",this_mo.position + vec3(0.0,0.7,0.0), vel);

	//MakeImpactParticle(this_mo.position);

	block_health += time_step * 0.3f * num_frames;
	block_health = min(temp_health, block_health);
	temp_health += time_step * 0.05f * num_frames;
	temp_health = min(permanent_health, temp_health);

	if(state == _movement_state){
		UpdateDuckAmount();
		UpdateGroundAndAirTime();
		HandleAccelTilt();
		UpdateMovementControls();
		UpdateAnimation();
		ApplyPhysics();
		HandlePickUp();
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
		this_mo.char_path = "Data/Characters/guard.xml";
		character_getter.Load(this_mo.char_path);
		this_mo.RecreateRiggedObject(this_mo.char_path);
		this_mo.StartAnimation(character_getter.GetAnimPath("idle"));
		SetState(_movement_state);
	}
	if(controlled && GetInputPressed("2")){
		this_mo.char_path = "Data/Characters/guard2.xml";
		character_getter.Load(this_mo.char_path);
		this_mo.RecreateRiggedObject(this_mo.char_path);
		this_mo.StartAnimation(character_getter.GetAnimPath("idle"));
		SetState(_movement_state);
	}
	if(controlled && GetInputPressed("3")){
		this_mo.char_path = "Data/Characters/turner.xml";
		character_getter.Load(this_mo.char_path);
		this_mo.RecreateRiggedObject(this_mo.char_path);
		this_mo.StartAnimation(character_getter.GetAnimPath("idle"));
		SetState(_movement_state);
	}
	if(controlled && GetInputPressed("4")){
		this_mo.char_path = "Data/Characters/civ.xml";
		character_getter.Load(this_mo.char_path);
		this_mo.RecreateRiggedObject(this_mo.char_path);
		this_mo.StartAnimation(character_getter.GetAnimPath("idle"));
		SetState(_movement_state);
	}
	if(controlled && GetInputPressed("5")){
		this_mo.char_path = "Data/Characters/wolf.xml";
		character_getter.Load(this_mo.char_path);
		this_mo.RecreateRiggedObject(this_mo.char_path);
		this_mo.StartAnimation(character_getter.GetAnimPath("idle"));
		SetState(_movement_state);
	}
	if(controlled && GetInputPressed("6")){
		this_mo.char_path = "Data/Characters/rabbot.xml";
		character_getter.Load(this_mo.char_path);
		this_mo.RecreateRiggedObject(this_mo.char_path);
		this_mo.StartAnimation(character_getter.GetAnimPath("idle"));
		SetState(_movement_state);
	}
	
	if(GetInputPressed("b")){
		// if you were looking for the controls to change if the AI is hostile or not, look at enemycontrol.as
		/*if(state == _movement_state){
			SetState(_ground_state);
		} else {
			SetState(_movement_state);
		}*/
		TestMocap();
	}

	if(!controlled){
		HandleCollisionsBetweenCharacters();
	}

	float terminal_velocity = 50.0f;
	if(length_squared(this_mo.velocity) > terminal_velocity*terminal_velocity){
		this_mo.velocity *= pow(0.99f,num_frames);
	}	
	
	tilt = tilt * pow(_tilt_inertia,num_frames) +
		   target_tilt * (1.0f - pow(_tilt_inertia,num_frames));

	//tilt = vec3(sin(time*2.0f)*20.0f,0.0f,0.0f);

	this_mo.SetTilt(tilt);

	
	if(on_ground && state == _movement_state){
		DecalCheck();
	}
	left_smear_time += time_step * num_frames;
	right_smear_time += time_step * num_frames;
	smear_sound_time += time_step * num_frames;
	ApplyCameraControls();
}

void init(string character_path) {
	this_mo.char_path = character_path;
	character_getter.Load(this_mo.char_path);
	this_mo.RecreateRiggedObject(this_mo.char_path);
	for(int i=0; i<5; ++i){
		HandleBumperCollision();
		HandleStandingCollision();
		this_mo.position = sphere_col.position;
		last_col_pos = this_mo.position;
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
			roll_ik_fade = min(roll_ik_fade + time_step * 5.0f * num_frames, 1.0f);
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
															   1.0 - pow(0.8f, num_frames)));
				this_mo.SetAnimation(character_getter.GetAnimPath("movement"));
				this_mo.SetBlendCoord("speed_coord",speed);
				this_mo.SetBlendCoord("ground_speed",speed);
			} else {
				if(!mirrored_stance){
					this_mo.SetAnimation(character_getter.GetAnimPath("idle"));
				} else {
					this_mo.SetAnimation(character_getter.GetAnimPath("idle"),5.0f,_ANM_MIRRORED);
				}
				this_mo.SetIKEnabled(true);
			}
			roll_ik_fade = max(roll_ik_fade - time_step * 5.0f * num_frames, 0.0f);
		}
	} else {
		jump_info.UpdateAirAnimation();
	}

	// center of mass offset
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
		offset_height = mix(offset_height, curr_offset_height, 1.0f-(pow(0.9f,num_frames)));
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
	// GetTargetVelocitY() is defined in enemycontrol.as and playercontrol.as. Player target velocity depends on the camera and controls, AI's on player's position.
	this_mo.velocity += GetTargetVelocity() * time_step * _walk_accel * num_frames;
}

void ApplyPhysics() {
	if(!on_ground){
		this_mo.velocity += physics.gravity_vector * time_step * num_frames;
	}
	if(on_ground){
		if(!feet_moving){
			this_mo.velocity *= pow(0.95f,num_frames);
		} else {
			const float e = 2.71828183f;
			float exp = _walk_accel*time_step*-1/max_speed;
			float current_movement_friction = pow(e,exp);
			this_mo.velocity *= pow(current_movement_friction, num_frames);
		}
	}
}