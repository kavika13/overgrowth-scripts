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
        //SendLevelMessage("reset");
        SendLevelMessage2("displaytext", params.GetString("Display Text"));
        //SendLevelMessage2("loadlevel", "Data/Levels/TerrainSculpt2_IGF.xml");
        //SendLevelMessage2("displaygui", "dialogs/parameters.html");
    }
}

void OnExit(MovementObject @mo) {
    Print("Exiting start.as hotspot\n");
    SendLevelMessage("cleartext");
}