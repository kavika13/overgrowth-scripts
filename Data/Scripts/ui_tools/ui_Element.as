#include "ui_tools/ui_support.as"
#include "ui_tools/ui_guistate.as"

/*******
 *  
 * ui_element.as
 *
 * Root element class for creating adhoc GUIs as part of the UI tools   
 *
 */

namespace AHGUI {

/*******************************************************************************************/
/**
 * @brief  Attachable behavior base class - called on update
 * 
 */
class UpdateBehavior {

    bool initialized = false;   // Has this update been run once?

    /*******************************************************************************************/
    /**
     * @brief  Called before the first update
     * 
     * @param element The element attached to this behavior 
     * @param delta Number of millisecond elapsed since last update
     * @param drawOffset Absolute offset from the upper lefthand corner (GUI space)
     * @param guistate The state of the GUI at this update
     *
     * @returns true if this behavior should continue next update, false otherwise
     *
     */
    bool initialize( Element@ element, uint64 delta, ivec2 drawOffset, GUIState& guistate ) {
        return true;
    }

    /*******************************************************************************************/
    /**
     * @brief  Called on update
     * 
     * @param element The element attached to this behavior 
     * @param delta Number of millisecond elapsed since last update
     * @param drawOffset Absolute offset from the upper lefthand corner (GUI space)
     * @param guistate The state of the GUI at this update
     *
     * @returns true if this behavior should continue next update, false otherwise
     *
     */
    bool update( Element@ element, uint64 delta, ivec2 drawOffset, GUIState& guistate ) {
        return true;
    }

}

/*******************************************************************************************/
/**
 * @brief  Attachable behavior base class - called on mouse over 
 * 
 */
class MouseOverBehavior {

    /*******************************************************************************************/
    /**
     * @brief  Called when the mouse enters the element
     * 
     * @param element The element attached to this behavior 
     * @param delta Number of millisecond elapsed since last update
     * @param drawOffset Absolute offset from the upper lefthand corner (GUI space)
     * @param guistate The state of the GUI at this update
     *
     */
    void onStart( Element@ element, uint64 delta, ivec2 drawOffset, GUIState& guistate ) {

    }

    /*******************************************************************************************/
    /**
     * @brief  Called when the mouse is still over the element 
     * 
     * @param element The element attached to this behavior 
     * @param delta Number of millisecond elapsed since last update
     * @param drawOffset Absolute offset from the upper lefthand corner (GUI space)
     * @param guistate The state of the GUI at this update
     *
     */
    void onContinue( Element@ element, uint64 delta, ivec2 drawOffset, GUIState& guistate ) {

    }

    /*******************************************************************************************/
    /**
     * @brief  Called when the mouse leaves the element
     * 
     * @param element The element attached to this behavior 
     * @param delta Number of millisecond elapsed since last update
     * @param drawOffset Absolute offset from the upper lefthand corner (GUI space)
     * @param guistate The state of the GUI at this update
     *
     * @return true if this behavior should be retained, false otherwise
     *
     */
    bool onFinish( Element@ element, uint64 delta, ivec2 drawOffset, GUIState& guistate ) {
        return true;
    }

}

/*******************************************************************************************/
/**
 * @brief  Attachable behavior base class - called on mouse down 
 * 
 */
class MouseClickBehavior {

    /*******************************************************************************************/
    /**
     * @brief  Called when the mouse button is pressed on element
     * 
     * @param element The element attached to this behavior 
     * @param delta Number of millisecond elapsed since last update
     * @param drawOffset Absolute offset from the upper lefthand corner (GUI space)
     * @param guistate The state of the GUI at this update
     *
     * @return true if this behavior should be retained, false otherwise
     *
     */
    bool onDown( Element@ element, uint64 delta, ivec2 drawOffset, GUIState& guistate ) {
        return true;
    }

    /*******************************************************************************************/
    /**
     * @brief  Called when the mouse button continues to be pressed on an element
     * 
     * @param element The element attached to this behavior 
     * @param delta Number of millisecond elapsed since last update
     * @param drawOffset Absolute offset from the upper lefthand corner (GUI space)
     * @param guistate The state of the GUI at this update
     *
     * @return true if this behavior should be retained, false otherwise
     *
     */
    bool onStillDown( Element@ element, uint64 delta, ivec2 drawOffset, GUIState& guistate ) {
        return true;
    }

