void Init() {
}

string _default_path = "Data/Levels/levelname.xml";

void SetParameters() {
    params.AddString("Level to load", _default_path);
    params.AddInt("light_id", -1);
    params.AddInt("spawn_point", -1);

    if(params.HasParam("spawn_point") && params.GetInt("spawn_point") != -1){
        int val = params.GetInt("spawn_point");
        if(ObjectExists(val)){
            Object@ obj = ReadObjectFromID(val);
            if(obj.GetType() == _placeholder_object){
                PlaceholderObject@ placeholder_object = cast<PlaceholderObject@>(obj);
                placeholder_object.SetPreview("Data/Objects/IGF_Characters/IGF_Guard.xml");
            }
        }
    }
}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
        OnEnter(mo);
    } if(event == "exit"){
        //Print("Exited lava\n");
    }
}

void OnEnter(MovementObject @mo) {
    if(mo.controlled){
        string path = params.GetString("Level to load");
        if(path != _default_path){
            level.SendMessage("loadlevel \""+path+"\"");
        } else {
            level.SendMessage("displaytext \"Target level not set\"");
        }
    }
}

void Update() {
    if(params.HasParam("light_id")){
        int target_id = params.GetInt("light_id");
        if(ObjectExists(target_id)){
            Object @obj = ReadObjectFromID(target_id);
            if(obj.GetType() == _dynamic_light_object){
                array<int> character_ids;
                GetCharactersInSphere(obj.GetTranslation(), 10.0f, character_ids);
                float brightness = 0.0f;
                for(int j=0, len=character_ids.size(); j<len; ++j){
                    brightness = max(brightness, 10.0f - distance(obj.GetTranslation(), ReadCharacterID(character_ids[j]).position));
                }
                float pulse = sin(the_time*23.0f) + sin(the_time*5.0f) + sin(the_time*17.0f);
                pulse = pulse / 3.0f / 2.0f + 0.5f;
                pulse = mix(pulse, 1.0f, 0.8f);
                obj.SetTint(vec3(brightness * 5.0f * pulse, 0.0, 0.0));
            }
        }
    }
}