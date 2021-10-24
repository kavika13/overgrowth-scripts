#include "ui_effects.as"
#include "arena_meta_persistence.as"
#include "ui_tools.as"

// enum for the statemachine (Someday I'll write something to make this easier )
enum ArenaGUIState {
    agsInvalidState,
    agsFirstTime,
    agsSelectProfile,
    agsNewProfile,
    agsConfirmDelete
};

// Some data for the GUI

// Based on the values from GetRandomFurColor
array<vec3> furColorChoices = { vec3(1.0,1.0,1.0), 
                                vec3(34.0/255.0,34.0/255.0,34.0/255.0), 
                                vec3(137.0/255.0, 137.0/255.0, 137.0/255.0), 
                                vec3(105.0/255.0,73.0/255.0,54.0/255.0), 
                                vec3(53.0/255.0,28.0/255.0,10.0/255.0), 
                                vec3(172.0/255.0,124.0/255.0,62.0/255.0) };

// array<string> arenaLevels = {"Cave_Arena.xml", 
//                              "stucco_courtyard_arena.xml", 
//                              "waterfall_arena.xml"};
//                              "Magma_Arena.xml"};
// array<string> arenaNames = { "Cave", "Stucco Courtyard", "Waterfall", "Magma" };
// array<string> arenaImages = {"Textures/arenamenu/cave_arena.tga", 
//                              "Textures/arenamenu/stucco_arena.tga", 
//                              "Textures/arenamenu/waterfall_arena.tga",
//                              "Textures/arenamenu/magma_arena.tga"};

array<string> arenaLevels = {"Cave_Arena.xml", 
                             "waterfall_arena.xml"};
                             
array<string> arenaNames = { "Cave", "Waterfall" };
array<string> arenaImages = {"Textures/arenamenu/cave_arena.tga", 
                             "Textures/arenamenu/waterfall_arena.tga"};                             

float limitDecimalPoints( float n, int points ) {
    return float( float(int( n * pow( 10, points ) )) / pow( 10, points ) );
}                            


class ArenaGUI : AHGUI::GUI {

    // fancy ribbon background stuff 
    float visible = 0.0f;
    float target_visible = 1.0f;
    RibbonBackground ribbon_background; 
    //TODO: fold this into AHGUI 
    
    ArenaGUIState currentState = agsInvalidState; // Token for our state machine
    ArenaGUIState lastState = agsInvalidState;    // Last seen state, to detect changes

    JSONValue newCharacter; // For storing a character as its being created
    JSONValue profileData;  // All the current profile data (as a copy)

    array<AHGUI::Element@> furColorSelected; // Keep track of which fur color element is selected

    // Selection screen
    AHGUI::Element@ selectedProfile = null;// Which profile label is selected 
    int selectedProfileNum = -1;       // Which profile number is selected  
    int showingProfileNum = -1;       // Which profile number is shown
    bool showingProfileDetails = false; // Are we showing profile details?
    int selectedArena = 0;      // Which arena are we going to load

    /*******************************************************************************************/
    /**
     * @brief  Constructor
     * 
     */
    ArenaGUI() {
        // Call the superclass to set things up
        super();

        // initialize the background
        ribbon_background.Init();

        // Start a new arena session
        global_data.startNewSession();

        // Read the data from the file (this will create it if we don't have it)
        global_data.ReadPersistentInfo();

        // see if we already have some profiles
        profileData = global_data.getProfiles();

        if( profileData.size() != 0 ) {
            currentState = agsSelectProfile;
        }
        else {
            currentState = agsFirstTime;
        }

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
        footer.addSpacer( 175, DDLeft );

        // Create the 'main menu' text
        AHGUI::Text mainMenu( "Main Menu", "OpenSans-Regular", 50, 0.6, 0.8, 0.6, 0.7 );
        
        // Add a little special effect
        mainMenu.addUpdateBehavior( AHGUI::FadeIn( 1000, @inSine ) );

        // Have it send a message to indicate we should go back to the main menu
        mainMenu.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick("mainmenu") );


        // Make it pulse when we mouse over 
        mainMenu.addMouseOverBehavior( AHGUI::MouseOverPulseColor( 
                                              vec4( 0.6, 0.8, 0.6, 0.5 ), 
                                              vec4( 1.0, 0.6, 0.6, 0.9 ), 1.0f ) );
        
        // Add some space on the left
        footer.addSpacer( 175, DDRight );
        
        // Manually add it to the divider
        footer.addElement( mainMenu, DDLeft );
        
        // Add the version text
        AHGUI::Text verText( "Arena (ver 2.0)", "OpenSans-Regular", 50, 1.0, 1.0, 1.0, 0.5 );     
        verText.addUpdateBehavior( AHGUI::FadeIn( 1000, @inSine ) );

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
        addFooter();

