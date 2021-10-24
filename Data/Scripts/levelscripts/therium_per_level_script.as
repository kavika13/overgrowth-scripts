void ReceiveMessage(string message) {
    TokenIterator token_iter;
    token_iter.Init();

    if(!token_iter.FindNextToken(message)) {
        return;
    }

    string token = token_iter.GetToken(message);

	if(token == "achievement_event") {
        if(token_iter.FindNextToken(message)) {
            string achievement_type = token_iter.GetToken(message);

            if(achievement_type == "player_jumped") {
                for(int i = 0, len = GetNumHotspots(); i < len; i++) {
                    Hotspot@ hotspot = ReadHotspot(i);

                    if(hotspot.GetTypeString() == "therium2_player_jump_height") {
                        Object@ hotspot_obj = ReadObjectFromID(hotspot.GetID());
                        hotspot_obj.QueueScriptMessage("therium2_player_jumped");
                    }
                }
            }
        }
    }
}

void Init(string level_name) {  // Required
}

void Update(int paused) {  // Required
}

void DrawGUI() {  // Required
}

bool HasFocus() {  // Required
	return false;
}
