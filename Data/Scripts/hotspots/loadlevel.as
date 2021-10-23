void Init() {
}

string _default_path = "Data/Levels/levelname.xml";

void SetParameters() {
    params.AddString("Level to load", _default_path);
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
        string path = params.GetString("Level to load");
        if(path != _default_path){
            SendLevelMessage2("loadlevel", path);
        } else {
            SendLevelMessage2("displaytext", "Target level not set");
        }
    }
}

void OnExit(MovementObject @mo) {
    if(mo.controlled){
        SendLevelMessage("cleartext");
    }
}