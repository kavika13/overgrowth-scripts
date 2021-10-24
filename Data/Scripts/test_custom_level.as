#include "threatcheck.as"

// Difficulty of current collection of enemies
float curr_difficulty;
float player_skill;

// Level reset timing info
const float _reset_delay = 1.0f;
float reset_timer;

// For trying to complete level in a given amount of time
float target_time;
float time;

// Audience info
float audience_excitement;
float total_excitement;
int audience_size;
int audience_sound_handle;
float crowd_cheer_amount;
float crowd_cheer_vel;
int fan_base;

// Level state
enum LevelState {
    kIntro = 0,
    kInProgress = 1,
    kOutro = 2
}
LevelState level_state;
vec3 initial_player_pos;
enum LevelOutcome {
    kUnknown = 0,
    kVictory = 1,
    kFailure = 2
}
LevelOutcome level_outcome;

// Text display info
int main_text_id;
float text_visible;

// All objects spawned by the script
array<int> spawned_object_ids;

// For rendering text using Awesomium
//TextRenderGUI text_render_gui;

// Called by level.cpp at start of level
void Init(string str) {
    main_text_id = level.CreateTextElement();
    TextCanvasTexture @text = level.GetTextElement(main_text_id);
    text.Create(512,512);
    curr_difficulty = 0.5f;
    player_skill = 0.5f;
    audience_sound_handle = -1;
    SetUpLevel(curr_difficulty);
    crowd_cheer_amount = 0.0f;
    crowd_cheer_vel = 0.0f;
    fan_base = 0;
    //text_render_gui.Create();
}

void DeleteObjectsInList(array<int> &inout ids){
    int num_ids = ids.length();
    for(int i=0; i<num_ids; ++i){
        DeleteObjectID(ids[i]);
    }
    ids.resize(0);
}

// Instantiate an object at the location of another object
// E.g. create a character at the location of a placeholder spawn point
Object@ SpawnObjectAtSpawnPoint(Object@ spawn, string &in path){
    Print("Spawning \"" + path + "\"\n");
    int obj_id = CreateObject(path);
    spawned_object_ids.push_back(obj_id);
    Object @new_obj = ReadObjectFromID(obj_id);
    new_obj.SetTranslation(spawn.GetTranslation());
    new_obj.SetRotation(spawn.GetRotation());
    return new_obj;
}

// Attach a specific preview path to a given placeholder object
void SetSpawnPointPreview(Object@ spawn, string &in path){
    PlaceholderObject@ placeholder_object = cast<PlaceholderObject@>(spawn);
    placeholder_object.SetPreview(path);
}

// Find spawn points and set which object is displayed as a preview
void SetPlaceholderPreviews() {
    array<int> @object_ids = GetObjectIDs();
    int num_objects = object_ids.length();
    for(int i=0; i<num_objects; ++i){
        Object @obj = ReadObjectFromID(object_ids[i]);
        ScriptParams@ params = obj.GetScriptParams();
        if(params.HasParam("Name")){
            string name_str = params.GetString("Name");
            if("player_spawn" == name_str){
                SetSpawnPointPreview(obj,"Data/Objects/IGF_Characters/IGF_Turner.xml");
            }
            if("enemy_spawn" == name_str){
                SetSpawnPointPreview(obj,"Data/Objects/IGF_Characters/IGF_Guard.xml");
            }
        }
    }
}

// This script has no need of input focus
bool HasFocus(){
    return false;
}

// This script has no GUI elements
void DrawGUI() {        
    float ui_scale = 0.5f;
    float visible = 1.0f;
    float display_time = time;

    {   HUDImage @image = hud.AddImage();
        image.SetImageFromPath("Data/Textures/diffuse.tga");
        float stretch = GetScreenHeight() / image.GetHeight();
        image.position.x = GetScreenWidth() * 0.4f - 200;
        image.position.y = ((1.0-visible) * GetScreenHeight() * -1.2);
        image.position.z = 3;
        image.tex_scale.y = 20;
        image.tex_scale.x = 20;
        image.color = vec4(0.6f,0.8f,0.6f,text_visible*0.8f);
        image.scale = vec3(460 / image.GetWidth(), stretch, 1.0);}

    {   HUDImage @image = hud.AddImage();
        image.SetImageFromText(level.GetTextElement(main_text_id)); 
        image.position.x = int(GetScreenWidth() * 0.4f - 200 + 10);
        image.position.y = GetScreenHeight()-500;
        image.position.z = 4;
        image.color = vec4(1,1,1,text_visible);}
}

