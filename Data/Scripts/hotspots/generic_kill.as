void Init() {
}

void SetParameters() {
	params.AddIntCheckbox("KillNPC", true);
	params.AddIntCheckbox("KillPlayer", true);
}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
        OnEnter(mo);
    }
}

void OnEnter(MovementObject @mo) {
    if( (mo.is_player && params.GetInt("KillPlayer") == 1) || (mo.is_player == false && params.GetInt("KillNPC") == 1)) {
        mo.Execute("TakeBloodDamage(1.0f);Ragdoll(_RGDL_FALL);zone_killed=1;");
    }
}
