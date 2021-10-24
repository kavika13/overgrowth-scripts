#include "ui_effects.as"
#include "arena_meta_persistence.as"
#include "ui_tools.as"
#include "music_load.as"

MusicLoad ml("Data/Music/menu.xml");

enum MenuGUIState {
    agsDifficulty,
    agsSelectLevel,
    agsNewUser,
    agsConfirmDelete,
    agsSelectUser,
    agsInvalidState,
	agsChallenge
};

class Level
  {
    string name;
    string file;
    vec2 position;

    Level(string _file, string _name, vec2 _position)
    {
        name = _name;
        file = _file;
        position = _position;
    }
	Level(string _file, string _name)
    {
        name = _name;
        file = _file;
    }
};

array<Level@> levels = {Level("LugaruStory/Village.xml",        "Village",          vec2(800,600)),
						Level("LugaruStory/Wonderer.xml",       "Wonderer",         vec2(840,600)),
                        Level("LugaruStory/Village_2.xml",      "Village 2",        vec2(800,600)),
						Level("LugaruStory/Clearing.xml",       "Clearing",         vec2(780,560)),
                        Level("LugaruStory/Raider_patrol.xml",  "Raider Patrol",    vec2(740,520)),
                        Level("LugaruStory/Raider_camp.xml",    "Raider Camp",      vec2(680,480)),
                        Level("LugaruStory/Raider_sentries.xml","Raider Sentries",  vec2(720,460)),
                        Level("LugaruStory/Raider_base.xml",    "Raider Base",      vec2(760,490)),
						Level("LugaruStory/Village_3.xml",      "Village 3",        vec2(800,600)),
                        Level("LugaruStory/Raider_base_2.xml",  "Raider Base 2",    vec2(1,111)),
                        Level("LugaruStory/Old_raider_base.xml","Old Raider Base",  vec2(820,500)),
                        Level("LugaruStory/Village_4.xml",      "Village 4",        vec2(1,231)),
                        Level("LugaruStory/Rocky_hall.xml",     "Rocky Hall",       vec2(880,605)),
                        Level("LugaruStory/Heading_north.xml",  "Heading North",    vec2(1000,455)),
                        Level("LugaruStory/Heading_north_2.xml","Heading North 2",  vec2(1050,370)),
                        Level("LugaruStory/Jack's_camp.xml",    "Jack's Camp",      vec2(1000,300)),
                        Level("LugaruStory/Jack's_camp_2.xml",  "Jack's Camp 2",    vec2(1,1)),
                        Level("LugaruStory/Rocky_hall_2.xml",   "Rocky Hall 2",     vec2(880,605)),
                        Level("LugaruStory/Rocky_hall_3.xml",   "Rocky Hall 3",     vec2(880,605)),
                        Level("LugaruStory/To_alpha_wolf.xml",  "To Alpha Wolf",    vec2(1100,455)),
                        Level("LugaruStory/To_alpha_wolf_2.xml","To Alpha Wolf 2",  vec2(1050,285)),
                        Level("LugaruStory/Wolf_den.xml",       "Wolf Den",         vec2(1000,185)),
                        Level("LugaruStory/Wolf_den_2.xml",     "Wolf Den 2",       vec2(1,1)),

                        Level("LugaruStory/Rocky_hall_4.xml",   "Rocky Hall 4",     vec2(1,1))};

array<Level@> challengelevels = {	Level("LugaruChallenge/lugaru_challenge.xml",	"Challenge Test Level"),
			                        Level("LugaruChallenge/lugaru_challenge2.xml",   "Village 2"),
			                        Level("LugaruChallenge/lugaru_challenge3.xml",   "Wonderer"),
			                        Level("LugaruChallenge/lugaru_challenge4.xml",   "Village 3"),
			                        Level("LugaruChallenge/lugaru_challenge5.xml",   "Clearing"),
			                        Level("LugaruChallenge/lugaru_challenge6.xml",  	"Raider Patrol"),
			                        Level("LugaruChallenge/lugaru_challenge7.xml",   "Raider Camp"),
			                        Level("LugaruChallenge/lugaru_challenge8.xml",	"Raider Sentries"),
			                        Level("LugaruChallenge/lugaru_challenge9.xml",   "Raider Base"),
			                        Level("LugaruChallenge/lugaru_challenge10.xml",  	"Raider Base 2"),
			                        Level("LugaruChallenge/lugaru_challenge11.xml",	"Old Raider Base"),
			                        Level("LugaruChallenge/lugaru_challenge12.xml",   "Village 4"),
			                        Level("LugaruChallenge/lugaru_challenge13.xml",   "Rocky Hall")};

float limitDecimalPoints( float n, int points ) {
    return float( float(int( n * pow( 10, points ) )) / pow( 10, points ) );
}

class MenuGUI : AHGUI::GUI {

    // fancy ribbon background stuff
    float visible = 0.0f;
    float target_visible = 1.0f;

    MenuGUIState currentState = agsSelectUser; // Token for our state machine
    MenuGUIState lastState = agsInvalidState;    // Last seen state, to detect changes

    // Selection screen
    AHGUI::Element@ selectedProfile = null;// Which profile label is selected
    int selectedProfileNum = -1;       // Which profile number is selected
    int showingProfileNum = -1;       // Which profile number is shown
    bool showingProfileDetails = false; // Are we showing profile details?
    int selectedLevel = 0;      // Which arena are we going to load
    int image_preview_size = 600;
    bool dataOutdated = false;
    JSON profileData;
    string difficulty = "";
    string user_name;
    bool dataLoaded = false;
    int profileId = -1;         // Which profile are we working with
    bool showBorders = false;
    int textSize = 60;
    int challengeTextSize = 70;
    vec4 textColor = vec4(0.7, 0.7, 0.7, 1.0);
    int minimapTextSize = 50;
    int minimapIconSizeSelectable = 40;
    int minimapIconSizeNotSelectable = 30;
    int levels_finished = -1;
    bool inputEnabled = false;
    array<string> inputName;
    bool bloodEffectEnabled = false;
    float bloodAlpha = 1.0;
    float bloodDisplayTime = 0.0f;
    float inputTime = 0.0f;
	JSONValue challengeData;
	int challengeLevelsFinished = -1;
	vec4 lineColorActive = vec4(1.0f, 0.2f, 0.2f, 1.0f);
	vec4 lineColorInactive = vec4(0.4f, 0.1f, 0.1f, 1.0f);
	int worldMapSizeX = 1500;
	int worldMapSizeY = 1000;
	int screen_height = 1500;
	int screen_width = 2560;