// Convert byte colors to float colors (255,0,0) to (1.0f,0.0f,0.0f)
vec3 FloatTintFromByte(const vec3 &in tint){
    vec3 float_tint;
    float_tint.x = tint.x / 255.0f;
    float_tint.y = tint.y / 255.0f;
    float_tint.z = tint.z / 255.0f;
    return float_tint;
}

// Create a random color tint, avoiding excess saturation
vec3 RandReasonableColor(){
    vec3 color;
    color.x = rand()%255;
    color.y = rand()%255;
    color.z = rand()%255;
    float avg = (color.x + color.y + color.z) / 3.0f;
    color = mix(color, vec3(avg), 0.7f);
    return color;
}

// Create a random enemy at spawn point obj, with a given skill level
void CreateEnemy(Object@ obj, float difficulty){
    string actor_path; // Path to actor xml
    int fur_channel = -1; // Which tint mask channel corresponds to fur
    int rnd = rand()%2+1;
    switch(rnd){
    case 0: 
        actor_path = "Data/Objects/IGF_Characters/IGF_RabbitCivActor.xml"; 
        break;
    case 1: 
        fur_channel = 1;
        actor_path = "Data/Objects/IGF_Characters/IGF_GuardActor.xml"; 
        break;
    case 2: 
        fur_channel = 0;
        actor_path = "Data/Objects/characters/raider_rabbit_actor.xml"; 
        break;
    }
    // Spawn actor
    Object@ char_obj = SpawnObjectAtSpawnPoint(obj,actor_path);
    // Set palette colors randomly, darkening based on skill
    for(int i=0; i<4; ++i){
        vec3 color = FloatTintFromByte(RandReasonableColor());
        color = mix(color, vec3(1.0-difficulty), 0.5f);
        char_obj.SetPaletteColor(i, color);
    }
    // Set fur color to one of six reasonable fur colors
    vec3 fur_color_byte;
    rnd = rand()%6;                    
    switch(rnd){
    case 0: fur_color_byte = vec3(255); break;
    case 1: fur_color_byte = vec3(34); break;
    case 2: fur_color_byte = vec3(137); break;
    case 3: fur_color_byte = vec3(105,73,54); break;
    case 4: fur_color_byte = vec3(53,28,10); break;
    case 5: fur_color_byte = vec3(172,124,62); break;
    }
    vec3 fur_color = FloatTintFromByte(fur_color_byte);
    char_obj.SetPaletteColor(fur_channel, fur_color);
    // Set character parameters based on difficulty
    ScriptParams@ params = char_obj.GetScriptParams();
    params.SetString("Teams", "arena_enemy");
    params.SetFloat("Block Follow-up", mix(RangedRandomFloat(0.01f,0.25f), RangedRandomFloat(0.75f,1.0f), difficulty));
    params.SetFloat("Block Skill", mix(RangedRandomFloat(0.01f,0.25f), RangedRandomFloat(0.5f,0.8f), difficulty));
    params.SetFloat("Movement Speed", mix(RangedRandomFloat(0.8f,1.0f), RangedRandomFloat(0.9f,1.1f), difficulty));
    params.SetFloat("Attack Speed", mix(RangedRandomFloat(0.8f,1.0f), RangedRandomFloat(0.9f,1.1f), difficulty));
    float damage = mix(RangedRandomFloat(0.3f,0.5f), RangedRandomFloat(0.9f,1.1f), difficulty);
    params.SetFloat("Attack Knockback", damage);
    params.SetFloat("Attack Damage", damage);
    params.SetFloat("Aggression", RangedRandomFloat(0.25f,0.75f));
    params.SetFloat("Damage Resistance", mix(RangedRandomFloat(0.3f,0.5f), RangedRandomFloat(0.9f,1.1f), difficulty));
    params.SetInt("Left handed", (rand()%5==0)?1:0);
}

