void Init() {
}

void SetParameters() {
    params.AddIntSlider("Smoke particle amount",5,"min:0,max:15");
    params.AddIntSlider("Sound",1,"min:1,max:3");
}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
        OnEnter(mo);
    }
	else if(event == "exit"){
        OnExit(mo);
    }
}

void ReceiveMessage(string msg) {
    TokenIterator token_iter;
    token_iter.Init();

    if(!token_iter.FindNextToken(msg)){
        return;
    }
    string token = token_iter.GetToken(msg);
    if(token == "reset") {
        Dispose();
    }
}

void Dispose() {
    if(fire_object_id != -1){
        QueueDeleteObjectID(fire_object_id);
        fire_object_id = -1;
    }
}

int fire_object_id = -1;

float explode_time = -1.0f;

void PreDraw(float curr_game_time) {
    if(fire_object_id != -1){
		Object@ thisHotspot = ReadObjectFromID(hotspot.GetID());
		vec3 explosion_point = thisHotspot.GetTranslation();
        Object@ fire_obj = ReadObjectFromID(fire_object_id);
        fire_obj.SetTranslation(explosion_point);
        float intensity_fade = pow(max(0.0, min(1.0, (explode_time-curr_game_time)*0.5+1.0)),2.0);
        fire_obj.SetTint(vec3(2.0,1.0,0.0)*1000.0*mix(0.02*(sin(curr_game_time*2.4)+sin(curr_game_time*1.5)+3.0),1,intensity_fade));
        fire_obj.SetScale(30.0);
    	DebugText("explode_time", "explode_time: "+explode_time, 0.5);

    }
}

void OnEnter(MovementObject @mo) {
	Object@ thisHotspot = ReadObjectFromID(hotspot.GetID());
	vec3 explosion_point = thisHotspot.GetTranslation();
	explode_time = the_time;
    if(fire_object_id == -1){
        fire_object_id = CreateObject("Data/Objects/default_light.xml", true);
    }
	MakeMetalSparks(explosion_point);
	float speed = 5.0f;
	for(int i=0; i<(params.GetFloat("Smoke particle amount")); i++){
			MakeParticle("Data/Particles/explosion_smoke.xml",mo.position,
			vec3(RangedRandomFloat(-speed,speed),RangedRandomFloat(-speed,speed),RangedRandomFloat(-speed,speed)));
	}
	PlaySound("Data/Sounds/explosives/explosion"+params.GetInt("Sound")+".wav");
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
