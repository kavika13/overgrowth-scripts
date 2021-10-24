#include "ui_effects.as"
#include "arena_meta_persistence.as"
#include "ui_tools.as"

enum MenuGUIState {
    agsDifficulty,
    agsSelectLevel,
    agsNewUser,
    agsConfirmDelete,
    agsSelectUser,
    agsInvalidState
};

class Level
  {
    string name;
    string file;
    vec2 position;

    Level(string _name, string _file, vec2 _position)
    {
        name = _name;
        file = _file;
        position = _position;
    }
};

array<Level@> levels = {Level("LugaruStory/Village.xml",        "Village",          vec2(1,1)),
                        Level("LugaruStory/Village_2.xml",      "Village 2",        vec2(1,1)),
                        Level("LugaruStory/Wonderer.xml",       "Wonderer",         vec2(1,1)),
                        Level("LugaruStory/Village_3.xml",      "Village 3",        vec2(1,1)),
                        Level("LugaruStory/Clearing.xml",       "Clearing",         vec2(1,1)),
                        Level("LugaruStory/Raider_patrol.xml",  "Raider Patrol",    vec2(1,1)),
                        Level("LugaruStory/Raider_camp.xml",    "Raider Camp",      vec2(1,1)),
                        Level("LugaruStory/Raider_sentries.xml","Raider Sentries",  vec2(1,1)),
                        Level("LugaruStory/Raider_base.xml",    "Raider Base",      vec2(1,1)),
                        Level("LugaruStory/Raider_base_2.xml",  "Raider Base 2",    vec2(1,1)),
                        Level("LugaruStory/Old_raider_base.xml","Old Raider Base",  vec2(1,1)),
                        Level("LugaruStory/Village_4.xml",      "Village 4",        vec2(1,1)),
                        Level("LugaruStory/Rocky_hall.xml",     "Rocky Hall",       vec2(1,1)),
                        Level("LugaruStory/Heading_north.xml",  "Heading North",    vec2(1,1)),
                        Level("LugaruStory/Heading_north_2.xml","Heading North 2",  vec2(1,1)),
                        Level("LugaruStory/Jack's_camp.xml",    "Jack's Camp",      vec2(1,1)),
                        Level("LugaruStory/Jack's_camp_2.xml",  "Jack's Camp 2",    vec2(1,1)),
                        Level("LugaruStory/Rocky_hall_2.xml",   "Rocky Hall 2",     vec2(1,1)),
                        Level("LugaruStory/Rocky_hall_3.xml",   "Rocky Hall 3",     vec2(1,1)),
                        Level("LugaruStory/To_alpha_wolf.xml",  "To Alpha Wolf",    vec2(1,1)),
                        Level("LugaruStory/To_alpha_wolf_2.xml","To Alpha Wolf 2",  vec2(1,1)),
                        Level("LugaruStory/Wolf_den.xml",       "Wolf Den",         vec2(1,1)),
                        Level("LugaruStory/Wolf_den_2.xml",     "Wolf Den 2",       vec2(1,1)),
                        Level("LugaruStory/Rocky_hall_4.xml",   "Rocky Hall 4",     vec2(1,1))};

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
    vec4 textColor = vec4(0.5, 0.5, 0.5, 1.0);
    int minimapTextSize = 30;
    int minimapIconSize = 30;
    int levels_finished = -1;
    bool inputEnabled = false;
    array<string> inputName;
    bool bloodEffectEnabled = false;
    float bloodAlpha = 1.0;
    float bloodDisplayTime = 0.0f;
    float inputTime = 0.0f;


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
        // The UNDEFINEDSIZE will tell it to expand to the size of it's container
        // So we take up the whole bottom of the screen
        AHGUI::Divider@ footer = root.addDivider( DDBottomRight,  DOHorizontal, ivec2( UNDEFINEDSIZE, 300 ) );
        footer.setName("footerdiv");

        // Add some space on the left
        footer.addSpacer( 50, DDLeft );

        // Create the 'main menu' text
        AHGUI::Text mainMenu( "MAIN MENU", "OptimusPrinceps", textSize, textColor.x, textColor.y, textColor.z, textColor.a );

        // Add a little special effect
        mainMenu.addUpdateBehavior( AHGUI::FadeIn( 1000, @inSine ) );

        // Have it send a message to indicate we should go back to the main menu
        mainMenu.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick("mainmenu") );


        // Make it pulse when we mouse over
        mainMenu.addMouseOverBehavior( AHGUI::MouseOverPulseColor(
                                              vec4( 0.6, 0.8, 0.6, 0.5 ),
                                              vec4( 1.0, 0.6, 0.6, 0.9 ), 1.0f ) );

        // Add some space on the left
        footer.addSpacer( 50, DDRight );

        // Manually add it to the divider
        footer.addElement( mainMenu, DDLeft );

        // Add the version text
        AHGUI::Text verText( "DELETE USER", "OptimusPrinceps", textSize, textColor.x, textColor.y, textColor.z, textColor.a );
        verText.addUpdateBehavior( AHGUI::FadeIn( 1000, @inSine ) );
        verText.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick("deleteuser") );
        verText.addMouseOverBehavior( AHGUI::MouseOverPulseColor(
                                              vec4( 0.6, 0.8, 0.6, 0.5 ),
                                              vec4( 1.0, 0.6, 0.6, 0.9 ), 1.0f ) );

        footer.addElement( verText ,DDRight );


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
                ShowUserSelectUI();
            }
            break;
        }
        AddBloodEffect();
    }

    void ShowConfirmDeleteUI(){
        AHGUI::Divider@ mainPane = root.addDivider( DDTop, DOHorizontal, ivec2( UNDEFINEDSIZE, UNDEFINEDSIZE ) );

        mainPane.addSpacer(50, DDLeft);
        AHGUI::Divider@ buttonsPanel = mainPane.addDivider( DDTop, DOVertical, ivec2( UNDEFINEDSIZE, UNDEFINEDSIZE ) );

        buttonsPanel.addSpacer(150, DDTop);


        AHGUI::Text deleteText( "ARE YOU SURE YOU WANT TO DELETE THIS USER?", "OptimusPrinceps", textSize, textColor.x, textColor.y, textColor.z, textColor.a );
        deleteText.addUpdateBehavior( AHGUI::FadeIn( 1000, @inSine ) );

        buttonsPanel.addElement( deleteText ,DDTop );
        buttonsPanel.addSpacer(50, DDTop);

        AHGUI::Divider@ yesPanel = buttonsPanel.addDivider( DDTop, DOHorizontal, ivec2( UNDEFINEDSIZE, UNDEFINEDSIZE ) );
        yesPanel.setHorizontalAlignment(BALeft);

        AHGUI::Text yesButton( "YES", "OptimusPrinceps", textSize, textColor.x, textColor.y, textColor.z, textColor.a );
        yesButton.addUpdateBehavior( AHGUI::FadeIn( 1000, @inSine ) );
        yesButton.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick("yesdelete") );
        yesButton.addMouseOverBehavior( AHGUI::MouseOverPulseColor(
                                              vec4( 0.6, 0.8, 0.6, 0.5 ),
                                              vec4( 1.0, 0.6, 0.6, 0.9 ), 1.0f ) );

        yesPanel.addElement(yesButton, DDLeft);
        buttonsPanel.addSpacer(50, DDTop);

        AHGUI::Divider@ noPanel = buttonsPanel.addDivider( DDTop, DOHorizontal, ivec2( UNDEFINEDSIZE, UNDEFINEDSIZE ) );
        noPanel.setHorizontalAlignment(BALeft);

        AHGUI::Text noButton( "NO", "OptimusPrinceps", textSize, textColor.x, textColor.y, textColor.z, textColor.a );
        noButton.addUpdateBehavior( AHGUI::FadeIn( 1000, @inSine ) );
        noButton.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick("nodelete") );
        noButton.addMouseOverBehavior( AHGUI::MouseOverPulseColor(
                                              vec4( 0.6, 0.8, 0.6, 0.5 ),
                                              vec4( 1.0, 0.6, 0.6, 0.9 ), 1.0f ) );

        noPanel.addElement( noButton ,DDTop );
        buttonsPanel.addSpacer(50, DDTop);


        if(showBorders){
            mainPane.setBorderSize( 10 );
            mainPane.setBorderColor( 0.0, 0.0, 1.0, 0.6 );
            mainPane.showBorder();

            buttonsPanel.setBorderSize( 10 );
            buttonsPanel.setBorderColor( 1.0, 0.0, 0.0, 0.6 );
            buttonsPanel.showBorder();
        }
    }

    void ShowDifficultySelectUI(){
        AHGUI::Divider@ mainPane = root.addDivider( DDCenter, DOHorizontal, ivec2( UNDEFINEDSIZE, UNDEFINEDSIZE ) );
        AHGUI::Divider@ footerPane = root.addDivider( DDBottomRight,  DOHorizontal, ivec2( UNDEFINEDSIZE, UNDEFINEDSIZE ) );
        footerPane.setName("footerdiv");
        mainPane.addSpacer(50, DDTop);

        AHGUI::Divider@ buttonsPanel = mainPane.addDivider( DDTop, DOVertical, ivec2( UNDEFINEDSIZE, UNDEFINEDSIZE ) );



        buttonsPanel.addSpacer(150, DDTop);

        AHGUI::Text easier( "EASIER", "OptimusPrinceps", textSize, textColor.x, textColor.y, textColor.z, textColor.a );
        easier.addUpdateBehavior( AHGUI::FadeIn( 1000, @inSine ) );
        easier.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick("easier") );
        easier.addMouseOverBehavior( AHGUI::MouseOverPulseColor(
                                              vec4( 0.6, 0.8, 0.6, 0.5 ),
                                              vec4( 1.0, 0.6, 0.6, 0.9 ), 1.0f ) );

        buttonsPanel.addElement( easier ,DDTop );
        buttonsPanel.addSpacer(50, DDTop);

        AHGUI::Text difficult( "DIFFICULT", "OptimusPrinceps", textSize, textColor.x, textColor.y, textColor.z, textColor.a );
        difficult.addUpdateBehavior( AHGUI::FadeIn( 1000, @inSine ) );
        difficult.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick("difficult") );
        difficult.addMouseOverBehavior( AHGUI::MouseOverPulseColor(
                                              vec4( 0.6, 0.8, 0.6, 0.5 ),
                                              vec4( 1.0, 0.6, 0.6, 0.9 ), 1.0f ) );

        buttonsPanel.addElement( difficult ,DDTop );
        buttonsPanel.addSpacer(50, DDTop);

        AHGUI::Text insane( "INSANE", "OptimusPrinceps", textSize, textColor.x, textColor.y, textColor.z, textColor.a );
        insane.addUpdateBehavior( AHGUI::FadeIn( 1000, @inSine ) );
        insane.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick("insane") );
        insane.addMouseOverBehavior( AHGUI::MouseOverPulseColor(
                                              vec4( 0.6, 0.8, 0.6, 0.5 ),
                                              vec4( 1.0, 0.6, 0.6, 0.9 ), 1.0f ) );

        buttonsPanel.addElement( insane ,DDTop );
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
        AHGUI::Divider@ footerPane = root.addDivider( DDBottomRight,  DOHorizontal, ivec2( UNDEFINEDSIZE, 200 ) );
        footerPane.setName("footerdiv");
        AHGUI::Divider@ mainPane = root.addDivider( DDBottom, DOHorizontal, ivec2( UNDEFINEDSIZE, UNDEFINEDSIZE ) );

        footerPane.addSpacer(50, DDLeft );
        footerPane.addSpacer(50, DDRight );

        AHGUI::Text mainMenuButton( "MAIN MENU", "OptimusPrinceps", textSize, textColor.x, textColor.y, textColor.z, textColor.a );
        mainMenuButton.addUpdateBehavior( AHGUI::FadeIn( 1000, @inSine ) );
        mainMenuButton.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick("mainmenu") );
        mainMenuButton.addMouseOverBehavior( AHGUI::MouseOverPulseColor(
                                              vec4( 0.6, 0.8, 0.6, 0.5 ),
                                              vec4( 1.0, 0.6, 0.6, 0.9 ), 1.0f ) );
        footerPane.addElement( mainMenuButton ,DDLeft );

        AHGUI::Text deleteUserButton( "DELETE USER", "OptimusPrinceps", textSize, textColor.x, textColor.y, textColor.z, textColor.a );
        deleteUserButton.addUpdateBehavior( AHGUI::FadeIn( 1000, @inSine ) );
        deleteUserButton.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick("deleteuser") );
        deleteUserButton.addMouseOverBehavior( AHGUI::MouseOverPulseColor(
                                              vec4( 0.6, 0.8, 0.6, 0.5 ),
                                              vec4( 1.0, 0.6, 0.6, 0.9 ), 1.0f ) );
        footerPane.addElement( deleteUserButton ,DDRight );

        AHGUI::Divider@ buttonsPanel = mainPane.addDivider( DDTop, DOVertical, ivec2( UNDEFINEDSIZE, UNDEFINEDSIZE ) );

        buttonsPanel.addSpacer(50, DDTop );

        AHGUI::Divider@ mainButtonsPanel = buttonsPanel.addDivider( DDCenter, DOVertical, ivec2( UNDEFINEDSIZE, UNDEFINEDSIZE ) );
        mainButtonsPanel.setVeritcalAlignment(BACenter);

        AHGUI::Divider@ usernamePane = buttonsPanel.addDivider( DDLeft, DOHorizontal, ivec2( UNDEFINEDSIZE, UNDEFINEDSIZE ) );
        usernamePane.setHorizontalAlignment(BALeft);
        usernamePane.addSpacer(50, DDLeft );
        usernamePane.addSpacer(50, DDRight );

        //Username
        AHGUI::Text profileName( user_name, "OptimusPrinceps", textSize, textColor.x, textColor.y, textColor.z, textColor.a );
        usernamePane.addElement(profileName, DDLeft);
        buttonsPanel.addSpacer(50, DDTop );

        AHGUI::Divider@ tutorialPanel = mainButtonsPanel.addDivider( DDTop, DOHorizontal, ivec2( UNDEFINEDSIZE, UNDEFINEDSIZE ) );
        tutorialPanel.setHorizontalAlignment(BALeft);
        tutorialPanel.addSpacer(50, DDLeft );
        tutorialPanel.addSpacer(50, DDRight );

        //Tutorial
        AHGUI::Text tutorialButton( "TUTORIAL", "OptimusPrinceps", textSize, textColor.x, textColor.y, textColor.z, textColor.a );
        tutorialButton.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick("starttutorial") );
        tutorialPanel.addElement(tutorialButton, DDTop);

        mainButtonsPanel.addSpacer(150, DDTop );
        tutorialButton.addMouseOverBehavior( AHGUI::MouseOverPulseColor(
                                              vec4( 0.6, 0.8, 0.6, 0.5 ),
                                              vec4( 1.0, 0.6, 0.6, 0.9 ), 1.0f ) );

        AHGUI::Divider@ challengePanel = mainButtonsPanel.addDivider( DDTop, DOHorizontal, ivec2( UNDEFINEDSIZE, UNDEFINEDSIZE ) );
        challengePanel.setHorizontalAlignment(BALeft);
        challengePanel.addSpacer(50, DDLeft );
        challengePanel.addSpacer(50, DDRight );

        //Challenge
        AHGUI::Text challengeButton( "CHALLENGE", "OptimusPrinceps", textSize, textColor.x, textColor.y, textColor.z, textColor.a );
        challengeButton.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick("challenge") );
        challengePanel.addElement(challengeButton, DDTop);
        mainButtonsPanel.addSpacer(150, DDTop );
        challengeButton.addMouseOverBehavior( AHGUI::MouseOverPulseColor(
                                              vec4( 0.6, 0.8, 0.6, 0.5 ),
                                              vec4( 1.0, 0.6, 0.6, 0.9 ), 1.0f ) );

        AHGUI::Divider@ changeUserPanel = mainButtonsPanel.addDivider( DDTop, DOHorizontal, ivec2( UNDEFINEDSIZE, UNDEFINEDSIZE ) );
        changeUserPanel.setHorizontalAlignment(BALeft);
        changeUserPanel.addSpacer(50, DDLeft );
        changeUserPanel.addSpacer(50, DDRight );

        AHGUI::Text changeUserButton( "CHANGE USER", "OptimusPrinceps", textSize, textColor.x, textColor.y, textColor.z, textColor.a );
        changeUserButton.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick("selectuser") );
        changeUserPanel.addElement(changeUserButton, DDTop);
        changeUserButton.addMouseOverBehavior( AHGUI::MouseOverPulseColor(
                                              vec4( 0.6, 0.8, 0.6, 0.5 ),
                                              vec4( 1.0, 0.6, 0.6, 0.9 ), 1.0f ) );


        AHGUI::Divider@ worldmapPane = mainPane.addDivider( DDCenter, DOHorizontal, ivec2( UNDEFINEDSIZE, 747 ) );
        challengePanel.setVeritcalAlignment(BATop);
        //mainPane.addSpacer(50, DDTop );

        AHGUI::Image worldmap("Textures/LugaruMenu/Map.png");
        worldmap.scaleToSizeX(2000);
        // Add this to the main pane
        worldmapPane.addElement( worldmap, DDCenter );

        array<int> activeLevels = GetActiveLevels();

        AHGUI::Divider@ levelsButtonPane = mainPane.addDivider( DDRight, DOVertical, ivec2( UNDEFINEDSIZE, UNDEFINEDSIZE ) );
        //Add the levels to the worldmap.
        for(uint i = 0; i < activeLevels.size(); i++){
            AHGUI::Divider@ buttonPane = levelsButtonPane.addDivider( DDRight, DOHorizontal, ivec2( UNDEFINEDSIZE, UNDEFINEDSIZE ) );
            AHGUI::Image levelButton("Textures/LugaruMenu/MapCircle.png");
            vec4 buttonColor( 1.0, 0.2f, 0.2f, 1.0 );
            levelButton.setColor( buttonColor );
            levelButton.addMouseOverBehavior( AHGUI::MouseOverPulseColor(
                                         vec4( 2.0, 0.2, 0.2, 1.0 ),
                                         vec4( 2.0, 0.2, 0.2, 2.0 ), 1.0f ) );
            levelButton.scaleToSizeX(minimapIconSize);
            // Turn it into a button
            AHGUI::Message selectMessage("loadlevel");
            selectMessage.intParams.insertLast(i);
            levelButton.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick(selectMessage) );
            //buttonPane.addElement(levelButton, DDLeft);
            //The levelname label
            AHGUI::Text levelName( levels[i].name, "OptimusPrinceps", minimapTextSize, textColor.x, textColor.y, textColor.z, textColor.a );
            //buttonPane.addElement(levelName, DDLeft);
        }



        if(showBorders){
            mainButtonsPanel.setBorderSize( 10 );
            mainButtonsPanel.setBorderColor( 0.0, 0.0, 1.0, 0.6 );
            mainButtonsPanel.showBorder();

            buttonsPanel.setBorderSize( 10 );
            buttonsPanel.setBorderColor( 1.0, 0.0, 0.0, 0.6 );
            buttonsPanel.showBorder();

            mainPane.setBorderSize( 10 );
            mainPane.setBorderColor( 0.0, 7.0, 0.0, 0.6 );
            mainPane.showBorder();

            footerPane.setBorderSize( 10 );
            footerPane.setBorderColor( 0.0, 7.0, 0.0, 0.6 );
            footerPane.showBorder();

            usernamePane.setBorderSize( 10 );
            usernamePane.setBorderColor( 1.0, 1.0, 1.0, 0.6 );
            usernamePane.showBorder();

            worldmapPane.setBorderSize( 10 );
            worldmapPane.setBorderColor( 1.0, 0.0, 1.0, 0.6 );
            worldmapPane.showBorder();

            levelsButtonPane.setBorderSize( 10 );
            levelsButtonPane.setBorderColor( 1.0, 0.0, 1.0, 0.6 );
            levelsButtonPane.showBorder();
        }
    }
    void ShowUserSelectUI(){
        AHGUI::Divider@ mainPane = root.addDivider( DDLeft, DOHorizontal, ivec2( UNDEFINEDSIZE, 400 ) );
        mainPane.addSpacer(50, DDLeft );
        AHGUI::Divider@ newUserPane = mainPane.addDivider( DDTop, DOVertical, ivec2( UNDEFINEDSIZE, UNDEFINEDSIZE ) );

        AHGUI::Divider@ centerPane = root.addDivider( DDCenter, DOHorizontal, ivec2( UNDEFINEDSIZE, 600 ) );
        centerPane.addSpacer(50, DDLeft );
        AHGUI::Divider@ usernamesPane = centerPane.addDivider( DDLeft, DOVertical, ivec2( UNDEFINEDSIZE, 10 ) );

        AHGUI::Divider@ footerPane = root.addDivider( DDBottomRight,  DOHorizontal, ivec2( UNDEFINEDSIZE, 200 ) );
        footerPane.setName("footerdiv");

        mainPane.addSpacer(50, DDLeft );
        centerPane.addSpacer(200, DDTop );

        JSONValue profiles = profileData.getRoot()["profiles"];

        //Do not allow more than 8 profiles.
        if(profiles.size() < 8){

            AHGUI::Text newUserButton( "NEW USER", "OptimusPrinceps", textSize, textColor.x, textColor.y, textColor.z, textColor.a );
            newUserButton.setName("newuser");
            newUserButton.addUpdateBehavior( AHGUI::FadeIn( 1000, @inSine ) );
            newUserButton.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick("newuser") );
            newUserButton.addMouseOverBehavior( AHGUI::MouseOverPulseColor(
                                                  vec4( 0.6, 0.8, 0.6, 0.5 ),
                                                  vec4( 1.0, 0.6, 0.6, 0.9 ), 1.0f ) );
            newUserPane.addElement( newUserButton ,DDBottom );
        }else{
            AHGUI::Text newUserButton( "NO MORE USERS", "OptimusPrinceps", textSize, textColor.x, textColor.y, textColor.z, textColor.a );
            newUserButton.addUpdateBehavior( AHGUI::FadeIn( 1000, @inSine ) );
            mainPane.addElement( newUserButton ,DDLeft );
        }



        for( uint i = 0; i < profiles.size(); ++i ) {
            //Add a seperate pane for every name to line every name to the left.
            AHGUI::Divider@ namePane = usernamesPane.addDivider( DDRight, DOHorizontal, ivec2( 20, 20 ) );
            namePane.setHorizontalAlignment(BALeft);
            AHGUI::Text verText( profiles[i]["user_name"].asString(), "OptimusPrinceps", textSize, textColor.x, textColor.y, textColor.z, textColor.a );
            verText.addUpdateBehavior( AHGUI::FadeIn( 1000, @inSine ) );
            AHGUI::Message selectMessage( "selectuser" );
            //Set the ID as param so the clicked function can use the ID number.
            selectMessage.intParams.insertLast(profiles[i]["id"].asInt());
            verText.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick(selectMessage) );
            verText.addMouseOverBehavior( AHGUI::MouseOverPulseColor(
                                                  vec4( 0.6, 0.8, 0.6, 0.5 ),
                                                  vec4( 1.0, 0.6, 0.6, 0.9 ), 1.0f ) );
            namePane.addElement( verText ,DDLeft );
        }

        footerPane.addSpacer(50, DDLeft );

        AHGUI::Text verText( "BACK", "OptimusPrinceps", textSize, textColor.x, textColor.y, textColor.z, textColor.a );
        verText.addUpdateBehavior( AHGUI::FadeIn( 1000, @inSine ) );
        verText.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick("mainmenu") );
        verText.addMouseOverBehavior( AHGUI::MouseOverPulseColor(
                                              vec4( 0.6, 0.8, 0.6, 0.5 ),
                                              vec4( 1.0, 0.6, 0.6, 0.9 ), 1.0f ) );

        footerPane.addElement( verText ,DDLeft );

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

    void ShowNewUserSelectUI(){
        AHGUI::Divider@ mainPane = root.addDivider( DDTop, DOHorizontal, ivec2( UNDEFINEDSIZE, 200 ) );
        AHGUI::Divider@ footerPane = root.addDivider( DDBottomRight,  DOHorizontal, ivec2( UNDEFINEDSIZE, 200 ) );
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

        AHGUI::Text verText( "BACK", "OptimusPrinceps", textSize, textColor.x, textColor.y, textColor.z, textColor.a );
        verText.addUpdateBehavior( AHGUI::FadeIn( 1000, @inSine ) );
        verText.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick("mainmenu") );
        verText.addMouseOverBehavior( AHGUI::MouseOverPulseColor(
                                              vec4( 0.6, 0.8, 0.6, 0.5 ),
                                              vec4( 1.0, 0.6, 0.6, 0.9 ), 1.0f ) );

        footerPane.addElement( verText ,DDLeft );

        AHGUI::Text newUser( "NEW USER", "OptimusPrinceps", textSize, textColor.x, textColor.y, textColor.z, textColor.a );
        newUser.addUpdateBehavior( AHGUI::FadeIn( 1000, @inSine ) );
        newUser.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick("newuser") );
        newUser.addMouseOverBehavior( AHGUI::MouseOverPulseColor(
                                              vec4( 0.6, 0.8, 0.6, 0.5 ),
                                              vec4( 1.0, 0.6, 0.6, 0.9 ), 1.0f ) );

        mainPane.addElement( newUser ,DDLeft );
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
        switch(levels_finished){
            case 0:{
                array<int> newarray = {0};
                returnLevels = newarray;
                break;
            }case 1:{
                array<int> newarray = {0, 1};
                returnLevels = newarray;
                break;
            }case 2:{
                array<int> newarray = {0, 1, 2};
                returnLevels = newarray;
                break;
            }case 3:{
                array<int> newarray = {0, 1, 2, 3};
                returnLevels = newarray;
                break;
            }case 4:{
                array<int> newarray = {0, 1, 2, 3, 4};
                returnLevels = newarray;
                break;
            }case 5:{
                array<int> newarray = {0, 1, 2, 3, 4, 5};
                returnLevels = newarray;
                break;
            }case 6:{
                array<int> newarray = {0, 1, 2, 3, 4, 5, 6};
                returnLevels = newarray;
                break;
            }
        }
        return returnLevels;
    }

    void addCommonElements(){
        AHGUI::Divider@ mainPane = root.addDivider( DDBottomRight, DOHorizontal, ivec2( UNDEFINEDSIZE, UNDEFINEDSIZE ) );

        //AHGUI::Divider@ footer = root.addDivider( DDBottomRight,  DOHorizontal, ivec2( UNDEFINEDSIZE, 300 ) );
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
                }else if(message.name == "starttutorial"){
                    LoadLevel("lugaru_tutorial.xml");
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
                }
            }
            break;
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

        Print("Profiles string : " + profiles_str + "\n");

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

        }

        dataLoaded = true;

        // Now see if we have a profile in this session -- if so load it
        if( sessionParams.isMember("profile_id") ) {
            // Get the id from the session and load it into the usable values
            int currentProfileId = sessionParams["profile_id"].asInt();
            setDataFrom( currentProfileId ); // This will throw an error if not found
            Print("Found profile_id\n");
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
            Print("Write back the lugaru session\n");
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
        newProfile[ "id" ] = JSONValue( newId );
        newProfile[ "active" ] = JSONValue( "true" );
        newProfile[ "levels_finished" ] = JSONValue( 0 );
        newProfile[ "user_name" ] = JSONValue( name );

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
        HUDImage @image = hud.AddImage();
        image.SetImageFromPath("Data/Textures/LugaruMenu/Title_FullScreen.png");
        image.position.x = -2;
        image.position.y = -2;
        image.position.z = 0;
        image.color.a = 0.5;
        float stretch_x = (GetScreenWidth()+4) / image.GetWidth();
        float stretch_y = (GetScreenHeight()+4) / image.GetHeight();
        image.scale = vec3(stretch_x, stretch_y, 1.0);
    }

    void AddBloodEffect(){
        bloodEffectEnabled = true;
        bloodAlpha = 1.0f;
        bloodDisplayTime = 0.0f;
    }

    void CheckForBloodEffect(){
        if(bloodEffectEnabled){
            HUDImage @newimage = hud.AddImage();
            newimage.SetImageFromPath("Data/Textures/diffuse.tga");
            newimage.position.x = -2;
            newimage.position.y = -2;
            newimage.position.z = 3;
            float stretch2_x = (GetScreenWidth()+4) / newimage.GetWidth();
            float stretch2_y = (GetScreenHeight()+4) / newimage.GetHeight();
            newimage.color.a = bloodAlpha;
            newimage.color.x = 1.0;
            newimage.color.y = 0.0;
            newimage.color.z = 0.0;
            newimage.scale = vec3(stretch2_x, stretch2_y, 0.1);
            bloodDisplayTime += time_step;
            bloodAlpha -= bloodDisplayTime * 0.05;
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
        Print("Writing session \n");
        save_file.WriteInPlace();

    }
    void WritePersistentInfo( bool moveDataToStore = true ) {

        // Make sure we've got information to write -- this is not an error
        if( !dataLoaded ) return;

        // Make sure our current data has been written back to the JSON structure
        if( moveDataToStore ) {
            Print("Writing data to profile\n");
            writeDataToProfiles(); // This'll do nothing if we haven't set a profile
        }

        SavedLevel @saved_level = save_file.GetSavedLevel("lugaru_levels_progress");

        // Render the JSON to a string
        string profilesString = profileData.writeString(false);

        // Set the value and write to disk
        saved_level.SetValue( "lugaru_profiles", profilesString );
        Print("Profiles string : " + profilesString + "\n");
        save_file.WriteInPlace();

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
    void PlayBackgroundMusic(){
        //int menuSong = PlaySoundLoop("Data/Music/LugaruMenuSong.wav", 0.0f);
    }
}

MenuGUI menuGUI;

bool HasFocus(){
    return false;
}

void Initialize(){
    menuGUI.startNewSession();
    menuGUI.ReadPersistentInfo();
    menuGUI.PlayBackgroundMusic();
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
void Dispose(){

}
