const float _ledge_move_speed = 10.0f;
const float _ledge_move_damping = 0.95f;
const float _height_under_ledge = 1.05f;
		
class TargetMove {
	vec3 start_pos;
	vec3 end_pos;
	float start_time;
	float end_time;
	float move_time;
	vec3 offset;
	float time;
	float speed;
	int id;

	void Move(vec3 _start_pos, 
			  vec3 _end_pos, 
			  float _start_time,
			  float _end_time,
			  vec3 _offset)
	{
		start_pos = _start_pos;
		end_pos = _end_pos;
		start_time = _start_time;
		end_time = _end_time;
		move_time = end_time - start_time;
		time = 0.0f;
		offset = _offset;
		speed = 2.0f;
	}

	void SetSpeed(float _speed){
		speed = _speed;
	}

	void SetEndPos(vec3 _pos) {
		if(time < end_time){
			end_pos = _pos + vec3(this_mo.velocity.x,
								  0.0f,
								  this_mo.velocity.z)* 0.1f;
		}
	}

	void Update() {
		time += time_step * speed * num_frames;
		if(time >= end_time){
			if(id < 2 && distance(start_pos, end_pos)>0.1f){
				//string path = "Data/Sounds/concrete_foley/bunny_edgecrawl_concrete.xml";
				//this_mo.PlaySoundGroupAttached(path, end_pos);
				if(id==0){
					this_mo.MaterialEvent("edge_crawl", this_mo.GetIKTargetPosition("leftarm"));
				} else {
					this_mo.MaterialEvent("edge_crawl", this_mo.GetIKTargetPosition("rightarm"));
				}
			}
			start_pos = end_pos;
			time -= 1.0f;
		}
	}

	float GetWeight(){
		if(time <= start_time){
			return 1.0f;
		}
		if(time >= end_time){
			return 1.0f;
		}
		float progress = (time - start_time)/move_time;
		float weight = 1.0f - sin(progress * 3.14f);
		return weight * weight;
	}

	vec3 GetPos() {
		if(time <= start_time){
			return start_pos;
		}
		if(time >= end_time){
			return end_pos;
		}
		float progress = (time - start_time)/move_time;
		vec3 pos = mix(start_pos, end_pos, progress);
		pos += offset * sin(progress * 3.14f) * distance(start_pos, end_pos);
		return pos;
	}

}

class ShimmyAnimation {
	bool moving;
	bool just_finished;
	float progress;
	vec3 start_pos;
	vec3 target_pos;
	TargetMove[] hand_pos;
	TargetMove[] foot_pos;
	vec3 lag_vel;
	vec3 ledge_dir;

	ShimmyAnimation() {
		hand_pos.resize(2);
		foot_pos.resize(2);
		hand_pos[0].id = 0;
		hand_pos[1].id = 1;
		foot_pos[0].id = 2;
		foot_pos[1].id = 3;
		moving = false;
		just_finished = false;
		lag_vel = vec3(0.0f);
	}

	void Start(vec3 pos, vec3 dir){
		start_pos = pos;
		ledge_dir = dir;
		hand_pos[0].Move(start_pos, start_pos, 0.0f, 0.4f, vec3(0.0f,0.1f,0.0f));
		hand_pos[1].Move(start_pos, start_pos, 0.5f, 0.9f, vec3(0.0f,0.1f,0.0f));
		foot_pos[0].Move(start_pos, start_pos, 0.1f, 0.5f, dir * -0.1f);
		foot_pos[1].Move(start_pos, start_pos, 0.6f, 1.0f, dir * -0.1f);
		progress = 0.0f;
		moving = true;
	}

	void Update(vec3 _target_pos, vec3 dir){
		target_pos = _target_pos;
		float old_progress = progress;
		progress += time_step * num_frames;

		hand_pos[0].SetEndPos(target_pos);
		hand_pos[1].SetEndPos(target_pos);
		foot_pos[0].SetEndPos(target_pos);
		foot_pos[1].SetEndPos(target_pos);
		hand_pos[0].Update();
		hand_pos[1].Update();
		foot_pos[0].Update();
		foot_pos[1].Update();

		float speed = sqrt(this_mo.velocity.x * this_mo.velocity.x
						  +this_mo.velocity.z * this_mo.velocity.z)*3.0f;
		speed = min(3.0f,max(1.0f,speed));
		
		hand_pos[0].SetSpeed(speed);
		hand_pos[1].SetSpeed(speed);
		foot_pos[0].SetSpeed(speed);
		foot_pos[1].SetSpeed(speed);

		lag_vel = mix(this_mo.velocity, lag_vel, pow(0.95f,num_frames)); 

		ledge_dir = dir;
	}

