void Init() {
}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
        OnEnter(mo);
    }
}

void OnEnter(MovementObject @mo) {
    Log(info, "Entered");
    float latest_time = -1.0f;
    int best_obj = -1;
    array<int> @object_ids = GetObjectIDsType(_hotspot_object);
    for(int i=0, len=object_ids.size(); i<len; ++i){
        Object@ obj = ReadObjectFromID(object_ids[i]);
        ScriptParams@ params = obj.GetScriptParams();
        if(params.HasParam("LastEnteredTime")){
            Log(info, "Found hotspot");
            float curr_time = params.GetFloat("LastEnteredTime");
            if(curr_time > latest_time){
                Log(info, "Best time: " + curr_time);
                best_obj = object_ids[i];
                latest_time = curr_time;
            } else {
                Log(info, "Bad time: " + curr_time);                
            }
        }
    }
    
    if(best_obj != -1){
        mo.position = ReadObjectFromID(best_obj).GetTranslation();
        mo.velocity = vec3(0.0);
    }
}
