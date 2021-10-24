bool played;

void Reset() {
    played = false;
}

void Init() {
    Reset();
}

void SetParameters() {
	params.AddIntCheckbox("Play Once", true);
    params.AddString("Dialogue", "Default text");
}

void Update() {
	bool hasAlive = false;
	bool hasDead = false;
    Object@ obj = ReadObjectFromID(hotspot.GetID());
    vec3 pos = obj.GetTranslation();
    vec3 scale = obj.GetScale();
	if(true){
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
				if(mo.GetIntVar("knocked_out") > 0){
					hasAlive = true;
				}else{
					hasDead = true;
				}
			}
		}
	}
	if(hasAlive && hasDead){
	    level.SendMessage("start_dialogue \""+params.GetString("Dialogue")+"\"");
	    played = true;
	}
}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
        OnEnter(mo);
    } else if(event == "exit"){
        OnExit(mo);
    }
}

void OnEnter(MovementObject @mo) {

}

void OnExit(MovementObject @mo) {
}