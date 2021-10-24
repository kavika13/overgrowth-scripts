void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
        OnEnter(mo);
    } else if(event == "exit"){
        OnExit(mo);
    }
}

void OnEnter(MovementObject @mo) {
    if(params.HasParam("Parent")){
        int id = params.GetInt("Parent");
        if(ObjectExists(id)){
            Object@ parent = ReadObjectFromID(id);
            parent.ReceiveScriptMessage("arm_spike");
        }
    }
}

void OnExit(MovementObject @mo) {
    if(params.HasParam("Parent")){
        int id = params.GetInt("Parent");
        if(ObjectExists(id)){
            Object@ parent = ReadObjectFromID(id);
            parent.ReceiveScriptMessage("disarm_spike");
        }
    }
}

void Draw() {
}