bool played;
string god_key = "f12";

void Reset() {
    played = false;
}

void Init() {
    Reset();
}

void SetParameters() {
	params.AddIntCheckbox("Check Every Frame", true);
}

void Update() {
    Object@ obj = ReadObjectFromID(hotspot.GetID());
    vec3 pos = obj.GetTranslation();
    vec3 scale = obj.GetScale();
	if(params.GetInt("Check Every Frame") == 1){
		int num_chars = GetNumCharacters();
		for(int i=0; i<num_chars; ++i){
			MovementObject @mo = ReadCharacter(i);
			
			vec3 mopos = mo.position;
			bool isinside =	   mopos.x > pos.x-scale.x*2.0f
							&& mopos.x < pos.x+scale.x*2.0f
							&& mopos.y > pos.y-scale.y*2.0f
							&& mopos.y < pos.y+scale.y*2.0f
							&& mopos.z > pos.z-scale.z*2.0f
							&& mopos.z < pos.z+scale.z*2.0f;
						
			if(isinside){
				OnEnter(mo);
			}
		}
	}
}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
        OnEnter(mo);
    } else if(event == "exit"){
        OnExit(mo);
			if(mo.controlled){
		}
    }
}

void OnEnter(MovementObject @mo) {
    if(GetInputDown(mo.controller_id, god_key)){
		PlaySound("Data/Sounds/voice/torikamal/fallscream_4.wav");
	}else{
	}
}

void OnExit(MovementObject @mo) {
}