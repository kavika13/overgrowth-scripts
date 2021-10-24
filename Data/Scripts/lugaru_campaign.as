
array<string> lugaru_levels = {"LugaruStory/Village.xml",         
                        "LugaruStory/Village_2.xml",      
                        "LugaruStory/Wanderer.xml",    
                        "LugaruStory/Village_3.xml",      
                        "LugaruStory/Clearing.xml",         
                        "LugaruStory/Raider_patrol.xml",  
                        "LugaruStory/Raider_camp.xml",    
                        "LugaruStory/Raider_sentries.xml",
                        "LugaruStory/Raider_base.xml",    
                        "LugaruStory/Raider_base_2.xml",      
                        "LugaruStory/Rocky_hall.xml",     
                        "LugaruStory/Heading_north.xml",  
                        "LugaruStory/Heading_north_2.xml",
                        "LugaruStory/Jack's_camp.xml",    
                        "LugaruStory/Jack's_camp_2.xml",  
                        "LugaruStory/Rocky_hall_2.xml",   
                        "LugaruStory/Rocky_hall_3.xml",   
                        "LugaruStory/To_alpha_wolf.xml",  
                        "LugaruStory/To_alpha_wolf_2.xml",
                        "LugaruStory/Wolf_den.xml",       
                        "LugaruStory/Wolf_den_2.xml",     
                        "LugaruStory/Rocky_hall_4.xml"};  

array<string> lugaru_level_names;

void InitializeLugaruLevelNames() {
    if( lugaru_levels.length() != lugaru_level_names.length() ) {
        lugaru_level_names.removeRange(0,lugaru_level_names.length());
        for( uint i = 0; i < lugaru_levels.length(); i++ ) {
            lugaru_level_names.insertLast(GetLevelName("Data/Levels/" + lugaru_levels[i]));
        }       
    }
}

void FinishedLugaruCampaignLevel(string level_name) {

    InitializeLugaruLevelNames();

    Log(info, "Finished Lugaru Level \"" + level_name + "\"" );
    SavedLevel @level = save_file.GetSavedLevel("lugaru_campaign");

    string current_highest_level = level.GetValue("highest_level");

    Log(info, "Current Lugaru Level id \"" + current_highest_level + "\"" );
    int id_current_highest_level = -1;

    if( current_highest_level != "" ) {
        id_current_highest_level = atoi(current_highest_level);
    }

    int id_new_level = -1;
    Log( info, "level_name: " + level_name );
    for( uint i = 0; i < lugaru_level_names.length(); i++ ) {
        if( level_name == lugaru_level_names[i] ) {
            Log( info, "Matched: " + i );
            id_new_level = i;
        }
    }

    if( id_new_level + 1 > id_current_highest_level ) {
        Log( info, "Setting new highest level id to: " + (id_new_level + 1));
        level.SetValue("highest_level", "" + (id_new_level + 1));  
        save_file.WriteInPlace();
    }
}
