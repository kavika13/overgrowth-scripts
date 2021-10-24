bool played;

void Reset() {
    played = false;
}

void Init() {
    Reset();
	//vec3 end = char.rigged_object().GetAvgIKChainPos("torso");
}

void SetParameters() {
	params.AddIntCheckbox("Play Once", true);
	params.AddIntCheckbox("Play Only If Dead", false);
	params.AddIntCheckbox("Play for NPCs", false);
	
    params.AddString("Lethal Dialogue", "Default text");
    params.AddString("Medium Dialogue", "Default text");
    params.AddString("Non Lethal Dialogue", "Default text");
}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
        OnEnter(mo);
    } else if(event == "exit"){
        OnExit(mo);
    }
}

void OnEnter(MovementObject @mo) {
    if((mo.GetIntVar("knocked_out") > 0 || params.GetInt("Play Only If Dead") == 0)	//condition for "Play Only If Dead"
		&& (!played || params.GetInt("Play Once") == 0)								//condition for "Play once"
		&& (mo.controlled || params.GetInt("Play for NPCs") == 1)){					//condition for "Play for NPCs"
		
		int num_chars = GetNumCharacters();
		bool everyone_alive = true;
		bool everyone_dead = true;
		for(int i=0; i<num_chars; ++i){												//check all character if they are alive
            MovementObject @char = ReadCharacter(i);
			if(!char.controlled && !mo.OnSameTeam(char)){
				if(char.GetIntVar("knocked_out") == _dead){
					everyone_alive = false;
					Log(warning, "dude is dead");
				} else {
					everyone_dead = false;
					Log(warning, "dude is alive");
				}
			} else {
				Log(warning, "this is the player char");
			}
		}
		
		if(everyone_alive){															//branches for different lethal states
			Log(warning, "everyone's alive");
			level.SendMessage("start_dialogue \""+params.GetString("Non Lethal Dialogue")+"\"");
		} else if(everyone_dead){
			Log(warning, "everyone's dead");
			level.SendMessage("start_dialogue \""+params.GetString("Lethal Dialogue")+"\"");
		} else {
			Log(warning, "some survived");
			level.SendMessage("start_dialogue \""+params.GetString("Medium Dialogue")+"\"");
		}
        played = true;
    }
}

void OnExit(MovementObject @mo) {
}