    /*******************************************************************************************/
    /**
     * @brief  Constructor
     *
     */
    MenuGUI() {
        // Call the superclass to set things up
        super();

    }

    /*******************************************************************************************/
    /**
     * @brief  Add the footer to the layout — all screens will have this
     *
     */
    void addFooter() {


        // Create a divider for our footer 300px high (using a convenience factory in the divider)
        // The AH_UNDEFINEDSIZE will tell it to expand to the size of it's container
        // So we take up the whole bottom of the screen
        AHGUI::Divider@ footer = root.addDivider( DDBottomRight,  DOHorizontal, ivec2( AH_UNDEFINEDSIZE, 300 ) );
        footer.setName("footerdiv");

        // Add some space on the left
        footer.addSpacer( 50, DDLeft );

        // Create the 'main menu' text
		DisplayText(footer, DDLeft, "MAIN MENU", textSize, textColor, true, "mainmenu", "mainmenu");

        // Add some space on the left
        footer.addSpacer( 50, DDRight );

        // Add the version text
		DisplayText(footer, DDLeft, "DELETE USER", textSize, textColor, true, "deleteuser", "deleteuser");
    }

    /*******************************************************************************************/
    /**
     * @brief  Change the contents of the GUI based on the state
     *
     */
    void handleStateChange() {


        //see if anything has changed
        if( lastState == currentState ) {
            return;
        }

        // Record the change
        lastState = currentState;

        // First clear the old screen
        clear();

        // first add the footer as all screens have the same footer
        //addFooter();

        //addCommonElements();

        // Now we switch on the state
        switch( currentState ) {

            case agsInvalidState: {
                // For completeness -- throw an error and move on
                DisplayError("GUI Error", "GUI in invalid state");

            }
            break;
            case agsSelectLevel: {
                ShowLevelSelectUI();
            }
            break;
            case agsDifficulty: {
                ShowDifficultySelectUI();
            }
            break;
            case agsNewUser: {
                ShowNewUserSelectUI();
            }
            break;
            case agsConfirmDelete: {
                ShowConfirmDeleteUI();
            }
            break;
            case agsSelectUser: {
				ResetActiveProfile();
                ShowUserSelectUI();
            }
            break;
			case agsChallenge: {
                ShowChallengeUI();
            }
            break;
        }
        AddBloodEffect();
    }

    void ShowConfirmDeleteUI(){
        AHGUI::Divider@ buttonsPanel = root.addDivider( DDCenter, DOVertical, ivec2( AH_UNDEFINEDSIZE, AH_UNDEFINEDSIZE ) );

        buttonsPanel.addSpacer(150, DDTop);
		DisplayText(buttonsPanel, DDTop, "ARE YOU SURE YOU WANT TO DELETE THIS USER?", textSize, textColor, true);
        buttonsPanel.addSpacer(50, DDTop);

		DisplayText(buttonsPanel, DDTop, "YES", textSize, textColor, true, "yesdelete", "yesdelete");
        buttonsPanel.addSpacer(50, DDTop);

		DisplayText(buttonsPanel, DDTop, "NO", textSize, textColor, true, "nodelete", "nodelete");
        buttonsPanel.addSpacer(50, DDTop);

        if(showBorders){
            buttonsPanel.setBorderSize( 10 );
            buttonsPanel.setBorderColor( 1.0, 0.0, 0.0, 0.6 );
            buttonsPanel.showBorder();
        }
    }

    void ShowDifficultySelectUI(){
        AHGUI::Divider@ mainPane = root.addDivider( DDCenter, DOHorizontal, ivec2( AH_UNDEFINEDSIZE, AH_UNDEFINEDSIZE ) );
        AHGUI::Divider@ footerPane = root.addDivider( DDBottomRight,  DOHorizontal, ivec2( AH_UNDEFINEDSIZE, AH_UNDEFINEDSIZE ) );
        footerPane.setName("footerdiv");
        mainPane.addSpacer(50, DDTop);

        AHGUI::Divider@ buttonsPanel = mainPane.addDivider( DDTop, DOVertical, ivec2( AH_UNDEFINEDSIZE, AH_UNDEFINEDSIZE ) );



        buttonsPanel.addSpacer(150, DDTop);

		DisplayText(buttonsPanel, DDTop, "EASIER", textSize, textColor, true, "easier", "easier");
        buttonsPanel.addSpacer(50, DDTop);

		DisplayText(buttonsPanel, DDTop, "DIFFICULT", textSize, textColor, true, "difficult", "difficult");
        buttonsPanel.addSpacer(50, DDTop);

		DisplayText(buttonsPanel, DDTop, "INSANE", textSize, textColor, true, "difficult", "difficult");
        buttonsPanel.addSpacer(50, DDTop);

        buttonsPanel.addSpacer(150, DDBottom);

        if(showBorders){
            mainPane.setBorderSize( 10 );
            mainPane.setBorderColor( 0.0, 0.0, 1.0, 0.6 );
            mainPane.showBorder();

            buttonsPanel.setBorderSize( 10 );
            buttonsPanel.setBorderColor( 1.0, 0.0, 0.0, 0.6 );
            buttonsPanel.showBorder();

            footerPane.setBorderSize( 10 );
            footerPane.setBorderColor( 0.0, 1.0, 0.0, 0.6 );
            footerPane.showBorder();
        }

    }