// Spawn all of the objects that we'll need in the level of given total difficulty
void SetUpLevel(float initial_difficulty){
    // Remove all spawned objects
    DeleteObjectsInList(spawned_object_ids);
    // Go through all spawn points, create player at player spawn, and remember enemy spawns
    array<int> @object_ids = GetObjectIDs();
    array<int> enemy_spawns;
    int num_objects = object_ids.length();
    for(int i=0; i<num_objects; ++i){
        Object @obj = ReadObjectFromID(object_ids[i]);
        ScriptParams@ params = obj.GetScriptParams();
        if(params.HasParam("Name")){
            string name_str = params.GetString("Name");
            if("player_spawn" == name_str){
                Object@ char_obj = SpawnObjectAtSpawnPoint(obj,"Data/Objects/IGF_Characters/IGF_TurnerActor.xml");
                char_obj.SetPlayer(true);
                bool spawn_weapon = false;
                if(spawn_weapon){
                    if(rand()%2 == 0){
                        string str;
                        int rnd = rand()%3;
                        switch(rnd){
                        case 0: str = "Data/Items/DogWeapons/DogKnife.xml"; break;
                        case 1: str = "Data/Items/DogWeapons/DogBroadSword.xml"; break;
                        case 2: str = "Data/Items/DogWeapons/DogSword.xml"; break;
                        }
                        Object@ item_obj = SpawnObjectAtSpawnPoint(obj,str);
                        char_obj.AttachItem(item_obj, _at_grip, false);
                    }
                }
                initial_player_pos = obj.GetTranslation();
            }
            if("enemy_spawn" == name_str){
                enemy_spawns.push_back(object_ids[i]);
            }
        }
    }
    // Divide up difficulty to provide a mix of weak and strong enemies
    // that add up to the given total difficulty
    float difficulty = initial_difficulty;
    Print("Total difficulty: "+difficulty+"\n");
    array<float> enemy_difficulties;
    while(difficulty > 0.0f){
        if(difficulty < 1.0f){
            enemy_difficulties.push_back(difficulty);
            difficulty = 0.0f;
        } else if(difficulty < 1.5f){
            if(rand()%2 == 0){
                enemy_difficulties.push_back(difficulty);
                difficulty = 0.0f;
            } else {
                float temp_difficulty = RangedRandomFloat(0.5f,min(1.5f, difficulty-0.5));
                enemy_difficulties.push_back(temp_difficulty);
                difficulty -= temp_difficulty;
            }
        } else {
            float temp_difficulty = RangedRandomFloat(0.5f,1.5f);
            enemy_difficulties.push_back(temp_difficulty);
            difficulty -= temp_difficulty;
        }           
    }
    const bool print_difficulties = false;
    if(print_difficulties){
        Print("Enemy difficulties: ");
        for(int i=0; i<int(enemy_difficulties.size()); ++i){
            Print(""+enemy_difficulties[i]+", ");
        }
        Print("\n");
    }
    // Assign each enemy to a random unused spawn point, and instantiate them there
    int num_enemies = min(enemy_difficulties.size(), enemy_spawns.size());
    array<int> chosen(enemy_spawns.size(), 0);
    for(int i=0; i<num_enemies; ++i){
        int next_enemy = rand()%(enemy_spawns.size() - i);
        int counter = -1;
        int j = 0;
        while (next_enemy >= 0){
            ++counter;
            while(chosen[counter] != 0){
                ++counter;
            }
            --next_enemy;
        }
        chosen[counter] = 1;
        Object @obj = ReadObjectFromID(enemy_spawns[counter]);
        CreateEnemy(obj, enemy_difficulties[i]-0.5f);
    } 
    // Reset level timer info
    target_time = 10.0f;
    reset_timer = _reset_delay;   
    time = 0.0f;
    // Reset audience info
    audience_excitement = 0.0f;
    total_excitement = 0.0f;
    // Audience size increases exponentially based on difficulty
    audience_size = (rand()%1000+100)*pow(4.0f,initial_difficulty)*0.1f;
    if(audience_sound_handle == -1){
        audience_sound_handle = PlaySoundLoop("Data/Sounds/crowd/crowd_arena_general_1.wav",0.0f);
    }
    SetIntroText();
    level_state = kIntro;
    level_outcome = kUnknown;
    text_visible = 1.0f;
    
    int num_chars = GetNumCharacters();
    for(int i=0; i<num_chars; ++i){
        MovementObject@ char = ReadCharacter(i);
        char.ReceiveMessage("set_hostile false");
    }
    //TimedSlowMotion(0.5f,7.0f, 0.0f);
}

