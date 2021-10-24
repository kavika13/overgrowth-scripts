void Init() {
}

void SetParameters() {
    params.AddString("Type", "Default text");
}

void HandleEvent(string event, MovementObject @mo) {
    if( event == "enter" 
        || event == "exit" 
        || event == "disengaged_player_control"  
        || event == "engaged_player_control" ) 
    {
        if(mo.controlled){
            if(event == "enter" || event == "engaged_player_control"){
                mo.ReceiveMessage("tutorial "+params.GetString("Type")+" enter");
            }
            if(event == "exit" || event == "disengaged_player_control"){
                mo.ReceiveMessage("tutorial "+params.GetString("Type")+" exit");
            }
        }
    }
}
