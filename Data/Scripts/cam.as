void Init() {
}

int controller_id = 0;

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

void Update() {
    if(!co.controlled){
        return;
    }
    
    camera.SetInterpSteps(1);
    if(GetInputPressed(controller_id, "o") && GetInputDown(controller_id, "ctrl")){
        camera_animation_reader.AttachTo("Data/Animations/test.canm");
        co.LoadParallaxScene("Data/Textures/twisted_paths.png",
                          "Data/Models/twisted_paths.obj");
    }
    if(camera_animation_reader.valid()){
        vec3 pos = camera_animation_reader.GetPosition();
        pos = vec3(pos.x, pos.z, -pos.y);
        co.position = pos;
        quaternion quat(camera_animation_reader.GetRotationVec4());
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
        UpdateListener(co.position,vel,camera.GetFacing(),camera.GetUpVector());            
        float lens = camera_animation_reader.GetLens();
        float angle = (2.0f * atan(16.0f/lens)) / 3.1415f * 180.0f;
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

            target_velocity += GetMoveXAxis(controller_id)*flat_right;
            if(!GetInputDown(controller_id, "crouch")){
                target_velocity -= GetMoveYAxis(controller_id)*camera.GetFacing();
            } else {
                target_velocity.y -= GetMoveYAxis(controller_id);
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
            co.velocity = co.velocity * _camera_inertia + target_velocity * (1.0f - _camera_inertia);
            co.position += co.velocity * time_step;

            
            /*vec3 start = co.position;
            vec3 end = co.position + camera.GetMouseRay()*50.0f;
            col.CheckRayCollisionCharacters(start, end);
            DebugDrawWireSphere(sphere_col.position, 0.05f, vec3(1.0f), _delete_on_update);
            */
             
            if(GetInputDown(controller_id, "mouse0") && !co.ignore_mouse_input){
                target_rotation -= GetLookXAxis(controller_id);
                target_rotation2 -= GetLookYAxis(controller_id);
            }
            SetGrabMouse(false);
        }
        
        /*if(scenegraph && ActiveCamera::Get()->GetCollisionDetection()){
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
        
        camera.CalcFacing();
        camera.CalcUp();
        
        /*DebugText("camx","Camera X: "+co.position.x,0.5f);
        DebugText("camy","Camera Y: "+co.position.y,0.5f);
        DebugText("camz","Camera Z: "+co.position.z,0.5f);*/

        UpdateListener(co.position,vel,camera.GetFacing(),camera.GetUpVector());
    }
}