	void UpdateIKTargets() {
		vec3[] offset(4);
		offset[0] = hand_pos[0].GetPos() - this_mo.position;
		offset[1] = hand_pos[1].GetPos() - this_mo.position;
		offset[2] = foot_pos[0].GetPos() - this_mo.position;
		offset[3] = foot_pos[1].GetPos() - this_mo.position;
		this_mo.SetIKTargetOffset("leftarm",offset[0]);
		this_mo.SetIKTargetOffset("rightarm",offset[1]);
		this_mo.SetIKTargetOffset("left_leg",offset[2]);
		this_mo.SetIKTargetOffset("right_leg",offset[3]);

		float[] weight(4);
		weight[0] = hand_pos[0].GetWeight();
		weight[1] = hand_pos[1].GetWeight();
		weight[2] = foot_pos[0].GetWeight();
		weight[3] = foot_pos[1].GetWeight();
		float total_weight = weight[0] + weight[1] + weight[2] + weight[3];
		vec3 weight_offset = vec3(0.0f);
		//for(int i=0; i<4; ++i){
		//	weight_offset += offset[i] * (weight[i] / total_weight);
		//}
		weight_offset += this_mo.GetIKTargetPosition("leftarm") * (weight[0] / total_weight);
		weight_offset += this_mo.GetIKTargetPosition("rightarm") * (weight[1] / total_weight);
		weight_offset += this_mo.GetIKTargetPosition("left_leg") * (weight[2] / total_weight);
		weight_offset += this_mo.GetIKTargetPosition("right_leg") * (weight[3] / total_weight);
		weight_offset -= this_mo.position;
		weight_offset -= dot(ledge_dir,weight_offset) * ledge_dir;
		float move_amount = sqrt(this_mo.velocity.x * this_mo.velocity.x
								+this_mo.velocity.z * this_mo.velocity.z) * 0.4f;
		weight_offset *= max(0.0f,min(1.0f,move_amount-0.1f))*0.5f;
		weight_offset.y = 0.0f;
		weight_offset += (lag_vel - this_mo.velocity) * 0.1f;
		//weight_offset += this_mo.velocity * 0.05f;
		weight_offset.y += 0.3f * move_amount;
		weight_offset += ledge_dir * move_amount * 0.2f;
		this_mo.SetIKTargetOffset("full_body",weight_offset);
	}
}

class LedgeInfo {
	bool on_ledge;
	float ledge_height;
	vec3 ledge_grab_pos;
	vec3 ledge_dir;
	bool climbed_up;

	ShimmyAnimation shimmy_anim;

	LedgeInfo() {	
		on_ledge = false;
		climbed_up = false;
	}

	void UpdateLedgeAnimation() {
		this_mo.SetAnimation(character_getter.GetAnimPath("ledge"),5.0f);
	}

	void UpdateIKTargets() {
		if(shimmy_anim.moving){
			shimmy_anim.UpdateIKTargets();
		} else {
			vec3 offset = ledge_grab_pos - this_mo.position;
			this_mo.SetIKTargetOffset("leftarm",offset);
			this_mo.SetIKTargetOffset("rightarm",offset);
			this_mo.SetIKTargetOffset("left_leg",offset);
			this_mo.SetIKTargetOffset("right_leg",offset);
		}
	}

	vec3 WallRight() {
		vec3 wall_right = ledge_dir;
		float temp = ledge_dir.x;
		wall_right.x = -ledge_dir.z;
		wall_right.z = temp;
		return wall_right;		
	}
	
	vec3 CalculateGrabPos() {
		vec3 test_end = this_mo.position+ledge_dir*1.0f;
		test_end.y = ledge_height;
		vec3 test_start = test_end+ledge_dir*-2.0f;
		test_start.y = ledge_height;
		this_mo.GetSweptCylinderCollision(test_start,
										  test_end,
										  _leg_sphere_size,
										  1.0f);

		/*DebugDrawWireCylinder(test_start,
							  _leg_sphere_size,
							  1.0f,
							  vec3(1.0f,0.0f,0.0f),
							  _delete_on_update);

		DebugDrawWireCylinder(test_end,
							  _leg_sphere_size,
							  1.0f,
							  vec3(0.0f,1.0f,0.0f),
							  _delete_on_update);

		DebugDrawWireCylinder(sphere_col.position,
							  _leg_sphere_size,
							  1.0f,
							  vec3(0.0f,0.0f,1.0f),
							  _delete_on_update);*/

		return sphere_col.position - vec3(0.0f, _height_under_ledge, 0.0f);
	}