enum MessageParseType {
    kSimple = 0,
    kOneInt = 1,
    kTwoInt = 2
}

// Parse string messages and react to them
void ReceiveMessage(string msg) {
    TokenIterator token_iter;
    token_iter.Init();
    if(!token_iter.FindNextToken(msg)){
        return;
    }

    // Handle simple tokens, or mark as requiring extra parameters
    MessageParseType type = kSimple;
    string token = token_iter.GetToken(msg);
    if(token == "reset"){
        SetUpLevel(curr_difficulty);    
    } else if(token == "dispose_level"){
        StopSound(audience_sound_handle);
    } else if(token == "knocked_over" ||
              token == "passive_blocked" ||
              token == "active_blocked" ||
              token == "dodged" ||
              token == "character_attack_feint" ||
              token == "character_attack_missed" ||
              token == "character_throw_escape" ||
              token == "character_thrown")
    {
        type = kTwoInt;
    } else if(token == "character_died" ||
              token == "character_knocked_out" ||
              token == "character_start_flip" ||
              token == "character_start_roll" ||
              token == "character_failed_flip")
    {
        type = kOneInt;
    }

    if(type == kOneInt){
        token_iter.FindNextToken(msg);
        int char_a = atoi(token_iter.GetToken(msg));
        if(token == "character_died"){
            Print("Player "+char_a+" was killed\n");
            audience_excitement += 4.0f;
        } else if(token == "character_knocked_out"){
            Print("Player "+char_a+" was knocked out\n");
            audience_excitement += 3.0f;
        } else if(token == "character_start_flip"){
            Print("Player "+char_a+" started a flip\n");
            audience_excitement += 0.4f;
        } else if(token == "character_start_roll"){
            Print("Player "+char_a+" started a roll\n");
            audience_excitement += 0.4f;
        } else if(token == "character_failed_flip"){
            Print("Player "+char_a+" failed a flip\n");
            audience_excitement += 1.0f;
        }
    } else if(type == kTwoInt){
        token_iter.FindNextToken(msg);
        int char_a = atoi(token_iter.GetToken(msg));
        token_iter.FindNextToken(msg);
        int char_b = atoi(token_iter.GetToken(msg));
        if(token == "knocked_over"){
            Print("Player "+char_a+" was knocked over by player "+char_b+"\n");
            audience_excitement += 1.5f;
        } else if(token == "passive_blocked"){
            Print("Player "+char_a+" passive-blocked an attack by player "+char_b+"\n");
            audience_excitement += 0.5f;
        } else if(token == "active_blocked"){
            Print("Player "+char_a+" active-blocked an attack by player "+char_b+"\n");
            audience_excitement += 0.7f;
        } else if(token == "dodged"){
            Print("Player "+char_a+" dodged an attack by player "+char_b+"\n");
            audience_excitement += 0.7f;
        } else if(token == "character_attack_feint"){
            Print("Player "+char_a+" feinted an attack aimed at "+char_b+"\n");
            audience_excitement += 0.4f;
        } else if(token == "character_attack_missed"){
            Print("Player "+char_a+" missed an attack aimed at "+char_b+"\n");
            audience_excitement += 0.4f;    
        } else if(token == "character_throw_escape"){
            Print("Player "+char_a+" escaped a throw attempt by "+char_b+"\n");
            audience_excitement += 0.7f;        
        } else if(token == "character_thrown"){
            Print("Player "+char_a+" was thrown by "+char_b+"\n");
            audience_excitement += 1.5f;
        }
    }
}

float ProbabilityOfWin(float a, float b){
    float a2 = a*a;
    float b2 = b*b;
    return a2 / (a2 + b2);
}

