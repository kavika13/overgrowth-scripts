void Init() {
}

int count = 0;
int water_surface_id = -1;
int water_decal_id = -1;

void Dispose() {
    if(water_decal_id != -1){
        QueueDeleteObjectID(water_decal_id);
        water_decal_id = -1;
    }
    if(water_surface_id != -1){
        QueueDeleteObjectID(water_surface_id);
        water_surface_id = -1;
    }
}

void HandleEvent(string event, MovementObject @mo){
    //DebugText("wed", "Event: " + event, _fade);
    if(event == "enter"){
        OnEnter(mo);
    } else if(event == "exit"){
        OnExit(mo);
    }
}

void OnEnter(MovementObject @mo) {
    mo.ReceiveMessage("extinguish");
}

void OnExit(MovementObject @mo) {
}


void PreDraw(float curr_game_time) {
}

void Update() {
    Object@ obj = ReadObjectFromID(hotspot.GetID());
    array<int> nearby_characters;
    GetCharacters(nearby_characters);
    int num_chars = nearby_characters.size();
    for(int i=0; i<num_chars; ++i){
        MovementObject@ mo = ReadCharacterID(nearby_characters[i]);
        mo.rigged_object().AddWaterCube(obj.GetTransform());
    }    
    if(water_surface_id == -1){
        water_surface_id = CreateObject("Data/Objects/water_test.xml", true);
    }
    Object@ water_surface_obj = ReadObjectFromID(water_surface_id);
    water_surface_obj.SetTranslation(obj.GetTranslation());
    water_surface_obj.SetRotation(obj.GetRotation());
    water_surface_obj.SetScale(obj.GetScale() * 2.0f);
    if(water_decal_id == -1){
        water_decal_id = CreateObject("Data/Objects/Decals/water_fog.xml", true);
    }
    Object@ water_decal_obj = ReadObjectFromID(water_decal_id);
    water_decal_obj.SetTranslation(obj.GetTranslation() + vec3(0.0, 0.01, 0.0)); // To avoid z-fighting
    water_decal_obj.SetRotation(obj.GetRotation());
    water_decal_obj.SetScale(obj.GetScale() * 4.00f);
}