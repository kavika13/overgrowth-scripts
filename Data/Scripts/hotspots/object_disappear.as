void Init() {
}

string _default_path = "Unknown";

void SetParameters() {
    params.AddString("Object name to disappear", _default_path);
}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
        OnEnter(mo);
    }
}

void OnEnter(MovementObject @mo) {
    if(mo.controlled){
        string to_disappear = params.GetString("Object name to disappear");
        array<int> @object_ids = GetObjectIDs();
        int num_objects = object_ids.length();
        for(int i=0; i<num_objects; ++i){
            Object @obj = ReadObjectFromID(object_ids[i]);
            ScriptParams@ params = obj.GetScriptParams();
            if(params.HasParam("Name")){
                string name_str = params.GetString("Name");
                if(to_disappear == name_str){
                    Log(info, "Test");
                    DeleteObjectID(object_ids[i]);
                }
            }
        }
    }
}
