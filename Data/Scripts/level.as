void Init() {
}

int controller_id = 0;
bool reset_allowed = true;
bool has_gui = false;
uint32 gui_id;
bool has_display_text = false;
uint32 display_text_id;
float time = 0.0f;
int score_left = 0;
int score_right = 0;

enum GameType {_normal, _versus};
GameType game_type = _normal;

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
    gui.Execute(gui_id, str);
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
            has_display_text = false;
        }
    }
}

void ReceiveMessage2(string msg, string msg2) {
    if(msg == "displaytext"){
       if(has_display_text){
            gui.RemoveGUI(display_text_id);
        }
        display_text_id = gui.AddGUI("text2","script_text.html",400,200, _GG_IGNORES_MOUSE);
        gui.Execute(display_text_id,"SetText(\""+msg2+"\")");
        has_display_text = true;
    } else if(msg == "loadlevel"){
        LoadLevel(msg2);
    } else if(msg == "displaygui"){
        gui_id = gui.AddGUI("displaygui_call",msg2,220,250,0);
        has_gui = true;
    }
}

class ScoreMark {
    bool mirrored;
    bool lit;
    int layer_id;
    int glow_layer_id;
    float scale_mult;
};
int top_crete_layer = -1;
int left_portrait_layer = -1;
int player_one_win_layer = -1;
int player_two_win_layer = -1;
int right_portrait_layer = -1;
int left_vignette_layer = -1;
int right_vignette_layer = -1;
float player_one_win_alpha = 0.0f;
float player_two_win_alpha = 0.0f;
int blackout_layer = -1;
int blackout_over_layer = -1;
array<ScoreMark> right_score_marks;
array<ScoreMark> left_score_marks;
float blackout_amount = 0.0f;
float score_change_time = 0.0f;

