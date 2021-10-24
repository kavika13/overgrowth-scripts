#include "threatcheck.as"

int progress = 0;
bool queued_goal_check = true;

float blackout_amount = 0.0;
float ko_time = -1.0;
float win_time = -1.0;
int win_target = 0;
bool sent_level_complete_message = false;
int curr_music_layer = 0;
float music_sting_end = 0.0;
const bool kDebugText = true;
int sting_handle = -1;

string music_prefix;
string success_sting = "Data/Music/slaver_loop/the_slavers_success.wav";
string defeat_sting = "Data/Music/slaver_loop/the_slavers_defeat.wav";

// Audience info
float audience_excitement;
float total_excitement;
int audience_size;
int audience_sound_handle;
float crowd_cheer_amount;
float crowd_cheer_vel;
float boo_amount = 0.0;

void SetParameters() {
    params.AddString("music", "slaver");
    params.AddString("player_spawn", "");
    if(params.GetString("music") == "slaver"){
        AddMusic("Data/Music/slaver_loop/layers.xml");
        PlaySong("slavers1");
        music_prefix = "slavers_";
        success_sting = "Data/Music/slaver_loop/the_slavers_success.wav";
        defeat_sting = "Data/Music/slaver_loop/the_slavers_defeat.wav";
    } else if(params.GetString("music") == "swamp"){
        AddMusic("Data/Music/swamp_loop/swamp_layer.xml");
        PlaySong("swamp1");
        music_prefix = "swamp_";
        success_sting = "Data/Music/swamp_loop/swamp_success.wav";
        defeat_sting = "Data/Music/swamp_loop/swamp_defeat.wav";
    } else if(params.GetString("music") == "cats"){
        AddMusic("Data/Music/cats_loop/layers.xml");
        PlaySong("cats1");
        music_prefix = "cats_";
        success_sting = "Data/Music/cats_loop/cats_success.wav";
        defeat_sting = "Data/Music/cats_loop/cats_defeat.wav";
    } else if(params.GetString("music") == "crete"){
        AddMusic("Data/Music/crete_loop/layers.xml");
        PlaySong("crete1");
        music_prefix = "crete_";
        success_sting = "Data/Music/crete_loop/crete_success.wav";
        defeat_sting = "Data/Music/crete_loop/crete_defeat.wav";
    } else if(params.GetString("music") == "rescue"){
        AddMusic("Data/Music/rescue_loop/layers.xml");
        PlaySong("rescue1");
        music_prefix = "rescue_";
        success_sting = "Data/Music/rescue_loop/rescue_success.wav";
        defeat_sting = "Data/Music/rescue_loop/rescue_defeat.wav";
    } else if(params.GetString("music") == "arena"){
        AddMusic("Data/Music/SubArena/layers.xml");
        PlaySong("sub_arena");
        music_prefix = "arena_";
        success_sting = "Data/Sounds/versus/fight_win1_1.wav";
        defeat_sting = "Data/Sounds/versus/fight_lose1_1.wav";
    } else {
        params.SetString("music", "slaver");
        SetParameters();
    }
}

void Init() {
    save_file.WriteInPlace();
    curr_music_layer = 0;
    level.ReceiveLevelEvents(hotspot.GetID());
    hotspot.SetCollisionEnabled(false);
    audience_sound_handle = -1;
}

void Dispose() {
    level.StopReceivingLevelEvents(hotspot.GetID());
}

enum GoalTriggerType {_sting_only, _all_but_sting};

