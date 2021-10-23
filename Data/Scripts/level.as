int controller_id = 0;
bool reset_allowed = true;
bool has_gui = false;
uint32 gui_id;
bool has_display_text = false;
uint32 display_text_id;
float time = 0.0f;
float no_win_time = 0.0f;
int score_left = 0;
int score_right = 0;
string level_name;

void Init(string p_level_name) {
    level_name = p_level_name;
}

enum GameType {_normal, _versus};
GameType game_type = _normal;

class Achievements {
    bool flawless_;
    bool no_first_strikes_;
    bool no_counter_strikes_;
    bool no_kills_;
    bool no_alert_;
    bool injured_;
    float total_block_damage_;
    float total_damage_;
    float total_blood_loss_;
    void Init() {
        flawless_ = true;
        no_first_strikes_ = true;
        no_counter_strikes_ = true;
        no_kills_ = true;
        no_alert_ = true;
        injured_ = false;
        total_block_damage_ = 0.0f;
        total_damage_ = 0.0f;
        total_blood_loss_ = 0.0f;
    }
    Achievements() {
        Init();
    }
    void UpdateDebugText() {
        /*DebugText("achmt0", "Flawless: "+flawless_, 0.5f);
        DebugText("achmt1", "No Injuries: "+!injured_, 0.5f);
        DebugText("achmt2", "No First Strikes: "+no_first_strikes_, 0.5f);
        DebugText("achmt3", "No Counter Strikes: "+no_counter_strikes_, 0.5f);
        DebugText("achmt4", "No Kills: "+no_kills_, 0.5f);
        DebugText("achmt5", "No Alerts: "+no_alert_, 0.5f);
        DebugText("achmt6", "Time: "+no_win_time, 0.5f);
        //DebugText("achmt_damage0", "Block damage: "+total_block_damage_, 0.5f);
        //DebugText("achmt_damage1", "Impact damage: "+total_damage_, 0.5f);
        //DebugText("achmt_damage2", "Blood loss: "+total_blood_loss_, 0.5f);
        
        SavedLevel @level = save_file.GetSavedLevel(level_name);
        DebugText("saved_achmt0", "Saved Flawless: "+(level.GetValue("flawless")=="true"), 0.5f);
        DebugText("saved_achmt1", "Saved No Injuries: "+(level.GetValue("no_injuries")=="true"), 0.5f);
        DebugText("saved_achmt2", "Saved No Kills: "+(level.GetValue("no_kills")=="true"), 0.5f);
        DebugText("saved_achmt3", "Saved No Alert: "+(level.GetValue("no_alert")=="true"), 0.5f);
        DebugText("saved_achmt4", "Saved Time: "+level.GetValue("time"), 0.5f);*/
    }
    void Save() {
        SavedLevel @level = save_file.GetSavedLevel(level_name);
        if(flawless_) level.SetValue("flawless","true");
        if(!injured_) level.SetValue("no_injuries","true");
        if(no_kills_) level.SetValue("no_kills","true");
        if(no_alert_) level.SetValue("no_alert","true");
        string time_str = level.GetValue("time");
        if(time_str == "" || no_win_time < atof(level.GetValue("time"))){
            level.SetValue("time", ""+no_win_time);
        }
        save_file.WriteInPlace();
    }
    void PlayerWasHit() {
        flawless_ = false;
    }
    void PlayerWasInjured() {
        injured_ = true;
        flawless_ = false;
    }
    void PlayerAttacked() {
        no_first_strikes_ = false;
    }
    void PlayerSneakAttacked() {
        no_first_strikes_ = false;
    }
    void PlayerCounterAttacked() {
        no_counter_strikes_ = false;
    }
    void EnemyDied() {
        no_kills_ = false;
    }
    void EnemyAlerted() {
        no_alert_ = false;
    }
    void PlayerBlockDamage(float val) {
        total_block_damage_ += val;
        PlayerWasHit();
    }
    void PlayerDamage(float val) {
        total_damage_ += val;
        PlayerWasInjured();
    }
    void PlayerBloodLoss(float val) {
        total_blood_loss_ += val;
        PlayerWasInjured();
    }
};

Achievements achievements;

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
    achievements.Init();
    ResetLevel();
}

string hotspot_image_string;

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
	if(msg == "clearhud"){
	    hotspot_image_string.resize(0);
	}   
}

void DrawGUI() {
    if(hotspot_image_string.length() != 0){
        hud.AddImage(hotspot_image_string, vec3(700,200,0));   
    }
    if(game_type == _versus){
        versus_gui.DrawGUI();
    }
}

