void SetParameters() {
	params.AddInt("level_hotspot_id", -1);
    params.AddInt("checkpoint_id", -1);
}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
        OnEnter(mo);
    }
}


void OnEnter(MovementObject @mo) {
    if(mo.controlled && params.HasParam("level_hotspot_id") && params.HasParam("checkpoint_id")){
        int level_hotspot_id = params.GetInt("level_hotspot_id");
        if(ObjectExists(level_hotspot_id)){
            Object@ obj = ReadObjectFromID(level_hotspot_id);
            int checkpoint_id = params.GetInt("checkpoint_id");
            obj.ReceiveScriptMessage("player_entered_checkpoint "+checkpoint_id);
        }
    }
}
