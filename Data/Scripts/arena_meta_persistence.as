#include "arena_funcs.as"
#include "utility/string_json_injector.as"
#include "utility/json_help.as"
#include "utility/array.as"
#include "arena_meta_persistence_sanity_check.as"

const float MIN_PLAYER_SKILL = 0.5f;
const float MAX_PLAYER_SKILL = 1.9f;

const int SAVEVERSION = 12;  // So we can keep track of older versions

// Just for fun let's have some random name -- total non-cannon 
array<string> firstNames = {"P'teth", "Greah", "Smugli", "Mec", "Jinx", "Malchi", 
"Fetla", "Qil", "Fet", "Vri", "Tenda", "Kwell", "Kanata", "Poi", "Wit", "Scar", "Trip", 
"Dreda", "Leki", "Yog", "Te-te", "Pela", "Quor", "Ando", "Imon", "Flip", "Goty", "Tril",
"Dede", "Menta", "Farren", "Gilt", "Gam", "Jer", "Pex", "Prim" };

array<string> lastNameFirsts = { "Bright", "Dark", "Golden", "Swift", "Still", "Quiet", 
"Hard", "Hidden", "Torn", "Silver", "Steel", "Rising" };
array<string> lastNameSeconds = { "water", "dawn", "leaf", "runner", "moon", "sky", 
"rain", "blood", "wind", "river" };

enum ActionIfOperator
{
    ActionOperatorAnd,
    ActionOperatorOr,
    ActionOperatorNot
};

class GlobalArenaData { 
    //Info about campaigns/world maps
    JSON campaignJSON;

    // Info about the save file
    bool dataLoaded = false;    // Have we loaded the data yet?
    bool dataOutdated = false;  // Did the version numbers match?
    JSON profileData;           // Data stored

    // Info about the player
    int profileId = -1;         // Which profile are we working with
    int fan_base;               // How big is the fan base?
    float player_skill;         // What's the player skill?
    array<vec3> player_colors;  // What colors has the player selected
    array<string> states;       // Current states of the player
    array<string> hidden_states; // Non visualized states
    int player_wins;            // Lifetime wins
    int player_loses;           // Lifetime loses
    int player_kills;           // Number of individuals murdered
    int player_kos;             // Number of individuals knocked out
    int player_deaths;     // Number of deaths.
    string character_name;      // Name for this character
    string character_id;        // Character type chosen
    string world_map_id;        // Current world map
    string world_map_node_id;    // Current world map node
    string world_node_id;       // Current node.
    int play_time;              // Play time in seconds
    /**************************/
    //Other data which isn't stored
    string queued_world_node_id;
    int meta_choice_option;
    bool arena_victory;
    bool done_with_current_node;

    /*******************************************************************************************/
    /**
     * @brief  Constructor
     *
     */
    GlobalArenaData() {
        // Make sure there's some values for non-arena campaign mode
        fan_base = 0;
        player_skill = MIN_PLAYER_SKILL;
        player_wins = 0;
        player_loses = 0;
        player_kills = 0;
        player_kos = 0;
        player_deaths = 0;
        character_name = generateRandomName();
        character_id = "";
        world_node_id = "";
        world_map_id = "";
        world_map_node_id = "";
        play_time = 0;

        player_colors.resize(4);

        // Now add the colors
        for( uint i = 0; i < 4; i++ ) {
            player_colors[i] = GetRandomFurColor();
        }

        queued_world_node_id = "";
        meta_choice_option = -1;
        arena_victory = false;
        done_with_current_node = false;

        ReloadJSON();
    }

    void ReloadJSON()
    {
        dictionary filesAndRoots = 
        {
            {"characters",      "Data/Campaign/ArenaMode/StandardCampaign/characters.json"},
            {"states",          "Data/Campaign/ArenaMode/StandardCampaign/states.json"},
            {"hidden_states",   "Data/Campaign/ArenaMode/StandardCampaign/hidden_states.json"},
            {"world_maps",      "Data/Campaign/ArenaMode/StandardCampaign/world_maps.json"},
            {"world_nodes",     "Data/Campaign/ArenaMode/StandardCampaign/world_nodes.json"},
            {"meta_choices",    "Data/Campaign/ArenaMode/StandardCampaign/meta_choices.json"},
            {"arena_instances", "Data/Campaign/ArenaMode/StandardCampaign/arena_instances.json"},
            {"messages",        "Data/Campaign/ArenaMode/StandardCampaign/messages.json"},
            {"actions",         "Data/Campaign/ArenaMode/StandardCampaign/actions.json"}
        };

        JSON j;

        array<string> keys = filesAndRoots.getKeys();

        for( uint i = 0; i < keys.length(); i++ )
        {
            string val;
            filesAndRoots.get(keys[i],val);
            j.parseFile( val );
            campaignJSON.getRoot()[keys[i]] = j.getRoot()[keys[i]];
        }
    } 