    void ShowLevelSelectUI(){
        AHGUI::Divider@ footerPane = root.addDivider( DDBottomRight,  DOHorizontal, ivec2( AH_UNDEFINEDSIZE, 200 ) );
        footerPane.setName("footerdiv");
        AHGUI::Divider@ mainPane = root.addDivider( DDBottom, DOHorizontal );

        footerPane.addSpacer(50, DDLeft );
        footerPane.addSpacer(50, DDRight );

		DisplayText(footerPane, DDLeft, "MAIN MENU", textSize, textColor, true, "mainmenu", "mainmenu");
		DisplayText(footerPane, DDRight, "DELETE USER", textSize, textColor, true, "deleteuser", "deleteuser");

        AHGUI::Divider@ buttonsPanel = mainPane.addDivider( DDTop, DOVertical, ivec2( AH_UNDEFINEDSIZE, AH_UNDEFINEDSIZE ) );

        buttonsPanel.addSpacer(50, DDTop );

        AHGUI::Divider@ mainButtonsPanel = buttonsPanel.addDivider( DDCenter, DOVertical, ivec2( AH_UNDEFINEDSIZE, AH_UNDEFINEDSIZE ) );
        mainButtonsPanel.setVeritcalAlignment(BACenter);

        AHGUI::Divider@ usernamePane = buttonsPanel.addDivider( DDLeft, DOHorizontal, ivec2( AH_UNDEFINEDSIZE, AH_UNDEFINEDSIZE ) );
        usernamePane.setHorizontalAlignment(BALeft);
        usernamePane.addSpacer(50, DDLeft );
        usernamePane.addSpacer(50, DDRight );

        //Username
		DisplayText(buttonsPanel, DDLeft, user_name, textSize, textColor, true);
        buttonsPanel.addSpacer(50, DDTop );

        AHGUI::Divider@ challengePanel = mainButtonsPanel.addDivider( DDTop, DOHorizontal, ivec2( AH_UNDEFINEDSIZE, AH_UNDEFINEDSIZE ) );
        challengePanel.setHorizontalAlignment(BALeft);
        challengePanel.addSpacer(50, DDLeft );

        //Challenge
        mainButtonsPanel.addSpacer(150, DDTop );
		DisplayText(challengePanel, DDTop, "CHALLENGE", textSize, textColor, true, "challenge", "challenge");

        AHGUI::Divider@ changeUserPanel = mainButtonsPanel.addDivider( DDTop, DOHorizontal, ivec2( AH_UNDEFINEDSIZE, AH_UNDEFINEDSIZE ) );
        changeUserPanel.setHorizontalAlignment(BALeft);
        changeUserPanel.addSpacer(50, DDLeft );

		DisplayText(changeUserPanel, DDTop, "CHANGE USER", textSize, textColor, true, "selectuser", "selectuser");

        AHGUI::Divider@ worldmapPane = mainPane.addDivider( DDCenter, DOHorizontal, ivec2(worldMapSizeX, worldMapSizeY ) );
		worldmapPane.setHorizontalAlignment(BALeft);
        worldmapPane.addSpacer(50, DDLeft );
        //mainPane.addSpacer(50, DDTop );

        worldmapPane.setBackgroundImage("Textures/LugaruMenu/Map.png");
		int paneSizeX = worldmapPane.getSizeX();
		int paneSizeY = worldmapPane.getSizeY();

        array<int> activeLevels = GetActiveLevels();
        //Add the levels to the worldmap.
        //for(uint i = 0; i < 3; i++){
		vec2 lastPosition;
        for(uint i = 0; i < activeLevels.size(); i++){
			int levelIndex = activeLevels[i];
            AHGUI::Image levelButton("Textures/LugaruMenu/MapCircle.png");
            // Turn it into a button
            AHGUI::Message selectMessage("loadlevel");
            selectMessage.intParams.insertLast(i);
			vec4 buttonColor( 1.0, 0.2f, 0.2f, 1.0 );
			vec4 colorStart;
			vec4 colorEnd;
			int buttonScale = 1;
			int buttonLevel = 3;
			if(i == (activeLevels.size() - 1)){
			//if(i == (3 - 1)){
				levelButton.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick(selectMessage) );
				AHGUI::Text levelName( levels[levelIndex].name, "OptimusPrinceps", paneSizeX/worldMapSizeX*minimapTextSize, 1.0f, 0.0f, 0.0f, 1.0f );
				levelName.setShadowed(true);
				worldmapPane.addFloatingElement(levelName, levels[levelIndex].name + "label", ivec2(int(levels[levelIndex].position.x) + 30, int(levels[levelIndex].position.y) - minimapTextSize/2), 3);
				buttonColor = vec4( 1.0, 0.2f, 0.2f, 2.0 );
				buttonScale = minimapIconSizeSelectable;
				colorStart = vec4( 1.0, 0.2, 0.2, 2.0 );
	            colorEnd = vec4( 2.0, 0.5, 0.5, 2.0 );
				buttonLevel++;
			}else{
				buttonColor = vec4( 0.3, 0.1f, 0.1f, 2.0 );
				buttonScale = minimapIconSizeNotSelectable;
				colorStart = vec4( 0.3, 0.1f, 0.1f, 2.0 );
	            colorEnd = vec4( 1.0f, 0.5f, 0.5f, 2.0 );
			}
			levelButton.setColor( buttonColor );
			levelButton.scaleToSizeX(buttonScale);
			levelButton.addMouseOverBehavior( AHGUI::MouseOverPulseColor(
												colorStart,
										 		colorEnd, 1.0f ) );
			float sizeX = levelButton.getSizeX();
			float sizeY = levelButton.getSizeY();
			ivec2 newPos = ivec2(int(levels[levelIndex].position.x) - int(sizeX/2), int(levels[levelIndex].position.y) - int(sizeY/2));
			ivec2 target = ivec2(int(levels[levelIndex].position.x), int(levels[levelIndex].position.y));
			worldmapPane.addFloatingElement(levelButton, levels[levelIndex].name, newPos, buttonLevel);

			vec2 from_node_pos(
				lastPosition.x,
				lastPosition.y
			);
			vec2 to_node_pos(
				target.x,
				target.y
			);

			float dist = length( from_node_pos - to_node_pos );
			vec2 dir = normalize( from_node_pos - to_node_pos );

			const float pi = 3.141592f;
			float rotation = -atan2(dir.y, dir.x) * (180/pi);
			if(i != 0){
				AHGUI::Image line( "Textures/world_map/line_segment.png" );
				vec4 lineColor;
				if(i == (activeLevels.size() - 1)){
					lineColor = vec4( lineColorActive );
				}else{
					lineColor = vec4( lineColorInactive );
				}
				int line_segment_width = line.getSizeX();
				int numLinesNeeded = int(distance(from_node_pos, to_node_pos) / line_segment_width) * 2;
				for(int o = 0; o < numLinesNeeded; o++){
					AHGUI::Image newline( "Textures/world_map/line_segment.png" );
					vec2 linePos = mix(from_node_pos, to_node_pos,  (1.0f / numLinesNeeded) * o);
					worldmapPane.addFloatingElement( newline, "newmapline " + i + "and" + o, ivec2(int(linePos.x), int(linePos.y))-ivec2(line_segment_width/2,line_segment_width/2), 1);
					newline.setRotation( rotation );
					newline.setColor(lineColor);
				}
			}
			lastPosition = vec2(target.x, target.y);
        }

