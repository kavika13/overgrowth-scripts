bool played;

void Reset() {
    played = false;
}

void Init() {
    Reset();
}

void SetParameters() {
	params.AddIntCheckbox("Check every Frame", false);
	params.AddIntCheckbox("Play Once", true);
	params.AddIntCheckbox("Play only If dead", false);
	params.AddIntCheckbox("Play for npcs", false);
	params.AddIntCheckbox("Play for player", true);
    params.AddString("Dialogue", "Default text");
}

array<int> character_ids;
GetCharacters(character_ids);
for(uint i = 0;i < character_ids.size(); i++){
    Object@ char_obj = ReadObjectFromID(character_ids[i]);
    ScriptParams@ char_params = char_obj.GetScriptParams();
    if(char_params.HasParam("Teams")) {
        string team = char_params.GetString("Teams");
    }
}

void Update() {
    Object@ obj = ReadObjectFromID(hotspot.GetID());
    vec3 pos = obj.GetTranslation();
    vec3 scale = obj.GetScale();
	if(params.GetInt("Check every Frame") == 1){
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
    }
}

void OnEnter(MovementObject @mo) {
    if((mo.GetIntVar("knocked_out") > 0 || params.GetInt("Play only If dead") == 0)
		&& (!played || params.GetInt("Play Once") == 0)
		&&( (!mo.controlled && params.GetInt("Play for npcs") == 1)
		|| (mo.GetIntVar("team") == key))){
		
        level.SendMessage("start_dialogue \""+params.GetString("Dialogue")+"\"");
        played = true;
    }
}

void OnExit(MovementObject @mo) {
}