void AchievementEvent(string event_str){
    if(event_str == "player_was_hit"){
	    achievements.PlayerWasHit();
	}
	if(event_str == "player_was_injured"){
	    achievements.PlayerWasInjured();
	}
	if(event_str == "player_attacked"){
	    achievements.PlayerAttacked();
	}
	if(event_str == "player_sneak_attacked"){
	    achievements.PlayerSneakAttacked();
	}
	if(event_str == "player_counter_attacked"){
	    achievements.PlayerCounterAttacked();
	}
	if(event_str == "enemy_died"){
	    achievements.EnemyDied();
	}
	if(event_str == "enemy_alerted"){
	    achievements.EnemyAlerted();
	}
}

void AchievementEventFloat(string event_str, float val){
    if(event_str == "player_block_damage"){
	    achievements.PlayerBlockDamage(val);
	}
    if(event_str == "player_damage"){
	    achievements.PlayerDamage(val);
	}
    if(event_str == "player_blood_loss"){
	    achievements.PlayerBloodLoss(val);
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
    } else if(msg == "displayhud"){
		if(hotspot_image_string.length() == 0){
		    hotspot_image_string = msg2;
		}
    }
}

class VersusGUI_ScoreMark {
    bool mirrored;
    bool lit;
    float scale_mult;
};

class VersusGUI {
    float player_one_win_alpha;
    float player_two_win_alpha;
    array<VersusGUI_ScoreMark> right_score_marks;
    array<VersusGUI_ScoreMark> left_score_marks;
    float blackout_amount;
    float score_change_time;

    VersusGUI() {
        player_one_win_alpha = 0.0f;
        player_two_win_alpha = 0.0f;
        blackout_amount = 0.0f;
        score_change_time = 0.0f;
        
        right_score_marks.resize(5);
        for(int i=0; i<5; ++i){
            right_score_marks[i].mirrored = false;
            right_score_marks[i].lit = false;
            right_score_marks[i].scale_mult = 1.0f;
        }
        
        left_score_marks.resize(5);
        for(int i=0; i<5; ++i){
            left_score_marks[i].mirrored = true;
            left_score_marks[i].lit = false;
            left_score_marks[i].scale_mult = 1.0f;
        }
    }

    void Update(){
        for(int i=0; i<5; ++i){
            if(right_score_marks[i].lit){
                right_score_marks[i].scale_mult = mix(1.0f, right_score_marks[i].scale_mult, 0.9f);
            } else {
                right_score_marks[i].scale_mult = mix(0.0f, right_score_marks[i].scale_mult, 0.9f);
            }
        }
        for(int i=0; i<5; ++i){
            if(left_score_marks[i].lit){
                left_score_marks[i].scale_mult = mix(1.0f, left_score_marks[i].scale_mult, 0.9f);
            } else {
                left_score_marks[i].scale_mult = mix(0.0f, left_score_marks[i].scale_mult, 0.9f);
            }
        }
    }
    