    /*******************************************************************************************/
    /**
     * @brief  Generates a random name from preset pieces
     * 
     * @returns name as a string
     *
     */
    string generateRandomName() { 

        return firstNames[ rand() % firstNames.length() ] + " " + 
               lastNameFirsts[ rand() % lastNameFirsts.length() ] +
               lastNameSeconds[ rand() % lastNameSeconds.length() ];
    }

    /*******************************************************************************************/
    /**
     * @brief  Produce a new blank set of profiles, etc
     *
     * @returns A JSON object with the minimum fields filled in
     *
     */
    JSON generateNewProfileSet() {

        JSON newProfileSet;

        newProfileSet.getRoot()["version"] = JSONValue( SAVEVERSION );
        newProfileSet.getRoot()["profiles"] =  JSONValue( JSONarrayValue );
        return newProfileSet; 

    }

    /*******************************************************************************************/
    /**
     * @brief Deletes all the profile data
     *
     */
    void clearProfiles() {
        if(!dataLoaded) {
            return;
        }

        profileData.getRoot()["version"] = JSONValue( SAVEVERSION );
        profileData.getRoot()["profiles"] =  JSONValue( JSONarrayValue );

    }

    /*******************************************************************************************/
    /**
     * @brief  Produce a new blank profile
     *
     * @returns A JSON value object with the minimum fields filled in
     *
     */
    JSONValue generateNewProfile() {

        if(!dataLoaded) {
            DisplayError("Persistence Error", "Can't create a profile without loading profiles first.");
        }
        
        JSONValue newProfile( JSONobjectValue );

        // generate a unique id
        bool idFound = false;
        int newId;

        JSONValue profiles = profileData.getRoot()["profiles"];

        while( !idFound ) {

            // Generate a random id
            newId = rand() % 10000;

            // See if it's being used already
            bool idInList = false;
            for( uint i = 0; i < profiles.size(); ++i ) {
                if( profiles[ i ]["id"].asInt() == newId ) {
                    idInList = true;
                }
            }

            // if not, we're good to go
            if( !idInList ) idFound = true;

        }

        // Write in some default value
        newProfile["id"]                    = JSONValue( newId );
        newProfile["fan_base"]              = JSONValue( 0 );
        newProfile["player_skill"]          = JSONValue( MIN_PLAYER_SKILL );
        newProfile["player_colors"]         = JSONValue( JSONarrayValue );
        newProfile["player_wins"]           = JSONValue( 0 );
        newProfile["player_loses"]          = JSONValue( 0 );
        newProfile["player_kills"]          = JSONValue( 0 );
        newProfile["player_kos"]            = JSONValue( 0 );
        newProfile["player_deaths"]         = JSONValue( 0 );
        newProfile["character_name"]        = JSONValue( generateRandomName() );
        newProfile["fans"]                  = JSONValue( 0 );
        newProfile["states"]                = JSONValue( JSONarrayValue );
        newProfile["hidden_states"]         = JSONValue( JSONarrayValue );
        newProfile["character_id"]          = JSONValue( "" );
        newProfile["world_node_id"]         = JSONValue( "" );
        newProfile["world_map_id"]          = JSONValue( "" );
        newProfile["world_map_node_id"]     = JSONValue( "" );
        newProfile["play_time"]             = JSONValue( 0 );
        newProfile["pronoun"]               = JSONValue( JSONobjectValue );
        newProfile["pronoun"]["she"]        = JSONValue( "he" );
        newProfile["pronoun"]["her"]        = JSONValue( "his" );
        newProfile["pronoun"]["herself"]    = JSONValue( "himself" );

        // Now add the colors
        for( uint i = 0; i < 4; i++ ) {
            
            JSONValue colorTriplet( JSONarrayValue );

            vec3 newRandomColor = GetRandomFurColor();

            colorTriplet.append( JSONValue( newRandomColor.x ) );
            colorTriplet.append( JSONValue( newRandomColor.y ) );
            colorTriplet.append( JSONValue( newRandomColor.z ) );

            newProfile[ "player_colors" ].append( colorTriplet );   
        }

        return newProfile;
    
    }

