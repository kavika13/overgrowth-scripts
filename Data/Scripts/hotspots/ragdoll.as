void Init() {
}

void SetParameters() {
	params.AddString("Recovery time", "5.0");
	params.AddString("Damage dealt", "0.0");
	params.AddString("Upward force", "0.0");
	params.AddString("Ragdoll type", "0");
}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
        OnEnter(mo);
    }
}

void OnEnter(MovementObject @mo) {
    string ragdollType = "_RGDL_FALL";

    if(params.GetFloat("Ragdoll type") == 1) {
    	ragdollType = "_RGDL_INJURED";
    }
    else if(params.GetFloat("Ragdoll type") == 2) {
    	ragdollType = "_RGDL_LIMP";
    }
    else if(params.GetFloat("Ragdoll type") == 3) {
    	ragdollType = "_RGDL_ANIMATION";
    }
    mo.Execute("DropWeapon(); Ragdoll("+ragdollType+"); HandleRagdollImpactImpulse(vec3(0.0f,"+params.GetFloat("Upward force")+",0.0f), this_mo.rigged_object().GetAvgIKChainPos(\"torso\"), "+params.GetFloat("Damage dealt")+"); roll_recovery_time = "+params.GetFloat("Recovery time")+"; recovery_time = "+params.GetFloat("Recovery time")+";");
}