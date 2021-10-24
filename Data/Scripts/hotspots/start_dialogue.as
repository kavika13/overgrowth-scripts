bool played;

void Reset() {
    played = false;
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
}