    /*******************************************************************************************/
    /**
     * @brief  Copy from the JSON structure to the member variables
     * 
     * @param targetId Id to load 
     *
     */
    void setDataFrom( int targetId ) {

        JSONValue profiles = profileData.getRoot()["profiles"];

        bool profileFound = false;

        for( uint i = 0; i < profiles.size(); ++i ) {
            if( profiles[ i ]["id"].asInt() == targetId ) {
                profileFound = true;

                // Copy all the values back
                profileId = targetId;
                fan_base = profiles[ i ][ "fan_base" ].asInt();
                player_skill = profiles[ i ][ "player_skill" ].asFloat();
                player_wins = profiles[ i ][ "player_wins" ].asInt();
                player_loses = profiles[ i ][ "player_loses" ].asInt();
                player_kills = profiles[ i ][ "player_kills" ].asInt();
                player_kos = profiles[ i ][ "player_kos" ].asInt();
                player_deaths = profiles[ i ][ "player_deaths" ].asInt();
                character_name = profiles[ i ][ "character_name" ].asString();
                character_id = profiles[ i ][ "character_id" ].asString();
                world_node_id = profiles[ i ][ "world_node_id" ].asString(); 
                world_map_id = profiles[ i ][ "world_map_id" ].asString(); 
                world_map_node_id = profiles[ i ][ "world_map_node_id" ].asString(); 
                play_time = profiles[ i ][ "play_time" ].asInt(); 

                // Combine the color vectors
                for( uint c = 0; c < 4; c++ ) {
                    player_colors[c].x = profiles[ i ][ "player_colors" ][c][0].asFloat();
                    player_colors[c].y = profiles[ i ][ "player_colors" ][c][1].asFloat();
                    player_colors[c].z = profiles[ i ][ "player_colors" ][c][2].asFloat();
                }
                
                states = array<string>();

                for( uint j = 0; j < profiles[i]["states"].size(); j++ )
                {
                    states.insertLast(profiles[i]["states"][j].asString());
                }

                hidden_states = array<string>();

                for( uint j = 0; j < profiles[i]["hidden_states"].size(); j++ )
                {
                    hidden_states.insertLast(profiles[i]["hidden_states"][j].asString());
                }

                // We're done here
                break;  
            }
        }

        // Sanity checking
        if( !profileFound ) {
            DisplayError("Persistence Error", "Profile id " + targetId + " not found in store.");
        }
    }

    /*******************************************************************************************/
    /**
     * @brief  Copy from the JSON structure to the member variables
     *
     */
    void writeDataToProfiles() {
        // Make sure that the data is good
        if( profileId == -1  ) {
            DisplayError("Persistence Error", "Trying to store an uninitialized profile.");
        }

        bool profileFound = false;

        for( uint i = 0; i < profileData.getRoot()["profiles"].size(); ++i ) {
            if( profileData.getRoot()["profiles"][ i ]["id"].asInt() == profileId ) {
                profileFound = true;

                // Copy all the values back
                profileData.getRoot()["profiles"][ i ][ "fan_base" ]        = JSONValue( fan_base );
                profileData.getRoot()["profiles"][ i ][ "player_skill" ]    = JSONValue( player_skill );
                profileData.getRoot()["profiles"][ i ][ "player_wins" ]     = JSONValue( player_wins );
                profileData.getRoot()["profiles"][ i ][ "player_loses" ]    = JSONValue( player_loses );
                profileData.getRoot()["profiles"][ i ][ "player_kills" ]    = JSONValue( player_kills );
                profileData.getRoot()["profiles"][ i ][ "player_kos" ]      = JSONValue( player_kos );
                profileData.getRoot()["profiles"][ i ][ "player_deaths" ]   = JSONValue( player_deaths );
                profileData.getRoot()["profiles"][ i ][ "character_name" ]  = JSONValue( character_name );
                profileData.getRoot()["profiles"][ i ][ "character_id" ]    = JSONValue( character_id );
                profileData.getRoot()["profiles"][ i ][ "world_node_id" ]   = JSONValue( world_node_id );
                profileData.getRoot()["profiles"][ i ][ "world_map_node_id"]= JSONValue( world_map_node_id );
                profileData.getRoot()["profiles"][ i ][ "play_time" ]       = JSONValue( play_time );
                

                // Unpack the color vectors
                for( uint c = 0; c < 4; c++ ) {
                    profileData.getRoot()["profiles"][ i ][ "player_colors" ][c][0] = JSONValue( player_colors[c].x );
                    profileData.getRoot()["profiles"][ i ][ "player_colors" ][c][1] = JSONValue( player_colors[c].y );
                    profileData.getRoot()["profiles"][ i ][ "player_colors" ][c][2] = JSONValue( player_colors[c].z );
                }

                profileData.getRoot()["profiles"][ i ][ "states" ] = JSONValue( JSONarrayValue );
                for( uint j = 0; j < states.length(); j++ )
                {
                    profileData.getRoot()["profiles"][ i ][ "states" ].append(JSONValue(states[j]));
                }

                profileData.getRoot()["profiles"][ i ][ "hidden_states" ] = JSONValue( JSONarrayValue );
                for( uint j = 0; j < hidden_states.length(); j++ )
                {
                    profileData.getRoot()["profiles"][ i ][ "hidden_states" ].append(JSONValue(hidden_states[j]));
                }

                // We're done here
                break;  
            }
        }

        // Sanity checking
        if( !profileFound ) {
            DisplayError("Persistence Error", "Profile id " + profileId + " not found in store.");
        }
    }

