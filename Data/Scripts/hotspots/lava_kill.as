void Init() {
}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
        OnEnter(mo);
    } if(event == "exit"){
        //Print("Exited lava\n");
    }
}

void OnEnter(MovementObject @mo) {
    //Print("Entered lava\n");
    mo.ReceiveMessage("ignite");
    mo.Execute("TakeBloodDamage(1.0f);Ragdoll(_RGDL_INJURED);zone_killed=1;");
}