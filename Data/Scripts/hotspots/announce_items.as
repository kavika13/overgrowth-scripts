array<int> contained_items;
void Init() {
}

void SetParameters() {
    params.AddString("Hotspot ID", "ID for the announcing hotspot");
}

void HandleEventItem( string event, ItemObject @obj ) {
    Log( info, "" + event + " occurred" );
    if( event == "enter" ) {
        bool has_id = false;
        for( uint i = 0; i < contained_items.length(); i++ ) {
            if( contained_items[i] == obj.GetID() ) {
                has_id = true; 
            }
        }
        if( has_id == false ) {
            contained_items.insertLast( obj.GetID() );
        }
    }

    if( event == "exit" ) {
        for( uint i = 0; i < contained_items.length(); i++ ) {
            if( contained_items[i] == obj.GetID() ) {
                contained_items.removeAt(i);
                i--;
            }
        }
    }

    if( event == "enter" || event == "exit" ) {
        level.SendMessage( "hotspot_announce_items " + params.GetString("Hotspot ID") + " " + event + " " + obj.GetID() );
        string message = "hotspot_announce_items " + params.GetString("Hotspot ID") + " inside_list";
        for( uint i = 0; i < contained_items.length(); i++ ) {
            message += " " + contained_items[i];
        }
        level.SendMessage( message );
    }
}

void OnEnter(MovementObject @mo) {
}
