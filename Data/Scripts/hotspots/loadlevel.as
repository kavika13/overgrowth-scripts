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
            level.SendMessage("loadlevel \""+path+"\"");
        } else {
            level.SendMessage("displaytext \"Target level not set\"");
        }
    }
}

void OnExit(MovementObject @mo) {
    if(mo.controlled){
        level.SendMessage("cleartext");
    }
}
