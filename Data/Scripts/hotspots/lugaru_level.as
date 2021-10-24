#include "threatcheck.as"
#include "lugaru_campaign.as"

void SetParameters() {
	params.AddString("next_level", "");
    params.AddString("music", "lugaru_ambient_grass");
}

void Init() {
    SavedLevel @level = save_file.GetSavedLevel("lugaru_campaign");
    level.SetValue("current_level",GetCurrLevel());
    save_file.WriteInPlace();
    AddMusic("Data/Music/lugaru_new.xml");
}

void Dispose() {
}

float blackout_amount = 0.0;
float ko_time = -1.0;
float win_time = -1.0;
bool sent_level_complete_message = false;

void Update() {
    int player_id = GetPlayerCharacterID();
    if(player_id != -1 && ReadCharacter(player_id).QueryIntFunction("int CombatSong()") == 1 && ReadCharacter(player_id).GetIntVar("knocked_out") == _awake){
        PlaySong("lugaru_combat");
    } else if(params.HasParam("music")){
        PlaySong(params.GetString("music"));
    }

	blackout_amount = 0.0;
	if(player_id != -1 && ObjectExists(player_id)){
		MovementObject@ char = ReadCharacter(player_id);
		if(char.GetIntVar("knocked_out") != _awake){
			if(ko_time == -1.0f){
				ko_time = the_time;
			}
			if(ko_time < the_time - 1.0){
				if(GetInputPressed(0, "attack") || ko_time < the_time - 5.0){
	            	level.SendMessage("reset"); 				
                    level.SendMessage("skip_dialogue");                 
				}
			}
            blackout_amount = 0.2 + 0.6 * (1.0 - pow(0.5, (the_time - ko_time)));
		} else {
			ko_time = -1.0f;
		}
	} else {
        ko_time = -1.0f;
    }
	if(ThreatsRemaining() == 0 && ThreatsPossible() != 0 && ko_time == -1.0){
		if(win_time == -1.0f){
			win_time = the_time;
		}
		if(win_time < the_time - 5.0 && !sent_level_complete_message){
			string path = params.GetString("next_level");
			if(path != ""){
                FinishedLugaruCampaignLevel(GetCurrLevel());
	            level.SendMessage("loadlevel \""+path+"\"");		
                sent_level_complete_message = true;
	        }
	    }
	} else {
        win_time = -1.0;
    }
}

void PreDraw(float curr_game_time) {
    camera.SetTint(camera.GetTint() * (1.0 - blackout_amount));
}

void Draw(){
    if(EditorModeActive()){
        Object@ obj = ReadObjectFromID(hotspot.GetID());
        DebugDrawBillboard("Data/Textures/ui/lugaru_icns_256x256.png",
                           obj.GetTranslation(),
                           obj.GetScale()[1]*2.0,
                           vec4(vec3(0.5), 1.0),
                           _delete_on_draw);
    }
}