    /*******************************************************************************************/
    /**
     * @brief Adds a newly created profile to the profile set
     *
     * Checks to see if the id already exists, if so replaces it
     *
     * Not that this function does not activate the newly added profile as the current one
     * 
     * @param newProfile JSON value of the new profile 
     *
     */
    void addProfile( JSONValue newProfile ) {
        // check to see if this profile already exists
        for( uint i = 0; i < profileData.getRoot()["profiles"].size(); ++i ) {
            if( newProfile["id"].asInt() == profileData.getRoot()["profiles"][ i ]["id"].asInt() ) {
                profileData.getRoot()["profiles"][ i ] = newProfile;
                return;
            }
        }

        // if we got this far, it's a new one, so just append it
        profileData.getRoot()["profiles"].append( newProfile );

    }

    /*******************************************************************************************/
    /**
     * @brief  Removes a profile from the store
     *  
     * @param targetProfileId id of the profile to remove
     *
     */
    void removeProfile( int targetProfileId ) {

        // Find the profile in the array
        int targetProfileIndex = -1;
        for( uint i = 0; i < profileData.getRoot()["profiles"].size(); ++i ) {
            if( profileData.getRoot()["profiles"][ i ]["id"].asInt() == targetProfileId ) {
                targetProfileIndex = i;
                break;
            }
        }

        // Throw an error if not found
        if( targetProfileIndex == -1 ) {
            DisplayError("Persistence Error", "Cannot find profile " + targetProfileId + " for deletion");
        }

        // Do the removal 
        profileData.getRoot()["profiles"].removeIndex(targetProfileIndex);

    }

    /*******************************************************************************************/
    /**
     * @brief  Get the profile information by id 
     * 
     * @param requestId the id of the profile 
     *
     * @returns array of profile ids (integers)
     *
     */
    array<int> getProfileIds() {
        array<int> profileIds;

        for( uint i = 0; i < profileData.getRoot()["profiles"].size(); ++i ) {
            profileIds.insertLast( profileData.getRoot()["profiles"][ i ]["id"].asInt() );
        }
        
        return profileIds;

    }

    int getProfileIndexFromId( int id )
    {
        array<int> profileIds = getProfileIds();
        return profileIds.find(id);
    }

    /*******************************************************************************************/
    /**
     * @brief  Gets a *copy* of the profile data 
     * 
     * @returns The profile data as a JSON object
     *
     */
    JSONValue getProfiles() {
       if(!dataLoaded) {
           DisplayError("Persistence Error", "Cannot get profiles if data is not loaded");
       }
       return profileData.getRoot()["profiles"];
    }

    /**
     * @brief Get a copy of the currently selection profile
     * 
     * @returns The currently active profiles JSON object, will write current cached state to JSONValue first.
     */
    JSONValue getCurrentProfile() {
        writeDataToProfiles();
        for( uint i = 0; i < profileData.getRoot()["profiles"].size(); ++i ) {
            if( profileData.getRoot()["profiles"][ i ]["id"].asInt() == profileId )
            {
                return profileData.getRoot()["profiles"][ i ];
            }
        }
        return JSONValue();
    }


    /*******************************************************************************************/
    /**
     * @brief  Read the data from disk and if blank, set things up
     * 
     */
    void ReadPersistentInfo() {
        SavedLevel @saved_level = save_file.GetSavedLevel("arena_progress");
        
        // First we determine if we have a session -- if not we're not going to read data 
        JSONValue sessionParams = getSessionParameters();

        if( !sessionParams.isMember("started") ) {
            // Nothing is started, so we shouldn't actually read the data
            return;
        }

        // read in campaign_started
        string profiles_str = saved_level.GetValue("arena_profiles");

        if( profiles_str == "" ) {
            profileData = generateNewProfileSet();
        }
        else {

            // Parse the JSON
            if( !profileData.parseString( profiles_str ) ) {
                DisplayError("Persistence Error", "Unable to parse profile information");
            }

            // Now check the version 
            if( profileData.getRoot()[ "version" ].asInt() == SAVEVERSION ) {
                dataOutdated = false;
            }
            else {
                // We have a save version from a previous incarnation 
                // For now we'll just nuke it and restart
                dataOutdated = true;
                profileData = generateNewProfileSet();
            }

        } 

        dataLoaded = true;

        // Now see if we have a profile in this session -- if so load it 
        if( sessionParams.isMember("profile_id") ) {
            // Get the id from the session and load it into the usable values
            int currentProfileId = sessionParams["profile_id"].asInt();
            setDataFrom( currentProfileId ); // This will throw an error if not found
        }

    }