    /*******************************************************************************************/
    /**
     * @brief  Called when the mouse button is released on element
     * 
     * @param element The element attached to this behavior 
     * @param delta Number of millisecond elapsed since last update
     * @param drawOffset Absolute offset from the upper lefthand corner (GUI space)
     * @param guistate The state of the GUI at this update
     *
     * @return true if this behavior should be retained, false otherwise
     *
     */
    bool onUp( Element@ element, uint64 delta, ivec2 drawOffset, GUIState& guistate ) {
        return true;
    }

}


/*******************************************************************************************/
/**
 * @brief  Base class for all AdHoc Gui elements
 *
 */
class Element {

    ivec2 size;             // dimensions of the actual region (GUI space)    
    ivec2 boundarySize;     // length and width of the maximum extent of this element (GUI Space) 
    ivec2 boundaryMax;      // the absolute biggest that this element can get
    ivec2 boundaryOffset;   // upper left coordinate relative to the containing boundary (GUI space)
    ivec2 drawDisplacement; // Is this element being drawn somewhere other than where it 'lives' (mostly for tweening)
    BoundaryAlignment alignmentX; // How to position this element versus a boundary that's bigger than the size
    BoundaryAlignment alignmentY; // How to position this element versus a boundary that's bigger than the size
    int paddingU;           // (minimum) Padding between the element and the upper boundary 
    int paddingD;           // (minimum) Padding between the element and the lower boundary 
    int paddingL;           // (minimum) Padding between the element and the left boundary 
    int paddingR;           // (minimum) Padding between the element and the right boundary 


    string name;            // name to refer to this object by -- incumbent on the programmer to make sure they're unique
    
    Element@ parent;        // null if 'root'
    GUI@ owner;             // what GUI owns this element

    array<UpdateBehavior@> updateBehaviors;         // update behaviors
    array<MouseOverBehavior@> mouseOverBehaviors;   // mouse over behaviors
    array<MouseClickBehavior@> leftMouseClickBehaviors;        // mouse up behaviors

    bool show;          // should this element be rendered?
    vec4 color;         // if this element is colored, what color is it? -- other elements may define further colors
    bool border;        // should this element have a border?
    int borderSize;     // how thick is this border (in GUI space pixels)
    vec4 borderColor;   // color for the border 

    bool mouseOver;     // has mouse been over this element

    /*******************************************************************************************/
    /**
     * @brief  Initializes the element (called internally)
     * 
     */
     void init() {
        
        name = "";

        size = ivec2( UNDEFINEDSIZE,UNDEFINEDSIZE );
        boundarySize = ivec2( UNDEFINEDSIZE,UNDEFINEDSIZE );
        boundaryMax = ivec2( UNDEFINEDSIZE,UNDEFINEDSIZE );
        boundaryOffset = ivec2( 0, 0 );
        drawDisplacement = ivec2( 0, 0);

        @parent = null;
        @owner = null;

        setPadding( 0 );

        show = true;
        color = vec4(1.0,1.0,1.0,1.0);
        border = false;
        borderSize = 1;
        borderColor = vec4(1.0,1.0,1.0,1.0);

        mouseOver = false;

        // By default every element is in the center of its container
        alignmentX = BACenter;
        alignmentY = BACenter;

     }

    /*******************************************************************************************/
    /**
     * @brief  Constructor
     * 
     * @param _name Name for this object (incumbent on the programmer to make sure they're unique)
     *
     */
    Element( string _name ) {
        
        init();
        name = _name;

    }

    /*******************************************************************************************/
    /**
     * @brief  Constructor
     * 
     */
    Element() {
        
        init();

    }
    
    /*******************************************************************************************/
    /**
     * @brief  Gets the name of the type of this element — for autonaming and debugging
     * 
     * @returns name of the element type as a string
     *
     */
    string getElementTypeName() {
        return "Element";
    }

    /*******************************************************************************************/
    /**
     * @brief  Set the color for the element
     *  
     * @param _R Red 
     * @param _G Green
     * @param _B Blue
     * @param _A Alpha
     *
     */
    void setColor( float _R, float _G, float _B, float _A = 1.0f ) {
        color = vec4( _R, _G, _B, _A );
    } 

    /*******************************************************************************************/
    /**
     * @brief  Set the color for the element
     *  
     * @param _color 4 component vector for the color
     *
     */
    void setColor( vec4 _color ) {
        color = _color;
    } 

