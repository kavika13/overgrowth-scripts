void Init() {
}

string displayText;
string changeToTeam;

void SetParameters() {

params.AddString("Change to Team","false");
    changeToTeam = params.GetString("Change to Team");
	
params.AddIntCheckbox("Play for NPCs", false);

}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
        OnEnter(mo);
    } else if(event == "exit"){
        OnExit(mo);
    }
}

void OnEnter(MovementObject @mo) {
	if(mo.controlled || params.GetInt("Play for NPCs") == 1){
		Object@ obj = ReadObjectFromID(mo.GetID());
		ScriptParams@ params = obj.GetScriptParams();
		params.SetString("Teams", ""+changeToTeam+"");
	}
}

void OnExit(MovementObject @mo) {
    if(mo.controlled){
        level.Execute("ReceiveMessage(\"cleartext\")");
    }
}