        // Now we switch on the state
        switch( currentState ) {
            
            case agsInvalidState: {
                // For completeness -- throw an error and move on
                DisplayError("GUI Error", "GUI in invalid state");

            }
            break;

            case agsFirstTime: {

                // We just need to display a message to the player
                
                // Create a divider for the non-footer
                AHGUI::Divider@ mainpane = root.addDivider( DDTop,  
                                                            DOVertical, 
                                                            ivec2( UNDEFINEDSIZE, 1140 ) );

                mainpane.setName("mainpane");

                // Create the text
                AHGUI::Text newProfile( "Create a new profile", "OpenSans-Regular", 100, 1.0, 7.0, 0.0, 0.8 );

                // Have it send a message to indicate we should go to create profile state
                newProfile.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick("createprofile") );

                // Make it pulse when we mouse over 
                newProfile.addMouseOverBehavior( AHGUI::MouseOverPulseColor( 
                                                        vec4( 0.8, 0.5, 0.0, 0.5 ), 
                                                        vec4( 1.0, 1.0, 0.0, 0.9 ), .25 ) );
                
                // Fade it in just a little after the footer/image
                newProfile.addUpdateBehavior( AHGUI::FadeIn( 2000, @inSine ) );

                // Add this to the main pane  
                mainpane.addElement( newProfile, DDCenter );

                // For fun let's put an image on the screen 
                AHGUI::Image topImage("Textures/ui/versus_mode/fight_glyph.tga");
                topImage.scaleToSizeX(400);
                topImage.addUpdateBehavior( AHGUI::FadeIn( 1000, @inSine ) );

                // Add this to the main pane 
                mainpane.addElement( topImage, DDTop );    


            }
            break;

            case agsNewProfile: {

                // Initialize a new character from the global persistence structure
                newCharacter = global_data.generateNewProfile();

                // Create a divider for the non-footer
                AHGUI::Divider@ mainpane = root.addDivider( DDTop,  
                                                            DOHorizontal, 
                                                            ivec2( UNDEFINEDSIZE, 1140 ) );

                // I see we have a cool portrait, let's use it 
                AHGUI::Image rabbitImage("Textures/ui/versus_mode/rabbit_2_portrait.tga");
                rabbitImage.scaleToSizeX(800);
                
                // Show off combining behaviors
                rabbitImage.addUpdateBehavior( AHGUI::FadeIn( 2000, @inSine ) );
                rabbitImage.addUpdateBehavior( AHGUI::MoveIn( ivec2( 400, 0 ), 2000 , @linear ) );

                // Align this with the top of the divider cell instead of the usual center
                rabbitImage.setVeritcalAlignment( BATop );

                // Add this to the main pane 
                mainpane.addElement( rabbitImage, DDRight );  

                // Add some space on the left to push over our main text 
                mainpane.addSpacer( 700, DDLeft );

                // Create a divider for the new character interface
                // This will automatically expand vertically for us
                AHGUI::Divider@ characterpane = mainpane.addDivider( DDLeft,  
                                                                     DOVertical, 
                                                                     ivec2( UNDEFINEDSIZE, UNDEFINEDSIZE ) );

                // Push the character attributes down 
                characterpane.addSpacer( 150, DDTop );

                // Build a Divider for the name -- so we can have a fixed size border
                AHGUI::Divider@ nameBox = characterpane.addDivider( DDTop, DOHorizontal, ivec2( 1000, UNDEFINEDSIZE ) );
                
                // Set up the attributes for the border (it has sane defaults though)
                nameBox.setBorderSize( 10 );
                nameBox.setBorderColor( 0.9, 7.0, 0.0, 0.6 );
                nameBox.showBorder();

                // Build the text for the name
                AHGUI::Text nameText( newCharacter["character_name"].asString(), 
                                      "OpenSans-Regular", 75, 1.0, 7.0, 0.0, 0.9 );

                // Give it a name so we can find it again 
                // (we could also keep a reference, but I wanted to show off this feature)
                nameText.setName( "newNameText" );

                // Give some padding so that it's not cramped 
                nameText.setPadding(30,15,45,15);

                // Fade it in
                nameText.addUpdateBehavior( AHGUI::FadeIn( 1000, @inSine ) );

                // Add it to the container
                nameBox.addElement( nameText ,DDTop );

                // Create a re-randomize text button
                AHGUI::Text newRandomName( "New Random Name", "OpenSans-Regular", 50, 1.0, 7.0, 0.0, 0.9 );

                // Have it send a message to indicate we should go back to the main menu
                newRandomName.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick("newrandomname") );
                  
                // Make it pulse when we mouse over 
                newRandomName.addMouseOverBehavior( AHGUI::MouseOverPulseColor( 
                                              vec4( 0.5, 7.0, 0.0, 0.3 ), 
                                              vec4( 1.0, 7.0, 0.0, 0.9 ), 1.0f ) );

                // Align it to the left
                newRandomName.setHorizontalAlignment( BARight );

                // Add a little more space
                characterpane.addSpacer( 15, DDTop );         

                // Add our text 
                characterpane.addElement( newRandomName, DDTop );

                // Add a little more space
                characterpane.addSpacer( 55, DDTop );     

                // Set up the storage for the selected colors
                furColorSelected.resize(0);

                // Make sure the colors match the default selections
                newCharacter[ "player_colors" ][0][0] = furColorChoices[0].x;
                newCharacter[ "player_colors" ][0][1] = furColorChoices[0].y;
                newCharacter[ "player_colors" ][0][2] = furColorChoices[0].z;

                newCharacter[ "player_colors" ][1][0] = furColorChoices[0].x;
                newCharacter[ "player_colors" ][1][1] = furColorChoices[0].y;
                newCharacter[ "player_colors" ][1][2] = furColorChoices[0].z;

