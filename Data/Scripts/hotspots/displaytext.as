void Init() {
}

void SetParameters() {
    params.AddString("Display Text", "Default text");
}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
        OnEnter(mo);
    } else if(event == "exit"){
        OnExit(mo);
    }
}

void OnEnter(MovementObject @mo) {
    if(mo.controlled){
        level.SendMessage("displaytext \"Display Text\"");
    }
}

void OnExit(MovementObject @mo) {
    if(mo.controlled){
        level.SendMessage("cleartext");
    }
}