float GetRandomDifficultyNearPlayerSkill() {
    float var = player_skill * RangedRandomFloat(0.5f,1.5f);
    if(var < 0.5f){
        var = 0.5f;
    }
    return var;
}

// Check if level should be reset
void VictoryCheck() {
    if(level_outcome == kUnknown){
        int player_id = GetPlayerCharacterID();
        if(player_id == -1){
            return;
        }
        // Check if any enemies are still standing
        bool victory = true;
        for(int i=0; i<level.GetNumObjectives(); ++i){
            int threats_remaining = ThreatsRemaining();
            int threats_possible = ThreatsPossible();
            if(threats_remaining > 0 || threats_possible == 0){
                victory = false;
            }
        }
        // Check if player is still standing
        bool failure = false;
        MovementObject@ player_char = ReadCharacter(player_id);
        if(player_char.GetIntVar("knocked_out") != _awake){
            failure = true;
        }
        if(failure || victory){
            reset_timer = _reset_delay;
            level_state = kOutro;
            float win_prob = ProbabilityOfWin(player_skill, curr_difficulty);
            float excitement_level = 1.0f-pow(0.9f,total_excitement*0.3f); 
            const float kMatchImportance = 0.3f; // How much this match influences your skill evaluation
            if(failure){ // Decrease difficulty on failure
                level_outcome = kFailure;   
                float audience_fan_ratio = 0.0f;
                if(win_prob < 0.5f){ // If you were predicted to lose, you still gain some fans
                    audience_fan_ratio += (0.5f - win_prob) * kMatchImportance;
                }
                audience_fan_ratio += (1.0f - audience_fan_ratio) * excitement_level * 0.4f;
                int new_fans = audience_size * audience_fan_ratio;
                fan_base += new_fans;
                player_skill -= player_skill * win_prob * kMatchImportance;
                if(player_skill < 0.5f){
                    player_skill = 0.5f;
                }         
                SetLoseText(new_fans, excitement_level);
            } else if(victory){ // Increase difficulty on win
                level_outcome = kVictory;
                player_skill += curr_difficulty * (1.0f - win_prob) * kMatchImportance;                
                float audience_fan_ratio = (1.0f - win_prob) * kMatchImportance;
                audience_fan_ratio += (1.0f - audience_fan_ratio) * excitement_level;
                int new_fans = audience_size * audience_fan_ratio;
                fan_base += new_fans;
                SetWinText(new_fans, excitement_level);
            }
        }        
    }

    // If player is KO or enemies are KO, countdown to level reset
    if(level_state == kOutro){
        reset_timer -= time_step;
        if(reset_timer <= 0.0f && GetInputPressed(0, "attack")){
            if(level_outcome == kVictory){ 
                PlaySoundGroup("Data/Sounds/versus/fight_win1.xml");  
            } else if(level_outcome == kFailure){ 
                PlaySoundGroup("Data/Sounds/versus/fight_lose1.xml");  
            }
            // Set up new level
            curr_difficulty = GetRandomDifficultyNearPlayerSkill();
            SetUpLevel(curr_difficulty);
        }
    }
    if(level_state == kIntro || level_state == kOutro){
        text_visible += time_step;
        text_visible = min(1.0f, text_visible);
    } else {
        text_visible -= time_step;
        text_visible = max(0.0f, text_visible);
    }
}

void SetIntroText() {
    TextCanvasTexture @text = level.GetTextElement(main_text_id);
    text.ClearTextCanvas();
    string font_str = "Data/UI/arena/images/arabtype.ttf";
    TextStyle small_style, big_style;
    small_style.font_face_id = GetFontFaceID(font_str, 48);
    big_style.font_face_id = GetFontFaceID(font_str, 72);

    vec2 pen_pos = vec2(0,256);
    text.SetPenPosition(pen_pos);
    text.SetPenColor(0,0,0,255);
    text.SetPenRotation(0.0f);
    text.AddText("Odds are ", small_style);
    float prob = ProbabilityOfWin(player_skill, curr_difficulty);
    int a, b;
    OddsFromProbability(1.0f-prob, a, b);
    if(a < b){
        text.AddText("" + b+":"+a, big_style);
        text.AddText(" in your favor", small_style);
    } else if(a > b){
        text.AddText("" + a+":"+b, big_style);
        text.AddText(" against you", small_style);
    } else {
        text.AddText("even", small_style);
    }

    int line_break_dist = 42;
    pen_pos.y += line_break_dist;
    text.SetPenPosition(pen_pos);
    text.AddText("There are ",small_style);
    text.AddText(""+audience_size,big_style);
    text.AddText(" spectators",small_style);

    pen_pos.y += line_break_dist;
    text.SetPenPosition(pen_pos);
    text.AddText("Good luck!",small_style);

    text.UploadTextCanvasToTexture();
}

