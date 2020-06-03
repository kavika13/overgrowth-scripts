#include "arena_funcs.as"

const float MIN_PLAYER_SKILL = 0.5f;
const float MAX_PLAYER_SKILL = 1.9f;

class GlobalArenaData { 

    int fan_base;
    float player_skill;
    array<vec3> player_colors;
    
    bool campaign_started; // is there progress saved?

    GlobalArenaData() {
        Reset();
    }

    void ReadPersistentInfo() {
        SavedLevel @saved_level = save_file.GetSavedLevel("arena_progress");
        
        // read in campaign_started
        string campaign_started_str = saved_level.GetValue("campaign_started");

        if(campaign_started_str == "true") {
            campaign_started = true;
        }
        else {
            campaign_started = false;   
        }

        string fan_base_str = saved_level.GetValue("fan_base");
        if(fan_base_str == "") {
            fan_base = 0;
        } else {
            fan_base = atoi(fan_base_str);
        }
        string player_color_str = saved_level.GetValue("player_colors");
        if(player_color_str == "") {
            SetPlayerColors();
        } else {
            TokenIterator token_iter;
            token_iter.Init();
            player_colors.resize(4);
            for(int i=0; i<4; ++i){
                for(int j=0; j<3; ++j){
                    token_iter.FindNextToken(player_color_str);
                    player_colors[i][j] = atof(token_iter.GetToken(player_color_str));
                }
            }
        }

        string player_skill_str = saved_level.GetValue("player_skill");
        if(player_skill_str == "") {
            player_skill = MIN_PLAYER_SKILL;
        } else {
            player_skill = atof(player_skill_str);
        }

    }

    void WritePersistentInfo() {
        
        SavedLevel @saved_level = save_file.GetSavedLevel("arena_progress");
        saved_level.SetValue("fan_base",""+fan_base);
        string player_colors_str;
        
        for(int i=0; i<4; ++i){
            for(int j=0; j<3; ++j) {
                player_colors_str += player_colors[i][j];
                player_colors_str += " ";
            }
        }
        
        saved_level.SetValue("player_colors",""+player_colors_str);
        saved_level.SetValue("player_skill",""+player_skill);
        
        if( campaign_started ) {
            saved_level.SetValue("campaign_started", "true");
        }
        else {
            saved_level.SetValue("campaign_started", "false");
        }

        save_file.WriteInPlace();
    
    }

    void SetPlayerColors() {
        player_colors.resize(4);
        player_colors[0] = GetRandomFurColor();
        player_colors[1] = GetRandomFurColor();
        player_colors[2] = GetRandomFurColor();
        player_colors[3] = GetRandomFurColor();
    }

    void Reset() {
        fan_base = 0;
        player_skill = MIN_PLAYER_SKILL;
        
        player_colors.resize(4);
        player_colors[0] = GetRandomFurColor();
        player_colors[1] = GetRandomFurColor();
        player_colors[2] = GetRandomFurColor();
        player_colors[3] = GetRandomFurColor();

        campaign_started = false;

    }

    /*******************************************************************************************/
    /**
     * @brief  Gets the JSON object representing the current arena session
     *  
     */
    JSONValue getSessionParameters() {
        SavedLevel @saved_level = save_file.GetSavedLevel("arena_progress");
        
        // read in the text for the session object
        string arena_session_str = saved_level.GetValue("arena_session");

        // sanity check 
        if( arena_session_str == "" ) {
            arena_session_str = "{}";
        }

        JSON sessionJSON;             

        // sanity check
        if( !sessionJSON.parseString( arena_session_str ) ) {
            DisplayError("Persistence Error", "Unable to parse session information");
        }

        return sessionJSON.getRoot();

    }

    /*******************************************************************************************/
    /**
     * @brief Stores the JSON representation for the current session
     *  
     */
    void setSessionParameters( JSONValue session ) {
        SavedLevel @saved_level = save_file.GetSavedLevel("arena_progress");
        
        // set the value to the stringified JSON
        JSON sessionJSON;
        sessionJSON.getRoot() = session;
        string arena_session_str = sessionJSON.writeString(false);
        saved_level.SetValue("arena_session", arena_session_str );

        // write out the changes
        save_file.WriteInPlace();

    }

}

GlobalArenaData global_data; 