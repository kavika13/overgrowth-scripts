void Init() {
}

void SetParameters() {
    params.AddString("Display Text", "Default text");
}

void HandleEvent(string event, MovementObject @mo) {
    if( event == "enter" 
        || event == "exit" 
        || event == "disengaged_player_control"  
        || event == "engaged_player_control" ) {

        array<int> collides_with;
        level.GetCollidingObjects(hotspot.GetID(), collides_with);

        Log( info, event );

        bool show_text = false;
        for( uint i = 0; i < collides_with.length(); i++ ) {
            if( ObjectExists(collides_with[i]) ) {
                Object@ obj =  ReadObjectFromID(collides_with[i]);
                if(obj !is null) {
                    if( obj.GetType() == _movement_object ) {
                        MovementObject @mo1 = ReadCharacterID(collides_with[i]);
                        if( mo1.controlled ) {
                            show_text = true;
                        }
                    }
                }
            }
        }

        //In the case where the player is exiting the hotspot,
        //it's not safe to call params.GetString for some reason.
        //Therefore we add this extra sanity check.
        bool safe_to_create_text = false;
        if( event != "exit" ) {
            safe_to_create_text = true; 
        }

        if(show_text && safe_to_create_text) {
            Log( info, params.GetString("Display Text"));
            level.SendMessage("displaytext \""+params.GetString("Display Text")+"\"");
        } else {
            level.SendMessage("cleartext");
        }
    }
}
