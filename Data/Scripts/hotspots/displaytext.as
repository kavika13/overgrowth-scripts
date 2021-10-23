void Init() {
}

void SetParameters() {
    params.AddString("Display Text", "Default text");
    params.AddString("Jump speed", "5.0");
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
        SendLevelMessage2("displaytext", params.GetString("Display Text"));
        mo.position.y += 0.3f;
        mo.velocity.y += params.GetFloat("Jump speed");
    }
}

void OnExit(MovementObject @mo) {
    if(mo.controlled){
        SendLevelMessage("cleartext");
    }
}