// Common items for all menus in the system

/*******
 *  
 * Fonts
 *
 */

string col = "#fff";
vec4 white = HexColor(col);
vec4 brightYellow = HexColor("#ffe600");
vec4 mediumYellow = HexColor("#ffde00");
vec4 khakiYellow = HexColor("#8b864e");
vec4 gold = HexColor("#EEC900");
vec4 butterMilk = HexColor("#FEF1B5");

FontSetup selectionListFont("OpenSans-Regular", 70, white, true);
FontSetup noteFont("OpenSans-Regular", 40, mediumYellow, false);
FontSetup creditFontSmall("OptimusPrinceps", 70, white, false); 
FontSetup creditFontBig("OptimusPrinceps", 120, white, false); 

FontSetup titleFont("edosz", 125, HexColor("#fff"));
FontSetup labelFont("Inconsolata", 80 , HexColor("#fff"));
FontSetup backFont("edosz", 60 , HexColor("#fff"));


/*******
 *  
 * Behaviors
 *
 */

IMMouseOverPulseColor selectionListButtonHover( butterMilk, mediumYellow, 2 );

/*******
 *  
 * Ribbon background
 *
 */

// Draw the fancy scrolling ribbon background/foreground
// Assumes:
//  - the GUI has at least one background and foreground layer 
//  - there's nothing else in the first background and first foreground layer
class RibbonEffect {
    
    IMGUI@ theGUI;  // GUI to modify

    // Coordinates (in GUI space) for the various 
    // Foreground objects
    vec2 fgUpper1Position;
    vec2 fgUpper2Position;
    vec2 fgLower1Position;
    vec2 fgLower2Position;
    // Background objects
    vec2 bgRibbonUp1Position;
    vec2 bgRibbonUp2Position;
    vec2 bgRibbonDown1Position;
    vec2 bgRibbonDown2Position;

    vec4 bgColor;
    vec4 fgColor;
    vec4 ribbonUpColor;
    vec4 ribbonDownColor;



    RibbonEffect( IMGUI@ _GUI, 
              vec4 _bgColor = vec4(1.0,1.0,1.0,0.8 ), 
              vec4 _fgColor = vec4( 0.7,0.7,0.7,0.7 ),
              vec4 _ribbonUpColor = vec4( 0.0,0.0,0.0,1.0 ),
              vec4 _ribbonDownColor = vec4( 0.0,0.0,0.0,1.0 ) ) {
        @theGUI = @_GUI;   
        bgColor = _bgColor;
        fgColor = _fgColor;
        ribbonUpColor = _ribbonUpColor;
        ribbonDownColor = _ribbonDownColor;
    }

    // Derive the starting offsets the various visual components
    void resetPositions() {
        fgUpper1Position =      vec2( 0,    0 );
        fgUpper2Position =      vec2( 2560, 0 );
        fgLower1Position =      vec2( 0,    screenMetrics.GUISpace.y/2 );
        fgLower2Position =      vec2( 2560, screenMetrics.GUISpace.y/2 );
        bgRibbonUp1Position =   vec2( 0, 0 );
        bgRibbonUp2Position =   vec2( 0, screenMetrics.GUISpace.y );
        bgRibbonDown1Position = vec2( 0, 0 );
        bgRibbonDown2Position = vec2( 0, -screenMetrics.GUISpace.y );        
    }

