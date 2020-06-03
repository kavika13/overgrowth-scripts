void init() {
    Print("Initializing start.as hotspot\n");
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
        //SendLevelMessage("reset");
        SendLevelMessage2("displaytext", "You are inside of a start.as hotspot");
    }
}

void OnExit(MovementObject @mo) {
    Print("Exiting start.as hotspot\n");
    SendLevelMessage("cleartext");
}