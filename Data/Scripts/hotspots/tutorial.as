void Init() {
}

void SetParameters() {
    params.AddString("Type", "Default text");
}

void SetEnabled(bool val){
    array<int> ids;
    level.GetCollidingObjects(hotspot.GetID(), ids);
    for(int i=0, len=ids.size(); i<len; ++i){
        int id = ids[i];
        if(ObjectExists(id)){
            Object@ obj = ReadObjectFromID(id);
            if(obj.GetType() == _movement_object){
                MovementObject@ mo = ReadCharacterID(id);
                if(mo.controlled){
                    if(val){
                        if( GetConfigValueBool("tutorials") ) {
                            mo.ReceiveMessage("tutorial "+params.GetString("Type")+" enter");
                        }
                    } else {
                        mo.ReceiveMessage("tutorial "+params.GetString("Type")+" exit");
                    }
                }
            }
        }
    }
}

void HandleEvent(string event, MovementObject @mo) {
    if( event == "enter" 
        || event == "exit" 
        || event == "disengaged_player_control"  
        || event == "engaged_player_control" ) 
    {
        if(mo.controlled && ReadObjectFromID(hotspot.GetID()).GetEnabled()){
            if(event == "enter" || event == "engaged_player_control"){
                SetEnabled(true);
            }
            if(event == "exit" || event == "disengaged_player_control"){
                mo.ReceiveMessage("tutorial "+params.GetString("Type")+" exit");
            }
        }
    }
}
