bool played;
string no_kills_ = "1";

void Reset() {
    played = false;
}

void Init() {
    Reset();
}

void SetParameters() {
	params.AddIntCheckbox("Play Once", true);
	params.AddIntCheckbox("Play only If dead", false);
	params.AddIntCheckbox("Play for npcs", false);
    params.AddString("Non-Lethal Dialogue", "Default text");
    params.AddString("Lethal Dialogue", "Default text");
}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
        OnEnter(mo);
    } else if(event == "exit"){
        OnExit(mo);
    }
}

void OnEnter(MovementObject @mo) {
    if((mo.GetIntVar("no_kills_") == 1)
		&& (!played || params.GetInt("Play Once") == 0)
		&& (mo.controlled || params.GetInt("Play for npcs") == 1)){
		
        level.SendMessage("start_dialogue \""+params.GetString("Non-Lethal Dialogue")+"\"");
        played = true;
    }
    else if((mo.GetIntVar("no_kills_") == 0)
		&& (!played || params.GetInt("Play Once") == 0)
		&& (mo.controlled || params.GetInt("Play for npcs") == 1)){
		
        level.SendMessage("start_dialogue \""+params.GetString("Lethal Dialogue")+"\"");
        played = true;
    }
}

void OnExit(MovementObject @mo) {
}