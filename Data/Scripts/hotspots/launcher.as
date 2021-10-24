void Init() {
}
// Credit to Steelraven7.

void SetParameters() {
	params.AddString("Velocity x", "0.0");
	params.AddString("Velocity y (up)", "0.0");
	params.AddString("Velocity z", "0.0");
	params.AddString("Trigger on entry", "1");
	params.AddString("Trigger on exit", "0");
}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter" && params.GetString("Trigger on entry") != "0") {
        Launch(mo);
    }
    else if(event == "exit" && params.GetString("Trigger on exit") != "0"){
        Launch(mo);
    }
}

void Launch(MovementObject @mo) {

	//If player is ragdollized, don't launch since this way of launching ragdolls may cause problems.
	if(mo.GetIntVar("state") == 4) return;

	mo.velocity.x = params.GetFloat("Velocity x");
	mo.velocity.y = params.GetFloat("Velocity y (up)");
	mo.velocity.z = params.GetFloat("Velocity z");
    mo.Execute("SetOnGround(false);");
    mo.Execute("pre_jump = false;");
}