void TriggerGoalString(const string &in goal_str, GoalTriggerType type){
    Log(info, "Triggering goal string: "+goal_str);
    TokenIterator token_iter;
    token_iter.Init();
    while(token_iter.FindNextToken(goal_str)){
        if(token_iter.GetToken(goal_str) == "dialogue" && !EditorModeActive()){
            if(token_iter.FindNextToken(goal_str) && type == _all_but_sting){
                level.SendMessage("start_dialogue \""+token_iter.GetToken(goal_str)+"\"");
            }
        }
        if(token_iter.GetToken(goal_str) == "dialogue_fade" && !EditorModeActive()){
            if(token_iter.FindNextToken(goal_str) && type == _all_but_sting){
                level.SendMessage("start_dialogue_fade \""+token_iter.GetToken(goal_str)+"\"");
            }
        }
        if(token_iter.GetToken(goal_str) == "dialogue_fade_if_not_hostile" && !EditorModeActive()){
            if(token_iter.FindNextToken(goal_str) && type == _all_but_sting){
                int player_id = GetPlayerCharacterID();
                if(player_id != -1 && ReadCharacter(player_id).QueryIntFunction("int CombatSong()") != 1){
                    level.SendMessage("start_dialogue_fade \""+token_iter.GetToken(goal_str)+"\"");
                }
            }
        }
        if(token_iter.GetToken(goal_str) == "activate" && !EditorModeActive()){
            if(token_iter.FindNextToken(goal_str) && type == _all_but_sting){
                int id = atoi(token_iter.GetToken(goal_str));
                if(ObjectExists(id) && ReadObjectFromID(id).GetType() == _movement_object){
                    ReadCharacterID(id).Execute("this_mo.static_char = false;");
                }
                if(ObjectExists(id) && ReadObjectFromID(id).GetType() == _hotspot_object){
                    ReadObjectFromID(id).ReceiveScriptMessage("activate");
                }
            }
        }
        if(token_iter.GetToken(goal_str) == "disable" && !EditorModeActive()){
            if(token_iter.FindNextToken(goal_str) && type == _all_but_sting){
                int id = atoi(token_iter.GetToken(goal_str));
                if(ObjectExists(id)){
                    Print("Disabling object "+id+"\n");
                    ReadObjectFromID(id).SetEnabled(false);
                }
            }
        }
        if(token_iter.GetToken(goal_str) == "enable" && !EditorModeActive()){
            if(token_iter.FindNextToken(goal_str) && type == _all_but_sting){
                int id = atoi(token_iter.GetToken(goal_str));
                if(ObjectExists(id)){
                    ReadObjectFromID(id).SetEnabled(true);
                }
            }
        }
        if(token_iter.GetToken(goal_str) == "music_layer_override" && !EditorModeActive()){
            if(token_iter.FindNextToken(goal_str) && type == _all_but_sting){
                int id = atoi(token_iter.GetToken(goal_str));
                music_layer_override = id;
            }
        }
        if(token_iter.GetToken(goal_str) == "play_success_sting" && !EditorModeActive()){
            if(type == _sting_only){
                PlaySuccessSting();
            }
        }
    }    
}

void TriggerGoalPre() {
    if(params.HasParam("goal_"+progress+"_pre")){
        Log(info, "Triggering "+"goal_"+progress+"_pre");
        TriggerGoalString(params.GetString("goal_"+progress+"_pre"), _all_but_sting);
    }
}

void TriggerGoalPost(GoalTriggerType type) {
    if(params.HasParam("goal_"+progress+"_post")){
        Log(info, "Triggering "+"goal_"+progress+"_post");
        TriggerGoalString(params.GetString("goal_"+progress+"_post"), type);
    }
}

void PlaySuccessSting() {
    if(sting_handle != -1){
        StopSound(sting_handle);
        sting_handle = -1;
    }
    sting_handle = PlaySound(success_sting);
    SetSoundGain(sting_handle, GetConfigValueFloat("music_volume"));
    music_sting_end = the_time + 5.0;
    SetLayerGain(music_prefix+"layer_"+curr_music_layer, 0.0);
}

void PlayDeathSting() {
    if(sting_handle != -1){
        StopSound(sting_handle);
        sting_handle = -1;
    }
    sting_handle = PlaySound(defeat_sting);
    SetSoundGain(sting_handle, GetConfigValueFloat("music_volume"));
    music_sting_end = the_time + 5.0;
    SetLayerGain(music_prefix+"layer_"+curr_music_layer, 0.0);    
}

void IncrementProgress() {
    EnterTelemetryZone("IncrementProgress()");
    Log(info, "IncrementProgress: "+progress+" to "+(progress+1));
    TriggerGoalPost(_all_but_sting);
    ++progress;
    win_time = -1.0;

    TriggerGoalPre();

    if(params.HasParam("goal_"+progress)){
        string goal_str = params.GetString("goal_"+progress);
        TokenIterator token_iter;
        token_iter.Init();
        if(token_iter.FindNextToken(goal_str)){
            if(token_iter.GetToken(goal_str) == "spawn_defeat"){
                while(token_iter.FindNextToken(goal_str)){
                     string token = token_iter.GetToken(goal_str);
                    if(token == "no_delay"){
                    } else {
                        int id = atoi(token_iter.GetToken(goal_str));
                        if(ObjectExists(id) && ReadObjectFromID(id).GetType() == _movement_object){
                            SetEnabledCharacterAndItems(id, true);
                        }
                    }
                }
            }
        }
    }

    // Place player character at correct spawn point
    int player_id = GetPlayerCharacterID();
    if(player_id != -1){
        EnterTelemetryZone("Restore player health");
        MovementObject@ mo = ReadCharacter(player_id);
        mo.ReceiveScriptMessage("restore_health");
        LeaveTelemetryZone();
    }
    LeaveTelemetryZone();

    // Check if enemies are already defeated
     if(win_time == -1.0){
        PossibleWinEvent("character_defeated", -1, progress);
    }
}