    /*******************************************************************************************/
    /**
     * @brief  Gets the current color
     * 
     * @returns 4 component vector of the color
     *
     */
     vec4 getColor() {
        return color;
     }

    /*******************************************************************************************/
    /**
     * @brief  Sets the red value
     * 
     * @param value Color value  
     *
     */
     void setR( float value ) {
        color.x = value;
     }

    /*******************************************************************************************/
    /**
     * @brief  Gets the red value
     * 
     * @returns Color value
     *
     */
     float getR() {
        return color.x;
     }

    /*******************************************************************************************/
    /**
     * @brief Sets the green value
     * 
     * @param value Color value  
     *
     */
     void setG( float value ) {
        color.y = value;
     }

    /*******************************************************************************************/
    /**
     * @brief Gets the green value
     * 
     * @returns Color value
     *
     */
     float getG() {
        return color.y;
     }

    /*******************************************************************************************/
    /**
     * @brief Sets the blue value
     * 
     * @param value Color value  
     *
     */
     void setB( float value ) {
        color.z = value;
     }

    /*******************************************************************************************/
    /**
     * @brief Gets the blue value
     * 
     * @returns Color value
     *
     */
     float getB() {
        return color.y;
     }

    /*******************************************************************************************/
    /**
     * @brief Sets the alpha value
     * 
     * @param value Color value  
     *
     */
     void setAlpha( float value ) {
        color.a = value;
     }

    /*******************************************************************************************/
    /**
     * @brief Gets the alpha value
     * 
     * @returns Color value
     *
     */
     float getAlpha() {
        return color.a;
     }


    /*******************************************************************************************/
    /**
     * @brief  Should this element have a border
     *  
     * @param _border Show this border or not
     *
     */
     void showBorder( bool _border = true ) {
        border = _border;
     }

    /*******************************************************************************************/
    /**
     * @brief  Sets the border thickness
     * 
     * @param thickness Thickness of the border in GUI space pixels 
     *
     */
     void setBorderSize( int _borderSize ) {
        borderSize = _borderSize;
     }


    /*******************************************************************************************/
    /**
     * @brief  Set the color for the border
     *  
     * @param _R Red 
     * @param _G Green
     * @param _B Blue
     * @param _A Alpha
     *
     */
    void setBorderColor( float _R, float _G, float _B, float _A = 1.0f ) {
        borderColor = vec4( _R, _G, _B, _A );
    } 

    /*******************************************************************************************/
    /**
     * @brief  Set the color for the border
     *  
     * @param _color 4 component vector for the color
     *
     */
    void setBorderColor( vec4 _color ) {
        borderColor = _color;
    } 

    /*******************************************************************************************/
    /**
     * @brief  Gets the current border color
     * 
     * @returns 4 component vector of the color
     *
     */
     vec4 getBorderColor() {
        return borderColor;
     }

    /*******************************************************************************************/
    /**
     * @brief  Sets the border red value
     * 
     * @param value Color value  
     *
     */
     void setBorderR( float value ) {
        borderColor.x = value;
     }

    /*******************************************************************************************/
    /**
     * @brief  Gets the border red value
     * 
     * @returns Color value
     *
     */
     float getBorderR() {
        return borderColor.x;
     }

    /*******************************************************************************************/
    /**
     * @brief Sets the border green value
     * 
     * @param value Color value  
     *
     */
     void setBorderG( float value ) {
        borderColor.y = value;
     }

    /*******************************************************************************************/
    /**
     * @brief Gets the border green value
     * 
     * @returns Color value
     *
     */
     float getBorderG() {
        return borderColor.y;
     }

    /*******************************************************************************************/
    /**
     * @brief Sets the border blue value
     * 
     * @param value Color value  
     *
     */
     void setBorderB( float value ) {
        borderColor.z = value;
     }

    /*******************************************************************************************/
    /**
     * @brief Gets the border blue value
     * 
     * @returns Color value
     *
     */
     float getBorderB() {
        return borderColor.y;
     }

    /*******************************************************************************************/
    /**
     * @brief Sets the border alpha value
     * 
     * @param value Color value  
     *
     */
     void setBorderAlpha( float value ) {
        borderColor.a = value;
     }

    /*******************************************************************************************/
    /**
     * @brief Gets the border alpha value
     * 
     * @returns Color value
     *
     */
     float getBorderAlpha() {
        return borderColor.a;
     }

