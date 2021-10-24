void Init() {
}

void SetParameters() {
	params.AddString("Smoke particle amount", "5.0");
}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
        OnEnter(mo);
    }
	else if(event == "exit"){
        OnExit(mo);
    }
}
void OnEnter(MovementObject @mo) {
		Object@ thisHotspot = ReadObjectFromID(hotspot.GetID());
		vec3 explosion_point = thisHotspot.GetTranslation();
		MakeMetalSparks(explosion_point);
		float speed = 5.0f;
		for(int i=0; i<(params.GetFloat("Smoke particle amount")); i++){
				MakeParticle("Data/Particles/explosion_smoke.xml",mo.position,
				vec3(RangedRandomFloat(-speed,speed),RangedRandomFloat(-speed,speed),RangedRandomFloat(-speed,speed)));
		}
	  PlaySound("Data/Sounds/explosives/explosion1.wav");
}
void OnExit(MovementObject @mo) {
}
void MakeMetalSparks(vec3 pos){
    int num_sparks = 60;
		float speed = 20.0f;
    for(int i=0; i<num_sparks; ++i){
        MakeParticle("Data/Particles/explosion_fire.xml",pos,vec3(RangedRandomFloat(-speed,speed),
                                                         RangedRandomFloat(-speed,speed),
                                                         RangedRandomFloat(-speed,speed)));
    }
}
