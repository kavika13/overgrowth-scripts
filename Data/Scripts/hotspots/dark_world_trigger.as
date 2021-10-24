
void SetParameters() {
  params.AddInt("dark_world_level_id", -1);
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
        int dark_world_level_id = params.GetInt("dark_world_level_id");
        if(ObjectExists(dark_world_level_id)){
            Object@ obj = ReadObjectFromID(dark_world_level_id);
            obj.ReceiveScriptMessage("trigger_enter");
        }
    }
}

void Update() {
}