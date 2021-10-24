void SetParameters() {
	params.AddInt("level_hotspot_id", -1);
    params.AddInt("checkpoint_id", -1);
}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
        OnEnter(mo);
    }
    if(event == "exit"){
        OnExit(mo);
    }
}

int entered = -1;
float entered_time = 0.0f;

void OnEnter(MovementObject @mo) {
    if(mo.controlled && params.HasParam("level_hotspot_id") && params.HasParam("checkpoint_id")){
        if(params.HasParam("fall_death")){
            int level_hotspot_id = params.GetInt("level_hotspot_id");
            if(ObjectExists(level_hotspot_id)){
                Object@ obj = ReadObjectFromID(level_hotspot_id);
                int checkpoint_id = params.GetInt("checkpoint_id");
                obj.ReceiveScriptMessage("player_entered_checkpoint_fall_death "+checkpoint_id);
            }
        } else {
            entered = mo.GetID();
            entered_time = the_time;
        }
    }
}

void OnExit(MovementObject @mo) {
    if(mo.controlled){
        if(mo.GetID() == entered){
            entered = -1;
        }
    }
}

void Update() {
    if(entered != -1){
        if(!params.HasParam("time") || entered_time < the_time - params.GetFloat("time")){
            int level_hotspot_id = params.GetInt("level_hotspot_id");
            if(ObjectExists(level_hotspot_id)){
                Object@ obj = ReadObjectFromID(level_hotspot_id);
                int checkpoint_id = params.GetInt("checkpoint_id");
                obj.ReceiveScriptMessage("player_entered_checkpoint "+checkpoint_id);
            }
            entered = -1;
        }
    }
}