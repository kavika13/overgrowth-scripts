void init() {
}

bool reset_allowed = true;
bool has_gui = false;
uint32 gui_id;
float time = 0.0f;

void GUIDeleted(uint32 id){
    if(id == gui_id){
        has_gui = false;
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

void Update() {
    gui.Update();
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
    if(!has_gui && GetInputDown("esc") && GetPlayerCharacterID() == -1){
        gui_id = gui.AddGUI("gamemenu","dialogs\\gamemenu.html",220,250);
        has_gui = true;
    }  /*
    if(GetInputPressed("l")){
        //LoadLevel("Data/Levels/Project60/8_dead_volcano.xml");
    }*/
    if(GetInputPressed("l")){
        Reset();
        //LoadLevel("Data/Levels/Project60/8_dead_volcano.xml");
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
        char.SetAnimUpdatePeriod(period);
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
                gui_id = gui.AddGUI("levelend","dialogs\\levelend.html",400,400);
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