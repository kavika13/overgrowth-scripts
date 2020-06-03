#include "threatcheck.as"

float curr_difficulty;
const float _reset_delay = 2.0f;
float reset_timer = _reset_delay;

void Init(string str) {
    curr_difficulty = 0.5f;
    SetUpLevel(curr_difficulty);
}

void DeleteObjectsInList(array<int> &inout ids){
    int num_ids = ids.length();
    for(int i=0; i<num_ids; ++i){
        DeleteObjectID(ids[i]);
    }
    ids.resize(0);
}

array<int> spawned_object_ids;

Object@ SpawnObjectAtSpawnPoint(Object@ spawn, string &in path){
    Print("Spawning \"" + path + "\"\n");
    int obj_id = CreateObject(path);
    spawned_object_ids.push_back(obj_id);
    Object @new_obj = ReadObjectFromID(obj_id);
    new_obj.SetTranslation(spawn.GetTranslation());
    new_obj.SetRotation(spawn.GetRotation());
    return new_obj;
}

void SetSpawnPointPreview(Object@ spawn, string &in path){
    PlaceholderObject@ placeholder_object = cast<PlaceholderObject@>(spawn);
    placeholder_object.SetPreview(path);
}

void SetPreviews() {
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

bool HasFocus(){
    return false;
}

void DrawGUI() {    
}

vec3 FloatTintFromByte(const vec3 &in tint){
    vec3 float_tint;
    float_tint.x = tint.x / 255.0f;
    float_tint.y = tint.y / 255.0f;
    float_tint.z = tint.z / 255.0f;
    return float_tint;
}

vec3 RandReasonableColor(){
    vec3 color;
    color.x = rand()%255;
    color.y = rand()%255;
    color.z = rand()%255;
    float avg = (color.x + color.y + color.z) / 3.0f;
    color = mix(color, vec3(avg), 0.7f);
    return color;
}

void CreateEnemy(Object@ obj, float difficulty){
    string str;
    int fur_channel = -1;
    int rnd = rand()%2+1;
    switch(rnd){
    case 0: 
        str = "Data/Objects/IGF_Characters/IGF_RabbitCivActor.xml"; 
        break;
    case 1: 
        fur_channel = 1;
        str = "Data/Objects/IGF_Characters/IGF_GuardActor.xml"; 
        break;
    case 2: 
        fur_channel = 0;
        str = "Data/Objects/characters/raider_rabbit_actor.xml"; 
        break;
    }
    Object@ char_obj = SpawnObjectAtSpawnPoint(obj,str);
    for(int i=0; i<4; ++i){
        vec3 color = FloatTintFromByte(RandReasonableColor());
        color = mix(color, vec3(1.0-difficulty), 0.5f);
        char_obj.SetPaletteColor(i, color);
    }
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

void SetUpLevel(float difficulty){
    DeleteObjectsInList(spawned_object_ids);
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
    
                /*if(rand()%2 == 0){
                    string str;
                    int rnd = rand()%3;
                    switch(rnd){
                    case 0: str = "Data/Items/DogWeapons/DogKnife.xml"; break;
                    case 1: str = "Data/Items/DogWeapons/DogBroadSword.xml"; break;
                    case 2: str = "Data/Items/DogWeapons/DogSword.xml"; break;
                    }
                    Object@ item_obj = SpawnObjectAtSpawnPoint(obj,str);
                    char_obj.AttachItem(item_obj, _at_grip, false);
                }*/
            }
            if("enemy_spawn" == name_str){
                enemy_spawns.push_back(object_ids[i]);
            }
        }
    }
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
    /*Print("Enemy difficulties: ");
    for(int i=0; i<int(enemy_difficulties.size()); ++i){
        Print(""+enemy_difficulties[i]+", ");
    }
    Print("\n");*/
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
    reset_timer = _reset_delay;   
}

void ReceiveMessage(string msg) {
    TokenIterator token_iter;
    token_iter.Init();
    if(!token_iter.FindNextToken(msg)){
        return;
    }
    string token = token_iter.GetToken(msg);
    if(token == "reset"){
        SetUpLevel(curr_difficulty);    
    }
}

void VictoryCheck() {
    int player_id = GetPlayerCharacterID();
    if(player_id == -1){
        return;
    }
    bool victory = true;
    float max_reset_delay = _reset_delay;
    for(int i=0; i<level.GetNumObjectives(); ++i){
        int threats_remaining = ThreatsRemaining();
        int threats_possible = ThreatsPossible();
        if(threats_remaining > 0 || threats_possible == 0){
            victory = false;
        }
    }
    reset_timer = min(max_reset_delay, reset_timer);
    
    bool failure = false;
    MovementObject@ player_char = ReadCharacter(player_id);
    if(player_char.GetIntVar("knocked_out") != _awake){
        failure = true;
    }
    if(reset_timer > 0.0f && (victory || failure)){
        reset_timer -= time_step;
        if(reset_timer <= 0.0f){
            if(victory){
                curr_difficulty += RangedRandomFloat(0.1f,0.5f);
                PlaySoundGroup("Data/Sounds/versus/fight_win1.xml");  
            } else if(failure){
                curr_difficulty -= RangedRandomFloat(0.1f,0.5f);
                if(curr_difficulty < 0.5f){
                    curr_difficulty = 0.5f;
                }
                PlaySoundGroup("Data/Sounds/versus/fight_lose1.xml");  
            }
            SetUpLevel(curr_difficulty);
        }
    } else {
        reset_timer = _reset_delay;
    }
}

void Update() {
    SetPreviews();
    if(GetInputPressed(0, "t")){
        SetUpLevel(curr_difficulty);
    }
    DebugText("a","Difficulty: "+curr_difficulty*2.0f,0.5f);
    VictoryCheck();
}