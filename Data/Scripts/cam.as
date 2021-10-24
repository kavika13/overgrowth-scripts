void Init() {
    position = co.GetTranslation();
    vec3 facing = co.GetRotation() * vec3(0,0,1);
    vec3 flat_facing = normalize(vec3(facing.x, 0.0f, facing.z));
    target_rotation =  atan2(-flat_facing.x, flat_facing.z) / 3.1417f * 180.0f;
    target_rotation2 =  asin(facing.y) / 3.1417f * 180.0f;
    rotation = target_rotation;
    rotation2 = target_rotation2;
}

int controller_id = 0;

vec3 position;
vec3 old_position;
float speed = 0.0f;
float target_rotation = 0.0f;
float target_rotation2 = 0.0f;
float rotation = 0.0f;
float rotation2 = 0.0f;
float smooth_speed = 0.0f;

const float _camera_rotation_inertia = 0.8f;
const float _camera_inertia = 0.8f;
const float _camera_media_mode_rotation_inertia = 0.99f;
const float _camera_media_mode_inertia = 0.99f;
const float _acceleration = 20.0f;
const float _base_speed = 5.0f;

bool just_got_control = false;

void Update() {
    if(!co.controlled) {
        just_got_control = true;
        return;
    }

    if( just_got_control ) {
        if( co.has_position_initialized == false ) {

            co.has_position_initialized = true; 

            int num_chars = GetNumCharacters();
            if( num_chars > 0 )
            {
                 MovementObject@ char = ReadCharacter(0);
                 Object@ char_obj = ReadObjectFromID(char.GetID());
                 position = char_obj.GetTranslation() + vec3(0,1,0);
            }

        }
        just_got_control = false; 
    }

    if(level.QueryIntFunction("int HasCameraControl()") == 1){
        return;
    }
    
    camera.SetInterpSteps(1);

    old_position = position;
    vec3 vel;
    if(!co.frozen){
        vec3 target_velocity;
        bool moving = false;
        vec3 flat_facing = camera.GetFlatFacing();
        vec3 flat_right = vec3(-flat_facing.z, 0.0f, flat_facing.x);
        target_velocity += GetMoveXAxis(controller_id)*flat_right;
        if(!GetInputDown(controller_id, "crouch")){
            target_velocity -= GetMoveYAxis(controller_id)*camera.GetFacing();
        } else {
            target_velocity -= GetMoveYAxis(controller_id)*camera.GetUpVector();
        }
        if(length_squared(target_velocity) > 0.0f){
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
        if(GetInputDown(controller_id, "space")){
            target_velocity *= 0.1f;   
        }
        float inertia;
        if(MediaMode()){
            inertia = _camera_media_mode_inertia;
        } else {
            inertia = _camera_inertia;
        }
        co.velocity = co.velocity * inertia + target_velocity * (1.0f - inertia);
        position += co.velocity * time_step;
        if(GetInputDown(controller_id, "mouse0") && !co.ignore_mouse_input){
            target_rotation -= GetLookXAxis(controller_id);
            target_rotation2 -= GetLookYAxis(controller_id);
        }
        SetGrabMouse(false);
    }

    float _camera_collision_radius = 0.4f;
    vec3 old_new_position = position;
    position = col.GetSlidingCapsuleCollision(old_position, position, _camera_collision_radius) ;
    co.velocity += (position - old_new_position)/time_step;

    float rot_inertia;
    if(MediaMode()){
        rot_inertia = _camera_media_mode_rotation_inertia;
    } else {
        rot_inertia = _camera_rotation_inertia;
    }
    rotation = rotation * rot_inertia + 
               target_rotation * (1.0f - rot_inertia);
    rotation2 = rotation2 * rot_inertia + 
               target_rotation2 * (1.0f - rot_inertia);

    float smooth_inertia = 0.9f;
    smooth_speed = mix(length(co.velocity), smooth_speed, smooth_inertia);
    
    float move_speed = smooth_speed;
    SetAirWhoosh(move_speed*0.01f,min(2.0f,move_speed*0.01f+0.5f));
    
    float camera_vibration_mult = 0.001f;
    float camera_vibration = move_speed * camera_vibration_mult;
    rotation += RangedRandomFloat(-camera_vibration, camera_vibration);
    rotation2 += RangedRandomFloat(-camera_vibration, camera_vibration);

    quaternion rot = quaternion(vec4(0.0f, -1.0f, 0.0f, rotation  * 3.1417f / 180.0f)) *
                     quaternion(vec4(-1.0f, 0.0f, 0.0f, rotation2 * 3.1417f / 180.0f));
    co.SetRotation(rot);

    camera.SetYRotation(rotation);    
    camera.SetXRotation(rotation2);
    camera.SetZRotation(0.0f);
    camera.SetPos(position);

    camera.SetDistance(0);
    camera.SetVelocity(co.velocity); 
    camera.SetFOV(90.0f);
    
    camera.CalcFacing();
    camera.CalcUp();

    UpdateListener(position,vel,camera.GetFacing(),camera.GetUpVector());
    
    co.SetTranslation(position);
}
