bool played;

void Reset() {
    played = false;
}

void Init() {
    Reset();
}

void SetParameters() {
	params.AddIntCheckbox("Play Once", true);
	params.AddIntCheckbox("Play Lethal Dialogue", false);
	params.AddIntCheckbox("Play for npcs", false);
    params.AddString("Dialogue", "Test");
    params.AddString("Lethal Dialogue", "Test2");
}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
        OnEnter(mo);
    } else if(event == "exit"){
        OnExit(mo);
    }
}

void OnEnter(MovementObject @mo) {
    if((mo.GetIntVar("no_kills_") == 1 || params.GetInt("Play Lethal Dialogue") == 1)
		&& (mo.controlled || params.GetInt("Play for npcs") == 1)){
		
        level.SendMessage("start_dialogue \""+params.GetString("Lethal Dialogue")+"\"");
        played = true;
    }
}

void OnExit(MovementObject @mo) {
}