void SetEnabledCharacterAndItems(int id, bool enabled){
    ReadObjectFromID(id).SetEnabled(enabled);
    MovementObject@ char = ReadCharacterID(id);
    for(int item_index=0; item_index<6; ++item_index){
        int item_id = char.GetArrayIntVar("weapon_slots",item_index);
        if(item_id != -1 && ObjectExists(item_id)){
            ReadObjectFromID(item_id).SetEnabled(enabled);                                    
        }
    }
}

void CheckReset() {
    EnterTelemetryZone("CheckReset()");
    // Count valid player spawn points, and set their preview viz
    TokenIterator token_iter;
    int num_player_spawn = 0;
    if(params.HasParam("player_spawn")){
        string param_str = params.GetString("player_spawn");
        token_iter.Init();
        while(token_iter.FindNextToken(param_str)){
            int id = atoi(token_iter.GetToken(param_str));
            if(ObjectExists(id)){
                Object@ obj = ReadObjectFromID(id);
                if(obj.GetType() == _placeholder_object){
                    PlaceholderObject@ placeholder_object = cast<PlaceholderObject@>(obj);
                    placeholder_object.SetPreview("Data/Objects/IGF_Characters/pale_turner.xml");
                    ++num_player_spawn;
                }
            }
        }
    }

    // Cannot respawn at progress points with no spawn point
    if(progress > num_player_spawn){
        progress = num_player_spawn;
    }

    // Re-enable all characters
    int num_characters = GetNumCharacters();
    for(int i=0; i<num_characters; ++i){
        SetEnabledCharacterAndItems(ReadCharacter(i).GetID(), true);
    }

    // Disable all defeated characters
    for(int i=0; i<progress; ++i){
        Log(info, "Iterating through completed goal: "+i);
        if(params.HasParam("goal_"+i)){
            string goal_str = params.GetString("goal_"+i);
            token_iter.Init();
            if(token_iter.FindNextToken(goal_str)){
                if(token_iter.GetToken(goal_str) == "defeat" || token_iter.GetToken(goal_str) == "spawn_defeat" || token_iter.GetToken(goal_str) == "defeat_optional"){
                    while(token_iter.FindNextToken(goal_str) && token_iter.GetToken(goal_str) != ""){
                        string token = token_iter.GetToken(goal_str);
                        if(token == "no_delay"){
                        } else {
                            int id = atoi(token_iter.GetToken(goal_str));
                            if(ObjectExists(id) && ReadObjectFromID(id).GetType() == _movement_object){
                                SetEnabledCharacterAndItems(id, false);
                            }
                        }
                    }
                }
            }
        }
    }

    // Disable all characters that have not been spawned yet
    for(int i=progress+1; params.HasParam("goal_"+i); ++i){
        Log(info, "Iterating through future goals: "+i);
        if(params.HasParam("goal_"+i)){
            string goal_str = params.GetString("goal_"+i);
            Log(info, "Goal_str: "+goal_str);
            token_iter.Init();
            if(token_iter.FindNextToken(goal_str)){
                if(token_iter.GetToken(goal_str) == "spawn_defeat"){
                    while(token_iter.FindNextToken(goal_str)){
                         string token = token_iter.GetToken(goal_str);
                        if(token == "no_delay"){
                        } else {
                            int id = atoi(token_iter.GetToken(goal_str));
                            if(ObjectExists(id) && ReadObjectFromID(id).GetType() == _movement_object){
                                Log(info, "Disabling: "+id);
                                SetEnabledCharacterAndItems(id, false);
                            }
                        }
                    }
                }
            }
        }
    }

    // Place player character at correct spawn point
    int player_id = GetPlayerCharacterID();
    if(player_id != -1){
        MovementObject@ mo = ReadCharacter(player_id);
        if(progress == 0){ // Spawn at actual initial player spawn point
            Object@ obj = ReadObjectFromID(mo.GetID());
            mo.position = obj.GetTranslation();
            mo.SetRotationFromFacing(obj.GetRotation() * vec3(0,0,1));
        } else { // Spawn at a custom spawn point
            string param_str = params.GetString("player_spawn");
            token_iter.Init();
            for(int i=0; i<progress; ++i){
                token_iter.FindNextToken(param_str);
            }
            int id = atoi(token_iter.GetToken(param_str));
            if(ObjectExists(id)){
                Object@ obj = ReadObjectFromID(id);
                if(obj.GetType() == _placeholder_object){
                    mo.position = obj.GetTranslation();
                    mo.SetRotationFromFacing(obj.GetRotation() * vec3(0,0,1));
                    mo.Execute("SetCameraFromFacing(); SetOnGround(true); FixDiscontinuity();");
                }
            }
        }
    }

    // Trigger whatever happens at the start of this goal
    TriggerGoalPre();
    LeaveTelemetryZone();
}