    /*******************************************************************************************/
    /**
     * @brief  Show or hide this element
     *  
     * @param _show Show this element or not
     *
     */
     void setVisible( bool _show ) {
        show = _show;
     }

    /*******************************************************************************************/
    /**
     * @brief  Draw a box (in *screen* coordinates) -- used internally
     * 
     */
    void drawBox( ivec2 boxPos, ivec2 boxSize, vec4 boxColor ) {

        HUDImage @boximage = hud.AddImage();
        boximage.SetImageFromPath("Data/Textures/ui/whiteblock.tga");

        boximage.scale = 1;
        boximage.scale.x *= boxSize.x;
        boximage.scale.y *= boxSize.y;

        boximage.position.x = boxPos.x;
        boximage.position.y = GetScreenHeight() - boxPos.y - (boximage.GetWidth() * boximage.scale.y );
        boximage.position.z = 1.0;

        boximage.color = boxColor;  

    }


    /*******************************************************************************************/
    /**
     * @brief  Rather counter-intuitively, this draws this object on the screen
     *
     * @param drawOffset Absolute offset from the upper lefthand corner (GUI space)
     *
     */
    void render( ivec2 drawOffset ) {

        // see if we're visible 
        if( !show ) return;

        // See if we're supposed to draw a border
        if( border ) {

            ivec2 borderCornerUL = drawOffset + drawDisplacement + boundaryOffset - ivec2( paddingL, paddingU );
            ivec2 borderCornerLR = drawOffset + drawDisplacement + boundaryOffset + size + ivec2( paddingR, paddingD );

            ivec2 screenCornerUL = GUIToScreen( borderCornerUL );
            ivec2 screenCornerLR = GUIToScreen( borderCornerLR );

            // figure out the thickness in screen pixels (minimum 1)
            int thickness = max( int( float( borderSize ) * GUItoScreenXScale ), 1 );

            // top 
            drawBox( screenCornerUL, 
                     ivec2( screenCornerLR.x - screenCornerUL.x, thickness ),
                     borderColor  );

            // bottom 
            drawBox( ivec2( screenCornerUL.x, screenCornerLR.y - thickness ), 
                     ivec2( screenCornerLR.x - screenCornerUL.x, thickness ),
                     borderColor );

            // left
            drawBox( ivec2( screenCornerUL.x, screenCornerUL.y + thickness ), 
                     ivec2( thickness, screenCornerLR.y - screenCornerUL.y - (2 * thickness) ),
                     borderColor );            

            // left
            drawBox( ivec2( screenCornerLR.x - thickness, screenCornerUL.y + thickness ), 
                     ivec2( thickness, screenCornerLR.y - screenCornerUL.y - (2 * thickness) ),
                     borderColor );  


            hud.Draw();          

        }

    }

    /*******************************************************************************************/
    /**
     * @brief  Checks to see if a point is inside this element
     * 
     * @param drawOffset The upper left hand corner of where the boundary is drawn
     * @param point point in question
     *
     * @returns true if inside, false otherwise
     *
     */
    bool pointInElement( ivec2 drawOffset, ivec2 point ) {

        ivec2 UL = drawOffset + boundaryOffset;
        ivec2 LR = UL + size;

        if( UL.x <= point.x && UL.y <= point.y &&
            LR.x >  point.x && LR.y > point.y ) {
            return true;
        }
        else {
            return false;
        }

    }

    /*******************************************************************************************/
    /**
     * @brief  Add an update behavior
     *  
     * @param behavior Handle to behavior in question
     *
     */
     void addUpdateBehavior( UpdateBehavior@ behavior ) {
        updateBehaviors.insertLast( behavior );
     }

    /*******************************************************************************************/
    /**
     * @brief  Clear update behaviors
     *
     */
     void clearUpdateBehaviors() {
        updateBehaviors.resize(0);
     }

    /*******************************************************************************************/
    /**
     * @brief  Add a mouse over behavior
     *  
     * @param behavior Handle to behavior in question
     *
     */
     void addMouseOverBehavior( MouseOverBehavior@ behavior ) {
        mouseOverBehaviors.insertLast( behavior );
     }

    /*******************************************************************************************/
    /**
     * @brief  Add a click behavior
     *  
     * @param behavior Handle to behavior in question
     *
     */
     void addLeftMouseClickBehavior( MouseClickBehavior@ behavior ) {
        leftMouseClickBehaviors.insertLast( behavior );
     }

