bool played;

void Reset() {
    played = false;
    if(params.HasParam("Start Disabled")){
        played = true;
    }
}

void Init() {
    Reset();
}

void SetParameters() {
    params.AddString("Dialogue", "Default text");
    params.AddIntCheckbox("Automatic", true);
    params.AddIntCheckbox("Visible in game", true);
}

void ReceiveMessage(string msg){
    if(msg == "player_pressed_attack"){
        TryToPlayDialogue();
    }
    if(msg == "reset"){
        Reset();
    }
    if(msg == "activate"){
        if(played){
            played = false;

            array<int> collides_with;
            level.GetCollidingObjects(hotspot.GetID(), collides_with);
            for(int i=0, len=collides_with.size(); i<len; ++i){
                int id = collides_with[i];
                if(ObjectExists(id) && ReadObjectFromID(id).GetType() == _movement_object){
                    MovementObject@ mo = ReadCharacterID(id);
                    if(mo.controlled && params.GetInt("Automatic") == 1){
                        TryToPlayDialogue();
                    }
                }
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

void TryToPlayDialogue() {
    if(!played){
        bool player_in_valid_state = false;
        for(int i=0, len=GetNumCharacters(); i<len; ++i){
            MovementObject@ mo = ReadCharacter(i);
            if(mo.controlled && mo.QueryIntFunction("int CanPlayDialogue()") == 1){
                player_in_valid_state = true;
            }
        }
        if(player_in_valid_state){
            level.SendMessage("start_dialogue \""+params.GetString("Dialogue")+"\"");
            played = true;
        }
    }
}

void OnEnter(MovementObject @mo) {
    if(mo.controlled && params.GetInt("Automatic") == 1){
        TryToPlayDialogue();
    }
}

void OnExit(MovementObject @mo) {
}

void Draw() {
    if(params.GetInt("Visible in game") == 1 || EditorModeActive()){
        Object@ obj = ReadObjectFromID(hotspot.GetID());
        DebugDrawBillboard("Data/UI/spawner/thumbs/Hotspot/sign_icon.png",
                           obj.GetTranslation() + obj.GetScale()[1] * vec3(0.0f,0.5f,0.0f),
                           2.0f,
                           vec4(1.0f),
                           _delete_on_draw);
    }
    if(!played && level.QueryIntFunction("int HasCameraControl()") == 0){
        if(params.HasParam("Exclamation Character")){
            int id = params.GetInt("Exclamation Character");
            if(ObjectExists(id) && ReadObjectFromID(id).GetType() == _movement_object){
                DebugDrawBillboard("Data/Textures/ui/stealth_debug/exclamation.tga",
                            ReadCharacterID(id).position + vec3(0.0, 1.6, 0.0),
                                1.0f,
                                vec4(vec3(1.0f), 1.0f),
                              _delete_on_draw);
            }
        }
        if(params.HasParam("Question Character")){
            int id = params.GetInt("Question Character");
            if(ObjectExists(id) && ReadObjectFromID(id).GetType() == _movement_object){
                vec3 offset;
                if(params.HasParam("Offset")){
                    offset = vec3(0.4, 0.0, -0.4);
                }
                DebugDrawBillboard("Data/Textures/ui/stealth_debug/question.tga",
                            ReadCharacterID(id).position + vec3(0, 1.6, 0) + offset,
                                1.0f,
                                vec4(vec3(1.0f), 1.0f),
                              _delete_on_draw);
            }
        }
    }
}


void PreDraw(float curr_game_time) {
    EnterTelemetryZone("Start_Dialogue hotspot update");
    if(!played){
        array<int> collides_with;
        level.GetCollidingObjects(hotspot.GetID(), collides_with);
        for(int i=0, len=collides_with.size(); i<len; ++i){
            int id = collides_with[i];
            if(ObjectExists(id) && ReadObjectFromID(id).GetType() == _movement_object){
                MovementObject@ mo = ReadCharacterID(id);
                if(mo.controlled){
                    mo.Execute("dialogue_request_time = time;");
                }
            }
        }        
    }
    LeaveTelemetryZone();
}