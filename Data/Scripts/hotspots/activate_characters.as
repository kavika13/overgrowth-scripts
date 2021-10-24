void SetParameters() {
	params.AddString("characters", "");
}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
        OnEnter(mo);
    }
}


void OnEnter(MovementObject @mo) {
    if(mo.controlled && params.HasParam("characters")){
        TokenIterator token_iter;
        token_iter.Init();
        string str = params.GetString("characters");
        while(token_iter.FindNextToken(str)){
            int id = atoi(token_iter.GetToken(str));
            if(ObjectExists(id) && ReadObjectFromID(id).GetType() == _movement_object){
                ReadCharacterID(id).Execute("static_char = false;");
            }
        }    

        if(params.HasParam("music_layer_override")){
            int override = params.GetInt("music_layer_override");
            level.SendMessage("music_layer_override "+override);
        }
    }
}