    void DrawGUI(){
        float ui_scale = GetScreenWidth() / 2560.0f;
        
        HUDImage @top_crete_image = hud.AddImage("Data/Textures/ui/versus_mode/top_crete.tga", vec3(0,0,0));
        top_crete_image.position.y = GetScreenHeight() - 256 * ui_scale;
        top_crete_image.position.x = GetScreenWidth() * 0.5 - 1024 * ui_scale;
        top_crete_image.scale = vec3(ui_scale);
        
        HUDImage @left_portrait_image = hud.AddImage("Data/Textures/ui/versus_mode/rabbit_1_portrait.tga", vec3(0,0,0));
        left_portrait_image.position.y = GetScreenHeight() - 512 * ui_scale * 0.6f;
        left_portrait_image.position.x = GetScreenWidth() * 0.5 - 850 * ui_scale;
        left_portrait_image.position.z = 1.0f;
        left_portrait_image.scale = vec3(ui_scale * 0.6f);
        
        HUDImage @right_portrait_image = hud.AddImage("Data/Textures/ui/versus_mode/rabbit_2_portrait.tga", vec3(0,0,0));
        right_portrait_image.position.y = GetScreenHeight() - 512 * ui_scale * 0.6f;
        right_portrait_image.position.x = GetScreenWidth() * 0.5 + 530 * ui_scale;
        right_portrait_image.position.z = 1.0f;
        right_portrait_image.scale = vec3(ui_scale * 0.6f);
        
        HUDImage @left_vignette_image = hud.AddImage("Data/Textures/ui/versus_mode/corner_vignette.tga", vec3(0,0,0));
        left_vignette_image.position.y = GetScreenHeight() - 256 * ui_scale * 2.0f;
        left_vignette_image.position.x = 0.0f;
        left_vignette_image.position.z = -1.0f;
        left_vignette_image.scale = vec3(ui_scale * 2.0f);
        
        HUDImage @right_vignette_image = hud.AddImage("Data/Textures/ui/versus_mode/corner_vignette.tga", vec3(0,0,0));
        right_vignette_image.position.y = GetScreenHeight() - 256 * ui_scale * 2.0f;
        right_vignette_image.position.x = GetScreenWidth();
        right_vignette_image.position.z = -1.0f;
        right_vignette_image.scale = vec3(ui_scale * 2.0f);
        right_vignette_image.scale.x *= -1.0f;        
        
        HUDImage @blackout_image = hud.AddImage("Data/Textures/diffuse.tga", vec3(0,0,0));
        blackout_image.position.y = 0;
        blackout_image.position.x = 0;
        blackout_image.position.z = -2.0f;
        blackout_image.scale = vec3(GetScreenWidth() + GetScreenHeight());
        blackout_image.color = vec4(0.0f,0.0f,0.0f,blackout_amount);
        
        HUDImage @blackout_over_image = hud.AddImage("Data/Textures/diffuse.tga", vec3(0,0,0));
        blackout_over_image.position.y = 0;
        blackout_over_image.position.x = 0;
        blackout_over_image.position.z = 2.0f;
        blackout_over_image.scale = vec3(GetScreenWidth() + GetScreenHeight());
        blackout_over_image.color = vec4(0.0f,0.0f,0.0f,max(player_one_win_alpha,player_two_win_alpha)*0.5f);
        
        HUDImage @player_one_win_image = hud.AddImage("Data/Textures/ui/versus_mode/rabbit_1_win.tga", vec3(0,0,0));
        float player_one_scale = 1.5f + sin(player_one_win_alpha*1.570796f) * 0.2f;
        player_one_win_image.position.y = GetScreenHeight() * 0.5 - 512 * ui_scale * player_one_scale;
        player_one_win_image.position.x = GetScreenWidth() * 0.5 - 512 * ui_scale * player_one_scale;
        player_one_win_image.position.z = 3.0f;
        player_one_win_image.scale = vec3(ui_scale * player_one_scale);
        player_one_win_image.color.a = player_one_win_alpha;
        
        HUDImage @player_two_win_image = hud.AddImage("Data/Textures/ui/versus_mode/rabbit_2_win.tga", vec3(0,0,0));
        float player_two_scale = 1.5f + sin(player_two_win_alpha*1.570796f) * 0.2f;
        player_two_win_image.position.y = GetScreenHeight() * 0.5 - 512 * ui_scale * player_two_scale;
        player_two_win_image.position.x = GetScreenWidth() * 0.5 - 512 * ui_scale * player_two_scale;
        player_two_win_image.position.z = 3.0f;
        player_two_win_image.scale = vec3(ui_scale * player_two_scale);
        player_two_win_image.color.a = player_two_win_alpha;
        
        for(int i=0; i<5; ++i){
            float special_scale = 1.0f;
            HUDImage @hud_image = hud.AddImage("Data/Textures/ui/versus_mode/match_mark.tga", vec3(0,0,0));
            hud_image.position.y = GetScreenHeight() - (122 + 128 * special_scale) * ui_scale;
            hud_image.position.x = GetScreenWidth() * 0.5 + (498 - 128 * special_scale) * ui_scale - i * 90 * ui_scale;
            hud_image.scale = vec3(ui_scale * 0.6f * special_scale);
            special_scale = right_score_marks[i].scale_mult;
            HUDImage @glow_image = hud.AddImage("Data/Textures/ui/versus_mode/match_win.tga", vec3(0,0,0));
            glow_image.position.y = GetScreenHeight() - (122 + 128 * special_scale) * ui_scale;
            glow_image.position.z = 0.1f;
            glow_image.position.x = GetScreenWidth() * 0.5 + (498 - 128 * special_scale) * ui_scale - i * 90 * ui_scale;
            glow_image.scale = vec3(ui_scale * 0.6f * special_scale);
            glow_image.color.a = 1.0f - abs(special_scale - 1.0f);
        }
        for(int i=0; i<5; ++i){
            float special_scale = 1.0f;
            HUDImage @hud_image = hud.AddImage("Data/Textures/ui/versus_mode/match_mark.tga", vec3(0,0,0));
            hud_image.position.y = GetScreenHeight() - (122 + 128 * special_scale) * ui_scale;
            hud_image.position.x = GetScreenWidth() * 0.5 - (528 - 128 * special_scale) * ui_scale + i * 90 * ui_scale;
            hud_image.scale = vec3(ui_scale * 0.6f * special_scale);
            hud_image.scale.x *= -1.0f;
            special_scale = left_score_marks[i].scale_mult;
            HUDImage @glow_image = hud.AddImage("Data/Textures/ui/versus_mode/match_win.tga", vec3(0,0,0));
            glow_image.position.y = GetScreenHeight() - (122 + 128 * special_scale) * ui_scale;
            glow_image.position.z = 0.1f;
            glow_image.position.x = GetScreenWidth() * 0.5 - (528 - 128 * special_scale) * ui_scale + i * 90 * ui_scale;
            glow_image.scale = vec3(ui_scale * 0.6f * special_scale);
            glow_image.scale.x *= -1.0f;
            glow_image.color.a = 1.0f - abs(special_scale - 1.0f);
        }
    }
    
