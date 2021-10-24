void Init() {
}

int count = 0;
int water_surface_id = -1;
int water_decal_id = -1;

void SetParameters() {
    params.AddFloatSlider("Wave Density",0.25f,"min:0,max:1,step:0.01");
    params.AddFloatSlider("Wave Height",0.5f,"min:0,max:1,step:0.01");
    params.AddFloatSlider("Water Fog",1.0f,"min:0,max:1,step:0.01");

}

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
    //mo.ReceiveScriptMessage("extinguish");
    //mo.Execute("TakeBloodDamage(1.0f);Ragdoll(_RGDL_FALL);zone_killed=1;");
}

void OnExit(MovementObject @mo) {
    mo.Execute("WaterExit("+hotspot.GetID()+");");
}


void PreDraw(float curr_game_time) {
}

void Update() {
    EnterTelemetryZone("wet cube update");
    Object@ obj = ReadObjectFromID(hotspot.GetID());
    /*array<int> nearby_characters;
    GetCharacters(nearby_characters);
    int num_chars = nearby_characters.size();
    for(int i=0; i<num_chars; ++i){
        MovementObject@ mo = ReadCharacterID(nearby_characters[i]);
        mo.rigged_object().AddWaterCube(obj.GetTransform());
    }    */
    if(!params.HasParam("Invisible")){
        if(water_surface_id == -1){
            water_surface_id = CreateObject("Data/Objects/water_test.xml", true);
        }
        Object@ water_surface_obj = ReadObjectFromID(water_surface_id);
        water_surface_obj.SetTranslation(obj.GetTranslation());
        water_surface_obj.SetRotation(obj.GetRotation());
        water_surface_obj.SetScale(obj.GetScale() * 2.0f);

        water_surface_obj.SetTint(vec3(params.GetFloat("Wave Height"),params.GetFloat("Wave Density"),params.GetFloat("Water Fog")));
    }    
    if(water_decal_id == -1){
        water_decal_id = CreateObject("Data/Objects/Decals/water_fog.xml", true);
    }
    Object@ water_decal_obj = ReadObjectFromID(water_decal_id);
    water_decal_obj.SetTranslation(obj.GetTranslation());
    water_decal_obj.SetRotation(obj.GetRotation());
    water_decal_obj.SetScale(obj.GetScale() * 4.00f);

    array<int> collides_with;
    level.GetCollidingObjects(hotspot.GetID(), collides_with);
    for(int i=0, len=collides_with.size(); i<len; ++i){
        int id = collides_with[i];
        if(ObjectExists(id) && ReadObjectFromID(id).GetType() == _movement_object){
            MovementObject@ mo = ReadCharacterID(id);
            mo.Execute("WaterIntersect("+hotspot.GetID()+");");
            if(params.HasParam("Lethal")){
              mo.Execute("zone_killed=1;TakeDamage(1.0f);");
            }
        }
    }
    LeaveTelemetryZone();
}
