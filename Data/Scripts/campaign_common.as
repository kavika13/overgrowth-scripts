class LevelInfo
{
    string name;
    string id;
    string file;
    string image;
	string campaign_id;
    string lock_icon = "Textures/ui/menus/main/icon-lock.png";
    int highest_diff;
    bool level_played = false;
    bool hide_stars = false;
	bool coming_soon = false;

    LevelInfo(ModLevel level)
    {
        name = level.GetTitle();
        file = level.GetPath();
        image = level.GetThumbnail();
        id = level.GetID();
        highest_diff = GetHighestDifficultyFinished(id);
        level_played = GetLevelPlayed(level.GetID());
    }

    LevelInfo(string _file, string _name, string _image, string _campaign_id)
    {
        name = _name;
        file = _file;
        image = _image;
		campaign_id = _campaign_id;
        id = _name;
        highest_diff = GetHighestDifficultyFinishedCampaign(_campaign_id);
    }

    LevelInfo(string _file, string _name, string _image, string _campaign_id, bool _level_played)
    {
        name = _name;
        file = _file;
        image = _image;
		campaign_id = _campaign_id;
        id = _name;
        highest_diff = GetHighestDifficultyFinishedCampaign(_campaign_id);
        level_played = _level_played;
    }

	LevelInfo(string _file, string _name, string _image, bool _coming_soon)
    {
        name = _name;
        file = _file;
        image = _image;
		coming_soon = _coming_soon;
        id = _name;
        highest_diff = 0;
    }

	LevelInfo(string _file, string _name, string _image, int _highest_diff)
    {
        name = _name;
        file = _file;
        image = _image;
		coming_soon = false;
        id = _name;
        highest_diff = _highest_diff;
    }

	LevelInfo(string _file, string _name, string _image, int _highest_diff, bool _level_played)
    {
        name = _name;
        file = _file;
        image = _image;
		coming_soon = false;
        id = _name;
        highest_diff = _highest_diff;
        level_played = _level_played;
    }

	LevelInfo(string _file, string _name, string _image)
    {
        name = _name;
        file = _file;
        image = _image;
		coming_soon = false;
        id = _name;
        highest_diff = 0;
    }
};

SavedLevel@ GetGlobalSave() {
    return save_file.GetSave("","global","");
}

SavedLevel@ GetLinearCampaignSave(string campaign_id) {
    return save_file.GetSave(campaign_id,"linear_campaign","");
}

SavedLevel@ GetLinearCampaignSave() {
    return GetLinearCampaignSave(GetCurrCampaignID());
}

SavedLevel@ GetLinearLevelSave(string level_id) {
    return GetLinearLevelSave(GetCurrCampaignID(),level_id);
}

SavedLevel@ GetLinearLevelSave(string campaign_id,string level_id) {
    return save_file.GetSave(campaign_id, "linear_campaign",level_id);
}

bool IsLevelUnlocked(LevelInfo@ level ) {
    return IsLevelUnlocked(level.id);
}

bool IsLevelUnlocked( string level_name ) {
    SavedLevel @campaign = GetLinearCampaignSave();
    for( uint i = 0; i < campaign.GetArraySize("unlocked_levels"); i++ ) {
        if( campaign.GetArrayValue("unlocked_levels",i) == level_name ) {
            return true;
        }
    }
    return false;
}

bool IsLastPlayedLevel(LevelInfo@ level){
    SavedLevel @campaign = GetLinearCampaignSave();
    if( campaign.GetValue("last_level_played") == level.id ) {
        return true;
    }
    return false;
}

void SetLevelPlayed(string name) {
    SavedLevel@ level_save = GetLinearLevelSave(name);
    level_save.SetValue("level_played","true");
}

bool GetLevelPlayed(string name) {
    SavedLevel@ level_save = GetLinearLevelSave(name);
    return level_save.GetValue("level_played") == "true";
}

string GetLastLevelPlayed(string campaign_id) {
    return GetLinearCampaignSave(campaign_id).GetValue("last_level_played");
}

void SetLastLevelPlayed(string name) {
    Log(info, "Setting last played level in campaign " + GetCurrCampaignID() + " as " + name);
    GetLinearCampaignSave().SetValue("last_level_played",name);
    GetGlobalSave().SetValue("last_campaign_played",GetCurrCampaignID());
    GetGlobalSave().SetValue("last_level_played",name);
    save_file.WriteInPlace();
}