void UpdateVersusUI(){
    float ui_scale = GetScreenWidth() / 2560.0f;
    if(top_crete_layer == -1){
        top_crete_layer = hud.AddImage("Data/Textures/ui/versus_mode/top_crete.tga", vec3(0,0,0));
    }
    if(left_portrait_layer == -1){
        left_portrait_layer = hud.AddImage("Data/Textures/ui/versus_mode/rabbit_1_portrait.tga", vec3(0,0,0));
    }
    if(right_portrait_layer == -1){
        right_portrait_layer = hud.AddImage("Data/Textures/ui/versus_mode/rabbit_2_portrait.tga", vec3(0,0,0)); 
    }
    if(left_vignette_layer == -1){
        left_vignette_layer = hud.AddImage("Data/Textures/ui/versus_mode/corner_vignette.tga", vec3(0,0,0));
    }
    if(right_vignette_layer == -1){
        right_vignette_layer = hud.AddImage("Data/Textures/ui/versus_mode/corner_vignette.tga", vec3(0,0,0));
    }
    if(blackout_layer == -1){
        blackout_layer = hud.AddImage("Data/Textures/diffuse.tga", vec3(0,0,0));
    }
    if(blackout_over_layer == -1){
        blackout_over_layer = hud.AddImage("Data/Textures/diffuse.tga", vec3(0,0,0));
    }
    if(player_one_win_layer == -1){
        player_one_win_layer = hud.AddImage("Data/Textures/ui/versus_mode/rabbit_1_win.tga", vec3(0,0,0));
    }
    if(player_two_win_layer == -1){
        player_two_win_layer = hud.AddImage("Data/Textures/ui/versus_mode/rabbit_2_win.tga", vec3(0,0,0));
    }
    if(right_score_marks.size() == 0){
        right_score_marks.resize(5);
        for(int i=0; i<5; ++i){
            right_score_marks[i].layer_id = hud.AddImage("Data/Textures/ui/versus_mode/match_mark.tga", vec3(0,0,0));
            right_score_marks[i].glow_layer_id = hud.AddImage("Data/Textures/ui/versus_mode/match_win.tga", vec3(0,0,0));
            right_score_marks[i].mirrored = false;
            right_score_marks[i].lit = false;
            right_score_marks[i].scale_mult = 1.0f;
        }
    }
    if(left_score_marks.size() == 0){
        left_score_marks.resize(5);
        for(int i=0; i<5; ++i){
            left_score_marks[i].layer_id = hud.AddImage("Data/Textures/ui/versus_mode/match_mark.tga", vec3(0,0,0));
            left_score_marks[i].glow_layer_id = hud.AddImage("Data/Textures/ui/versus_mode/match_win.tga", vec3(0,0,0));
            left_score_marks[i].mirrored = true;
            left_score_marks[i].lit = false;
            left_score_marks[i].scale_mult = 1.0f;
        }
    }
    HUDImage @blackout_image = hud.GetImage(blackout_layer);
    blackout_image.position.y = 0;
    blackout_image.position.x = 0;
    blackout_image.position.z = -2.0f;
    blackout_image.scale = vec3(GetScreenWidth() + GetScreenHeight());
    blackout_image.color = vec4(0.0f,0.0f,0.0f,blackout_amount);
    if(GetInputPressed(0, "j")){
        IncrementScoreLeft();
    }
    HUDImage @blackout_over_image = hud.GetImage(blackout_over_layer);
    blackout_over_image.position.y = 0;
    blackout_over_image.position.x = 0;
    blackout_over_image.position.z = 2.0f;
    blackout_over_image.scale = vec3(GetScreenWidth() + GetScreenHeight());
    blackout_over_image.color = vec4(0.0f,0.0f,0.0f,max(player_one_win_alpha,player_two_win_alpha)*0.5f);
    HUDImage @player_one_win_image = hud.GetImage(player_one_win_layer);
    float player_one_scale = 1.5f + sin(player_one_win_alpha*1.570796f) * 0.2f;
    player_one_win_image.position.y = GetScreenHeight() * 0.5 - 512 * ui_scale * player_one_scale;
    player_one_win_image.position.x = GetScreenWidth() * 0.5 - 512 * ui_scale * player_one_scale;
    player_one_win_image.position.z = 3.0f;
    player_one_win_image.scale = vec3(ui_scale * player_one_scale);
    player_one_win_image.color.a = player_one_win_alpha;
    HUDImage @player_two_win_image = hud.GetImage(player_two_win_layer);
    float player_two_scale = 1.5f + sin(player_two_win_alpha*1.570796f) * 0.2f;
    player_two_win_image.position.y = GetScreenHeight() * 0.5 - 512 * ui_scale * player_two_scale;
    player_two_win_image.position.x = GetScreenWidth() * 0.5 - 512 * ui_scale * player_two_scale;
    player_two_win_image.position.z = 3.0f;
    player_two_win_image.scale = vec3(ui_scale * player_two_scale);
    player_two_win_image.color.a = player_two_win_alpha;
    HUDImage @left_portrait_image = hud.GetImage(left_portrait_layer);
    left_portrait_image.position.y = GetScreenHeight() - 512 * ui_scale * 0.6f;
    left_portrait_image.position.x = GetScreenWidth() * 0.5 - 850 * ui_scale;
    left_portrait_image.position.z = 1.0f;
    left_portrait_image.scale = vec3(ui_scale * 0.6f);
    HUDImage @right_portrait_image = hud.GetImage(right_portrait_layer);
    right_portrait_image.position.y = GetScreenHeight() - 512 * ui_scale * 0.6f;
    right_portrait_image.position.x = GetScreenWidth() * 0.5 + 530 * ui_scale;
    right_portrait_image.position.z = 1.0f;
    right_portrait_image.scale = vec3(ui_scale * 0.6f);
    HUDImage @left_vignette_image = hud.GetImage(left_vignette_layer);
    left_vignette_image.position.y = GetScreenHeight() - 256 * ui_scale * 2.0f;
    left_vignette_image.position.x = 0.0f;
    left_vignette_image.position.z = -1.0f;
    left_vignette_image.scale = vec3(ui_scale * 2.0f);
    HUDImage @right_vignette_image = hud.GetImage(right_vignette_layer);
    right_vignette_image.position.y = GetScreenHeight() - 256 * ui_scale * 2.0f;
    right_vignette_image.position.x = GetScreenWidth();
    right_vignette_image.position.z = -1.0f;
    right_vignette_image.scale = vec3(ui_scale * 2.0f);
    right_vignette_image.scale.x *= -1.0f;
    HUDImage @top_crete_image = hud.GetImage(top_crete_layer);
    top_crete_image.position.y = GetScreenHeight() - 256 * ui_scale;
    top_crete_image.position.x = GetScreenWidth() * 0.5 - 1024 * ui_scale;
    top_crete_image.scale = vec3(ui_scale);
    for(int i=0; i<5; ++i){
        if(right_score_marks[i].lit){
            right_score_marks[i].scale_mult = mix(1.0f, right_score_marks[i].scale_mult, 0.9f);
        } else {
            right_score_marks[i].scale_mult = mix(0.0f, right_score_marks[i].scale_mult, 0.9f);
        }
        float special_scale = 1.0f;
        HUDImage @hud_image = hud.GetImage(right_score_marks[i].layer_id);
        hud_image.position.y = GetScreenHeight() - (122 + 128 * special_scale) * ui_scale;
        hud_image.position.x = GetScreenWidth() * 0.5 + (498 - 128 * special_scale) * ui_scale - i * 90 * ui_scale;
        hud_image.scale = vec3(ui_scale * 0.6f * special_scale);
        special_scale = right_score_marks[i].scale_mult;
        HUDImage @glow_image = hud.GetImage(right_score_marks[i].glow_layer_id);
        glow_image.position.y = GetScreenHeight() - (122 + 128 * special_scale) * ui_scale;
        glow_image.position.z = 0.1f;
        glow_image.position.x = GetScreenWidth() * 0.5 + (498 - 128 * special_scale) * ui_scale - i * 90 * ui_scale;
        glow_image.scale = vec3(ui_scale * 0.6f * special_scale);
        glow_image.color.a = 1.0f - abs(special_scale - 1.0f);
    }
    for(int i=0; i<5; ++i){
        if(left_score_marks[i].lit){
            left_score_marks[i].scale_mult = mix(1.0f, left_score_marks[i].scale_mult, 0.9f);
        } else {
            left_score_marks[i].scale_mult = mix(0.0f, left_score_marks[i].scale_mult, 0.9f);
        }
        float special_scale = 1.0f;
        HUDImage @hud_image = hud.GetImage(left_score_marks[i].layer_id);
        hud_image.position.y = GetScreenHeight() - (122 + 128 * special_scale) * ui_scale;
        hud_image.position.x = GetScreenWidth() * 0.5 - (528 - 128 * special_scale) * ui_scale + i * 90 * ui_scale;
        hud_image.scale = vec3(ui_scale * 0.6f * special_scale);
        hud_image.scale.x *= -1.0f;
        special_scale = left_score_marks[i].scale_mult;
        HUDImage @glow_image = hud.GetImage(left_score_marks[i].glow_layer_id);
        glow_image.position.y = GetScreenHeight() - (122 + 128 * special_scale) * ui_scale;
        glow_image.position.z = 0.1f;
        glow_image.position.x = GetScreenWidth() * 0.5 - (528 - 128 * special_scale) * ui_scale + i * 90 * ui_scale;
        glow_image.scale = vec3(ui_scale * 0.6f * special_scale);
        glow_image.scale.x *= -1.0f;
        glow_image.color.a = 1.0f - abs(special_scale - 1.0f);
    }
}

