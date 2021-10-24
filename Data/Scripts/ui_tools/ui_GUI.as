#include "ui_tools/ui_Element.as"
#include "ui_tools/ui_Message.as"
#include "ui_tools/ui_support.as"

/*******
 *  
 * ui_GUI.as
 *
 * Main class for creating adhoc GUIs as part of the UI tools  
 *
 */

namespace AHGUI {

/*******************************************************************************************/
/**
 * @brief One thing to rule them all
 *
 */
class GUI {

    Divider@ root;  // Root of the UI, holds all the contents 
    uint64 lastUpdateTime; // When was this last updated (ms)
    uint elementCount; // Counter for naming unnamed elements
    ivec2 aspectCompensation; // offset from the upper left hand corner for 'letterboxing' 
    bool needsRelayout; // has a relayout signal been fired?
    bool showGuides; // overlay some extra lines to aid layout
    IMUIContext imui_context; // Getting UI information from the engine
    ivec2 mousePosition; // Where is the mouse?
    UIMouseState leftMouseState; // What's the state of the left mouse button?
    array<Message@> messageQueue;// Messages waiting to process

    /*******************************************************************************************/
    /**
     * @brief Constructor
     *  
     * @param mainOrientation The orientation of the container
     *
     */
    GUI( DividerOrientation mainOrientation = DividerOrientation::DOVertical ) {
        
        Divider newRoot( "root", mainOrientation );
        newRoot.setSize( GUISpaceX, GUISpaceY );

        @newRoot.owner = @this;
        @newRoot.parent = null;
        @root = @newRoot;
        lastUpdateTime = 0;

        aspectCompensation = getRenderOffset();

        needsRelayout = false;
        showGuides = false;

        imui_context.Init();

    }

    /*******************************************************************************************/
    /**
     * @brief Destructor 
     *  
     */
    ~GUI() {
        @root = null;
    }

    /*******************************************************************************************/
    /**
     * @brief  Clear the GUI
     * 
     * @param mainOrientation The orientation of the container
     *
     */
     void clear( DividerOrientation mainOrientation = AHGUI::DividerOrientation::DOVertical ) {
        Divider newRoot( "root", mainOrientation );
        newRoot.setSize( GUISpaceX, GUISpaceY );

        @newRoot.owner = @this;
        @newRoot.parent = null;
        @root = @newRoot;
     }

    /*******************************************************************************************/
    /**
     * @brief  Turns on (or off) the visual guides
     *  
     * @param setting True to turn on guides, false otherwise
     *
     */
     void setGuides( bool setting ) {
        showGuides = setting;
     }

    /*******************************************************************************************/
    /**
     * @brief  When this element is resized, moved, etc propagate this signal upwards
     * 
     */
     void onRelayout() {

        // Record this
        needsRelayout = true;
     
     }

    /*******************************************************************************************/
    /**
     * @brief  Receives a message - used internally
     * 
     * @param message The message in question  
     *
     */
     void receiveMessage( Message@ message ) {
        messageQueue.insertLast( message );
     }

    /*******************************************************************************************/
    /**
     * @brief Called for each message received -- override this one in your subclass to 
     *        deal with messages from the GUI
     * 
     * @param message The message in question  
     *
     */
     void processMessage( Message@ message ) {
        // Print("Got a message: " + message.name + "\n");

        // for( uint i = 0; i < message.intParams.length(); i++ ) {
        //     Print("Int parameter " + i + ": " + message.intParams[ i ] + "\n" );
        // }

        // for( uint i = 0; i < message.stringParams.length(); i++ ) {
        //     Print("String parameter " + i + ": " + message.stringParams[ i ] + "\n" );
        // }

        // for( uint i = 0; i < message.floatParams.length(); i++ ) {
        //     Print("Float parameter " + i + ": " + message.floatParams[ i ] + "\n" );
        // }
     }

    /*******************************************************************************************/
    /**
     * @brief  Updates the gui  
     * 
     */
    int count = 0;