	void CheckLedges(bool hit_wall, vec3 wall_dir) {
		if(hit_wall){
			ledge_dir = wall_dir;
			/*DebugDrawLine(this_mo.position,
						  this_mo.position + ledge_dir,
						  vec3(1.0f,0.0f,0.0f),
						  _persistent);*/
		} else {
			this_mo.GetSlidingSphereCollision(this_mo.position,
											  _leg_sphere_size*1.5f);
			if(sphere_col.NumContacts() == 0){
				return;
			} else {
				float closest_dist = 0.0f;
				float dist;
				int closest_point = -1;
				int num_contacts = sphere_col.NumContacts();
				for(int i=0; i<num_contacts; ++i){
					dist = distance_squared(
						sphere_col.GetContact(i).position, this_mo.position);
					if(closest_point == -1 || dist < closest_dist){
						closest_dist = dist;
						closest_point = i;
					}
				}
				ledge_dir = sphere_col.GetContact(closest_point).position - this_mo.position;
				ledge_dir.y = 0.0f;
				ledge_dir = normalize(ledge_dir);
			}
		}

		// Get ledge height
		float cyl_height = 1.0f;
		vec3 test_start = this_mo.position+vec3(0.0f,5.0f,0.0f)+ledge_dir * 0.5f;
		vec3 test_end = this_mo.position+vec3(0.0f,0.5f,0.0f)+ledge_dir * 0.5f;
		this_mo.GetSweptCylinderCollision(test_start,
							     test_end,
								 _leg_sphere_size,
								 1.0f);

		float edge_height = sphere_col.position.y - cyl_height * 0.5f;

		if(sphere_col.NumContacts() == 0){
			return;
		}

		// Make sure top surface is clear
		this_mo.GetCylinderCollision(sphere_col.position + vec3(0.0f,0.01f,0.0f),
								    _leg_sphere_size,
								    1.0f);
		if(sphere_col.NumContacts() != 0){
			return;
		}

		// Get ledge depth
		test_end = this_mo.position+ledge_dir*1.0f;
		test_end.y = edge_height;
		test_start = test_end+ledge_dir*-1.0f;
		this_mo.GetSweptCylinderCollision(test_start,
										  test_end,
										  _leg_sphere_size,
										  1.0f);
/*		
		DebugDrawWireCylinder(test_start,
							  _leg_sphere_size,
							  1.0f,
							  vec3(1.0f,0.0f,0.0f),
							  _delete_on_update);

		DebugDrawWireCylinder(test_end,
							  _leg_sphere_size,
							  1.0f,
							  vec3(0.0f,1.0f,0.0f),
							  _delete_on_update);

		DebugDrawWireCylinder(sphere_col.position,
							  _leg_sphere_size,
							  1.0f,
							  vec3(0.0f,0.0f,1.0f),
							  _delete_on_update);*/

		if(sphere_col.NumContacts() > 0){
			vec3 edge_pos = sphere_col.position + ledge_dir * _leg_sphere_size;
			vec3 wall_right = WallRight();
		} else {
			return;
		}

		ledge_height = edge_height;

		float char_height = this_mo.position.y;
		float grab_height = 2.5f;
		if(!on_ledge && char_height > edge_height - grab_height){
			on_ledge = true;
			climbed_up = false;
			this_mo.velocity = vec3(0.0f);
			ledge_grab_pos = CalculateGrabPos();
			shimmy_anim.Start(ledge_grab_pos, ledge_dir);

			//string path = "Data/Sounds/concrete_foley/bunny_edge_grab_concrete.xml";
			//this_mo.PlaySoundGroupAttached(path, this_mo.position);
			this_mo.MaterialEvent("edge_grab", this_mo.position + wall_dir * _leg_sphere_size);
		}
	}
	
	void UpdateLedge(bool hit_wall) {
		if(!WantsToGrabLedge() || !hit_wall){
			on_ledge = false;	
		}

		this_mo.velocity += ledge_dir * 0.1f * num_frames;

		float target_height = ledge_height - _height_under_ledge;
		this_mo.velocity.y += (target_height - this_mo.position.y) * 0.8f;
		this_mo.velocity.y *= pow(0.92f, num_frames);
		
		if(this_mo.position.y > target_height + 0.5f){
			this_mo.position.y = target_height + 0.5f;
		}
		if(this_mo.position.y < target_height - 0.1f){
			this_mo.position.y = target_height - 0.1f;
		}
		
		//this_mo.velocity.y = 0.0f;
		//this_mo.position.y = target_height;

		vec3 target_velocity = GetTargetVelocity();
		float ledge_dir_dot = dot(target_velocity, ledge_dir);
		vec3 horz_vel = target_velocity - (ledge_dir * ledge_dir_dot);
		vec3 real_velocity = horz_vel;
		if(ledge_dir_dot > 0.0f){
			real_velocity.y += ledge_dir_dot * time_step * num_frames * _ledge_move_speed * 70.0f;
		}	
		this_mo.velocity += real_velocity * time_step * num_frames * _ledge_move_speed;
		this_mo.velocity.x *= pow(_ledge_move_damping, num_frames);
		this_mo.velocity.z *= pow(_ledge_move_damping, num_frames);

		vec3 new_ledge_grab_pos = CalculateGrabPos();
		shimmy_anim.Update(new_ledge_grab_pos, ledge_dir);

		if(this_mo.velocity.y >= 0.0f && this_mo.position.y > target_height + 0.4f){
			on_ledge = false;	
			climbed_up = true;
			this_mo.velocity = vec3(0.0f);
			this_mo.position.y = ledge_height + _leg_sphere_size * 0.7f;
			this_mo.position += ledge_dir * 0.7f;
		}
		//if(distance(new_ledge_grab_pos, ledge_grab_pos) > 0.2f){
		//	ledge_grab_pos = new_ledge_grab_pos;
		//}
	}
};