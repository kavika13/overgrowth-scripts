void Init() {
}

void SetParameters() {
}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
        OnEnter(mo);
    } 
}

void OnEnter(MovementObject @mo) {;
    if(mo.controlled){
        level.Execute("ReceiveMessage(\"reset\")");
    }
}