    /*******************************************************************************************/
    /**
     * @brief  Save the profile data to disk 
     * 
     * @param moveDataToStore Is there data in the variables that should be moved to the store
     *
     */
    void WritePersistentInfo( bool moveDataToStore = true ) {

        // Make sure we've got information to write -- this is not an error
        if( !dataLoaded ) return;

        // Make sure our current data has been written back to the JSON structure
        if( moveDataToStore ) {
            Print("Writing data to profile\n");
            writeDataToProfiles(); // This'll do nothing if we haven't set a profile
        }

        SavedLevel @saved_level = save_file.GetSavedLevel("arena_progress");
        
        // Render the JSON to a string
        string profilesString = profileData.writeString(false);

        // Set the value and write to disk
        saved_level.SetValue( "arena_profiles", profilesString );        
        save_file.WriteInPlace();
    
    }

    /*******************************************************************************************/
    /**
     * @brief  Begins a new session — overwrites any data that is there
     * 
     */
    void startNewSession() {
        JSONValue thisSession = getSessionParameters();
        thisSession["started"] = JSONValue( "true" );
        setSessionParameters( thisSession );
    }

    /*******************************************************************************************/
    /**
     * @brief  Sets which profile this session is using 
     *   
     * @param _profileId Which profile id will be using for this session
     *
     */
    void setSessionProfile(int _profileId) {
        JSONValue thisSession = getSessionParameters();
        thisSession["profile_id"] = JSONValue( _profileId );
        setSessionParameters( thisSession );
    }    

    /*******************************************************************************************/
    /**
     * @brief  Gets which profile this session is using 
     *   
     * @returns The profile id for this session
     *
     */
    int getSessionProfile() {
        JSONValue thisSession = getSessionParameters();
        if( !thisSession.isMember("profile_id") ) {
            return -1;
        }
        else {
            return thisSession["profile_id"].asInt();
        }
    }