    /*******************************************************************************************/
    /**
     * @brief  Updates the element  
     * 
     * @param delta Number of millisecond elapsed since last update
     * @param drawOffset Absolute offset from the upper lefthand corner (GUI space)
     * @param guistate The state of the GUI at this update
     *
     */
    void update( uint64 delta, ivec2 drawOffset, GUIState& guistate ) {

        // Update behaviors 
        for( int i = int(updateBehaviors.length())-1; i >= 0 ; i-- ) {
            
            // See if this behavior has been initialized
            if( !updateBehaviors[i].initialized ) {

                if( !updateBehaviors[i].initialize( this, delta, drawOffset, guistate ) ) {
                    // If the behavior has indicated it should not begin remove it
                    updateBehaviors.removeAt(uint(i));    
                    continue;
                }
                else {
                    updateBehaviors[i].initialized = true;
                }
            }

            if( !updateBehaviors[i].update( this, delta, drawOffset, guistate ) ) {
                // If the behavior has indicated it is done
                updateBehaviors.removeAt(uint(i));
            }
        }

        // Now do mouse behaviors 

        // Mouse overs

        if( pointInElement( drawOffset, guistate.mousePosition ) ) {
            if( !mouseOver ) {
                mouseOver = true;

                // Update behaviors 
                for( int i = int(mouseOverBehaviors.length())-1; i >= 0 ; i-- ) {
                    mouseOverBehaviors[i].onStart( this, delta, drawOffset, guistate );
                }
            }
            else {
                for( int i = int(mouseOverBehaviors.length())-1; i >= 0 ; i-- ) {
                    mouseOverBehaviors[i].onContinue( this, delta, drawOffset, guistate );
                }   
            }   

            // Mouse click status
            switch( guistate.leftMouseState ) {
            
            case kMouseDown: {
                for( int i = int(leftMouseClickBehaviors.length())-1; i >= 0 ; i-- ) {
                    if( !leftMouseClickBehaviors[i].onDown( this, delta, drawOffset, guistate ) ) {
                        // If the behavior has indicated it is done
                        leftMouseClickBehaviors.removeAt(uint(i));
                    }
                }
            }
            break; 
            
            case kMouseStillDown: {
                for( int i = int(leftMouseClickBehaviors.length())-1; i >= 0 ; i-- ) {
                    if( !leftMouseClickBehaviors[i].onStillDown( this, delta, drawOffset, guistate ) ) {
                        // If the behavior has indicated it is done
                        leftMouseClickBehaviors.removeAt(uint(i));
                    }
                }
            }
            break;

            case kMouseUp: {
                for( int i = int(leftMouseClickBehaviors.length())-1; i >= 0 ; i-- ) {
                    if( !leftMouseClickBehaviors[i].onUp( this, delta, drawOffset, guistate ) ) {
                        // If the behavior has indicated it is done
                        leftMouseClickBehaviors.removeAt(uint(i));
                    }
                    // Consider this no longer hovering
                    mouseOver = false;
                }
            }
            break; 

            case kMouseStillUp: 
            default:

            break;
            
            }

        }
        else {
            // See if this is an 'exit'
            if( mouseOver )
            {
                for( int i = int(mouseOverBehaviors.length())-1; i >= 0 ; i-- ) {
                    if( !mouseOverBehaviors[i].onFinish( this, delta, drawOffset, guistate ) ) {
                        // If the behavior has indicated it is done
                        mouseOverBehaviors.removeAt(uint(i));
                    }
                }
                mouseOver = false;    
            }
        }
    }

    /*******************************************************************************************/
    /**
     * @brief  When this element is resized, moved, etc propagate this signal upwards
     * 
     */
     void onRelayout() {

        if( owner !is null ) {
            owner.onRelayout();
        }
     
     }

    /*******************************************************************************************/
    /**
     * @brief  When a resize, move, etc has happened do whatever is necessary
     * 
     */
     void doRelayout() {
        
        // Make sure the boundary is up to date and sensible
        checkBoundary();
        resetAlignmentInBoundary();

     }

    /*******************************************************************************************/
    /**
     * @brief Set the name of this element
     * 
     * @param _name New name (incumbent on the programmer to make sure they're unique)
     *
     */
     void setName( string _name ) {
        
        name = _name;
     
     }

