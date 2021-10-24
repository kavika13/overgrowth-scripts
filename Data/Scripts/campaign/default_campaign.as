#include "campaign_common.as"

void Dispose() {
}

void EnterCampaign() {
    SavedLevel @camp_save = save_file.GetSave(GetCurrCampaignID(),"linear_campaign","");
            
    Campaign camp = GetCampaign(GetCurrCampaignID());

    array<ModLevel>@ levels = camp.GetLevels();

    //Unlock all levels
    for( uint i = 0; i < levels.size(); i++ ) {
        UnlockLevel(levels[i].GetID());
    }
}

void EnterLevel() {
    Log(info, "Entered level " + GetCurrLevelName() );
    SetLevelPlayed(GetCurrLevelID());
    SetLastLevelPlayed(GetCurrLevelID());
}

void LeaveLevel() {
    Log(info, "Left level"+ GetCurrLevelName());
}

void LeaveCampaign() { 
    Log(info, "Left campaign"+ GetCurrCampaignID());
}

void ReceiveMessage(string msg) {
    Log(info, "Getting msg in lugaru: " + msg );
    TokenIterator token_iter;
    token_iter.Init();
    if(!token_iter.FindNextToken(msg)){
        return;
    }
    string token = token_iter.GetToken(msg);

    if(token == "levelwin" ) {
        if(!EditorModeActive()){
            string curr_id = GetCurrLevelID();
            LevelFinished(curr_id);

            Log( info, "Setting " + GetCurrLevel() + " as finished level " );

            if( IsLastLevel(curr_id) ) {
                //We can roll credits here maybe.
                SendLevelMessage("go_to_main_menu");		
            } else {
                string next_level_id = GetFollowingLevel(curr_id);
                if(next_level_id != ""){
                    UnlockLevel(next_level_id); 

                    LoadLevelID(next_level_id);
                } else {
                    Log(error, "unexpected error" );
                    SendLevelMessage("go_to_main_menu");		
                }
            }
        } else {
            Log(info, "Ignoring levelwin command, game is in editor mode");
        }
    }

}
