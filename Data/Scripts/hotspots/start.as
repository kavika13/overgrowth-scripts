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
    if(mo.controlled){
        level.Execute("ReceiveMessage2(\"displaytext\",\""+params.GetString("Display Text")+"\")");
    }
}

void OnExit(MovementObject @mo) {
    level.Execute("ReceiveMessage(\"cleartext\")");
}