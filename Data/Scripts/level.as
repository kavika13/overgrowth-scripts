void init() {
}

int controller_id = 0;
bool reset_allowed = true;
bool has_gui = false;
uint32 gui_id;
bool has_display_text = false;
uint32 display_text_id;
float time = 0.0f;

void GUIDeleted(uint32 id){
    if(id == gui_id){
        has_gui = false;
    }
    if(id == display_text_id){
        has_display_text = false;
    }
}

void UpdateTimerDisplay() {
    string str;
    str += "SetTime(\"";
    int mins = int(time)/60;
    int secs = int(time)%60;
    str += mins + ":";
    if(secs<10){
        str += "0";
    }
    str += secs;
    str += "\")";
    gui.CallFunction(gui_id, str);
}

int HasFocus(){
    return has_gui?1:0;
}

void Reset(){
    time = 0.0f;
    reset_allowed = true;
    reset_timer = _reset_delay;
    ResetLevel();
}

void ReceiveMessage(string msg) {
    if(msg == "reset"){
        Reset();
    }
    if(msg == "cleartext"){
        if(has_display_text){
            gui.RemoveGUI(display_text_id);
        }
    }
}

void ReceiveMessage2(string msg, string msg2) {
    if(msg == "displaytext"){
       if(has_display_text){
            gui.RemoveGUI(display_text_id);
        }
        display_text_id = gui.AddGUI("text2","script_text.html",400,200, _GG_IGNORES_MOUSE);
        gui.CallFunction(display_text_id,"SetText(\""+msg2+"\")");
        has_display_text = true;
    }
}

void Update() {
    if(has_gui){
        SetGrabMouse(false);
        string callback = gui.GetCallback(gui_id);
        while(callback != ""){
            Print("AS Callback: "+callback+"\n");
            if(callback == "retry"){
                gui.RemoveGUI(gui_id);
                has_gui = false;
                Reset();
                break;
            }
            if(callback == "continue"){
                gui.RemoveGUI(gui_id);
                has_gui = false;
                break;
            }
            if(callback == "mainmenu"){
                gui.RemoveGUI(gui_id);
                has_gui = false;
                LoadLevel("mainmenu");
                break;
            }
            callback = gui.GetCallback(gui_id);
        }
    }
    if(!has_gui && GetInputDown(controller_id, "esc") && GetPlayerCharacterID() == -1){
        gui_id = gui.AddGUI("gamemenu","dialogs\\gamemenu.html",220,250,0);
        has_gui = true;
    }
    /*if(GetInputPressed("l")){
        //LoadLevel("Data/Levels/Project60/8_dead_volcano.xml");
    }*/
    if(GetInputPressed(controller_id, "l")){
        Reset();
        //LoadLevel("Data/Levels/Project60/8_dead_volcano.xml");
    }
    
    if(GetInputDown(controller_id, "x")){  
        int num_items = GetNumItems();
        for(int i=0; i<num_items; i++){
            ItemObject@ item_obj = ReadItem(i);
            item_obj.CleanBlood();
        }
    }
    
    time += time_step;

    SetAnimUpdateFreqs();
    VictoryCheck();
    UpdateMusic();
}

const float _max_anim_frames_per_second = 100.0f;

void SetAnimUpdateFreqs() {
    int num = GetNumCharacters();
    array<float> framerate_request(num);
    vec3 cam_pos = camera.GetPos();
    float total_framerate_request = 0.0f;
    for(int i=0; i<num; ++i){
        MovementObject@ char = ReadCharacter(i);
        if(char.controlled){
            continue;
        }
        float dist = distance(char.position, cam_pos);
        framerate_request[i] = 120.0f/max(4.0f,min(dist*0.5f,32.0f));
        total_framerate_request += framerate_request[i];
    }
    float scale = 1.0f;
    if(total_framerate_request > _max_anim_frames_per_second){
        scale *= _max_anim_frames_per_second/total_framerate_request;
    }
    for(int i=0; i<num; ++i){
        MovementObject@ char = ReadCharacter(i);
        if(char.controlled){
            continue;
        }
        int period = 120.0f/(framerate_request[i]*scale);
        if(char.QueryIntFunction("int GetTetherID()") != -1){
            char.SetAnimUpdatePeriod(2);
            char.SetScriptUpdatePeriod(2);
        } else {
            char.SetAnimUpdatePeriod(period);
            char.SetScriptUpdatePeriod(4);
        }
    }
}

const float _reset_delay = 4.0f;
float reset_timer = _reset_delay;
void VictoryCheck() {
    int player_id = GetPlayerCharacterID();
    if(player_id == -1){
        return;
    }
    bool victory = false;
    if(ThreatsRemaining() <= 0 && ThreatsPossible() > 0){
        victory = true;
    }
    bool failure = false;
    MovementObject@ player_char = ReadCharacter(player_id);
    if(player_char.IsKnockedOut() != _awake){
        failure = true;
    }
    if(victory || failure){
        reset_timer -= time_step;
        if(reset_timer <= 0.0f){
            if(reset_allowed && !has_gui){
                gui_id = gui.AddGUI("levelend","dialogs\\levelend.html",400,400,0);
                has_gui = true;
                UpdateTimerDisplay();
                if(victory){
                    gui.CallFunction(gui_id,"SetText(\"You beat the level!\")");
                }
                if(failure){
                    gui.CallFunction(gui_id,"SetText(\"You were defeated.\")");
                }
                reset_allowed = false;
            }
            //Reset();
        }
    } else {
        reset_timer = _reset_delay;
    }
}


void UpdateMusic() {
    int threats_remaining = ThreatsRemaining();
    if(threats_remaining == 0){
        PlaySong("ambient-happy");
        return;
    }
    //if(target_id != -1 && ReadCharacterID(target_id).IsKnockedOut() == _awake){
    //    PlaySong("combat");
    //    return;
    //}
    PlaySong("ambient-tense");
}

int GetPlayerCharacterID() {
    int num = GetNumCharacters();
    for(int i=0; i<num; ++i){
        MovementObject@ char = ReadCharacter(i);
        if(char.controlled){
            return i;
        }
    }
    return -1;
}

int ThreatsRemaining() {
    int player_id = GetPlayerCharacterID();
    if(player_id == -1){
        return -1;
    }
    MovementObject@ player_char = ReadCharacter(player_id);
    character_getter.Load(player_char.char_path);

    int num = GetNumCharacters();
    int num_threats = 0;
    for(int i=0; i<num; ++i){
        MovementObject@ char = ReadCharacter(i);
        vec3 target_pos = char.position;
        if(char.IsKnockedOut() == _awake &&
           character_getter.OnSameTeam(char.char_path) == 0)
        {
            ++num_threats;
        }
    }
    return num_threats;
}
   
int ThreatsPossible() {
    int player_id = GetPlayerCharacterID();
    if(player_id == -1){
        return -1;
    }
    MovementObject@ player_char = ReadCharacter(player_id);
    character_getter.Load(player_char.char_path);

    int num = GetNumCharacters();
    int num_threats = 0;
    for(int i=0; i<num; ++i){
        MovementObject@ char = ReadCharacter(i);
        vec3 target_pos = char.position;
        if(character_getter.OnSameTeam(char.char_path) == 0)
        {
            ++num_threats;
        }
    }
    return num_threats;
}

void HotspotEnter(string str, MovementObject @mo) {
    Print("Enter hotspot: "+str+"\n");
    if(str == "Stop"){
        Reset();
    }
}

void HotspotExit(string str, MovementObject @mo) {
    Print("Exit hotspot: "+str+"\n");
}