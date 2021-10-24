bool played;

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
    if((mo.GetIntVar("knocked_out") > 0 || params.GetInt("Play only If dead") == 0)
		&& (!played || params.GetInt("Play Once") == 0)
		&& (mo.controlled || params.GetInt("Play for npcs") == 1)){
		
        level.SendMessage("start_dialogue \""+params.GetString("Dialogue")+"\"");
        played = true;
    }
}

void OnExit(MovementObject @mo) {
}