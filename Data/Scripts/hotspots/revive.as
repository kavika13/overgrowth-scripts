void Init() {
}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
        OnEnter(mo);
    } if(event == "exit"){
        //Print("Exited Revive\n");
    }
}

void OnEnter(MovementObject @mo) {
    //Print("Entered Revive\n");
	int num_chars = GetNumCharacters();
				for(int i=0; i<num_chars; ++i){
					MovementObject @char = ReadCharacter(i);
	char.Execute("RecoverHealth();cut_throat = false;lives = p_lives;ko_shield = max_ko_shield;");
	}
}