    void IncrementScoreLeft(int score){
        left_score_marks[score].lit = true;
        left_score_marks[score].scale_mult = 2.0f;
    }
    
    void IncrementScoreRight(int score){
        right_score_marks[score].lit = true;
        right_score_marks[score].scale_mult = 2.0f;
    }
    
    void ClearScores() {
        for(int i=0; i<5; ++i){
            left_score_marks[i].lit = false;
            right_score_marks[i].lit = false;
        }                 
    }
}

VersusGUI versus_gui;

void Update() {
    if(GetPlayerCharacterID() != -1){
        achievements.UpdateDebugText();
    }
    
    bool versus_mode = !GetSplitscreen() && GetNumCharacters() == 2 && ReadCharacter(0).controlled && ReadCharacter(1).controlled;
    if(versus_mode){
        game_type = _versus;
        versus_gui.Update();
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
        if(game_type == _versus){
            ClearVersusScores();
        }
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
        if(char.GetIntVar("tether_id") != -1){
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
        versus_gui.IncrementScoreLeft(score_left);
    }
    if(score_left < 4){
        PlaySoundGroup("Data/Sounds/versus/fight_win1.xml");
    }
    ++score_left;
}

void IncrementScoreRight() {
    if(score_right < 5){
        versus_gui.IncrementScoreRight(score_right);
    }
    if(score_right < 4){
        PlaySoundGroup("Data/Sounds/versus/fight_win2.xml");
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
    if(player_char.GetIntVar("knocked_out") != _awake){
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
            if(victory){
                achievements.Save();
            }
            //Reset();
        }
    } else {
        reset_timer = _reset_delay;
        no_win_time = time;
    }
}

void ClearVersusScores(){
    score_left = 0;
    score_right = 0;
    versus_gui.ClearScores();        
}

void VictoryCheckVersus() {
    int which_alive = -1;
    int num_alive = 0;
    int num = GetNumCharacters();
    for(int i=0; i<num; ++i){
        MovementObject@ char = ReadCharacter(i);
        if(char.GetIntVar("knocked_out") == _awake){
            which_alive = i;
            ++num_alive;
        }
    }
    const float _blackout_speed = 2.0f;
    if(num_alive <= 1){
        if(reset_timer <= 1.0f / _blackout_speed){
            versus_gui.blackout_amount = min(1.0f, versus_gui.blackout_amount + time_step * _blackout_speed);
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
                    PlaySoundGroup("Data/Sounds/versus/fight_lose1.xml");              
                    Reset();
                }
            }
        }
    } else {
        versus_gui.blackout_amount = max(0.0f, versus_gui.blackout_amount - time_step * _blackout_speed);
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
                versus_gui.player_one_win_alpha = min(1.0f, versus_gui.player_one_win_alpha + time_step);
            } else {
                versus_gui.player_two_win_alpha = min(1.0f, versus_gui.player_two_win_alpha + time_step);
            }
        } else {
            versus_gui.player_one_win_alpha = max(0.0f, versus_gui.player_one_win_alpha - time_step);
            versus_gui.player_two_win_alpha = max(0.0f, versus_gui.player_two_win_alpha - time_step);
        }
        if(end_game_delay == 0.0f){
            ClearVersusScores();
            Reset();
            PlaySound("Data/Sounds/versus/voice_start_1.wav");
        }
    } else {
        versus_gui.player_one_win_alpha = 0.0f;
        versus_gui.player_two_win_alpha = 0.0f;
    }
}


void UpdateMusic() {
    int player_id = GetPlayerCharacterID();
    if(player_id != -1 && ReadCharacter(player_id).GetIntVar("knocked_out") != _awake){
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

    int num = GetNumCharacters();
    int num_threats = 0;
    for(int i=0; i<num; ++i){
        MovementObject@ char = ReadCharacter(i);
        vec3 target_pos = char.position;
        if(char.GetIntVar("knocked_out") == _awake &&
           !player_char.OnSameTeam(char))
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
   
    int num = GetNumCharacters();
    int num_threats = 0;
    for(int i=0; i<num; ++i){
        MovementObject@ char = ReadCharacter(i);
        vec3 target_pos = char.position;
        if(!player_char.OnSameTeam(char))
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