    /*******************************************************************************************/
    /**
     * @brief Gets the name of this element
     * 
     * @returns name of this element
     *
     */
     string getName() {
        return name;
     }


    /*******************************************************************************************/
    /**
     * @brief  Set the padding for each direction on the element
     *
     * UNDEFINEDSIZE will cause no change 
     * 
     * @param U (minimum) Padding between the element and the upper boundary  
     * @param D (minimum) Padding between the element and the lower boundary  
     * @param L (minimum) Padding between the element and the left boundary  
     * @param R (minimum) Padding between the element and the right boundary  
     *
     */
    void setPadding( int U, int D, int L, int R) {

        if( U != UNDEFINEDSIZE ) { paddingU = U; }
        if( D != UNDEFINEDSIZE ) { paddingD = D; }
        if( L != UNDEFINEDSIZE ) { paddingL = L; }
        if( R != UNDEFINEDSIZE ) { paddingR = R; }

        onRelayout();

    }

    /*******************************************************************************************/
    /**
     * @brief  Set the padding for all directions on the element
     *
     * @param paddingSize The number of pixels (in GUI space) to add to the padding on all sides
     *
     */
    void setPadding( int paddingSize ) {

        paddingU = paddingSize; 
        paddingD = paddingSize; 
        paddingL = paddingSize; 
        paddingR = paddingSize; 

        onRelayout();

    }

    /*******************************************************************************************/
    /**
     * @brief  Sets the drawing displacement (mostly used for tweening)
     * 
     * @param newDisplacement newValues for the displacement
     *
     */
     void setDisplacement( ivec2 newDisplacement = ivec2(0,0) ) {
        drawDisplacement = newDisplacement;
     }

    /*******************************************************************************************/
    /**
     * @brief  Sets the drawing displacement x component (mostly used for tweening)
     * 
     * @param newDisplacement newValues for the displacement
     *
     */
     void setDisplacementX( int newDisplacement = 0 ) {
        drawDisplacement.x = newDisplacement;
     }

    /*******************************************************************************************/
    /**
     * @brief  Sets the drawing displacement y component (mostly used for tweening)
     * 
     * @param newDisplacement newValues for the displacement
     *
     */
     void setDisplacementY( int newDisplacement = 0 ) {
        drawDisplacement.y = newDisplacement;
     }

    /*******************************************************************************************/
    /**
     * @brief  Gets the drawing displacement (mostly used for tweening)
     * 
     * @returns Displacement vector
     *
     */
     ivec2 getDisplacement( ivec2 newDisplacement = ivec2(0,0) ) {
        return drawDisplacement;
     }

    /*******************************************************************************************/
    /**
     * @brief  Gets the drawing displacement x component (mostly used for tweening)
     * 
     * @returns Displacement value
     *
     */
     int getDisplacementX() {
        return drawDisplacement.x;
     }

    /*******************************************************************************************/
    /**
     * @brief  Gets the drawing displacement y component (mostly used for tweening)
     * 
     * @returns Displacement value
     *
     */
     int getDisplacementY() {
        return drawDisplacement.y;
     }

    /*******************************************************************************************/
    /**
     * @brief  Make sure that the element isn't too big for the max boundary - called internally
     * 
     * @param throwErorr Should this throw an error if the boundary is exceeded
     *
     */
     bool checkBoundary( bool throwErorr = true ) {
        
        // first check if we have undefined boundary sizes (probably shouldn't happen)
        if( boundarySize.x == UNDEFINEDSIZE ) boundarySize.x = size.x + paddingL + paddingR;
        if( boundarySize.y == UNDEFINEDSIZE ) boundarySize.y = size.y + paddingU + paddingD;

        // The boundary is defined to always be at least as big as the element it contains
        // Make sure this is the case
        if( size.x + paddingL + paddingR > boundarySize.x ) {
            boundarySize.x = size.x + paddingL + paddingR;
        }

        if( size.y + paddingU + paddingD > boundarySize.y ) {
            boundarySize.y = size.y + paddingU + paddingD;
        }

        // Make sure we haven't exceeded the maximum boundary
        // if the boundary or boundaryMax is undefined this always passes
        if( boundaryMax.x != UNDEFINEDSIZE && boundarySize.x != UNDEFINEDSIZE && boundarySize.x > boundaryMax.x ) {
            if( throwErorr ) {
                Print("Element " + name + " has a boundary of " + getBoundarySize().toString() + "\n");
                DisplayError("GUI Error", "Element " + name + " exceeds its x boundaries");
            }
            return false;
        }
    
        if( boundaryMax.y != UNDEFINEDSIZE && boundarySize.y != UNDEFINEDSIZE && boundarySize.y > boundaryMax.y ) {
            if( throwErorr ) {
                DisplayError("GUI Error", "Element " + name + " exceeds its y boundaries");
            }
            return false;
        }
     
        return true;

     }