void Update() {
    bool versus_mode = !GetSplitscreen() && GetNumCharacters() == 2 && ReadCharacter(0).controlled && ReadCharacter(1).controlled;
    if(versus_mode){
        game_type = _versus;
        UpdateVersusUI();
    } else {
        game_type = _normal;
    }
    
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
            if(callback == "settings"){
                gui.RemoveGUI(gui_id);
                gui_id = gui.AddGUI("gamemenu","settings\\settings.html",600,600,0);
                has_gui = true;
                break;
            }
            callback = gui.GetCallback(gui_id);
        }
    }
    if(!has_gui && GetInputDown(controller_id, "esc") && GetPlayerCharacterID() == -1){
        gui_id = gui.AddGUI("gamemenu","dialogs\\gamemenu.html",220,270,0);
        has_gui = true;
    }
    /*if(GetInputPressed("l")){
        //LoadLevel("Data/Levels/Project60/8_dead_volcano.xml");
    }*/
    if(GetInputPressed(controller_id, "l")){
        Reset();
        ClearVersusScores();
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
    if(game_type == _normal){
        VictoryCheckNormal();
        UpdateMusic();
    } else {
        VictoryCheckVersus();
        UpdateMusicVersus();
    }
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

void IncrementScoreLeft(){
    if(score_left < 5){
        left_score_marks[score_left].lit = true;
        left_score_marks[score_left].scale_mult = 2.0f;
    }
    if(score_left < 4){
        PlaySound("Data/Sounds/versus/fight_win.wav");
    }
    ++score_left;
}

void IncrementScoreRight() {
    if(score_right < 5){
        right_score_marks[score_right].lit = true;
        right_score_marks[score_right].scale_mult = 2.0f;
    }
    if(score_right < 4){
        PlaySound("Data/Sounds/versus/fight_win.wav");
    }
    ++score_right;
}

const float _reset_delay = 4.0f;
float reset_timer = _reset_delay;
float end_game_delay = 0.0f;
void VictoryCheckNormal() {
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
                    gui.Execute(gui_id,"SetText(\"You beat the level!\")");
                }
                if(failure){
                    gui.Execute(gui_id,"SetText(\"You were defeated.\")");
                }
                reset_allowed = false;
            }
            //Reset();
        }
    } else {
        reset_timer = _reset_delay;
    }
}