void LevelFinished(string name) {
    GetLinearCampaignSave().SetValue("last_level_finished",name);
    SavedLevel@ level_save = GetLinearLevelSave(name);

    array<string> valid_options = GetConfigValueOptions("difficulty_preset");
    string current_difficulty = GetConfigValueString("difficulty_preset");
    bool standard_difficulty = false;
    
    for( uint i = 0; i < valid_options.size(); i++ ) {
        if( current_difficulty == valid_options[i] ) {
            standard_difficulty = true;
        } 
    }

    if( standard_difficulty ) {
        bool previously_finished = false;
        for( uint i = 0; i < level_save.GetArraySize("finished_difficulties"); i++ ) {
            if( level_save.GetArrayValue("finished_difficulties", i) == current_difficulty) {
                previously_finished = true;
            }
        }

        if( previously_finished == false ) {
            level_save.AppendArrayValue("finished_difficulties", current_difficulty);
        }
    }

    save_file.WriteInPlace();
}

void UnlockLevel( string name ) {
    Log(info, "Unlocking " + name + " in campaign " + GetCurrCampaignID() ); 
    if( IsLevelUnlocked(name) == false ) {
        SavedLevel @campaign = GetLinearCampaignSave();
        campaign.AppendArrayValue("unlocked_levels",name);
        save_file.WriteInPlace();
    }
}

bool IsLastLevel(string name) {
    Campaign camp = GetCampaign(GetCurrCampaignID());

    array<ModLevel>@ levels = camp.GetLevels();

    if( levels.size() > 0 ) {
        if( levels[levels.size()-1].GetID() == name ) {
            return true;
        }
    } 
    return false;
}

string GetFollowingLevel(string name) {
    Campaign camp = GetCampaign(GetCurrCampaignID());

    array<ModLevel>@ levels = camp.GetLevels();
    
    for( uint i = 0; i < levels.size()-1; i++ ) {
        if( name == levels[i].GetID() ) {
            return levels[i+1].GetID();
        }
    }
    return "";
}

string GetLevelPath(string name) {
    Campaign camp = GetCampaign(GetCurrCampaignID());

    array<ModLevel>@ levels = camp.GetLevels();
    
    for( uint i = 0; i < levels.size(); i++ ) {
        if( name == levels[i].GetID() ) {
            return levels[i].GetPath();
        }
    }
    return "";
}

int GetHighestDifficultyFinished(string name) {
    return GetHighestDifficultyFinished(GetCurrCampaignID(),name);
}

int GetHighestDifficultyFinished(string campaign, string name) {
    int highest = 0;
    SavedLevel@ level_save = GetLinearLevelSave(campaign,name);
    array<string> valid_options = GetConfigValueOptions("difficulty_preset");
    
    for( uint i = 0; i < valid_options.size(); i++ ) {
        for( uint k = 0; k < level_save.GetArraySize("finished_difficulties"); k++ ) {
            if( level_save.GetArrayValue("finished_difficulties", k) == valid_options[i] ) {
                highest = i+1;
            }
        }
    }
    return highest;
}

int GetCurrentDifficulty() {
    array<string> valid_options = GetConfigValueOptions("difficulty_preset");
    string current = GetConfigValueString("difficulty_preset");
    
    for( uint i = 0; i < valid_options.size(); i++ ) {
        if( valid_options[i] == current ) {
            return i+1;
        }
    }
    return 0;
}

int GetHighestDifficultyFinishedCampaign(string campaign_id ) {
    int highest = 0;
    Campaign campaign = GetCampaign(campaign_id);
    array<ModLevel>@ levels = campaign.GetLevels();
    array<string> valid_options = GetConfigValueOptions("difficulty_preset");
    for( uint i = 0; i < valid_options.size(); i++ ) {
        bool all_ok = true;
        for( uint k = 0; k < levels.length(); k++ ) {
            ModLevel level = levels[k];
            if(GetHighestDifficultyFinished(campaign_id,level.GetID()) < int(i+1)) {
                all_ok = false;
            }
        }
        if( all_ok ) {
            highest = i+1;
        }
    }
    return highest;
}