void PossibleWinEvent(const string &in event, int val, int goal_check, int recursion = 0){
    if(ko_time != -1.0){
        return;
    }
    Log(info, "PossibleWinEvent("+event+", "+val+", "+goal_check+", " + recursion + ")");
    if( recursion > 5000 ) {
        Log( error, "we have recursed over 5000 times, will break" );
        return;
    }
    if(event == "checkpoint"){
        Log(info, "Player entered checkpoint: "+val);
        if(params.HasParam("goal_"+goal_check)){
            string goal_str = params.GetString("goal_"+goal_check);
            Log(info, "Looking at goal: "+goal_str);
            TokenIterator token_iter;
            token_iter.Init();
            if(token_iter.FindNextToken(goal_str)){
                string goal_type = token_iter.GetToken(goal_str);
                Log(info, "goal_type: "+goal_type);
                if(goal_type == "reach" || goal_type == "reach_skippable"){
                    if(token_iter.FindNextToken(goal_str)){
                        int id = atoi(token_iter.GetToken(goal_str));
                        Log(info, "id: "+id);
                        if(id == val){
                            win_time = the_time + 1.0;
                            TriggerGoalPost(_sting_only);
                            win_target = goal_check+1;
                        } else if(goal_type == "reach_skippable") {
                            Log(info, "Checking next");
                            PossibleWinEvent(event, val, goal_check+1, recursion+1);
                        }
                    }
                }
                if(goal_type == "defeat_optional"){
                    PossibleWinEvent(event, val, goal_check+1,recursion+1);
                }
            }
        }
    } else if(event == "character_defeated"){
        Log(info, "Character defeated, checking goal");
        if(params.HasParam("goal_"+goal_check)){
            string goal_str = params.GetString("goal_"+goal_check);
            Log(info, "Goal_str: "+goal_str);
            TokenIterator token_iter;
            token_iter.Init();
            if(token_iter.FindNextToken(goal_str)){
                string goal_type = token_iter.GetToken(goal_str);
                if(goal_type == "defeat" || goal_type == "spawn_defeat" || goal_type == "defeat_optional"){
                    Log(info, "Checking defeat conditions");
                    bool success = true;
                    bool no_delay = false;
                    while(token_iter.FindNextToken(goal_str) && token_iter.GetToken(goal_str) != ""){
                        string token = token_iter.GetToken(goal_str);
                        if(token == "no_delay"){
                            no_delay = true;
                        } else {
                            Log(info, "Looking at token \""+token_iter.GetToken(goal_str)+"\"");
                            int id = atoi(token_iter.GetToken(goal_str));
                            if(ObjectExists(id) && ReadObjectFromID(id).GetType() == _movement_object && ReadCharacterID(id).GetIntVar("knocked_out") == _awake){
                                success = false;
                                Log(info, "Conditions failed, "+id+" is awake");
                            }
                        }
                    }
                    if(success){
                        int player_id = GetPlayerCharacterID();
                        if(player_id != -1){
                            EnterTelemetryZone("Restore player health");
                            MovementObject@ mo = ReadCharacter(player_id);
                            mo.QueueScriptMessage("restore_health");
                            LeaveTelemetryZone();
                        }
                        if(no_delay) {
                            win_time = the_time + 2.0;
                        } else {
                            win_time = the_time + 5.0;
                        }
                        TriggerGoalPost(_sting_only);
                        win_target = goal_check+1;
                    } else if(goal_type == "defeat_optional") {
                            Log(info, "Checking next");
                            PossibleWinEvent(event, val, goal_check+1,recursion+1);
                        }
                }
                if(goal_type == "reach_skippable"){
                    PossibleWinEvent(event, val, goal_check+1,recursion+1);
                }
            }
        }
    }
}