void ClearVersusScores(){
    score_left = 0;
    score_right = 0;
    for(int i=0; i<5; ++i){
        left_score_marks[i].lit = false;
        right_score_marks[i].lit = false;
    }                         
}

void VictoryCheckVersus() {
    int which_alive = -1;
    int num_alive = 0;
    int num = GetNumCharacters();
    for(int i=0; i<num; ++i){
        MovementObject@ char = ReadCharacter(i);
        if(char.IsKnockedOut() == _awake){
            which_alive = i;
            ++num_alive;
        }
    }
    const float _blackout_speed = 2.0f;
    if(num_alive <= 1){
        if(reset_timer <= 1.0f / _blackout_speed){
            blackout_amount = min(1.0f, blackout_amount + time_step * _blackout_speed);
        }
        if(end_game_delay == 0.0f){
            reset_timer -= time_step;
            if(reset_timer <= 0.0f){
                if(num_alive == 1){
                    MovementObject @char = ReadCharacter(which_alive);
                    int controller = char.controller_id;
                    //Print("Player "+(controller+1)+" wins!\n");
                    if(controller == 0){
                        IncrementScoreLeft();
                    } else {
                        IncrementScoreRight();
                    }
                    if(score_left >= 5 || score_right >= 5){
                        end_game_delay = 3.0f;
                        PlaySound("Data/Sounds/versus/fight_end.wav");
                    } else {                            
                        Reset();
                    }
                } else {        
                    PlaySound("Data/Sounds/versus/fight_lose.wav");              
                    Reset();
                }
            }
        }
    } else {
        blackout_amount = max(0.0f, blackout_amount - time_step * _blackout_speed);
        reset_timer = 2.0f;
    }
    if(end_game_delay != 0.0f){
        float old_end_game_delay = end_game_delay;
        end_game_delay = max(0.0f, end_game_delay - time_step);
        if(old_end_game_delay > 2.0f && end_game_delay <= 2.0f){
            if(score_left > score_right){
                PlaySound("Data/Sounds/versus/voice_end_1.wav");
            } else {
                PlaySound("Data/Sounds/versus/voice_end_2.wav");
            }
        }
        if(end_game_delay > 1.0f){
            if(score_left > score_right){
                player_one_win_alpha = min(1.0f, player_one_win_alpha + time_step);
            } else {
                player_two_win_alpha = min(1.0f, player_two_win_alpha + time_step);
            }
        } else {
            player_one_win_alpha = max(0.0f, player_one_win_alpha - time_step);
            player_two_win_alpha = max(0.0f, player_two_win_alpha - time_step);
        }
        if(end_game_delay == 0.0f){
            ClearVersusScores();
            Reset();
            PlaySound("Data/Sounds/versus/voice_start_1.wav");
        }
    } else {
        player_one_win_alpha = 0.0f;
        player_two_win_alpha = 0.0f;
    }
}


void UpdateMusic() {
    int player_id = GetPlayerCharacterID();
    if(player_id != -1 && ReadCharacter(player_id).QueryIntFunction("int IsKnockedOut()") != _awake){
        PlaySong("sad");
        return;
    }
    int threats_remaining = ThreatsRemaining();
    if(threats_remaining == 0){
        PlaySong("ambient-happy");
        return;
    }
    if(player_id != -1 && ReadCharacter(player_id).QueryIntFunction("int CombatSong()") == 1){
        PlaySong("combat");
        return;
    }
    PlaySong("ambient-tense");
}

float time_since_attack = 10.0f;

void UpdateMusicVersus() {
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