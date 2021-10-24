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
	params.AddIntCheckbox("Play If No Combat", true);
	
    params.AddString("Lethal Dialogue", "Default text");
    params.AddString("Medium Dialogue", "Default text");
    params.AddString("Non Lethal Dialogue", "Default text");
    params.AddString("Non Lethal Ghost Dialogue", "Default text");
}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
        OnEnter(mo);
    } else if(event == "exit"){
        OnExit(mo);
    }
}

void OnEnter(MovementObject @mo) {
	if(mo.controlled || params.GetInt("Play for NPCs") == 1)													//condition for "Play for NPCs"
    if((mo.GetIntVar("knocked_out") > 0 || params.GetInt("Play Only If Dead") == 0)								//condition for "Play Only If Dead"
		&& (!played || params.GetInt("Play Once") == 0)															//condition for "Play once"
		&& (mo.QueryIntFunction("int CombatSong()") == 0) || params.GetInt("Play If No Combat") == 0){			//condition for No Combat
		
		int num_chars = GetNumCharacters();
		bool everyone_alive = true;
		bool everyone_awake = true;
		bool everyone_dead = true;
		for(int i=0; i<num_chars; ++i){												//check all character if they are alive
            MovementObject @char = ReadCharacter(i);
			if(!char.controlled && !mo.OnSameTeam(char)){
				if(char.GetIntVar("knocked_out") > 0){
					everyone_awake = false;
					Log(warning, "dude is ko");
				} else {
					everyone_dead = false;
					Log(warning, "dude is conscious");
				}
			}
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


		if(everyone_awake){															//branches for different security states
			Log(warning, "everyone's awake");
			level.SendMessage("start_dialogue \""+params.GetString("Non Lethal Ghost Dialogue")+"\"");	
		} else if(everyone_alive){															//branches for different lethal states
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