void SetWinText(int new_fans, float excitement_level) {
    TextCanvasTexture @text = level.GetTextElement(main_text_id);
    text.ClearTextCanvas();
    string font_str = "Data/UI/arena/images/arabtype.ttf";
    TextStyle small_style, big_style;
    small_style.font_face_id = GetFontFaceID(font_str, 48);
    big_style.font_face_id = GetFontFaceID(font_str, 72);

    vec2 pen_pos = vec2(0,256);
    text.SetPenPosition(pen_pos);
    text.SetPenColor(0,0,0,255);
    text.SetPenRotation(0.0f);
    text.AddText("You won!", small_style);

    int line_break_dist = 42;
    pen_pos.y += line_break_dist;
    text.SetPenPosition(pen_pos);
    text.AddText("You gained ",small_style);
    text.AddText(""+new_fans,big_style);
    text.AddText(" fans",small_style);
    
    pen_pos.y += line_break_dist;
    text.SetPenPosition(pen_pos);
    text.AddText("Your fanbase totals ",small_style);
    text.AddText(""+fan_base,big_style);
    
    pen_pos.y += line_break_dist;
    text.SetPenPosition(pen_pos);
    text.AddText("Your skill assessment is now ",small_style);
    text.AddText(""+int((player_skill-0.5f)*40+1),big_style);

    pen_pos.y += line_break_dist;
    text.SetPenPosition(pen_pos);
    text.AddText("Audience ",small_style);
    text.AddText(""+int(excitement_level * 100.0f) + "%",big_style);
    text.AddText(" entertained",small_style);

    text.UploadTextCanvasToTexture();
}

void SetLoseText(int new_fans, float excitement_level) {
    TextCanvasTexture @text = level.GetTextElement(main_text_id);
    text.ClearTextCanvas();
    string font_str = "Data/UI/arena/images/arabtype.ttf";
    TextStyle small_style, big_style;
    small_style.font_face_id = GetFontFaceID(font_str, 48);
    big_style.font_face_id = GetFontFaceID(font_str, 72);
    int line_break_dist = 42;

    vec2 pen_pos = vec2(0,256);
    text.SetPenPosition(pen_pos);
    text.SetPenColor(0,0,0,255);
    text.SetPenRotation(0.0f);
    text.AddText("You were defeated.", small_style);
    
    if(new_fans > 0){
        pen_pos.y += line_break_dist;
        text.SetPenPosition(pen_pos);
        text.AddText("You gained ",small_style);
        text.AddText(""+new_fans, big_style);
        text.AddText(" new fans",small_style);
    
        pen_pos.y += line_break_dist;
        text.SetPenPosition(pen_pos);
        text.AddText("Your fanbase totals ",small_style);
        text.AddText(""+fan_base,big_style);
    }

    pen_pos.y += line_break_dist;
    text.SetPenPosition(pen_pos);
    text.AddText("Your skill assessment is now ",small_style);
    text.AddText(""+int((player_skill-0.5f)*40+1),big_style);
    
    pen_pos.y += line_break_dist;
    text.SetPenPosition(pen_pos);
    text.AddText("Audience ",small_style);
    text.AddText(""+int(excitement_level * 100.0f) + "%",big_style);
    text.AddText(" entertained",small_style);

    text.UploadTextCanvasToTexture();
}