    // Make this a separate function so we can call it on resize
    void reset() {

        Print("GUIspace: " + screenMetrics.GUISpace.x + ", " + screenMetrics.GUISpace.y + "\n" );

        Log(info, "Ribbon reset");

        resetPositions();

        // get references to the foreground and background containers
        IMContainer@ background = theGUI.getBackgroundLayer();
        IMContainer@ foreground = theGUI.getForegroundLayer();

        background.clear();
        background.clear();

        // Make a new image 
        IMImage backgroundImage("Textures/ui/menus/ribbon/blue_gradient_c_nocompress.tga");
        // fill the screen
        backgroundImage.setSize(vec2(2560.0, screenMetrics.GUISpace.y));
        backgroundImage.setColor( bgColor );
        // Call it bgBG and give it a z value of 1 to put it furthest behind
        background.addFloatingElement( backgroundImage, "bgBG", vec2( 0, 0 ), 1 );  

        // Make a new image for half the upper image
        IMImage fgImageUpper1("Textures/ui/menus/ribbon/red_gradient_border_c.tga");
        fgImageUpper1.setSize(vec2(2560, screenMetrics.GUISpace.y/2));
        fgImageUpper1.setColor( fgColor );
        // use only the top half(ish) of the image
        fgImageUpper1.setImageOffset( vec2(0,0), vec2(1024, 600) );
        // flip it upside down 
        fgImageUpper1.setRotation( 180 );
        // Call it gradientUpper1 
        foreground.addFloatingElement( fgImageUpper1, "gradientUpper1", fgUpper1Position, 2 );

        // repeat for a second image so we can scroll unbrokenly  
        IMImage fgImageUpper2("Textures/ui/menus/ribbon/red_gradient_border_c.tga");
        fgImageUpper2.setSize(vec2(2560, screenMetrics.GUISpace.y/2));
        fgImageUpper2.setColor( fgColor );
        fgImageUpper2.setImageOffset( vec2(0,0), vec2(1024, 600) );
        fgImageUpper2.setRotation( 180 );
        foreground.addFloatingElement( fgImageUpper2, "gradientUpper2", fgUpper2Position, 2 );        

        // repeat again for the bottom image(s) (not flipped this time)
        IMImage bgImageLower1("Textures/ui/menus/ribbon/red_gradient_border_c.tga");
        bgImageLower1.setSize(vec2(2560, screenMetrics.GUISpace.y/2));
        bgImageLower1.setColor( fgColor );
        bgImageLower1.setImageOffset( vec2(0,0), vec2(1024, 600) );
        foreground.addFloatingElement( bgImageLower1, "gradientLower1", fgLower1Position, 2 ); 

        IMImage fgImageLower2("Textures/ui/menus/ribbon/red_gradient_border_c.tga");
        fgImageLower2.setSize(vec2(2560, screenMetrics.GUISpace.y/2));
        fgImageLower2.setColor( fgColor );
        fgImageLower2.setImageOffset( vec2(0,0), vec2(1024, 600) );
        foreground.addFloatingElement( fgImageLower2, "gradientLower2", fgLower2Position, 2 );   

        // Repeat this same process for the two 'ribbons' which will, instead' go up and down
        IMImage bgRibbonUp1("Textures/ui/menus/ribbon/giometric_ribbon_c.tga");
        bgRibbonUp1.setImageOffset( vec2(256,0), vec2(768, 1024) );
        // Fill the left half of the screen
        bgRibbonUp1.setSize(vec2(1280, screenMetrics.GUISpace.y));
        bgRibbonUp1.setColor( ribbonUpColor );
        // Put this at the front of the blue background (z=3)
        background.addFloatingElement( bgRibbonUp1, "ribbonUp1", bgRibbonUp1Position, 3 );

        IMImage bgRibbonUp2("Textures/ui/menus/ribbon/giometric_ribbon_c.tga");
        bgRibbonUp2.setImageOffset( vec2(256,0), vec2(768, 1024) );
        bgRibbonUp2.setSize(vec2(1280, screenMetrics.GUISpace.y));
        bgRibbonUp2.setColor( ribbonUpColor );
        background.addFloatingElement( bgRibbonUp2, "ribbonUp2", bgRibbonUp2Position, 3 );
        
        IMImage bgRibbonDown1("Textures/ui/menus/ribbon/giometric_ribbon_c.tga");
        bgRibbonDown1.setImageOffset( vec2(256,0), vec2(768, 1024) );
        bgRibbonDown1.setSize(vec2(1280, screenMetrics.GUISpace.y));
        bgRibbonDown1.setColor( ribbonDownColor );
        background.addFloatingElement( bgRibbonDown1, "ribbonDown1", bgRibbonDown1Position, 3 );

        IMImage bgRibbonDown2("Textures/ui/menus/ribbon/giometric_ribbon_c.tga");
        bgRibbonDown2.setImageOffset( vec2(256,0), vec2(768, 1024) );
        bgRibbonDown2.setSize(vec2(1280, screenMetrics.GUISpace.y));
        bgRibbonDown2.setColor( ribbonDownColor );
        background.addFloatingElement( bgRibbonDown2, "ribbonDown2", bgRibbonDown2Position, 3 );
    
    }

    // Go through the motions
    void update() {
        // Calculate the new positions
        fgUpper1Position.x -= 2;
        fgUpper2Position.x -= 2;
        fgLower1Position.x -= 1;
        fgLower2Position.x -= 1;
        bgRibbonUp1Position.y -= 1;
        bgRibbonUp2Position.y -= 1;
        bgRibbonDown1Position.y += 1;
        bgRibbonDown2Position.y += 1;

        // wrap the images around
        if( fgUpper1Position.x == 0 ) {
            fgUpper2Position.x = 2560;
        }

        if( fgUpper2Position.x == 0 ) {
            fgUpper1Position.x = 2560;
        }

        if( fgLower1Position.x == 0 ) {
            fgLower2Position.x = 2560;
        }

        if( fgLower2Position.x == 0 ) {
            fgLower1Position.x = 2560;
        }

        if( bgRibbonUp1Position.y <= -screenMetrics.GUISpace.y ) {
            bgRibbonUp1Position.y = screenMetrics.GUISpace.y;
        }

        if( bgRibbonUp2Position.y <= -screenMetrics.GUISpace.y ) {
            bgRibbonUp2Position.y = screenMetrics.GUISpace.y;
        }

        if( bgRibbonDown1Position.y >= screenMetrics.GUISpace.y ) {
            bgRibbonDown1Position.y = -screenMetrics.GUISpace.y;
        }

        if( bgRibbonDown2Position.y >= screenMetrics.GUISpace.y ) {
            bgRibbonDown2Position.y = -screenMetrics.GUISpace.y;
        }

        // Get a reference to the first background container
        IMContainer@ background = theGUI.getBackgroundLayer();
        IMContainer@ foreground = theGUI.getForegroundLayer();

        // Update the images position in the container
        foreground.moveElement( "gradientUpper1", fgUpper1Position );
        foreground.moveElement( "gradientUpper2", fgUpper2Position );
        foreground.moveElement( "gradientLower1", fgLower1Position );
        foreground.moveElement( "gradientLower2", fgLower2Position );
        background.moveElement( "ribbonUp1",      bgRibbonUp1Position );
        background.moveElement( "ribbonUp2",      bgRibbonUp2Position );
        background.moveElement( "ribbonDown1",    bgRibbonDown1Position );
        background.moveElement( "ribbonDown2",    bgRibbonDown2Position );
    }

};