    /*******************************************************************************************/
    /**
     * @brief Resizes the boundary (based solely on the element dimension)
     * 
     */
     void setBoundarySize() {

        boundarySize = size;
        boundarySize.x += paddingL + paddingR;
        boundarySize.y += paddingU + paddingD;
        onRelayout();

     }

    /*******************************************************************************************/
    /**
     * @brief  Sets the alignment versus the container
     *  
     * @param v vertical alignment 
     *
     */
     void setVeritcalAlignment( BoundaryAlignment v = BACenter) {
        alignmentY = v;
        onRelayout();
     }

    /*******************************************************************************************/
    /**
     * @brief  Sets the alignment versus the container
     *  
     * @param h horizontal alignment
     *
     */
     void setHorizontalAlignment( BoundaryAlignment h = BACenter) {
        alignmentX = h;
        onRelayout();
     }

     /*******************************************************************************************/
    /**
     * @brief  Sets the alignment versus the container
     *  
     * @param h vertical alignment 
     * @param v horizontal alignment
     *
     */
     void setAlignment( BoundaryAlignment h = BACenter, BoundaryAlignment v = BACenter) {
        alignmentX = h;
        alignmentY = v;
        onRelayout();
     }
    
    /*******************************************************************************************/
    /**
     * @brief  Sets the elements position in the boundary appropriately
     * 
     */
     void resetAlignmentInBoundary() {
        
        // Compute the boundary offset based on the alignment

        // x position
        switch( alignmentX ) {
            case BALeft:
                boundaryOffset.x = paddingL;
            break;
            case BACenter:
                boundaryOffset.x = (boundarySize.x - (size.x + paddingL + paddingR ))/2;
            break;
            case BARight:
                boundaryOffset.x = boundarySize.x - (size.x + paddingL + paddingR );
            break;
            default:
            break;
        }

        // y position
        switch( alignmentY ) {
            case BALeft:
                boundaryOffset.y = paddingU;
            break;
            case BACenter:
                boundaryOffset.y = (boundarySize.y - (size.y + paddingU + paddingD ))/2;
            break;
            case BARight:
                boundaryOffset.y = boundarySize.y - (size.y + paddingU + paddingD );
            break;
            default:
            break;
        }
    
     }


    /*******************************************************************************************/
    /**
     * @brief  Gets the offset (in GUI space) of the element vs the boundary of the element
     * 
     * @returns The position vector 
     *
     */
    ivec2 getBoundaryOffset() {
        
        return boundaryOffset;
    
    }

    /*******************************************************************************************/
    /**
     * @brief  Sets the size of the region  
     * 
     * @param _size 2d size vector (-1 element implies undefined - or use UNDEFINEDSIZE)
     * @param resetBoundarySize Should we reset the boundary if it's too small?
     *
     */
    void setSize( const ivec2 _size, bool resetBoundarySize = true ) {
        
        size = _size;
        onRelayout();

    }

    /*******************************************************************************************/
    /**
     * @brief  Sets the size of the region 
     * 
     * @param x x dimension size (-1 implies undefined - or use UNDEFINEDSIZE)
     * @param y y dimension size (-1 implies undefined - or use UNDEFINEDSIZE)
     * @param resetBoundarySize Should we reset the boundary if it's too small?
     *
     */
    void setSize( const int x, const int y, bool resetBoundarySize = true  ) {
                
        ivec2 newSize( x, y );
        setSize( newSize, resetBoundarySize );

    }

    /*******************************************************************************************/
    /**
     * @brief  Sets the x dimension of a region
     * 
     * @param x x dimension size (-1 implies undefined - or use UNDEFINEDSIZE)
     * @param resetBoundarySize Should we reset the boundary if it's too small?
     *
     */
    void setSizeX( const int x, bool resetBoundarySize = true ) {
    
        size.x = x;        
        onRelayout();
    
    }   