void OddsFromProbability(float prob, int &out a, int &out b) {
    // Escape if 0 or 1, to avoid divide by zero
    if(prob == 0.0f){
        a = 0;
        b = 1;
        return;
    }
    if(prob == 1.0f){
        a = 1;
        b = 0;
        return;
    }
    string str;
    // If probability is 0.5, we want 1:1 odds, or 1.0 ratio
    // If probability is 0.33, we want 1:2 odds, or 0.5 ratio
    // Convert probability to ratio
    float target_ratio = prob / (1.0f - prob);
    int closest_numerator = -1;
    int closest_denominator = -1;
    float closest_dist = 0.0f;
    for(int i=1; i<10; ++i){
        for(int j=1; j<10; ++j){
            float val = i/float(j);
            float dist = abs(target_ratio - val);
            if(closest_numerator == -1 || dist < closest_dist){
                closest_dist = dist;
                closest_numerator = i;
                closest_denominator = j;
            }
        }
    }
    if(closest_numerator == 1 && closest_denominator == 9){
        closest_denominator = int(1.0f/target_ratio);
    }
    if(closest_numerator == 9 && closest_denominator == 1){
        closest_numerator = int(target_ratio);
    }
    a = closest_numerator;
    b = closest_denominator;
}

void Update() {
    SetPlaceholderPreviews();
    if(GetInputPressed(0, "t")){
        curr_difficulty = GetRandomDifficultyNearPlayerSkill();
        SetUpLevel(curr_difficulty);
    }

    if(level_state == kIntro){
        int player_id = GetPlayerCharacterID();
        if(player_id != -1){
            MovementObject@ player_char = ReadCharacter(player_id);
            if(distance_squared(initial_player_pos, player_char.position) > 1.0f){
                level_state = kInProgress;
                int num_chars = GetNumCharacters();
                for(int i=0; i<num_chars; ++i){
                    MovementObject@ char = ReadCharacter(i);
                    char.ReceiveMessage("set_hostile true");
                }
            }
        }
    }


    bool debug_text = false;
    VictoryCheck();
    time += time_step;
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
    audience_excitement *= pow(0.05f, 0.001f*excitement_decay_rate);
    total_excitement += audience_excitement * time_step;
    // Update crowd sound effect volume and pitch based on excitement
    float target_crowd_cheer_amount = audience_excitement * 0.1f + 0.15f;
    crowd_cheer_vel += (target_crowd_cheer_amount - crowd_cheer_amount) * time_step * 10.0f;
    if(crowd_cheer_vel > 0.0f){
        crowd_cheer_vel *= 0.99f;
    } else {
        crowd_cheer_vel *= 0.95f;
    }
    crowd_cheer_amount += crowd_cheer_vel * time_step;
    crowd_cheer_amount = max(crowd_cheer_amount, 0.1f);
    SetSoundGain(audience_sound_handle, crowd_cheer_amount*2.0f);
    SetSoundPitch(audience_sound_handle, min(0.8f + crowd_cheer_amount * 0.5f,1.2f));
    
    if(debug_text){
        DebugText("a","Difficulty: "+curr_difficulty*2.0f,0.5f);
        DebugText("ab","Player Skill: "+player_skill*2.0f,0.5f);
        float prob = ProbabilityOfWin(player_skill, curr_difficulty);
        DebugText("ac","Probability of player win: "+ProbabilityOfWin(player_skill, curr_difficulty),0.5f);
        int a, b;
        OddsFromProbability(1.0f-prob, a, b);
        DebugText("ad","Odds against win: "+a+":"+b,0.5f);
        DebugText("b","Target time: "+target_time,0.5f);
        DebugText("c","Current time: "+time,0.5f);
        DebugText("d","Excitement: "+audience_excitement,0.5f);
        DebugText("g","Total excitement: "+total_excitement,0.5f);
        DebugText("h","Audience size:  "+audience_size,0.5f);
        DebugText("ha","Fans:  "+fan_base,0.5f);
        DebugText("hb","target_crowd_cheer_amount:  "+target_crowd_cheer_amount,0.5f);
        DebugText("i","crowd_cheer_amount:  "+crowd_cheer_amount,0.5f);
        DebugText("j","crowd_cheer_vel:  "+crowd_cheer_vel,0.5f);
    }
}