enum MessageParseType {
    kSimple = 0,
    kOneInt = 1,
    kTwoInt = 2
}

int music_layer_override = -1;
bool crowd_override = false;
float crowd_gain_override;
float crowd_pitch_override;
array<float> dof_params;

void ReceiveMessage(string msg) {
    TokenIterator token_iter;
    token_iter.Init();
    if(!token_iter.FindNextToken(msg)){
        return;
    }

    string msg_start = token_iter.GetToken(msg);
    if(msg_start == "reset"){
        queued_goal_check = true;
        ko_time = -1.0;
        win_time = -1.0;
        music_layer_override = -1;
    }

    if(msg_start == "level_event" &&
       token_iter.FindNextToken(msg))
    {
        string sub_msg = token_iter.GetToken(msg);
        if(sub_msg == "music_layer_override"){
            if(token_iter.FindNextToken(msg)){
                Log(info, "Set music_layer_override to "+atoi(token_iter.GetToken(msg)));
                music_layer_override = atoi(token_iter.GetToken(msg));
            }
        } else if(sub_msg == "crowd_override"){
            crowd_override = false;
            if(token_iter.FindNextToken(msg)){
                crowd_gain_override = atof(token_iter.GetToken(msg));
                if(token_iter.FindNextToken(msg)){
                    crowd_override = true;
                    crowd_pitch_override = atof(token_iter.GetToken(msg));
                }
            }
        } else if(sub_msg == "set_camera_dof"){
            dof_params.resize(0);
            while(token_iter.FindNextToken(msg)){
                dof_params.push_back(atof(token_iter.GetToken(msg)));
            }
            if(dof_params.size() == 6){
                camera.SetDOF(dof_params[0], dof_params[1], dof_params[2], dof_params[3], dof_params[4], dof_params[5]);
            }
        } else if(sub_msg == "character_knocked_out" || sub_msg == "character_died") {
             if(win_time == -1.0){
                PossibleWinEvent("character_defeated", -1, progress);
            }
        }
    }


    // Handle simple tokens, or mark as requiring extra parameters
    MessageParseType type = kSimple;
    string token = token_iter.GetToken(msg);
   if(token == "knocked_over" ||
              token == "passive_blocked" ||
              token == "active_blocked" ||
              token == "dodged" ||
              token == "character_attack_feint" ||
              token == "character_attack_missed" ||
              token == "character_throw_escape" ||
              token == "character_thrown" ||
              token == "cut")
    {
        type = kTwoInt;
    } else if(token == "character_died" ||
              token == "character_knocked_out" ||
              token == "character_start_flip" ||
              token == "character_start_roll" ||
              token == "character_failed_flip"||
              token == "item_hit")
    {
        type = kOneInt;
    }

    if(type == kOneInt){
        token_iter.FindNextToken(msg);
        int char_a = atoi(token_iter.GetToken(msg));
        if(token == "character_died"){
            Log(info, "Player "+char_a+" was killed");
            audience_excitement += 4.0f;
        } else if(token == "character_knocked_out"){
            Log(info, "Player "+char_a+" was knocked out");
            audience_excitement += 3.0f;
        } else if(token == "character_start_flip"){
            Log(info, "Player "+char_a+" started a flip");
            audience_excitement += 0.4f;
        } else if(token == "character_start_roll"){
            Log(info, "Player "+char_a+" started a roll");
            audience_excitement += 0.4f;
        } else if(token == "character_failed_flip"){
            Log(info, "Player "+char_a+" failed a flip");
            audience_excitement += 1.0f;
        } else if(token == "item_hit"){
            Log(info, "Player "+char_a+" was hit by an item");
            audience_excitement += 1.5f;
        }
    } else if(type == kTwoInt){
        token_iter.FindNextToken(msg);
        int char_a = atoi(token_iter.GetToken(msg));
        token_iter.FindNextToken(msg);
        int char_b = atoi(token_iter.GetToken(msg));
        if(token == "knocked_over"){
            Log(info, "Player "+char_a+" was knocked over by player "+char_b);
            audience_excitement += 1.5f;
        } else if(token == "passive_blocked"){
            Log(info, "Player "+char_a+" passive-blocked an attack by player "+char_b);
            audience_excitement += 0.5f;
        } else if(token == "active_blocked"){
            Log(info, "Player "+char_a+" active-blocked an attack by player "+char_b);
            audience_excitement += 0.7f;
        } else if(token == "dodged"){
            Log(info, "Player "+char_a+" dodged an attack by player "+char_b);
            audience_excitement += 0.7f;
        } else if(token == "character_attack_feint"){
            Log(info, "Player "+char_a+" feinted an attack aimed at "+char_b);
            audience_excitement += 0.4f;
        } else if(token == "character_attack_missed"){
            Log(info, "Player "+char_a+" missed an attack aimed at "+char_b);
            audience_excitement += 0.4f;    
        } else if(token == "character_throw_escape"){
            Log(info, "Player "+char_a+" escaped a throw attempt by "+char_b);
            audience_excitement += 0.7f;        
        } else if(token == "character_thrown"){
            Log(info, "Player "+char_a+" was thrown by "+char_b);
            audience_excitement += 1.5f;
        } else if(token == "cut"){
            Log(info, "Player "+char_a+" was cut by "+char_b);
            audience_excitement += 2.0f;
        }
    }
    
    if(msg_start == "player_entered_checkpoint_fall_death"){
        if(token_iter.FindNextToken(msg)){
            int checkpoint_id = atoi(token_iter.GetToken(msg));
            if(progress >= checkpoint_id){
                int player_id = GetPlayerCharacterID();
                if(player_id != -1 && ObjectExists(player_id)){
                    MovementObject@ char = ReadCharacter(player_id);
                    char.ReceiveMessage("fall_death");
                }
            }
        }
    }

    if(win_time == -1.0){
        if(msg_start == "player_entered_checkpoint"){
            if(token_iter.FindNextToken(msg)){
                int checkpoint_id = atoi(token_iter.GetToken(msg));
                PossibleWinEvent("checkpoint", checkpoint_id, progress);
            }
        }        
    }
}

