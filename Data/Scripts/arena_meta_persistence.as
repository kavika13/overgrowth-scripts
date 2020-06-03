#include "arena_funcs.as"

const float MIN_PLAYER_SKILL = 0.5f;
const float MAX_PLAYER_SKILL = 1.9f;

const int SAVEVERSION = 1;  // So we can keep track of older versions


// Just for fun let's have some random name -- total non-cannon 
array<string> firstNames = {"P'teth", "Greah", "Smugli", "Mec", "Jinx", "Malchi", 
"Fetla", "Qil", "Fet", "Vri", "Tenda", "Kwell", "Kanata", "Poi", "Wit", "Scar", "Trip", 
"Dreda", "Leki", "Yog", "Te-te", "Pela", "Quor", "Ando", "Imon", "Flip", "Goty", "Tril",
"Dede", "Menta", "Farren", "Gilt", "Gam", "Jer", "Pex", "Prim" };

array<string> lastNameFirsts = { "Bright", "Dark", "Golden", "Swift", "Still", "Quiet", 
"Hard", "Hidden", "Torn", "Silver", "Steel", "Rising" };
array<string> lastNameSeconds = { "water", "dawn", "leaf", "runner", "moon", "sky", 
"rain", "blood", "wind", "river" };

class GlobalArenaData { 

    // Info about the save file
    bool dataLoaded = false;    // Have we loaded the data yet?
    bool dataOutdated = false;  // Did the version numbers match?
    JSON profileData;           // Data stored

    // Info about the player
    int profileId = -1;         // Which profile are we working with
    int fan_base;               // How big is the fan base?
    float player_skill;         // What's the player skill?
    array<vec3> player_colors;  // What colors has the player selected
    int player_wins;            // Lifetime wins
    int player_loses;           // Lifetime loses
    string character_name;       // Name for this character

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
        character_name = generateRandomName();

        player_colors.resize(4);

        // Now add the colors
        for( uint i = 0; i < 4; i++ ) {
            player_colors[i] = GetRandomFurColor();
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
        newProfile[ "id" ] = JSONValue( newId );
        newProfile[ "fan_base" ] = JSONValue( 0 );
        newProfile[ "player_skill" ] = JSONValue( MIN_PLAYER_SKILL );
        newProfile[ "player_colors" ] = JSONValue( JSONarrayValue );
        newProfile[ "player_wins" ] = JSONValue( 0 );
        newProfile[ "player_loses" ] = JSONValue( 0 );
        newProfile[ "character_name" ] = JSONValue( generateRandomName() );

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
                character_name = profiles[ i ][ "character_name" ].asString();

                // Combine the color vectors
                for( uint c = 0; c < 4; c++ ) {
                    
                    player_colors[c].x = profiles[ i ][ "player_colors" ][c][0].asFloat();
                    player_colors[c].y = profiles[ i ][ "player_colors" ][c][1].asFloat();
                    player_colors[c].z = profiles[ i ][ "player_colors" ][c][2].asFloat();

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
                profileData.getRoot()["profiles"][ i ][ "fan_base" ] = JSONValue( fan_base );
                profileData.getRoot()["profiles"][ i ][ "player_skill" ] = JSONValue( player_skill );
                profileData.getRoot()["profiles"][ i ][ "player_wins" ] = JSONValue( player_wins );
                profileData.getRoot()["profiles"][ i ][ "player_loses" ] = JSONValue( player_loses );
                profileData.getRoot()["profiles"][ i ][ "character_name" ] = JSONValue( character_name );

                // Unpack the color vectors
                for( uint c = 0; c < 4; c++ ) {

                    profileData.getRoot()["profiles"][ i ][ "player_colors" ][c][0] = JSONValue( player_colors[c].x );
                    profileData.getRoot()["profiles"][ i ][ "player_colors" ][c][1] = JSONValue( player_colors[c].y );
                    profileData.getRoot()["profiles"][ i ][ "player_colors" ][c][2] = JSONValue( player_colors[c].z );
 
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

}

GlobalArenaData global_data;