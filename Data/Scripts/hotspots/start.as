void Init() {
    Log(info, "Initializing start.as hotspot");
}

void SetParameters() {
    params.AddString("Display Text", "Default text");
}

void HandleEvent(string event, MovementObject @mo){
    Log(info, "Handling event: "+event);  
    if(event == "enter"){
        OnEnter(mo);
    } else if(event == "exit"){
        OnExit(mo);
    }
}

void OnEnter(MovementObject @mo) {
    Log(info, "Entering start.as hotspot");
    if(mo.controlled) {
        level.SendMessage("displaytext \"Display Text\"");
    }
}

void OnExit(MovementObject @mo) {
    level.SendMessage("cleartext");
}
