void Init() {
    Print("Initializing start.as hotspot\n");
}

void SetParameters() {
    params.AddString("Display Text", "Default text");
}

void HandleEvent(string event, MovementObject @mo){
    Print("Handling event: "+event+"\n");  
    if(event == "enter"){
        OnEnter(mo);
    } else if(event == "exit"){
        OnExit(mo);
    }
}

void OnEnter(MovementObject @mo) {
    Print("Entering start.as hotspot\n");
    if(mo.controlled)
        level.SendMessage("displaytext \"Display Text\"");
    }
}

void OnExit(MovementObject @mo) {
    level.SendMessage("cleartext");
}