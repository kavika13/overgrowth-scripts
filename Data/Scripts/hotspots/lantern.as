int light_id = -1;
int lamp_id = -1;
vec3 light_color = vec3(8.0f,7.75f,6.75f);
vec3 light_range = vec3(500.0f);
bool init_done = false;

void Init() {
    Object@ hotspot_obj = ReadObjectFromID(hotspot.GetID());
    hotspot_obj.SetScale(0.5f);
}
void Update() {
    if(!init_done){
        FindSavedLantern();
        init_done = true;
    }

    if(light_id == -1 || !ObjectExists(light_id)){
        CreateLight();
    }else if(lamp_id == -1 || !ObjectExists(lamp_id)){
        CreateLantern();
    }else{
        ItemObject@ io = ReadItemID(lamp_id);
        Object@ light = ReadObjectFromID(light_id);
        light.SetTranslation(io.GetPhysicsPosition());
    }
}

void CreateLight(){
    //Setting up the actual light emitter.
    light_id = CreateObject("Data/Objects/lights/dynamic_light.xml");
    Object@ light = ReadObjectFromID(light_id);
    light.SetScaleable(true);
    light.SetTintable(true);
    light.SetSelectable(true);
    light.SetTranslatable(true);
}

void CreateLantern(){
    //This is the lantern model that can be equipt.
    lamp_id = CreateObject("Data/Objects/lantern_small.xml", false);
    Object@ lamp = ReadObjectFromID(lamp_id);
    ScriptParams@ lamp_params = lamp.GetScriptParams();
    lamp_params.SetInt("BelongsTo", hotspot.GetID());
    Object@ hotspot_obj = ReadObjectFromID(hotspot.GetID());
    lamp.SetTranslation(hotspot_obj.GetTranslation());
    lamp.SetSelectable(true);
    lamp.SetTranslatable(true);

}

void FindSavedLantern(){
    array<int> all_obj = GetObjectIDsType(_item_object);
    Print("found nr " + all_obj.size() + "\n");
    for(uint i = 0; i < all_obj.size(); i++){
        Object@ current_obj = ReadObjectFromID(all_obj[i]);
        ScriptParams@ current_param = current_obj.GetScriptParams();
        Print("If " + all_obj[i] + " belongs to \n");
        if(current_param.HasParam("BelongsTo")){
            if(current_param.GetInt("BelongsTo") == hotspot.GetID()){
                lamp_id = all_obj[i];
                return;
            }
        }
    }
}
