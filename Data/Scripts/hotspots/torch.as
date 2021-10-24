int light_id = -1;
int lamp_id = -1;
vec3 light_color = vec3(3.0f,1.75f,1.75f);
vec3 light_range = vec3(25.0f);
bool init_done = false;

void Init() {
    Object@ hotspot_obj = ReadObjectFromID(hotspot.GetID());
    hotspot_obj.SetScale(0.5f);
}
void Update() {
    if(!init_done){
        FindSavedTorch();
        FindFlameHotspot();
        init_done = true;
    }
    if(lamp_id == -1 || !ObjectExists(lamp_id)){
        CreateTorch();
    }else if(light_id == -1 || !ObjectExists(light_id)){
        Print("No flame hotspot found\n");
    }else{
        ItemObject@ io = ReadItemID(lamp_id);
        Object@ light = ReadObjectFromID(light_id);
        mat4 torch_transform = io.GetPhysicsTransform();
        quaternion torch_rotation = QuaternionFromMat4(torch_transform.GetRotationPart());
        light.SetTranslation(io.GetPhysicsPosition() + (torch_rotation * vec3(0.0f,0.35f,0.0f)) + vec3(0.0f, -0.25f, 0.0f));
    }
}

void CreateTorch(){
    //This is the torch model that can be equipt.
    lamp_id = CreateObject("Data/Items/torch.xml", false);
    Object@ lamp = ReadObjectFromID(lamp_id);
    ScriptParams@ lamp_params = lamp.GetScriptParams();
    lamp_params.SetInt("BelongsTo", hotspot.GetID());
    Object@ hotspot_obj = ReadObjectFromID(hotspot.GetID());
    lamp.SetTranslation(hotspot_obj.GetTranslation());
    lamp.SetSelectable(true);
    lamp.SetTranslatable(true);

}

void FindSavedTorch(){
    array<int> all_obj = GetObjectIDsType(_item_object);
    for(uint i = 0; i < all_obj.size(); i++){
        Object@ current_obj = ReadObjectFromID(all_obj[i]);
        ScriptParams@ current_param = current_obj.GetScriptParams();
        if(current_param.HasParam("BelongsTo")){
            if(current_param.GetInt("BelongsTo") == hotspot.GetID()){
                lamp_id = all_obj[i];
                return;
            }
        }
    }
}

void FindFlameHotspot(){
    array<int> all_obj = GetObjectIDsType(_hotspot_object);
    for(uint i = 0; i < all_obj.size(); i++){
        Object@ current_obj = ReadObjectFromID(all_obj[i]);
        ScriptParams@ current_param = current_obj.GetScriptParams();
        if(current_param.HasParam("FlameTaken")){
            if(current_param.GetInt("FlameTaken") == 0 || current_param.GetInt("FlameTaken") == hotspot.GetID()){
                current_param.SetInt("FlameTaken", hotspot.GetID());
                light_id = all_obj[i];
                return;
            }
        }
    }
}
