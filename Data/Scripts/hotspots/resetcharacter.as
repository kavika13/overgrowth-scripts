void Init() {
}

void SetParameters() {
}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
        OnEnter(mo);
    } else if (event == "exit"){
    	OnExit(mo);
    }
}

void OnEnter(MovementObject @mo) {
	Object@ charObject = ReadObjectFromID(mo.GetID());
	mo.Execute("Recover();");
	mo.Execute("Reset();");
	mo.position = charObject.GetTranslation();
	mo.velocity = vec3(0);
	//mo.Execute("SetParameters();");
	mo.Execute("PostReset();");
	mo.Execute("ResetSecondaryAnimation();");
	if(mo.controlled){
		level.SendMessage("achievement_event character_reset_hotspot");
	}
}

void OnExit(MovementObject @mo) {;

}