void Init() {
}

bool launch = false;
bool play_launch_sound = false;
float time = 0.0f;
int flight_top = 200;
vec3 target_pos;
vec3 direction;
int char_id = 0;
vec3 flight_smoke_point;
float direction_weight = 0.0f;
float flight_smoke_point_weight = 1.0f;
bool play_end_sound = true;
vec3 starting_point;

void SetParameters() {
    params.AddIntCheckbox("Friendly", false);
    params.AddString("Rocket OBJ ID Number", "1001");
    params.AddString("Recovery time", "5.0");
    params.AddString("Damage dealt", "1.0");
    params.AddString("Upward force", "20.0");
    params.AddString("Smoke particle amount", "15");
    params.AddIntCheckbox("Show DebugLines", false);
}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
        OnEnter(mo);
    } 
    else if(event == "exit"){
        OnExit(mo);
    }
}

void OnEnter(MovementObject @mo) {  
    if (params.GetInt("Friendly") ==  1 && mo.controlled || launch == true){
    }
    else{
        starting_point = ReadObjectFromID(params.GetFloat("Rocket OBJ ID Number")).GetTranslation();
        char_id = mo.GetID();
        launch = true;
        play_launch_sound = true;
    }

}

void OnExit(MovementObject @mo) {    
}

void Update() {    
    time += time_step;
    Object@ obj = ReadObjectFromID(hotspot.GetID());
    Object@ rocket_obj = ReadObjectFromID(params.GetFloat("Rocket OBJ ID Number"));
    vec3 rocket_pos = rocket_obj.GetTranslation();
    vec3 initial_smoke_pos = rocket_obj.GetTranslation();
    initial_smoke_pos.y = initial_smoke_pos.y - 0.7f;
    vec3 pos = obj.GetTranslation();
    vec3 scale = obj.GetScale();
    quaternion rotation = obj.GetRotation();

    if (launch == true){
        target_pos = ReadCharacterID(char_id).position;
        direction = normalize(target_pos - rocket_pos);
        vec3 target_dir = normalize(direction* direction_weight+ flight_smoke_point* flight_smoke_point_weight);
        DebugDrawLine(rocket_pos, rocket_pos + target_dir * 10.0f, vec3(0.0f,1.0f,0.0f), _delete_on_update);
        vec3 dir = Mult(rocket_obj.GetRotation(), vec3(0,1,0));
        DebugDrawLine(rocket_pos, rocket_pos + dir * 10.0f, vec3(1.0f,0.0f,0.0f), _delete_on_update);
        vec3 perp = cross(dir, target_dir);
        float angle = acos(dot(dir, target_dir));
        quaternion quat(vec4(perp.x, perp.y, perp.z, angle));
        quaternion new_rotation = quat * rocket_obj.GetRotation();
        rocket_obj.SetRotation(new_rotation);  
    
        if(play_launch_sound == true){
            flight_top = rocket_pos.y + 200;
            PlaySound("Data/Custom/gyrth/rocket/Sounds/rocket_flight_end.wav", rocket_pos);
            play_launch_sound = false;
        }
        flight_smoke_point = normalize(vec3(rocket_pos.x, rocket_pos.y + flight_top, rocket_pos.z) - rocket_pos);
        vec3 fly_towards_pos = rocket_pos + (direction* direction_weight+ flight_smoke_point* flight_smoke_point_weight);
        rocket_obj.SetTranslation(fly_towards_pos);
        if(flight_smoke_point_weight >= 0.0f){
            direction_weight += 0.0008f;
            flight_smoke_point_weight -= 0.0008f;
        }
        array<int> is_target_nearby_for_sound;
        GetCharactersInSphere(rocket_pos, 100.0f, is_target_nearby_for_sound);
        if(params.GetInt("Show DebugLines") == 1){
            DebugDrawWireSphere(rocket_pos, 100.0f, vec3(1.0f), _delete_on_draw);
            DebugDrawWireSphere(rocket_pos, 1.0f, vec3(0.0f,0.0f,1.0f) ,_delete_on_draw);
            DebugDrawLine(rocket_pos, rocket_pos+(direction* direction_weight+ flight_smoke_point* flight_smoke_point_weight)*100, vec3(0.0f,1.0f,0.0f), _delete_on_update);
        }
        int num_nearby_char_for_sound = is_target_nearby_for_sound.size();
        for(int i=0; i<num_nearby_char_for_sound; ++i){
            if(is_target_nearby_for_sound[i] == char_id && play_end_sound ==true){
                play_end_sound = false;
                PlaySound("Data/Custom/gyrth/rocket/Sounds/rocket_flight_end.wav", target_pos);
            }
        }
        array<int> is_target_nearby;
        GetCharactersInSphere(rocket_pos, 1.0f, is_target_nearby);
        int num_nearby_char = is_target_nearby.size();
        for(int i=0; i<num_nearby_char; ++i){
            if(is_target_nearby[i] == char_id){
                launch = false;
                play_end_sound = true;
                array<int> nearby_characters;
                GetCharactersInSphere(target_pos, 5.0f, nearby_characters);
                int num_chars = nearby_characters.size();
                for(int i=0; i<num_chars; ++i){
                ReadCharacterID(nearby_characters[i]).Execute(
                        "GoLimp();" +   //Comment this line if you don't want an impact, but don't jump.
                        "TakeDamage("+ params.GetFloat("Damage dealt") +");"
                    );
                ReadCharacterID(nearby_characters[i]).rigged_object().ApplyForceToRagdoll(vec3(direction.x, -direction.y, direction.z)*100000, ReadCharacterID(nearby_characters[i]).rigged_object().GetAvgIKChainPos("torso"));
        } 
        camera.AddShake(10.0f);
        rocket_obj.SetTranslation(starting_point);
        rocket_obj.SetRotation(quaternion(vec4(0,0,0,1)));
        vec3 explosion_point(ReadCharacterID(char_id).position.x,ReadCharacterID(char_id).position.y-4,ReadCharacterID(char_id).position.z);
        MakeParticle("Data/Custom/gyrth/rocket/Scripts/propane.xml",explosion_point,vec3(0.0f,15.0f,0.0f));
        ReadCharacterID(char_id).Execute("TakeDamage("+params.GetFloat("Damage dealt")+");");
        for(int i=0; i<(params.GetFloat("Smoke particle amount")); i++){
            MakeParticle("Data/Custom/gyrth/rocket/Scripts/explosion_smoke.xml",ReadCharacterID(char_id).position,
                vec3(RangedRandomFloat(-2.0f,2.0f),RangedRandomFloat(-2.0f,2.0f),RangedRandomFloat(-2.0f,2.0f))*3.0f);
            }
            PlaySound("Data/Custom/gyrth/rocket/Sounds/explosion.wav", target_pos);

        direction_weight = 0.0f;
        flight_smoke_point_weight = 1.0f;
            }
        } 
        vec3 smoke_point = rocket_pos - (direction* direction_weight+ flight_smoke_point* flight_smoke_point_weight);
        MakeParticle("Data/Custom/gyrth/rocket/Scripts/flight_smoke.xml", smoke_point, vec3(0.0f,0.0f,0.0f));
    }
}