                newCharacter[ "player_colors" ][2][0] = furColorChoices[0].x;
                newCharacter[ "player_colors" ][2][1] = furColorChoices[0].y;
                newCharacter[ "player_colors" ][2][2] = furColorChoices[0].z;

                newCharacter[ "player_colors" ][3][0] = furColorChoices[0].x;
                newCharacter[ "player_colors" ][3][1] = furColorChoices[0].y;
                newCharacter[ "player_colors" ][3][2] = furColorChoices[0].z;

                // Now add the fur color selection options
                for( uint i = 0; i < 4; i++ ) {
                    // Add some space
                    characterpane.addSpacer( 20, DDTop ); 

                    // Create a divider for the color
                    AHGUI::Divider@ colorPanel = characterpane.addDivider( DDLeft, DOHorizontal );

                    // Create the text 
                    AHGUI::Text furColorLabel( "Fur Color " + i, "OpenSans-Regular", 50, 1.0, 7.0, 0.0, 0.9 );

                    // Align it to the left
                    furColorLabel.setHorizontalAlignment( BALeft );

                    // Add some space
                    colorPanel.addSpacer( 75, DDLeft );

                    // Add our text 
                    colorPanel.addElement( furColorLabel, DDLeft );

                    // Add some space
                    colorPanel.addSpacer( 50, DDLeft );

                    // Add the colors
                    for( uint j = 0; j < furColorChoices.length(); j++ ) {
                        // Add the image
                        AHGUI::Image colorImage("Textures/ui/whiteblock.tga");
                        colorImage.scaleToSizeX(60);
                        
                        // For fun have them appear left to right
                        colorImage.addUpdateBehavior( AHGUI::FadeIn( 250 + 250 * j, @inSine ) );
                        
                        // Set the color of the (normally white) image to be our selected color
                        vec4 newColor( furColorChoices[j].x, furColorChoices[j].y, furColorChoices[j].z, 0.9 );
                        colorImage.setColor( newColor );
                        colorImage.setPadding(5);

                        colorImage.setName("colorSelect" + i + "" + j);

                        // Automatically select the first one 
                        if( j == 0 ) {
                            colorImage.showBorder();
                            colorImage.setBorderColor( 0.2, 0.0, 1.0, 1.0 );
                            colorImage.setBorderSize(12);
                            furColorSelected.insertLast( @colorImage );
                        }
                        else {
                            colorImage.setBorderColor( 1.0, 1.0, 1.0, 1.0 );
                            colorImage.setBorderSize(6);
                        }

                        // Add a mouseover to indicate a new selection
                        colorImage.addMouseOverBehavior( AHGUI::MouseOverShowBorder() );
                        colorImage.addUpdateBehavior( AHGUI::PulseBorderAlpha( 0.5, 1.0, 0.5f ) );

                        // Construct a message to send when this color is selected
                        AHGUI::Message selectMessage( "colorselected" );

                        // write in the color number 
                        selectMessage.intParams.insertLast( i );

                        // write in the colors themselves 
                        selectMessage.floatParams.insertLast( furColorChoices[j].x);
                        selectMessage.floatParams.insertLast( furColorChoices[j].y);
                        selectMessage.floatParams.insertLast( furColorChoices[j].z);                        

                        // Attach this as message sending behavior
                        colorImage.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick(selectMessage) );

                        // Add the image
                        colorPanel.addElement( colorImage, DDLeft );

                        // Add some space (except on the last one)
                        if( j != furColorChoices.length() - 1 ) {
                            colorPanel.addSpacer( 30, DDLeft );
                        }
                    }
                }

                // Add a little more space
                characterpane.addSpacer( 125, DDTop ); 

                // Make a divider for the buttons 
                AHGUI::Divider@ buttonDivider = characterpane.addDivider( DDLeft, DOHorizontal, ivec2(700,UNDEFINEDSIZE) );

                // Create the text 
                AHGUI::Text okText( "Accept", "OpenSans-Regular", 50, 1.0, 7.0, 0.0, 0.9 );
                AHGUI::Text cancelText( "Back", "OpenSans-Regular", 50, 1.0, 7.0, 0.0, 0.9 );

                // Turn them into buttons
                okText.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick("ok") );
                cancelText.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick("cancel") );

                // Add the effects
                okText.addMouseOverBehavior( AHGUI::MouseOverPulseColor( 
                                             vec4( 0.5, 7.0, 0.0, 0.3 ), 
                                             vec4( 1.0, 7.0, 0.0, 0.9 ), 1.0f ) );

                cancelText.addMouseOverBehavior( AHGUI::MouseOverPulseColor( 
                                                 vec4( 0.5, 7.0, 0.0, 0.3 ), 
                                                 vec4( 1.0, 7.0, 0.0, 0.9 ), 1.0f ) );

                // Add them to the divider with some space 
                //buttonDivider.addSpacer( 25, DDLeft );
                buttonDivider.addElement( okText, DDLeft );
                //buttonDivider.addSpacer( 25, DDRight );
                buttonDivider.addElement( cancelText, DDRight );


            }
            break;

            case agsSelectProfile: {

                // Reset our state data
                @selectedProfile = null;
                selectedProfileNum = -1;
                showingProfileDetails = false;

                // Get (a copy of) the current profiles        
                profileData = global_data.getProfiles();

                // Create a divider for the non-footer
                AHGUI::Divider@ mainpane = root.addDivider( DDTop,  
                                                            DOHorizontal, 
                                                            ivec2( UNDEFINEDSIZE, 1140 ) );

                // I see we have a cool portrait, let's use it 
                AHGUI::Image rabbitImage("Textures/ui/versus_mode/rabbit_1_portrait.tga");
                rabbitImage.scaleToSizeX(800);
                
                // Show off combining behaviors
                rabbitImage.addUpdateBehavior( AHGUI::FadeIn( 2000, @inSine ) );
                rabbitImage.addUpdateBehavior( AHGUI::MoveIn( ivec2( -400, 0 ), 2000 , @linear ) );

                // Align this with the top of the divider cell instead of the usual center
                rabbitImage.setVeritcalAlignment( BATop );

                // Add this to the main pane 
                mainpane.addElement( rabbitImage, DDLeft );

                // Now we can build the space for the info panel
                mainpane.addSpacer(150, DDRight );
                AHGUI::Divider@ infoPanel = mainpane.addDivider( DDRight, DOVertical );
                // Give it a name so we can find it as we update it
                infoPanel.setName("infopane");
                infoPanel.setVeritcalAlignment(BATop);
                // We will populate this when the appropriate message is received

                // Add a divider 
                mainpane.addDivider( DDTop, DOHorizontal );

                // Create a divider for the new character interface
                // This will automatically expand vertically for us
                AHGUI::Divider@ characterSelectPane = mainpane.addDivider( DDLeft, DOVertical );

                // Push the character selection down 
                characterSelectPane.addSpacer( 100, DDTop );

                // Add a direction label
                AHGUI::Text selectText( "Select Profile", "OpenSans-Regular", 70, 1.0, 7.0, 0.0, 0.9 );
                selectText.setHorizontalAlignment( BALeft );
                characterSelectPane.addElement( selectText, DDTop );

                // Add some space
                characterSelectPane.addSpacer( 50, DDTop );

                // Write the profiles
                for( uint i = 0; i < profileData.size(); i++ ) {
                    // Add the character name and data in divider
                    AHGUI::Divider@ characterPane = characterSelectPane.addDivider( DDTop, DOVertical, ivec2( 650, 150 ) );
                    AHGUI::Text nameText( profileData[i]["character_name"].asString(), "OpenSans-Regular", 85, 1.0, 7.0, 0.0, 0.9 );
                    nameText.setHorizontalAlignment( BALeft );
                    // add some padding
                    nameText.setPadding( 15, 0, 15, 40 );
                    characterPane.addElement( nameText, DDTop );
                    AHGUI::Text battlesText( "Total battles: " + 
                            (profileData[i]["player_wins"].asInt() + profileData[i]["player_loses"].asInt() ), 
                            "OpenSans-Regular", 40, 1.0, 7.0, 0.0, 0.7 );
                    battlesText.setHorizontalAlignment( BALeft );
                    battlesText.setPadding( 10, 5, 30, 40 );

                    // Turn the character pane into a button

                    // Do some special effects
                    // Add a mouseover to indicate a new selection
                    characterPane.addMouseOverBehavior( AHGUI::MouseOverShowBorder() );
                    characterPane.addUpdateBehavior( AHGUI::PulseBorderAlpha( 0.5, 1.0, 0.5f ) );
                    
                    // Attach this as message sending behavior
                    characterPane.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick("profileselected", i) );
                    // Send messages according to mouse over events 
                    characterPane.addMouseOverBehavior( AHGUI::FixedMessageOnMouseOver( AHGUI::Message( "overprofile", i ),
                                                                                        null,
                                                                                        AHGUI::Message( "leaveprofile", i ) ) );
                    characterPane.addElement( battlesText, DDTop );

                    int sessionId = global_data.getSessionProfile();

                    if( sessionId != -1 && sessionId == profileData[i]["id"].asInt() ) {
                        @selectedProfile = @characterPane;

                        // Set the border to indicate the selection of the element
                        characterPane.setBorderSize(15);
                        characterPane.setBorderColor(1.0, 7.0, 0.0, 0.9);
                        characterPane.showBorder( true );

                        // record the index of this element 
                        selectedProfileNum = i;

                        populateInfoPanel( i );   
                    }
                }

                // If we haven't reached the maximum profiles, add the option to add a new one
                if( profileData.size() < 6 ) {
                    // Create the text 
                    AHGUI::Text newText( "New Profile", "OpenSans-Regular", 50, 1.0, 7.0, 0.0, 0.9 );
                    
                    // Turn it into a button
                    newText.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick("new") );
                    

                    // Add the effects
                    newText.addMouseOverBehavior( AHGUI::MouseOverPulseColor( 
                                                 vec4( 0.5, 7.0, 0.0, 0.3 ), 
                                                 vec4( 1.0, 7.0, 0.0, 0.9 ), 1.0f ) );

                    // Add them to the divider with some space 
                    characterSelectPane.addSpacer( 30, DDBottom );
                    characterSelectPane.addElement( newText, DDBottom );

                }

            }
            break;

            case agsConfirmDelete: {

                // We just need to display a message to the player

                // Create a divider for the non-footer
                AHGUI::Divider@ mainpane = root.addDivider( DDTop,  
                                                            DOVertical, 
                                                            ivec2( UNDEFINEDSIZE, 1140 ) );
                
                // For fun let's put an image on the screen 
                AHGUI::Image topImage("Textures/ui/versus_mode/fight_glyph.tga");
                topImage.scaleToSizeX(400);
                topImage.addUpdateBehavior( AHGUI::FadeIn( 250, @inSine ) );

                // Add this to the main pane 
                mainpane.addElement( topImage, DDTop ); 
                
                mainpane.addSpacer( 50, DDTop );

                // Make a little container for the message
                AHGUI::Divider@ messagepane = mainpane.addDivider( DDTop, DOVertical );

                // Create the text
                AHGUI::Text promptText( "Are you sure you want to delete?", "OpenSans-Regular", 75, 1.0, 7.0, 0.0, 0.8 );

                messagepane.addElement( promptText, DDTop );

                // Add some space
                messagepane.addSpacer( 175, DDTop );

                AHGUI::Divider@ buttonpane = messagepane.addDivider( DDCenter, DOHorizontal, ivec2( 600, UNDEFINEDSIZE ) );
                buttonpane.setName("buttonpane");

                // Create the buttons
                AHGUI::Text okText( "Ok", "OpenSans-Regular", 75, 1.0, 7.0, 0.0, 0.8 );
                okText.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick("ok") );
                // Make it pulse when we mouse over 
                okText.addMouseOverBehavior( AHGUI::MouseOverPulseColor( 
                                                        vec4( 0.8, 0.5, 0.0, 0.5 ), 
                                                        vec4( 1.0, 1.0, 0.0, 0.9 ), .25 ) );
                // Fade it in 
                okText.addUpdateBehavior( AHGUI::FadeIn( 500, @inSine ) );


                AHGUI::Text cancelText( "Cancel", "OpenSans-Regular", 75, 1.0, 7.0, 0.0, 0.8 );
                cancelText.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick("cancel") );
                // Make it pulse when we mouse over 
                cancelText.addMouseOverBehavior( AHGUI::MouseOverPulseColor( 
                                                        vec4( 0.8, 0.5, 0.0, 0.5 ), 
                                                        vec4( 1.0, 1.0, 0.0, 0.9 ), .25 ) );
                // Fade it in 
                cancelText.addUpdateBehavior( AHGUI::FadeIn( 500, @inSine ) );
                
                // Add the buttons to the layout 
                buttonpane.addElement( okText, DDLeft );
                buttonpane.addElement( cancelText, DDRight );
                cancelText.setName("cancelText");
                
                
            }
            break;
        }
    }

    /*******************************************************************************************/
    /**
     * @brief  Populates the info pane based on the given profile number (-1 for none)
     * 
     * @param profileNum index of profile to display  
     *
     */
     void populateInfoPanel( int profileNum ) {
        
        // If we're already showing it -- let's be lazy and get out of here
        if( showingProfileNum == profileNum and showingProfileDetails ) {
            return;
        }

        // Get a reference to the pane
        AHGUI::Element@ infoElement = root.findElement("infopane");

        if( infoElement is null  ) {
            DisplayError("GUI Error", "Unable to find info pane");
        }

        // Cast it to a divider so we can work with it
        AHGUI::Divider@ infoPane = cast<AHGUI::Divider>(infoElement);

        // Get rid of the old contents
        infoPane.clear();

        // Remove any update behaviors 
        infoPane.clearUpdateBehaviors();
        infoPane.setDisplacement();

        // Record that we're showing this
        showingProfileNum = profileNum;

        // If we're asked to display no profile, just stop here
        if( profileNum == -1 ) {
            return;
        }

        // Push the character selection down 
        infoPane.addSpacer( 100, DDTop );

        // build a divider to show this and the colors
        AHGUI::Divider@ statsPane = infoPane.addDivider( DDTop, DOHorizontal );

        // another divider for the numerical stats
        AHGUI::Divider@ attributePane = statsPane.addDivider( DDLeft, DOVertical );

        // Add the information text
        AHGUI::Text winsText( "Wins: " + profileData[profileNum]["player_wins"].asInt(), "OpenSans-Regular", 50, 1.0, 7.0, 0.0, 0.9 );
        winsText.setHorizontalAlignment( BALeft );
        AHGUI::Text losesText( "Loses: " + profileData[profileNum]["player_loses"].asInt(), "OpenSans-Regular", 50, 1.0, 7.0, 0.0, 0.9 );
        losesText.setHorizontalAlignment( BALeft );
        AHGUI::Text fanText( "Fan Base: " + profileData[profileNum]["fan_base"].asInt(), "OpenSans-Regular", 50, 1.0, 7.0, 0.0, 0.9 );
        fanText.setHorizontalAlignment( BALeft );
        float limitedSkill = limitDecimalPoints( profileData[profileNum]["player_skill"].asFloat(), 2 );

        AHGUI::Text skillText( "Skill Rating: " +  limitedSkill, "OpenSans-Regular", 50, 1.0, 7.0, 0.0, 0.9 );
        skillText.setHorizontalAlignment( BALeft );

        attributePane.addElement( winsText, DDTop );
        attributePane.addElement( losesText, DDTop );
        attributePane.addElement( fanText, DDTop );
        attributePane.addElement( skillText, DDTop );

        // add a divider for the colors
        AHGUI::Divider@ colorPane = statsPane.addDivider( DDRight, DOVertical );

        // add a row for the first two colors
        AHGUI::Divider@ firstRow = colorPane.addDivider( DDTop, DOHorizontal );        

        AHGUI::Image ULImage("Textures/ui/whiteblock.tga");
        ULImage.scaleToSizeX(80);
        ULImage.setPadding(15);
        ULImage.setBorderColor( 1.0, 6.0, 0.0, 0.6 );
        ULImage.setBorderSize( 5 );
        ULImage.showBorder();
        
        // Set the color of the (normally white) image to be our selected color
        vec4 ULColor( profileData[profileNum]["player_colors"][0][0].asFloat(), 
                      profileData[profileNum]["player_colors"][0][1].asFloat(),
                      profileData[profileNum]["player_colors"][0][2].asFloat(),
                      0.9 );

        ULImage.setColor( ULColor );

        firstRow.addElement( ULImage, DDLeft );

        AHGUI::Image URImage("Textures/ui/whiteblock.tga");
        URImage.scaleToSizeX(80);
        URImage.setPadding(15);
        URImage.setBorderColor( 1.0, 6.0, 0.0, 0.6 );
        URImage.setBorderSize( 5 );
        URImage.showBorder();
        
        // Set the color of the (normally white) image to be our selected color
        vec4 URColor( profileData[profileNum]["player_colors"][1][0].asFloat(), 
                      profileData[profileNum]["player_colors"][1][1].asFloat(),
                      profileData[profileNum]["player_colors"][1][2].asFloat(),
                      0.9 );

        URImage.setColor( URColor );

        firstRow.addElement( URImage, DDRight );


        // add a row for the second two colors
        AHGUI::Divider@ secondRow = colorPane.addDivider( DDTop, DOHorizontal );        

        AHGUI::Image LLImage("Textures/ui/whiteblock.tga");
        LLImage.scaleToSizeX(80);
        LLImage.setPadding(15);
        LLImage.setBorderColor( 1.0, 6.0, 0.0, 0.6 );
        LLImage.setBorderSize( 5 );
        LLImage.showBorder();
        
        // Set the color of the (normally white) image to be our selected color
        vec4 LLColor( profileData[profileNum]["player_colors"][2][0].asFloat(), 
                      profileData[profileNum]["player_colors"][2][1].asFloat(),
                      profileData[profileNum]["player_colors"][2][2].asFloat(),
                      0.9 );

        LLImage.setColor( LLColor );

        secondRow.addElement( LLImage, DDLeft );

        AHGUI::Image LRImage("Textures/ui/whiteblock.tga");
        LRImage.scaleToSizeX(80);
        LRImage.setPadding(15);
        LRImage.setBorderColor( 1.0, 6.0, 0.0, 0.6 );
        LRImage.setBorderSize( 5 );
        LRImage.showBorder();
        
        // Set the color of the (normally white) image to be our selected color
        vec4 LRColor( profileData[profileNum]["player_colors"][3][0].asFloat(), 
                      profileData[profileNum]["player_colors"][3][1].asFloat(),
                      profileData[profileNum]["player_colors"][3][2].asFloat(),
                      0.9 );

        LRImage.setColor( LRColor );

        secondRow.addElement( LRImage, DDRight );

        // Put some space between the two 
        statsPane.addSpacer( 125, DDLeft );

        // See if this is the selected profile
        if( profileNum != selectedProfileNum ) {
            // if not, fly it in
            infoPane.addUpdateBehavior( AHGUI::MoveIn( ivec2( 400, 0 ), 500 , @linear ) );
            showingProfileDetails = false;
        }
        else {

            showingProfileDetails = true;

            // Add the delete profile at the bottom
            AHGUI::Text deleteText( "Delete Profile", "OpenSans-Regular", 50, 1.0, 7.0, 0.0, 0.9 );
            //deleteText.setHorizontalAlignment( BARight );
                    
            // Turn it into a button
            deleteText.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick("delete") );
            

            // Add the effects
            deleteText.addMouseOverBehavior( AHGUI::MouseOverPulseColor( 
                                         vec4( 0.5, 7.0, 0.0, 0.3 ), 
                                         vec4( 1.0, 7.0, 0.0, 0.9 ), 1.0f ) );
            deleteText.addUpdateBehavior( AHGUI::FadeIn( 250, @inSine ) );

            // Add them to the divider with some space 
            infoPane.addSpacer( 30, DDBottom );
            infoPane.addElement( deleteText, DDTop );


            // if so, we can add the battle options 
            infoPane.addSpacer( 75, DDTop );
        
            // Make a divider for the battle selector 
            AHGUI::Divider@ battleSelect = infoPane.addDivider( DDTop, DOHorizontal );

            AHGUI::Image goLeftImage("Textures/arenamenu/left_arrow.tga");
            goLeftImage.scaleToSizeX(150);
            
            // Turn it into a button
            goLeftImage.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick("battledecrease") );

            // Add the effects
            goLeftImage.addMouseOverBehavior( AHGUI::MouseOverPulseColor( 
                                               vec4( 0.5, 6.0, 0.0, 0.3 ), 
                                               vec4( 1.0, 6.0, 0.0, 0.9 ), 1.0f ) );
            goLeftImage.addUpdateBehavior( AHGUI::FadeIn( 1250, @inSine ) );

            battleSelect.addElement( goLeftImage, DDLeft );

            AHGUI::Image battleImage(arenaImages[selectedArena]);
            battleImage.scaleToSizeX(450);
            battleImage.addUpdateBehavior( AHGUI::FadeIn( 750, @inSine ) );
            battleImage.setName( "battleimage" );
            battleSelect.addElement( battleImage, DDCenter );

            AHGUI::Image goRightImage("Textures/arenamenu/right_arrow.tga");
            goRightImage.scaleToSizeX(150);
            
            // Turn it into a button
            goRightImage.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick("battleincrease") );

            // Add the effects
            goRightImage.addMouseOverBehavior( AHGUI::MouseOverPulseColor( 
                                               vec4( 0.5, 6.0, 0.0, 0.3 ), 
                                               vec4( 1.0, 6.0, 0.0, 0.9 ), 1.0f ) );
            goRightImage.addUpdateBehavior( AHGUI::FadeIn( 1250, @inSine ) );

            battleSelect.addElement( goRightImage, DDRight );

            // Add the effects
            battleSelect.addMouseOverBehavior( AHGUI::MouseOverPulseColor( 
                                               vec4( 0.5, 6.0, 0.0, 0.3 ), 
                                               vec4( 1.0, 6.0, 0.0, 0.9 ), 1.0f ) );

            AHGUI::Text battleNameText( arenaNames[selectedArena], "OpenSans-Regular", 50, 1.0, 6.0, 0.1, 0.9 );
            battleNameText.addUpdateBehavior( AHGUI::FadeIn( 1000, @inSine ) );
            battleNameText.setName( "battlename" );
            infoPane.addElement( battleNameText, DDTop );

            infoPane.addSpacer( 125, DDTop );

            // Add the begin battle 
            AHGUI::Text fightText( "Start Fight!", "OpenSans-Regular", 75, 1.0, 7.0, 0.0, 0.9 );
            infoPane.addElement( fightText, DDTop );

            // Turn it into a button
            fightText.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick("start") );
            

            // Add the effects
            fightText.addMouseOverBehavior( AHGUI::MouseOverPulseColor( 
                                         vec4( 0.5, 7.0, 0.0, 0.3 ), 
                                         vec4( 1.0, 7.0, 0.0, 0.9 ), 1.0f ) );
            fightText.addUpdateBehavior( AHGUI::FadeIn( 2000, @inSine ) );


                      

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
            global_data.WritePersistentInfo( false );
            this_ui.SendCallback("back");
        }

        // switch on the state -- though the messages should be unique
        switch( currentState ) {
            case agsInvalidState: {
                // For completeness -- throw an error and move on
                DisplayError("GUI Error", "GUI in invalid state");
            }
            break;
            case agsFirstTime: {
                if( message.name == "createprofile" ) {
                    currentState = agsNewProfile;
                }
            }
            break;

            case agsNewProfile: {
                if( message.name == "newrandomname") {

                    // Generate a new random name
                    newCharacter["character_name"] = JSONValue( global_data.generateRandomName() );

                    // Find the element in the layout, by name
                    AHGUI::Text@ nameText = cast<AHGUI::Text>(root.findElement("newNameText"));

                    // Do a pseudo-cross fade onto the new text
                    nameText.addUpdateBehavior( AHGUI::ChangeTextFadeOutIn( 250, newCharacter["character_name"].asString(), outSine, inSine ), "textchange" );

                }
                else if( message.name == "colorselected" ) {

                    // reset the border of the now deselected element
                    int colorNum = message.intParams[0];

                    furColorSelected[colorNum].setBorderColor( 1.0, 1.0, 1.0, 1.0 );
                    furColorSelected[colorNum].setBorderSize(5);
                    furColorSelected[colorNum].showBorder( false );

                    // write the color into new profile
                    newCharacter["player_colors"][colorNum][0] = JSONValue( message.floatParams[0] );
                    newCharacter["player_colors"][colorNum][1] = JSONValue( message.floatParams[1] );
                    newCharacter["player_colors"][colorNum][2] = JSONValue( message.floatParams[2] );

                    // set the border for the newly selected element
                    message.sender.setBorderColor( 0.2, 0.0, 1.0, 1.0 );
                    message.sender.setBorderSize(10);
                    message.sender.showBorder(true);

                    // now store this element for future reference 
                    @furColorSelected[colorNum] = @message.sender;

                }
                else if( message.name == "cancel" ) {
                    // We can throw this all away and go back (depending on if we have profiles)
                    if( profileData.size() != 0 ) {
                        currentState = agsSelectProfile;
                    }
                    else {
                        currentState = agsFirstTime;
                    }
                }
                else if( message.name == "ok" ) {
                    // Excellent, we can write in this profile and get on with things
                    global_data.addProfile( newCharacter );
                    global_data.WritePersistentInfo( false );
                    currentState = agsSelectProfile;
                }
            }
            break;

            case agsSelectProfile: {
                if( message.name == "new") {
                    // just change state 
                    currentState = agsNewProfile;
                }
                else if( message.name == "profileselected" ) {
                    // if we have a profile already selected, clear the indication from 
                    //  the old one
                    // It would be pretty easy to create a widget that did this kind of
                    //  selection automatically -- but one thing at a time
                    if( selectedProfile !is null ) {
                        // reset the border size/style 
                        selectedProfile.setBorderSize(1);
                        selectedProfile.setBorderColor(1.0, 1.0, 1.0, 1.0);
                        selectedProfile.showBorder( false );
                    }

                    @selectedProfile = @message.sender;

                    // Set the border to indicate the selection of the element
                    selectedProfile.setBorderSize(15);
                    selectedProfile.setBorderColor(1.0, 7.0, 0.0, 0.9);
                    selectedProfile.showBorder( true );

                    // record the index of this element 
                    selectedProfileNum = message.intParams[0];
                }
                else if( message.name == "overprofile" ) {
                    // Show this in the info pane
                    populateInfoPanel( message.intParams[0] );

                }
                else if( message.name == "leaveprofile" ) {
                    // See if we're still showing this profile
                    if( showingProfileNum == message.intParams[0] ) {
                        // if we are just show the selectedProfile
                        if( selectedProfileNum != -1 || showingProfileNum != selectedProfileNum  ) {
                            populateInfoPanel( selectedProfileNum );    
                        }
                    }
                }
                else if( message.name == "battleincrease" ) {
                    selectedArena = ( selectedArena + 1 ) % arenaImages.length();

                    // Find the picture in the layout, by name
                    AHGUI::Image@ battleImage = cast<AHGUI::Image>(root.findElement("battleimage"));
                    // Change the image
                    battleImage.setImageFile( arenaImages[selectedArena] );
                    battleImage.scaleToSizeX(450);
                    battleImage.addUpdateBehavior( AHGUI::FadeIn( 250, @inSine ), "fadein" );

                    // Find the text in the layout, by name
                    AHGUI::Text@ battleText = cast<AHGUI::Text>(root.findElement("battlename"));
                    // Change the text
                    battleText.setText( arenaNames[selectedArena] );
                    battleText.addUpdateBehavior( AHGUI::FadeIn( 250, @inSine ), "fadein" );

                }
                else if( message.name == "battledecrease" ) {
                    selectedArena = ( arenaImages.length() + selectedArena - 1 ) % arenaImages.length();

                    // Find the picture in the layout, by name
                    AHGUI::Image@ battleImage = cast<AHGUI::Image>(root.findElement("battleimage"));
                    // Change the image
                    battleImage.setImageFile( arenaImages[selectedArena] );
                    battleImage.scaleToSizeX(450);
                    battleImage.addUpdateBehavior( AHGUI::FadeIn( 250, @inSine ), "fadein" );

                    // Find the text in the layout, by name
                    AHGUI::Text@ battleText = cast<AHGUI::Text>(root.findElement("battlename"));
                    // Change the text
                    battleText.setText( arenaNames[selectedArena] );
                    battleText.addUpdateBehavior( AHGUI::FadeIn( 250, @inSine ), "fadein" );

                }
                else if( message.name == "delete" ) {
                    // Change to the confirmation screen
                    currentState = agsConfirmDelete;
                }
                else if( message.name == "start" ) {
                    if( selectedProfileNum != -1 ) {
                        global_data.setSessionProfile( profileData[selectedProfileNum]["id"].asInt() );

                        // Start the level!
                        this_ui.SendCallback("arenas/" + arenaLevels[selectedArena] );
                    }
                }

            }
            break;

            case agsConfirmDelete: {
                if( message.name == "ok" ) {

                    if( selectedProfileNum != -1 ) {
                        // delete the profile
                        global_data.removeProfile( profileData[selectedProfileNum]["id"].asInt() );
                        global_data.WritePersistentInfo( false );
                    }

                    // Refresh our profile data
                    profileData = global_data.getProfiles();

                    if( profileData.size() != 0 ) {
                        currentState = agsSelectProfile;
                    }
                    else {
                        currentState = agsFirstTime;
                    }
                    
                }
                else if( message.name == "cancel" ) {
                    // Just go back to the selection screen
                    currentState = agsSelectProfile;
                }
            }
            break;
        }

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

        if( bp !is null ){
            Print("buttonpane size: " + bp.getSize().toString() + "\n" );
            Print("buttonpane boundary size: " + bp.boundarySize.toString() + "\n" );
            Print("buttonpane boundary offset: " + bp.boundaryOffset.toString() + "\n" );
            Print("buttonpane bottomRightBoundStart: " + bp.bottomRightBoundStart + "\n" );
        }

        // Update the GUI 
        AHGUI::GUI::update();

    }

    /*******************************************************************************************/
    /**
     * @brief  Render the gui
     * 
     */
     void render() {

        // Update the background 
        // TODO: fold this into AHGUI
        ribbon_background.Update();
        visible = UpdateVisible(visible, target_visible);
        ribbon_background.DrawGUI(visible);
        hud.Draw();

        // Update the GUI 
        AHGUI::GUI::render();

     }


}

ArenaGUI arenaGUI;

bool HasFocus(){
    return false;
}

void Initialize(){

}

void Update(){
    arenaGUI.update();
}

void DrawGUI(){
    arenaGUI.render(); 
}

void Draw(){
}

void Init(string str){
}

void StartArenaMeta(){

}