    void clearSessionProfile()
    {
        JSONValue thisSession = getSessionParameters();
        thisSession["profile_id"] = JSONValue(-1); 
        setSessionParameters( thisSession );
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

            // write it back
            saved_level.SetValue("arena_session", arena_session_str );
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


    bool EvaluateActionIfNode( JSONValue node, string result )
    {
        //Array value means that it's an operator first, then one or more subevals.
        if( node.type() == JSONarrayValue )
        {
            if( node.size() >= 2 )
            {
                bool val = false;
                ActionIfOperator op = ActionOperatorAnd;

                if( node[0].type() == JSONstringValue )
                {
                    string str = node[0].asString();

                    if( str == "or" )
                    {
                        op = ActionOperatorOr;
                    }
                    else if( str == "and" )
                    {
                        op = ActionOperatorAnd;
                    }
                    else if( str == "not" )
                    {
                        op = ActionOperatorNot;
                    }
                    else
                    {
                        Log( error, "Unknown action-if operator " + str );
                    }
                }
                else
                {
                    Log( error, "First value in if-action-array isn't a string, as expected" );
                }
                
                if( op == ActionOperatorNot )
                {
                    if( node.size() == 2 )
                    {
                        val = !EvaluateActionIfNode(node[1],result);
                    }
                    else
                    {
                        DisplayError("Invalid not operator", "not operator is followed by more than one value or no value, has to be 1.");
                    }
                }
                else
                {
                    for( uint i = 1;  i < node.size(); i++ )
                    {
                        if( i == 1 )
                        {
                            val = EvaluateActionIfNode(node[i], result);
                        }   
                        else
                        {
                            if( op == ActionOperatorAnd )
                            {
                                val = val && EvaluateActionIfNode(node[i], result);
                            }
                            else if( op == ActionOperatorOr )
                            {
                                val = val || EvaluateActionIfNode(node[i], result);
                            }
                            else
                            {
                                Log( error, "Unknown if-action operator state" ); 
                            }
                        }

                        //We can do some potential early outs due to the nature of these operators.
                        if( op == ActionOperatorAnd )
                        {
                            if( !val )
                                break;
                        }
                        else if( op == ActionOperatorOr )
                        {
                            if( val )
                                break;
                        }
                    }
                }
                return val;
            }
            else
            {
                Log( error, "if-action-array doesn't contain enough elements" );
                return false;
            }

        }
        else if( node.type() == JSONbooleanValue )
        {
            return node.asBool();
        }
        else if( node.type() == JSONobjectValue )
        {
            array<string>@ memberNames = node.getMemberNames();

            if( memberNames.length() == 1 )
            { 
                string memb = memberNames[0];
                bool ret_value = false;

                if( memb == "if_result_match_any" ) {
                    ret_value = false;
                    JSONValue if_result_match_any = node["if_result_match_any"];
                    for( uint j = 0; j < if_result_match_any.size(); j++ )
                    {
                        if( if_result_match_any[j].asString() == result )
                        {
                            Log( info, "Match on result " + if_result_match_any[j].asString() + " and " + result );
                            ret_value = true;
                        }
                    }
                } else if(memb == "if_eq" ) {
                    JSONValue if_eq = node["if_eq"];
                    for( uint k = 0; k < if_eq.size(); k++ )
                    {
                        for( uint j = 1; j < if_eq[k].size(); j++  )
                        {
                            string s1 = resolveString(if_eq[k][j-1].asString());
                            string s2 = resolveString(if_eq[k][j].asString());
                            if( s1 == s2 )
                            {
                                Log( info, "Evaluated \"" + s1 + "\" == \"" + s2 + "\" to true" );
                                ret_value = true;
                            }
                            else
                            {
                                Log( info, "Evaluated \"" + s1 + "\" == \"" + s2 + "\" to false" );
                                ret_value = false;
                            }
                        }
                    }
                } else if( memb == "if_gt" ) {
                    JSONValue if_gt = node["if_gt"];
                    for( uint k = 0; k < if_gt.size(); k++ )
                    {
                        for( uint j = 1; j < if_gt[k].size(); j++  )
                        {
                            string s1 = resolveString(if_gt[k][j-1].asString());
                            string s2 = resolveString(if_gt[k][j].asString());

                            uint c1 = 0;
                            double v1 = parseFloat(s1,c1);
                            uint c2 = 0;
                            double v2 = parseFloat(s2,c2);
                            
                            if( c1 == s1.length() && c2 == s2.length() )
                            {
                                if( v1 > v2 )
                                {
                                    Log( info, "Evaluated \"" + s1 + "\" > \"" + s2 + "\" to true" );
                                    ret_value = true;
                                }
                                else
                                {
                                    Log( info, "Evaluated \"" + s1 + "\" > \"" + s2 + "\" to false" );
                                    ret_value = false;
                                }
                            }
                            else
                            {
                                Log( error, "Malformed input for evaluating \"" + s1 + "\" > \"" + s2 + "\"" );
                            }
                        }
                    }
                } else if( memb ==  "chance" ) {
                        JSONValue chance = node["chance"];
                        double r = ((rand()%1001)/1000.0f);
                        ret_value = ( r <= chance.asDouble());
                } else if( memb == "if_has_state" ) {
                        ret_value = global_data.hasState( node["if_has_state"].asString() );
                } else if( memb == "if_has_hidden_state" ) {
                        ret_value = global_data.hasHiddenState( node["if_has_hidden_state"].asString() );
                } else if( memb == "if_current_world_node_is" ) {
                        ret_value = (global_data.world_node_id == node["if_current_world_node_is"].asString());
                } else {
                    DisplayError("Unknown action if-clause", "Unknown action if-clause \"" + memberNames[0] + "\"");
                }
                return ret_value;
            }
            else
            {
                DisplayError( "Action data error", "Invalid number of objects in action if-clause, only one per object is allowed." );
                return false;
            }
        }
        else
        {
            DisplayError( "Action data error", "Invalid node in action if statement for node " + node["id"].asString() );
            PrintCallstack();
            return false;
        }
    }

    void ApplyWorldNodeActionClause(JSONValue action_clause, string result)
    {
        JSONValue set_world_node = action_clause["set_world_node"];
        if( set_world_node.type() != JSONnullValue )
        {
            queued_world_node_id = set_world_node.asString();
            Log( info, "Setting next world_node to " + world_node_id );
        }
        
        JSONValue add_states = action_clause["add_states"];
        if( add_states.type() != JSONnullValue )
        {
            for( uint j = 0; j < add_states.size(); j++ )
            {
                addState( add_states[j].asString() );
            }
        }

        JSONValue lose_states = action_clause["lose_states"];
        if( lose_states.type() != JSONnullValue )
        {
            for( uint j = 0; j < lose_states.size(); j++ )
            {
                removeState( lose_states[j].asString() );
            }
        }

        JSONValue add_hidden_states = action_clause["add_hidden_states"];
        if( add_hidden_states.type() != JSONnullValue )
        {
            for( uint j = 0; j < add_hidden_states.size(); j++ )
            {
                addHiddenState( add_hidden_states[j].asString() );
            }
        }

        JSONValue lose_hidden_states = action_clause["lose_hidden_states"];
        if( lose_hidden_states.type() != JSONnullValue )
        {
            for( uint j = 0; j < lose_hidden_states.size(); j++ )
            {
                removeHiddenState( lose_hidden_states[j].asString() );
            }
        }

        JSONValue actions = action_clause["actions"];
        if( actions.type() != JSONnullValue )
        {
            ProcessActionNodeArray( actions, result );
        }
    }

    void ProcessActionNode( JSONValue action_node, string result )
    {

        Log(info, "Processing action node: \"" + action_node["id"].asString() + "\"");

        JSONValue action_if = action_node["if"];
        JSONValue action_then = action_node["then"];
        JSONValue action_else = action_node["else"];

        if( EvaluateActionIfNode( action_if, result ) )
        {
            if( action_then.type() != JSONnullValue )
            {
                Log( info, "Running " + action_node["id"].asString() + " then clause" );
                ApplyWorldNodeActionClause(action_then,result);
            }
            else
            {
                Log( info, "Won't run " + action_node["id"].asString() );
            }
        }
        else
        {
            if( action_else.type() != JSONnullValue )
            {
                Log( info, "Running " + action_node["id"].asString() + " else clause" );
                ApplyWorldNodeActionClause(action_else,result);
            }
            else
            {
                Log( info, "Won't run " + action_node["id"].asString() );
            }
        }
    }

    void ProcessActionNodeArray( JSONValue actions, string result )
    {
        for( uint i = 0; i < actions.size(); i++ )
        {
            JSONValue action = actions[i];

            if( action.type() == JSONstringValue )
            {
                ProcessActionNode(getAction(action.asString()),result);
            }
            else if( action.type() == JSONobjectValue )
            {
                ProcessActionNode(action,result);
            }
        }
    }

    void ResolveWorldNode()
    {
        JSONValue world_node = getCurrentWorldNode();
        JSONValue character = getCurrentCharacter();

        if( queued_world_node_id != "" )
        {
            Log(info, "Trying to resolve pre_action for node: \"" + world_node["id"].asString() + "\"");
            world_node_id = queued_world_node_id;
            queued_world_node_id = "";
            ProcessActionNodeArray(character["global_pre_actions"], "");
            ProcessActionNodeArray(world_node["pre_actions"], "");
            ProcessActionNodeArray(character["global_post_actions"], "");

            done_with_current_node = false;
            ResolveWorldNode();
        }
        else if( done_with_current_node )
        {
            Log(info, "Trying to resolve post_action for node: \"" + world_node["id"].asString() + "\"");
            if( world_node["type"].asString() == "meta_choice" )
            { 
                JSONValue meta_choice = getMetaChoice(world_node["target_id"].asString());

                if( meta_choice_option >= 0 && meta_choice_option < int(meta_choice["options"].size()) )
                {
                    JSONValue result = meta_choice["options"][meta_choice_option];
                    Log( info, "Got result " + result["result"].asString() + "\n" );

                    ProcessActionNodeArray(character["global_pre_actions"], result["result"].asString());
                    ProcessActionNodeArray(world_node["post_actions"], result["result"].asString());
                    ProcessActionNodeArray(character["global_post_actions"], result["result"].asString());
                }
                else
                {
                    Log(error, "Invalid meta choice option" );
                }
            }
            else  if( world_node["type"].asString() == "message" ) 
            {
                ProcessActionNodeArray(character["global_pre_actions"], "continue");
                ProcessActionNodeArray(world_node["post_actions"], "continue");
                ProcessActionNodeArray(character["global_post_actions"], "continue");
            }
            else if( world_node["type"].asString() == "arena_instance" )
            {
                ProcessActionNodeArray(character["global_pre_actions"], arena_victory ? "win" : "loss");
                ProcessActionNodeArray(world_node["post_actions"], arena_victory ? "win" : "loss");
                ProcessActionNodeArray(character["global_post_actions"], arena_victory ? "win" : "loss");
            }
            else
            {
                Log(error, "Unknown world_node type \""  + world_node["type"].asString() + "\"" );
            }

            if( queued_world_node_id == "" )
            { 
                DisplayError( "Arena Mode", "We were not given a new world_node from actions this means we are stuck here.");
            }
            done_with_current_node = false;
            ResolveWorldNode();
        }
    }

    bool hasState( string state )
    {
        for( uint i = 0; i < states.length(); i++ )
        {
            if( states[i] == state )
                return true;
        }
        return false;
    }

    void removeState( string state )
    {
        if(hasState(state))
        {
            for( uint i = 0; i < states.length(); i++ )
            {
                if( states[i] == state )
                {
                    states.removeAt(i);
                    i--;
                }
            }
        }

        WritePersistentInfo();
    }

    void addState( string state )
    {
        if( getState( state ).type() != JSONnullValue )
        {
            if( not hasState( state ) )
            {
                states.insertLast(state);
            } 
            WritePersistentInfo();
        }
        else
        {
            Log( error, "State " + state + " isn't declared\n") ;
        }
    }

    bool hasHiddenState( string hidden_state )
    {
        for( uint i = 0; i < hidden_states.length(); i++ )
        {
            if( hidden_states[i] == hidden_state )
                return true;
        }
        return false;
    }

    void removeHiddenState( string hidden_state )
    {
        if(hasHiddenState(hidden_state))
        {
            for( uint i = 0; i < hidden_states.length(); i++ )
            {
                if( hidden_states[i] == hidden_state )
                {
                    hidden_states.removeAt(i);
                    i--;
                }
            }
        }
        WritePersistentInfo();
    }

    void addHiddenState( string hidden_state )
    {
        if( getHiddenState( hidden_state ).type() != JSONnullValue )
        {
            if( not hasHiddenState( hidden_state ) )
            {
                hidden_states.insertLast(hidden_state); 
            }
            WritePersistentInfo();
        }
        else
        {
            Log( error, "Hidde state " + hidden_state + " isn't declared\n") ;
        }
    }

    /**
    * @brief Contains the character type data 
    *
    */
    JSONValue getCharacters()
    {
        return campaignJSON.getRoot()["characters"]; 
    }

    /**
    * @brief Contains state information
    */
    JSONValue getStates()
    {
        return campaignJSON.getRoot()["states"];
    }

    JSONValue getHiddenStates()
    {
        return campaignJSON.getRoot()["hidden_states"];
    }

    JSONValue getMetaChoices()
    {
        return campaignJSON.getRoot()["meta_choices"];
    }

    JSONValue getWorldMaps()
    {
        return campaignJSON.getRoot()["world_maps"];
    }

    JSONValue getArenaInstances()
    {
        return campaignJSON.getRoot()["arena_instances"];
    }

    JSONValue getMessages()
    {
        return campaignJSON.getRoot()["messages"];
    }
    
    JSONValue getActions()
    {
        return campaignJSON.getRoot()["actions"];
    }

    JSONValue getWorldNodes()
    {
        return campaignJSON.getRoot()["world_nodes"]; 
    }

    JSONValue getState( string id )
    {
        JSONValue states = getStates();
        for( uint i = 0; i < states.size(); i++ )
        {
            if( states[i]["id"].asString() == id )
            {
                return states[i];
            }
        } 
        return JSONValue();
    }

    JSONValue getHiddenState( string id )
    {
        JSONValue hidden_states = getHiddenStates();
        for( uint i = 0; i < hidden_states.size(); i++ )
        {
            if( hidden_states[i]["id"].asString() == id )
            {
                return hidden_states[i];
            }
        } 
        return JSONValue();
    }

    JSONValue getWorldMap( string id )
    {
        JSONValue worldmaps = getWorldMaps();

        for( uint i = 0; i < worldmaps.size(); i++ )
        {
            if( worldmaps[i]["id"].asString() == id )
            {
                return worldmaps[i];
            } 
        }
        return JSONValue();
    }

    JSONValue getCharacter( string id )
    {
        JSONValue characters = getCharacters();

        for( uint i = 0; i < characters.size(); i++ )
        {
            if( characters[i]["id"].asString() == id )
            {
                return characters[i];
            }
        }
        return JSONValue();
    } 

    JSONValue getMessage( string id )
    {
        JSONValue messages = getMessages();
    
        for( uint i = 0; i < messages.size(); i++ )
        {
            if( messages[i]["id"].asString() == id )
            {
                return messages[i];
            }
        }
        return JSONValue();
    }

    JSONValue getCurrentCharacter()
    {
        return getCharacter(character_id);
    }

    JSONValue getCurrentWorldMap()
    {
        return getWorldMap(world_map_id);
    }

    JSONValue getWorldNode(string node_id )
    {
        JSONValue world_nodes = getWorldNodes();
        for( uint i = 0; i < world_nodes.size(); i++ )
        {
            if( world_nodes[i]["id"].asString() == node_id )
            {
                return world_nodes[i];
            }
        }

        return JSONValue();
    }

    JSONValue getMetaChoice(string id)
    {
        JSONValue meta_choices = getMetaChoices();

        for( uint i = 0; i < meta_choices.size(); i++ )
        {
            if( meta_choices[i]["id"].asString() == id )
            {
                return meta_choices[i];
            }
        } 

        return JSONValue();
    }

    JSONValue getArenaInstance( string id )
    {
        JSONValue arena_instances = getArenaInstances(); 

        for( uint i = 0; i < arena_instances.size(); i++ )
        {
            if( arena_instances[i]["id"].asString() == id )
            {
                return arena_instances[i];
            }
        }

        return JSONValue();
    }

    JSONValue getAction( string id )
    {
        JSONValue actions = getActions(); 

        for( uint i = 0; i < actions.size(); i++ )
        {
            if( actions[i]["id"].asString() == id )
            {
                return actions[i];
            }
        }

        return JSONValue();
    }

    JSONValue getCurrentWorldNode()
    {
        return getWorldNode( world_node_id );
    }

    /**
     * Resolve a string and fill it with data from the json data structures
     */
    string resolveString( string input )
    {
        StringJSONInjector sjsoni;    

        sjsoni.setRoot( "profile", getCurrentProfile() );

        return sjsoni.evaluate(input);
    }
}

GlobalArenaData global_data;