void SetMusicLayer(int layer){
    if(kDebugText){
        DebugText("music_layer", "music_layer: "+layer, 0.5);
        DebugText("music_layer_override", "music_layer_override: "+music_layer_override, 0.5);
        DebugText("music_prefix", "music_prefix: "+music_prefix, 0.5);
    }
    if(layer != curr_music_layer){
        for(int i=0; i<5; ++i){
            SetLayerGain(music_prefix+"layer_"+i, 0.0);
        }
        SetLayerGain(music_prefix+"layer_"+layer, 1.0);
        curr_music_layer = layer;
    }
}

void Update() {
    EnterTelemetryZone("Overgrowth Level Update");

    if(GetInputPressed(0, "k")){
        ++progress;
        if(!params.HasParam("goal_"+progress)){
            progress = 0;
        }
    }
    LeaveTelemetryZone();

    if(audience_sound_handle == -1 && music_prefix == "arena_"){
        audience_sound_handle = PlaySoundLoop("Data/Sounds/crowd/crowd_arena_general_1.wav",0.0f);
    } else if(audience_sound_handle != -1 && music_prefix != "arena_"){
        StopSound(audience_sound_handle);
        audience_sound_handle = -1;
    }

    // Get total amount of character movement
    float total_char_speed = 0.0f;
    int num = GetNumCharacters();
    for(int i=0; i<num; ++i){
        MovementObject@ char = ReadCharacter(i);
        if(char.GetIntVar("knocked_out") == _awake){
            total_char_speed += length(char.velocity);
        }
    }
    // Decay excitement based on total character movement
    float excitement_decay_rate = 1.0f / (1.0f + total_char_speed / 14.0f);
    excitement_decay_rate *= 3.0f;
    audience_excitement *= pow(0.05f, 0.001f*excitement_decay_rate);
    total_excitement += audience_excitement * time_step;
    // Update crowd sound effect volume and pitch based on excitement
    float target_crowd_cheer_amount = audience_excitement * 0.1f + 0.15f;

    float target_boo_amount = 0.0;
    if(crowd_override){
        target_crowd_cheer_amount = crowd_gain_override;
        target_boo_amount = crowd_pitch_override;
    }
    boo_amount = mix(target_boo_amount, boo_amount, 0.98);
    crowd_cheer_vel += (target_crowd_cheer_amount - crowd_cheer_amount) * time_step * 10.0f;
    if(crowd_cheer_vel > 0.0f){
        crowd_cheer_vel *= 0.99f;
    } else {
        crowd_cheer_vel *= 0.95f;
    }
    crowd_cheer_amount += crowd_cheer_vel * time_step;
    crowd_cheer_amount = max(crowd_cheer_amount, 0.1f);


    SetSoundGain(audience_sound_handle, crowd_cheer_amount*2.0f);
    SetSoundPitch(audience_sound_handle, mix(min(0.8f + crowd_cheer_amount * 0.5f,1.2f), 0.7, boo_amount));
}