    void update() {


        // If we haven't updated yet, set the time
        if( lastUpdateTime == 0 ) {
            lastUpdateTime = uint64( the_time * 1000 );
        }

        // Calculate the delta time 
        uint64 delta = uint64( the_time * 1000 ) - lastUpdateTime;

        imui_context.UpdateControls();

        vec2 engineMousePos = imui_context.getMousePosition();

        // Translate to GUISpace
        mousePosition.x = int( (engineMousePos.x - renderOffset.x ) / GUItoScreenXScale );
        mousePosition.y = int(float( GetScreenHeight() - int( engineMousePos.y + renderOffset.y ) ) / GUItoScreenYScale);  
        leftMouseState = imui_context.getLeftMouseState();

        if( showGuides ) {

            for( int i = 2; i <= 16; i *= 2 ) {

                // draw the vertical lines 
                int increment = GetScreenWidth() / i;
                int xpos = increment;

                while( xpos < GetScreenWidth() ) {

                    HUDImage @newimage = hud.AddImage();
                    newimage.SetImageFromPath("Data/Textures/ui/whiteblock.tga");

                    ivec2 imagepos( xpos-1, 0 );
                    
                    newimage.scale = 1;
                    newimage.scale.x *= 2;
                    newimage.scale.y *= GetScreenHeight();

                    newimage.position.x = imagepos.x;
                    newimage.position.y = GetScreenHeight() - imagepos.y - (newimage.GetWidth() * newimage.scale.y );
                    newimage.position.z = -100.0;// 0.1f;

                    newimage.color = vec4( 0.0, 0.2, 0.5 + (0.5/i), 0.25 );

                    xpos += increment;
                }

                increment = GetScreenHeight() / i;
                int ypos = increment;

                while( ypos < GetScreenHeight() ) {

                    HUDImage @newimage = hud.AddImage();
                    newimage.SetImageFromPath("Data/Textures/ui/whiteblock.tga");

                    ivec2 imagepos( 0, ypos -1 );
                    
                    newimage.scale = 1;
                    newimage.scale.x *= GetScreenWidth();
                    newimage.scale.y *= 2;

                    newimage.position.x = imagepos.x;
                    newimage.position.y = GetScreenHeight() - imagepos.y - (newimage.GetWidth() * newimage.scale.y );
                    newimage.position.z = -100.0;// 0.1f;

                    newimage.color = vec4( 0.0, 0.2, 0.5 + (0.5/i), 0.25 );

                    ypos += increment;
                }
            }
        }

        // Blackout the top and bottom if we're 'letterboxing' 
        if( renderOffset.y > 0 ) {

            // Top bar
            HUDImage @topbar = hud.AddImage();
            topbar.SetImageFromPath("Data/Textures/ui/whiteblock.tga");

            ivec2 imagepos( 0, 0 );
            
            topbar.scale = 1;
            topbar.scale.x *= GetScreenWidth();
            topbar.scale.y *= renderOffset.y;

            topbar.position.x = imagepos.x;
            topbar.position.y = GetScreenHeight() - imagepos.y - (topbar.GetWidth() * topbar.scale.y );
            topbar.position.z = 10.0;// 0.1f;

            topbar.color = vec4( 0.0, 0.0, 0.0, 1.0f ); 

            // Bottom bar
            HUDImage @bottombar = hud.AddImage();
            bottombar.SetImageFromPath("Data/Textures/ui/whiteblock.tga");

            imagepos = ivec2( 0, GetScreenHeight() - renderOffset.y );
            
            bottombar.scale = 1;
            bottombar.scale.x *= GetScreenWidth();
            bottombar.scale.y *= renderOffset.y;

            bottombar.position.x = imagepos.x;
            bottombar.position.y = GetScreenHeight() - imagepos.y - (bottombar.GetWidth() * bottombar.scale.y );
            bottombar.position.z = 10.0;// 0.1f;

            bottombar.color = vec4( 0.0, 0.0, 0.0, 1.0f );   
        }

        // Do relayout as necessary 
        while( needsRelayout ) {
            needsRelayout = false;
            root.doRelayout();

            // MJB Note: I'm aware that redoing the layout for the whole structure
            // is rather inefficient, but given that this is targeted at most a few
            // dozen elements, this should not be a problem -- can easily be optimized
            // if so
        }

        ivec2 origin(0,0);

        // Now pass this on to the children

        GUIState guistate;

        guistate.mousePosition = mousePosition;
        guistate.leftMouseState = leftMouseState;

        root.update( delta, origin, guistate );

        hud.Draw();

        while( needsRelayout ) {
            needsRelayout = false;
            root.doRelayout();
        }

        // Finally process all of our message
        for( uint i = 0; i < messageQueue.length(); i++ ) {
            processMessage( messageQueue[i] );
        }

        messageQueue.resize(0);

    }

    /*******************************************************************************************/
    /**
     * @brief  Gets a unique name for assigning to unnamed elements (used internally)
     * 
     * @returns Unique name as string
     *
     */
    string getUniqueName() {
        elementCount += 1;
        return "element" + elementCount;
    }

}
} // namespace AHGUI