        if(showBorders){
            mainButtonsPanel.setBorderSize( 1 );
            mainButtonsPanel.setBorderColor( 0.0, 0.0, 1.0, 0.6 );
            mainButtonsPanel.showBorder();

            buttonsPanel.setBorderSize( 1 );
            buttonsPanel.setBorderColor( 1.0, 0.0, 0.0, 0.6 );
            buttonsPanel.showBorder();

            mainPane.setBorderSize( 1 );
            mainPane.setBorderColor( 0.0, 7.0, 0.0, 0.6 );
            mainPane.showBorder();

            footerPane.setBorderSize( 1 );
            footerPane.setBorderColor( 0.0, 7.0, 0.0, 0.6 );
            footerPane.showBorder();

            usernamePane.setBorderSize( 1 );
            usernamePane.setBorderColor( 1.0, 1.0, 1.0, 0.6 );
            usernamePane.showBorder();

			challengePanel.setBorderSize( 1 );
            challengePanel.setBorderColor( 1.0, 0.0, 1.0, 0.6 );
            challengePanel.showBorder();

			changeUserPanel.setBorderSize( 1 );
            changeUserPanel.setBorderColor( 1.0, 0.0, 1.0, 0.6 );
            changeUserPanel.showBorder();

            worldmapPane.setBorderSize( 1 );
            worldmapPane.setBorderColor( 1.0, 0.0, 1.0, 0.6 );
            worldmapPane.showBorder();
        }
    }
    void ShowUserSelectUI(){
        AHGUI::Divider@ mainPane = root.addDivider( DDLeft, DOHorizontal, ivec2( AH_UNDEFINEDSIZE, 400 ) );
        mainPane.addSpacer(50, DDLeft );
        AHGUI::Divider@ newUserPane = mainPane.addDivider( DDTop, DOVertical, ivec2( AH_UNDEFINEDSIZE, AH_UNDEFINEDSIZE ) );

        AHGUI::Divider@ centerPane = root.addDivider( DDCenter, DOHorizontal, ivec2( AH_UNDEFINEDSIZE, 600 ) );
        centerPane.addSpacer(50, DDLeft );
        AHGUI::Divider@ usernamesPane = centerPane.addDivider( DDLeft, DOVertical, ivec2( AH_UNDEFINEDSIZE, 10 ) );

        AHGUI::Divider@ footerPane = root.addDivider( DDBottomRight,  DOHorizontal, ivec2( AH_UNDEFINEDSIZE, 200 ) );
        footerPane.setName("footerdiv");

        mainPane.addSpacer(50, DDLeft );
        centerPane.addSpacer(200, DDTop );

        JSONValue profiles = profileData.getRoot()["profiles"];

        //Do not allow more than 8 profiles.
        if(profiles.size() < 8){
			DisplayText(newUserPane, DDBottom, "NEW USER", textSize, textColor, true, "newuser", "newuser");
        }else{
			DisplayText(mainPane, DDLeft, "NO MORE USERS", textSize, textColor, true);
        }

        for( uint i = 0; i < profiles.size(); ++i ) {
            //Add a seperate pane for every name to line every name to the left.
            AHGUI::Divider@ namePane = usernamesPane.addDivider( DDRight, DOHorizontal, ivec2( 20, 20 ) );
            namePane.setHorizontalAlignment(BALeft);
			DisplayText(namePane, DDLeft, profiles[i]["user_name"].asString(), textSize, textColor, true, "username", "username");
			AHGUI::Text@ userName = cast<AHGUI::Text>(root.findElement( "username" ));
            AHGUI::Message selectMessage( "selectuser" );
            //Set the ID as param so the clicked function can use the ID number.
            selectMessage.intParams.insertLast(profiles[i]["id"].asInt());
            userName.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick(selectMessage));
        }
        footerPane.addSpacer(50, DDLeft );
		DisplayText(footerPane, DDLeft, "BACK", textSize, textColor, true, "mainmenu", "mainmenu");

        if(showBorders){
            footerPane.setBorderSize( 10 );
            footerPane.setBorderColor( 1.0, 0.0, 0.0, 0.6 );
            footerPane.showBorder();

            centerPane.setBorderSize( 10 );
            centerPane.setBorderColor( 0.0, 1.0, 0.0, 0.6 );
            centerPane.showBorder();

            usernamesPane.setBorderSize( 10 );
            usernamesPane.setBorderColor( 1.0, 1.0, 0.0, 0.6 );
            usernamesPane.showBorder();

            mainPane.setBorderSize( 10 );
            mainPane.setBorderColor( 0.0, 0.0, 1.0, 0.6 );
            mainPane.showBorder();

            newUserPane.setBorderSize( 10 );
            newUserPane.setBorderColor( 0.0, 0.0, 1.0, 0.6 );
            newUserPane.showBorder();
        }
    }

	void ShowChallengeUI(){
		AHGUI::Divider@ footerPane = root.addDivider( DDBottomRight,  DOHorizontal, ivec2( AH_UNDEFINEDSIZE, 200 ) );
        footerPane.setName("footerdiv");
		footerPane.addSpacer(50, DDLeft );

        AHGUI::Divider@ mainPane = root.addDivider( DDBottom, DOHorizontal, ivec2( AH_UNDEFINEDSIZE, AH_UNDEFINEDSIZE ) );
        mainPane.addSpacer(500, DDLeft );
        mainPane.addSpacer(500, DDRight );
        AHGUI::Divider@ levelPane = mainPane.addDivider( DDLeft, DOVertical, ivec2( AH_UNDEFINEDSIZE, AH_UNDEFINEDSIZE ) );
		mainPane.addSpacer(50, DDTop );
        AHGUI::Divider@ highscorePane = mainPane.addDivider( DDCenter, DOVertical, ivec2( AH_UNDEFINEDSIZE, AH_UNDEFINEDSIZE ) );
        AHGUI::Divider@ besttimePane = mainPane.addDivider( DDRight, DOVertical, ivec2( AH_UNDEFINEDSIZE, AH_UNDEFINEDSIZE ) );

        mainPane.addSpacer(50, DDLeft );

        JSONValue profiles = profileData.getRoot()["profiles"];

		DisplayText(levelPane, DDTop, "Level", challengeTextSize, textColor, true);
		DisplayText(highscorePane, DDTop, "High Score", challengeTextSize, textColor, true);
		DisplayText(besttimePane, DDTop, "Best Time", challengeTextSize, textColor, true);

		levelPane.addSpacer(50, DDTop );
		highscorePane.addSpacer(50, DDTop );
		besttimePane.addSpacer(50, DDTop );

		DisplayText(footerPane, DDLeft, "BACK", challengeTextSize, textColor, true, "back", "back");

		for(uint i = 0; i < challengelevels.size(); i++){
			vec4 scoreTextColor;
			if(uint(challengeLevelsFinished) >= i){
				scoreTextColor = vec4(0.7, 0.7, 0.7, 1.0);
			}else{
				scoreTextColor = vec4(0.7, 0.7, 0.7, 0.5);
			}
			DisplayText(levelPane, DDTop, challengelevels[i].name, challengeTextSize, scoreTextColor, true, "levelname" + i, "levelname" + i);
            if(challengeData[i].isNull()){
                challengeData[i]["highscore"] = 0;
                challengeData[i]["besttime"] = 0;
            }
			DisplayText(highscorePane, DDTop, challengeData[i]["highscore"].asString(), challengeTextSize, scoreTextColor, true, "highscore" + i, "highscore" + i);
			DisplayText(besttimePane, DDTop, GetTime(challengeData[i]["besttime"].asInt()), challengeTextSize, scoreTextColor, true, "besttime" + i, "besttime" + i);
			if(uint(challengeLevelsFinished) >= i){
				AHGUI::Message selectMessage("loadchallengelevel");
	            selectMessage.intParams.insertLast(i);
				AHGUI::Text@ levelname = cast<AHGUI::Text>(root.findElement("levelname" + i));
				AHGUI::Text@ highscore = cast<AHGUI::Text>(root.findElement("highscore" + i));
				AHGUI::Text@ besttime = cast<AHGUI::Text>(root.findElement("besttime" + i));
	            levelname.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick(selectMessage) );
	            highscore.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick(selectMessage) );
	            besttime.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick(selectMessage) );
			}
		}

        if(showBorders){
            footerPane.setBorderSize( 1 );
            footerPane.setBorderColor( 1.0, 0.0, 0.0, 0.6 );
            footerPane.showBorder();

			besttimePane.setBorderSize( 1 );
            besttimePane.setBorderColor( 0.0, 1.0, 0.0, 0.6 );
            besttimePane.showBorder();

			highscorePane.setBorderSize( 1 );
            highscorePane.setBorderColor( 1.0, 0.0, 1.0, 0.6 );
            highscorePane.showBorder();

			levelPane.setBorderSize( 1 );
            levelPane.setBorderColor( 1.0, 1.0, 0.0, 0.6 );
            levelPane.showBorder();

            mainPane.setBorderSize( 1 );
            mainPane.setBorderColor( 0.0, 0.0, 1.0, 0.6 );
            mainPane.showBorder();
        }
    }

	string GetTime(int seconds){
		string bestTime;
		int numSeconds = seconds % 60;
		int numMinutes = seconds / 60;

		if(numSeconds < 10){
			bestTime = numMinutes + ":0" + numSeconds;
		}else{
			bestTime = numMinutes + ":" + numSeconds;
		}
		return bestTime;
	}

    void ShowNewUserSelectUI(){
        AHGUI::Divider@ mainPane = root.addDivider( DDTop, DOHorizontal, ivec2( AH_UNDEFINEDSIZE, 200 ) );
        AHGUI::Divider@ footerPane = root.addDivider( DDBottomRight,  DOHorizontal, ivec2( AH_UNDEFINEDSIZE, 200 ) );
        footerPane.setName("footerdiv");

        // Add some space on the left
        footerPane.addSpacer( 50, DDLeft );
        mainPane.addSpacer( 50, DDLeft );
        mainPane.setName("mainpane");
        mainPane.setVeritcalAlignment(BATop);

        // Add a divider
        mainPane.addDivider( DDTop, DOHorizontal );

        mainPane.setHorizontalAlignment(BATop);
        mainPane.setVeritcalAlignment(BATop);

        footerPane.addSpacer(50, DDLeft );

		DisplayText(footerPane, DDLeft, "BACK", textSize, textColor, true, "mainmenu", "mainmenu");
		DisplayText(mainPane, DDLeft, "NEW USER", textSize, textColor, true, "newuser", "newuser");
        mainPane.addDivider( DDTop, DOHorizontal );
        mainPane.addSpacer(200, DDTop);

        if(showBorders){
            footerPane.setBorderSize( 10 );
            footerPane.setBorderColor( 1.0, 0.0, 0.0, 0.6 );
            footerPane.showBorder();

            mainPane.setBorderSize( 10 );
            mainPane.setBorderColor( 0.0, 0.0, 1.0, 0.6 );
            mainPane.showBorder();
        }
    }

    array<int> GetActiveLevels(){
        //The first levels are just shown on the map the last one can be selected.
        array<int> returnLevels;
		array<string> level_names;
        switch(levels_finished){
        //switch(18){
            case 0:{
				array<string> temp_names = {"Village"};
                level_names = temp_names;
                break;
            }case 1:{
                array<string> temp_names = {"Village", "Wonderer"};
				level_names = temp_names;
                break;
            }case 2:{
                array<string> temp_names = {"Wonderer" ,"Village 2"};
				level_names = temp_names;
                break;
            }case 3:{
                array<string> temp_names = {"Wonderer" ,"Village 2", "Clearing"};
				level_names = temp_names;
                break;
            }case 4:{
                array<string> temp_names = {"Wonderer" ,"Village 2", "Clearing", "Raider Patrol"};
				level_names = temp_names;
                break;
            }case 5:{
                array<string> temp_names = {"Wonderer", "Village 2", "Clearing", "Raider Patrol", "Raider Camp"};
				level_names = temp_names;
                break;
            }case 6:{
                array<string> temp_names = {"Wonderer", "Village 2", "Clearing", "Raider Patrol", "Raider Camp", "Raider Sentries"};
				level_names = temp_names;
                break;
            }case 7:{
                array<string> temp_names = {"Wonderer", "Village 2", "Clearing", "Raider Patrol", "Raider Camp", "Raider Sentries", "Raider Base"};
				level_names = temp_names;
                break;
            }case 8:{
                array<string> temp_names = {"Wonderer", "Village 2", "Clearing", "Raider Patrol", "Raider Camp", "Raider Sentries", "Raider Base", "Old Raider Base"};
				level_names = temp_names;
                break;
            }case 9:{
                array<string> temp_names = {"Wonderer", "Village 2", "Clearing", "Raider Patrol", "Raider Camp", "Raider Sentries", "Raider Base", "Old Raider Base", "Village 3"};
				level_names = temp_names;
                break;
            }case 10:{
                array<string> temp_names = {"Wonderer", "Village 2", "Clearing", "Raider Patrol", "Raider Camp", "Raider Sentries", "Raider Base", "Old Raider Base", "Village 3", "Rocky Hall"};
				level_names = temp_names;
                break;
            }case 11:{
                array<string> temp_names = {"Wonderer", "Village 2", "Clearing", "Raider Patrol", "Raider Camp", "Raider Sentries", "Raider Base", "Old Raider Base", "Village 3", "Rocky Hall", "Heading North"};
				level_names = temp_names;
                break;
            }case 12:{
                array<string> temp_names = {"Wonderer", "Village 2", "Clearing", "Raider Patrol", "Raider Camp", "Raider Sentries", "Raider Base", "Old Raider Base", "Village 3", "Rocky Hall", "Heading North", "Heading North 2"};
				level_names = temp_names;
                break;
            }case 13:{
                array<string> temp_names = {"Wonderer", "Village 2", "Clearing", "Raider Patrol", "Raider Camp", "Raider Sentries", "Raider Base", "Old Raider Base", "Village 3", "Rocky Hall", "Heading North", "Heading North 2", "Jack's Camp"};
				level_names = temp_names;
                break;
            }case 14:{
                array<string> temp_names = {"Wonderer", "Village 2", "Clearing", "Raider Patrol", "Raider Camp", "Raider Sentries", "Raider Base", "Old Raider Base", "Village 3", "Rocky Hall", "Heading North", "Heading North 2", "Jack's Camp", "Rocky Hall 2"};
				level_names = temp_names;
                break;
            }case 15:{
                array<string> temp_names = {"Wonderer", "Village 2", "Clearing", "Raider Patrol", "Raider Camp", "Raider Sentries", "Raider Base", "Old Raider Base", "Village 3", "Rocky Hall", "Heading North", "Heading North 2", "Jack's Camp", "Rocky Hall 2", "To Alpha Wolf"};
				level_names = temp_names;
                break;
            }case 16:{
                array<string> temp_names = {"Wonderer", "Village 2", "Clearing", "Raider Patrol", "Raider Camp", "Raider Sentries", "Raider Base", "Old Raider Base", "Village 3", "Rocky Hall", "Heading North", "Heading North 2", "Jack's Camp", "Rocky Hall 2", "To Alpha Wolf", "To Alpha Wolf 2"};
				level_names = temp_names;
                break;
            }case 17:{
                array<string> temp_names = {"Wonderer", "Village 2", "Clearing", "Raider Patrol", "Raider Camp", "Raider Sentries", "Raider Base", "Old Raider Base", "Village 3", "Rocky Hall", "Heading North", "Heading North 2", "Jack's Camp", "Rocky Hall 2", "To Alpha Wolf", "To Alpha Wolf 2", "Wolf Den"};
				level_names = temp_names;
                break;
            }case 18:{
                array<string> temp_names = {"Wonderer", "Village 2", "Clearing", "Raider Patrol", "Raider Camp", "Raider Sentries", "Raider Base", "Old Raider Base", "Village 3", "Rocky Hall", "Heading North", "Heading North 2", "Jack's Camp", "Rocky Hall 2", "To Alpha Wolf", "To Alpha Wolf 2", "Wolf Den", "Rocky Hall 3"};
				level_names = temp_names;
                break;
            }
        }
		for(uint i = 0; i < level_names.size(); i++){
			int index = -1;
			for(uint j = 0; j < levels.size(); j++){
				if(level_names[i] == levels[j].name){
					index = j;
					break;
				}
			}
			if(index != -1){
				returnLevels.insertLast(index);
			}
		}
        return returnLevels;
    }

    void addCommonElements(){
        AHGUI::Divider@ mainPane = root.addDivider( DDBottomRight, DOHorizontal, ivec2( AH_UNDEFINEDSIZE, AH_UNDEFINEDSIZE ) );

        //AHGUI::Divider@ footer = root.addDivider( DDBottomRight,  DOHorizontal, ivec2( AH_UNDEFINEDSIZE, 300 ) );
        mainPane.addSpacer( 50, DDLeft );

        mainPane.addSpacer(50, DDLeft );
        mainPane.setName("mainpane");
        mainPane.setVeritcalAlignment(BACenter);

        // Add a divider
        mainPane.addDivider( DDTop, DOHorizontal );

        if(showBorders){
            mainPane.setBorderSize( 10 );
            mainPane.setBorderColor( 0.0, 7.0, 0.0, 0.6 );
            mainPane.showBorder();
        }
    }


    /*******************************************************************************************/
    /**
     * @brief Called for each message received
     *
     * @param message The message in question
     *
     */
    void processMessage( AHGUI::Message@ message ) {

        // Check to see if an exit has been requested
        if( message.name == "mainmenu" ) {
            WritePersistentInfo( false );
            this_ui.SendCallback("back");
        }

        // switch on the state -- though the messages should be unique
        switch( currentState ) {
            case agsInvalidState: {
                // For completeness -- throw an error and move on
                DisplayError("GUI Error", "GUI in invalid state");
            }
            break;
            case agsNewUser: {
                if(message.name  ==  "newuser"){
                    profileData = generateNewProfileSet();
                    JSONValue newProfile = generateNewProfile("GYRTH");
                    profileData.getRoot()["profiles"].append(newProfile);
                    currentState = agsDifficulty;
                }
            }
            break;
            case agsDifficulty: {
                if(message.name  ==  "easier"){
                    difficulty = "easier";
                }else if(message.name  ==  "difficult"){
                    difficulty = "difficult";
                }else if(message.name  ==  "insane"){
                    difficulty = "insane";
                }
                currentState = agsSelectLevel;
                WritePersistentInfo( true );
            }
            case agsSelectLevel: {
                if(message.name  ==  "deleteuser"){
                    currentState = agsConfirmDelete;
                }else if(message.name == "selectuser"){
                    currentState = agsSelectUser;
                }else if(message.name == "loadlevel"){
                    LoadLevel(levels[message.intParams[0]].file);
                }else if(message.name == "challenge"){
					currentState = agsChallenge;
				}
            }
            break;
            case agsConfirmDelete: {
                if(message.name == "yesdelete"){
                    DeleteCurrentUser();
                    currentState = agsSelectUser;
                }else if(message.name == "nodelete"){
                    currentState = agsSelectLevel;
                }
            }
            break;
            case agsSelectUser: {
                if(message.name  ==  "newuser"){
                    EnableTextInput();
                }else if(message.name == "selectuser"){
                    //Get the ID of the selected profile and fetch the other data.
                    setDataFrom(message.intParams[0]);
                    //If for some reason the user was typing in a name and clicked an already existing profile we need to clear the input.
                    inputEnabled = false;
                    StopTextInput();
                    inputName.resize(0);
                    currentState = agsSelectLevel;
					WritePersistentInfo(false);
                }
            }
            break;
			case agsChallenge: {
				if(message.name == "back"){
					currentState = agsSelectLevel;
				}else if(message.name == "loadchallengelevel"){
                    LoadLevel(challengelevels[message.intParams[0]].file);
				}
			}
        }

    }

    void DeleteCurrentUser(){
        if( profileId != -1 ) {
            // delete the profile
            int targetProfileIndex = -1;
            for( uint i = 0; i < profileData.getRoot()["profiles"].size(); ++i ) {
                if( profileData.getRoot()["profiles"][ i ]["id"].asInt() == profileId ) {
                    targetProfileIndex = i;
                    break;
                }
            }

            // Throw an error if not found
            if( targetProfileIndex == -1 ) {
                DisplayError("Persistence Error", "Cannot find profile " + profileId + " for deletion");
            }
            profileData.getRoot()["profiles"].removeIndex(targetProfileIndex);
            WritePersistentInfo( false );

            // Refresh our profile data
            //profileData = global_data.getProfiles();
        }
    }

    void EnableTextInput(){
        inputEnabled = true;
        AHGUI::Text@ inputText = cast<AHGUI::Text>(root.findElement("newuser"));
        inputText.setText("_");
        StartTextInput();
    }

    /*******************************************************************************************/
    /**
     * @brief  Update the menu
     *
     */
    void update() {

        // Do state machine stuff
        handleStateChange();

        AHGUI::Divider@ bp = cast<AHGUI::Divider>(root.findElement("buttonpane"));

        CheckForBloodEffect();

        if(inputEnabled){
            AHGUI::Text@ inputText = cast<AHGUI::Text>(root.findElement("newuser"));

            string input = GetTextInput();
            //Only add actual symbols. Since GetTextinput always return something.
            if(input != "" && inputName.size() < 15){
                inputName.insertLast(input);
            }
            //Keep updating the label. So any change can be seen by the user.
            inputText.setText(GetChosenName() + "_");
            //When done the user presses Enter or Return.
            if(GetInputPressed(0,'return')){
                JSONValue newProfile = generateNewProfile(GetChosenName());
                profileData.getRoot()["profiles"].append(newProfile);
                setDataFrom( newProfile["id"].asInt());
                StopTextInput();
                //Switch to the difficulty selecting screen, but don't save yet. Creation of a profile can still be canceled.
                currentState = agsDifficulty;
                //Reset the input name for the next time a profile is created.
                inputName.resize(0);
                inputEnabled = false;

            }else if(GetInputDown(0,'backspace') && inputName.size() > 0){
                //To remove the last character simply remove the last item in the array.
                inputTime += time_step;
                if(inputTime > 0.1f){
                    inputName.removeLast();
                    inputTime = 0.0f;
                }
            }
        }
        if(GetInputPressed(0,'esc')){
            this_ui.SendCallback("back");
        }
		if(currentState == agsSelectLevel){
			if(GetInputPressed(0,'o')){
				clear();
	            levels_finished--;
				ShowLevelSelectUI();
	        }
			if(GetInputPressed(0,'p')){
				clear();
	            levels_finished++;
				ShowLevelSelectUI();
	        }
		}
        // Update the GUI
        AHGUI::GUI::update();

    }

    string GetChosenName(){
        string name;
        for(uint i = 0; i < inputName.size(); i++){
            name += inputName[i];
        }
        return name;
    }

    void LoadLevel(string level){
        this_ui.SendCallback(level);
    }

    /*******************************************************************************************/
    /**
     * @brief  Render the gui
     *
     */
     void render() {

        // Update the background
        // TODO: fold this into AHGUI
        hud.Draw();

        // Update the GUI
        AHGUI::GUI::render();

     }
    void ReadPersistentInfo() {

        SavedLevel @saved_level = save_file.GetSavedLevel("lugaru_levels_progress");
        // First we determine if we have a session -- if not we're not going to read data
        JSONValue sessionParams = getSessionParameters();

        if( !sessionParams.isMember("started") ) {
            // Nothing is started, so we shouldn't actually read the data
            Print("could not find started :( \n");
            return;
        }
        // read in campaign_started
        string profiles_str = saved_level.GetValue("lugaru_profiles");

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
                //profileData = generateNewProfileSet();
            }
			ResetActiveProfile();
        }
		//Print( profileData.writeString(true) );
        dataLoaded = true;

        // Now see if we have a profile in this session -- if so load it
        if( sessionParams.isMember("profile_id") ) {
            // Get the id from the session and load it into the usable values
            int currentProfileId = sessionParams["profile_id"].asInt();
            setDataFrom( currentProfileId ); // This will throw an error if not found
        }

    }
    JSONValue getSessionParameters() {

        SavedLevel @saved_level = save_file.GetSavedLevel("lugaru_levels_progress");

        string lugaru_session_str = saved_level.GetValue("lugaru_session");

        // sanity check
        if( lugaru_session_str == "" ) {
            lugaru_session_str = "{}";

            // write it back
            saved_level.SetValue("lugaru_session", lugaru_session_str );
        }

        JSON sessionJSON;

        // sanity check
        if( !sessionJSON.parseString( lugaru_session_str ) ) {
            DisplayError("Persistence Error", "Unable to parse session information");

        }
        return sessionJSON.getRoot();
    }

    JSON generateNewProfileSet() {

        JSON newProfileSet;

        newProfileSet.getRoot()["version"] = JSONValue( SAVEVERSION );
        newProfileSet.getRoot()["profiles"] =  JSONValue( JSONarrayValue );
        return newProfileSet;

    }

    JSONValue generateNewProfile(string name) {

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
		// Newprofile
        newProfile[ "id" ] = JSONValue( newId );
        newProfile[ "active" ] = JSONValue( "true" );
        newProfile[ "levels_finished" ] = JSONValue( 0 );
        newProfile[ "user_name" ] = JSONValue( name );

		newProfile[ "challenge_levels_finished" ] = JSONValue( 0 );
		JSONValue challengeData;
		for( uint i = 0; i < challengelevels.size(); ++i ) {
			challengeData[ i ]["highscore"] = JSONValue(0);
			challengeData[ i ]["besttime"] = JSONValue(0);
			string levelName = challengelevels[i].file;
			levelName = join( levelName.split( "LugaruChallenge/" ), "" );
			levelName = join( levelName.split( ".xml" ), "" );
			challengeData[ i ]["levelname"] = JSONValue(levelName);
		}
		newProfile[ "challengeData" ] = challengeData;
        return newProfile;
    }

    void setDataFrom( int targetId ) {

        JSONValue profiles = profileData.getRoot()["profiles"];

        bool profileFound = false;

        for( uint i = 0; i < profiles.size(); ++i ) {
            if( profiles[ i ]["id"].asInt() == targetId ) {
                profileFound = true;
                // Copy all the values back
                profileId = targetId;
                levels_finished = profiles[ i ]["levels_finished"].asInt();
                user_name = profiles[ i ]["user_name"].asString();
                difficulty = profiles[ i ]["difficulty"].asString();
				challengeData = profiles[ i ]["challengeData"];
				challengeLevelsFinished = profiles[ i ]["challenge_levels_finished"].asInt();
				profileData.getRoot()["profiles"][i]["active"] = JSONValue( "true" );
                // We're done here
                break;
            }
        }
        // Sanity checking
        if( !profileFound ) {
            DisplayError("Persistence Error", "Profile id " + targetId + " not found in store.");
        }
    }

    void AddBackground(){
        AHGUI::Image background("Textures/LugaruMenu/Title_FullScreen.png");
        int backgroundLevel = 0;
        ivec2 newPos = ivec2(0, 0);
        root.addFloatingElement(background, "Lugaru_BG", newPos, backgroundLevel);
    }

    void AddBloodEffect(){
        bloodEffectEnabled = true;
        bloodAlpha = 1.0f;
        bloodDisplayTime = 0.0f;
    }

    void CheckForBloodEffect(){
        if(bloodEffectEnabled){
			AHGUI::Image blood("Textures/diffuse.tga");
			blood.setSize( screen_width,screen_height );
			blood.setColor(vec4(0.8f, 0.0f, 0.0f, bloodAlpha));
			int bloodLevel = 4;
			root.addFloatingElement(blood, "Lugaru_Blood", ivec2(0, 0), bloodLevel);

			bloodAlpha -= bloodDisplayTime * 0.05;
			bloodDisplayTime += time_step;
            if(bloodAlpha < 0.0f){
                bloodEffectEnabled = false;
            }
        }
    }
    void startNewSession() {
        JSONValue thisSession = getSessionParameters();
        thisSession["started"] = JSONValue( "true" );
        setSessionParameters( thisSession );
    }
    void setSessionParameters( JSONValue session ) {
        SavedLevel @saved_level = save_file.GetSavedLevel("lugaru_levels_progress");

        // set the value to the stringified JSON
        JSON sessionJSON;
        sessionJSON.getRoot() = session;
        string arena_session_str = sessionJSON.writeString(false);
        saved_level.SetValue("lugaru_session", arena_session_str );

        // write out the changes
        save_file.WriteInPlace();

    }
    void WritePersistentInfo( bool moveDataToStore = true ) {

        // Make sure we've got information to write -- this is not an error
        if( !dataLoaded ) return;

        // Make sure our current data has been written back to the JSON structure
        if( moveDataToStore ) {
            writeDataToProfiles(); // This'll do nothing if we haven't set a profile
        }

        SavedLevel @saved_level = save_file.GetSavedLevel("lugaru_levels_progress");

        // Render the JSON to a string
        string profilesString = profileData.writeString(false);

        // Set the value and write to disk
        saved_level.SetValue( "lugaru_profiles", profilesString );
        save_file.WriteInPlace();

    }

	void ResetActiveProfile(){
		//Make all the profiles inactive
		for( uint i = 0; i < profileData.getRoot()["profiles"].size(); ++i ) {
			profileData.getRoot()["profiles"][i]["active"] = JSONValue( "false" );
		}
	}

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
                profileData.getRoot()["profiles"][ i ][ "levels_finished" ] = JSONValue( levels_finished );
                profileData.getRoot()["profiles"][ i ][ "difficulty" ] = JSONValue( difficulty );

                // We're done here
                break;

            }
        }

        // Sanity checking
        if( !profileFound ) {
            DisplayError("Persistence Error", "Profile id " + profileId + " not found in store.");
        }
    }
	void DisplayText(AHGUI::Divider@ div, DividerDirection dd, string text, int textSize, vec4 color, bool shadowed, string textName = "singleSentence", string onClick = "none"){
        AHGUI::Text singleSentence( text, "OptimusPrinceps", textSize, color.x, color.y, color.z, color.a );
		singleSentence.addUpdateBehavior( AHGUI::FadeIn( 1000, @inSine ) );
		singleSentence.setName(textName);
		singleSentence.setShadowed(shadowed);
        div.addElement(singleSentence, dd);
		if(onClick != "none"){
			singleSentence.addMouseOverBehavior( AHGUI::MouseOverPulseColor(color, vec4(0.5f), 1.0f ) );
			singleSentence.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick(onClick) );
		}
        if(showBorders){
            singleSentence.setBorderSize(1);
            singleSentence.setBorderColor(1.0, 1.0, 1.0, 1.0);
            singleSentence.showBorder( false );
        }
    }
}

MenuGUI menuGUI;

bool HasFocus(){
    return false;
}

void Initialize(){
    menuGUI.startNewSession();
    menuGUI.ReadPersistentInfo();
	PlaySong("menu-lugaru");
}

void Update(){
    menuGUI.update();
}

void DrawGUI(){
    menuGUI.AddBackground();
    menuGUI.render();
}

void Draw(){
}

void Init(string str){
}

void StartArenaMeta(){

}
bool CanGoBack(){
	return false;
}
void Dispose(){

}

string text_input_buffer;

string GetTextInput()
{
    string text_input_buffer_temp = text_input_buffer;
    text_input_buffer = "";
    return text_input_buffer_temp;
}

void TextInput(string text)
{
    text_input_buffer = text_input_buffer + text;
}
