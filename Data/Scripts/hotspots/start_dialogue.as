bool played;
float visible_amount = 0.0;
float last_game_time = 0.0f;

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
    params.AddIntCheckbox("Fade", true);
    params.AddIntCheckbox("Visible in game", true);
    params.AddString("Color", "1.0 1.0 1.0");
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
            if(!params.HasParam("Fade") || params.GetInt("Fade") == 1){
                level.SendMessage("start_dialogue_fade \""+params.GetString("Dialogue")+"\"");
            } else {
                level.SendMessage("start_dialogue \""+params.GetString("Dialogue")+"\"");                
            }
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
    if(visible_amount > 0.0){
        vec3 color(1.0);
        if(params.HasParam("Color")){
            TokenIterator token_iter;
            token_iter.Init();
            string str = params.GetString("Color");
            token_iter.FindNextToken(str);
            color[0] = atof(token_iter.GetToken(str));
            if(token_iter.FindNextToken(str)){
                color[1] = atof(token_iter.GetToken(str));
                if(token_iter.FindNextToken(str)){
                    color[2] = atof(token_iter.GetToken(str));
                }
            }
        }
        vec3 offset;
        if(params.HasParam("Offset")){
            offset = vec3(0.4, 0.0, -0.4);
        }
        if(params.HasParam("Exclamation Character")){
            int id = params.GetInt("Exclamation Character");
            if(ObjectExists(id) && ReadObjectFromID(id).GetType() == _movement_object){
                DebugDrawBillboard("Data/Textures/ui/stealth_debug/exclamation_themed.png",
                            ReadCharacterID(id).position + vec3(0, 1.6 +sin(the_time*3.0)*0.03, 0) + offset,
                                1.0f+sin(the_time*3.0)*0.05,
                                vec4(color, visible_amount),
                              _delete_on_draw);
            }
        }
        if(params.HasParam("Question Character")){
            int id = params.GetInt("Question Character");
            if(ObjectExists(id) && ReadObjectFromID(id).GetType() == _movement_object){
                DebugDrawBillboard("Data/Textures/ui/stealth_debug/question_themed.png",
                            ReadCharacterID(id).position + vec3(0, 1.6 +sin(the_time*3.0)*0.03, 0) + offset,
                                1.0f+sin(the_time*3.0)*0.05,
                                vec4(color, visible_amount),
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

    if(params.HasParam("Exclamation Character") || params.HasParam("Question Character")){
        const float kFadeSpeed = 2.0;
        float offset = (curr_game_time-last_game_time) * kFadeSpeed;
        if(!played && level.QueryIntFunction("int HasCameraControl()") == 0){
            visible_amount = min(visible_amount+offset, 1.0);
        } else {
            visible_amount = max(visible_amount-offset, 0.0);
        }
    }

    last_game_time = curr_game_time;

    LeaveTelemetryZone();
}