    /*******************************************************************************************/
    /**
     * @brief  Sets the y dimension of a region
     * 
     * @param y y dimension size (-1 implies undefined - or use UNDEFINEDSIZE)
     * @param resetBoundarySize Should we reset the boundary if it's too small?
     *
     */
    void setSizeY( const int y, bool resetBoundarySize = true ) {
            
        size.y = y;
        onRelayout();

    }  

    /*******************************************************************************************/
    /**
     * @brief  Gets the size vector
     * 
     * @returns The size vector 
     *
     */
    ivec2 getSize() {
        return size;
    }

    /*******************************************************************************************/
    /**
     * @brief  Gets the size x component
     * 
     * @returns The x size
     *
     */
    int getSizeX() {
        return size.x;
    }

    /*******************************************************************************************/
    /**
     * @brief  Gets the size y component
     * 
     * @returns The y size
     *
     */
    int getSizeY() {
        return size.y;
    }

    /*******************************************************************************************/
    /**
     * @brief  Gets the boundary size vector
     * 
     * @returns The size vector 
     *
     */
    ivec2 getBoundarySize() {
        return boundarySize;
    }

    /*******************************************************************************************/
    /**
     * @brief  Gets the boundary size x component
     * 
     * @returns The x size
     *
     */
    int getBoundarySizeX() {
        return boundarySize.x;
    }

    /*******************************************************************************************/
    /**
     * @brief  Gets the boundary size y component
     * 
     * @returns The y size
     *
     */
    int getBoundarySizeY() {
        return boundarySize.y;
    }

    /*******************************************************************************************/
    /**
     * @brief Resizes the boundary 
     * 
     * @param newSize 2d size vector
     *
     */
     void setBoundarySize( ivec2 newSize ) {

        boundarySize = newSize;
        onRelayout();

     }

    /*******************************************************************************************/
    /**
     * @brief Resizes the boundary in the x dimension 
     * 
     * @param x the new size
     *
     */
     void setBoundarySizeX( int x ) {

        boundarySize.x = x;
        onRelayout();

     }


    /*******************************************************************************************/
    /**
     * @brief Resizes the boundary in the y dimension 
     * 
     * @param y the new size
     *
     */
     void setBoundarySizeY( int y ) {

        boundarySize.y = y;
        onRelayout();

     }

    /*******************************************************************************************/
    /**
     * @brief  Gets the max boundary size vector
     * 
     * @returns The max size vector 
     *
     */
    ivec2 getBoundaryMax() {
        return boundaryMax;
    }

    /*******************************************************************************************/
    /**
     * @brief  Gets the max boundary size x component
     * 
     * @returns The x size
     *
     */
    int getBoundaryMaxX() {
        return boundaryMax.x;
    }

    /*******************************************************************************************/
    /**
     * @brief  Gets the boundary size y component
     * 
     * @returns The y size
     *
     */
    int getBoundaryMaxY() {
        return boundaryMax.y;
    }

    /*******************************************************************************************/
    /**
     * @brief Resizes the boundary 
     * 
     * @param newSize 2d size vector
     *
     */
     void setBoundaryMax( ivec2 newSize ) {

        boundaryMax = newSize;
        checkBoundary();
        onRelayout();

     }

    /*******************************************************************************************/
    /**
     * @brief Resizes the boundary in the x dimension 
     * 
     * @param x the new size
     *
     */
     void setBoundaryMaxX( int x ) {

        boundaryMax.x = x;
        checkBoundary();
        onRelayout();

     }


    /*******************************************************************************************/
    /**
     * @brief Resizes the boundary in the y dimension 
     * 
     * @param y the new size
     *
     */
     void setBoundaryMaxY( int y ) {

        boundaryMax.y = y;
        checkBoundary();
        onRelayout();

     }


    /*******************************************************************************************/
    /**
     * @brief  Sends a message to the owning GUI
     * 
     * @param theMessage the message
     *
     */
     void sendMessage( Message@ theMessage ) {
        
        @theMessage.sender = this;
        
        if( owner !is null  ) {
            owner.receiveMessage( theMessage );
        }

     }

    /*******************************************************************************************/
    /**
     * @brief  Finds an element by a given name
     * 
     * @param elementName the name of the element
     *
     * @returns handle to the element (null if not found)  
     *
     */
    Element@ findElement( string elementName ) {
        // Check if this is the droid we're looking for
        if( name == elementName ) {
            return this;
        }
        else {
            return null;
        }
    }

};

} // namespace AHGUI

