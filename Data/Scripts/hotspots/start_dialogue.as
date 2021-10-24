bool played;

void Reset() {
    played = false;
}

void Init() {
    Reset();
}

void SetParameters() {
    params.AddString("Dialogue", "Default text");
}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
        OnEnter(mo);
    } else if(event == "exit"){
        OnExit(mo);
    }
}

void OnEnter(MovementObject @mo) {
    if(mo.controlled && !played){
        level.SendMessage("start_dialogue \""+params.GetString("Dialogue")+"\"");
        played = true;
    }
}

void OnExit(MovementObject @mo) {
}