void Init() {
}

void SetParameters() {
    params.AddString("branch","");
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
        string branch = params.GetString("branch");
        if(branch == "") {
            SendGlobalMessage("levelwin");
        } else {
            SendGlobalMessage("levelwin " + branch);
        }
    }
}

void OnExit(MovementObject @mo) {
}
