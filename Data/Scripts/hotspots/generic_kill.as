void Init() {
}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
        OnEnter(mo);
    }
}

void OnEnter(MovementObject @mo) {
    mo.Execute("TakeBloodDamage(1.0f);Ragdoll(_RGDL_FALL);zone_killed=1;");
}