bool can_press_attack = false;

void PreDraw(float curr_game_time) {
    EnterTelemetryZone("Overgrowth Level PreDraw");

    if(kDebugText){
        DebugText("progress", "progress: "+progress, 0.5);
    }
    if(queued_goal_check){
        CheckReset();
        queued_goal_check = false;
    }

    int player_id = GetPlayerCharacterID();
    if(ko_time == -1.0){
        if(music_layer_override == -1){
            if(player_id == -1){
                SetMusicLayer(-1);
            } else if(ReadCharacter(player_id).GetIntVar("knocked_out") != _awake){
                SetMusicLayer(0);
            } else if(ReadCharacter(player_id).QueryIntFunction("int CombatSong()") == 1){
                SetMusicLayer(3);
            } else if(params.HasParam("music")){
                SetMusicLayer(1);
            }
        } else {
            SetMusicLayer(music_layer_override);
        }
    } else {
        SetMusicLayer(-2);
    }

    if(the_time >= music_sting_end ){
        if(music_sting_end != 0.0 && ko_time == -1.0){
            music_sting_end = 0.0;
            SetLayerGain(music_prefix+"layer_"+curr_music_layer, 1.0);
        }
    } else {
        SetLayerGain(music_prefix+"layer_"+curr_music_layer, 0.0);
    }

    blackout_amount = 0.0;
    if(player_id != -1 && ObjectExists(player_id)){
        MovementObject@ char = ReadCharacter(player_id);
        if(char.GetIntVar("knocked_out") != _awake){
            if(ko_time == -1.0f){
                ko_time = the_time;
                PlayDeathSting();
                can_press_attack = false;
            }
            if(ko_time < the_time - 1.0){
                if(!GetInputDown(0, "attack")){
                    can_press_attack = true;
                }
                if((GetInputDown(0, "attack") && can_press_attack) || GetInputDown(0, "skip_dialogue") || GetInputDown(0, "keypadenter"))
                {
                    if(sting_handle != -1){
                        music_sting_end = the_time;
                        StopSound(sting_handle);
                        sting_handle = -1;
                    }
                    level.SendMessage("reset");                 
                    level.SendMessage("skip_dialogue");                 
                }
            }
            blackout_amount = 0.2 + 0.6 * (1.0 - pow(0.5, (the_time - ko_time)));
        } else {
            ko_time = -1.0f;
        }
        ReadCharacter(player_id).Execute("level_blackout = "+blackout_amount+";");
    } else {
        ko_time = -1.0f;
    }

    if(win_time != -1.0 && the_time > win_time && ko_time == -1.0){
        while(progress < win_target){
            IncrementProgress();
        }
    }

    int num_player_spawn = 0;
    if(params.HasParam("player_spawn")){
        string param_str = params.GetString("player_spawn");
        TokenIterator token_iter;
        token_iter.Init();
        while(token_iter.FindNextToken(param_str)){
            int id = atoi(token_iter.GetToken(param_str));
            if(ObjectExists(id)){
                Object@ obj = ReadObjectFromID(id);
                if(obj.GetType() == _placeholder_object){
                    PlaceholderObject@ placeholder_object = cast<PlaceholderObject@>(obj);
                    placeholder_object.SetPreview("Data/Objects/IGF_Characters/pale_turner.xml");
                    ++num_player_spawn;
                }
            }
        }
    }
    LeaveTelemetryZone();
}

void DrawEditor(){
    Object@ obj = ReadObjectFromID(hotspot.GetID());
    DebugDrawBillboard("Data/Textures/ui/ogicon.png",
                       obj.GetTranslation(),
                       obj.GetScale()[1]*2.0,
                       vec4(vec3(0.5), 1.0),
                       _delete_on_draw);
}
