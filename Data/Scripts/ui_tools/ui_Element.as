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

    ivec2 boundarySize;     // length and width of the maximum extent of this element (GUI Space) 
    ivec2 boundaryOffset;   // upper left coordinate relative to the containing boundary (GUI space)
    ivec2 size;             // dimensions of the actual region (GUI space)
    int paddingU;          // (minimum) Padding between the element and the upper boundary 
    int paddingD;          // (minimum) Padding between the element and the lower boundary 
    int paddingL;          // (minimum) Padding between the element and the left boundary 
    int paddingR;          // (minimum) Padding between the element and the right boundary 


    string name;            // name to refer to this object by -- incumbent on the programmer to make sure they're unique
    
    Element@ parent;        // null if 'root'
    GUI@ owner;             // what GUI owns this element

    array<UpdateBehavior@> updateBehaviors;         // update behaviors
    array<MouseOverBehavior@> mouseOverBehaviors;   // mouse over behaviors
    array<MouseClickBehavior@> leftMouseClickBehaviors;        // mouse up behaviors

    bool show; // should this element be rendered?
    bool mouseOver; // has mouse been over this element

    /*******************************************************************************************/
    /**
     * @brief  Initializes the element (called internally)
     * 
     */
     void init() {
        
        name = "";

        size = ivec2( UNDEFINEDSIZE,UNDEFINEDSIZE );
        boundarySize = ivec2( UNDEFINEDSIZE,UNDEFINEDSIZE );
        boundaryOffset = ivec2( 0, 0 );

        @parent = null;
        @owner = null;

        paddingU = 0;
        paddingD = 0;
        paddingL = 0;
        paddingR = 0;

        show = true;
        mouseOver = false;

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
     * @brief  Rather counter-intuitively, this draws this object on the screen
     *
     * @param drawOffset Absolute offset from the upper lefthand corner (GUI space)
     *
     */
    void render( ivec2 spaceOffset ) {

        // Nothing to do in the base class

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

        if( show ) {
            // Draw this element
            render( drawOffset );
        }

        // Update behaviors 
        for( int i = int(updateBehaviors.length())-1; i >= 0 ; i-- ) {
            if( !updateBehaviors[i].update( this, delta, drawOffset, guistate ) ) {
                // If the behavior has indicated it is done
                updateBehaviors.removeAt(uint(i));
            }
        }

        // Now do mouse behaviors 

        // Mouse overs
        ivec2 elementPos = drawOffset + boundaryOffset;

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
        
        // in the base class, nothing

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
     * @brief  Set the padding for each direction on the element
     *
     * UNDEFINEDSIZE will cause no change 
     * 
     * @param U (minimum) Padding between the element and the upper boundary  
     * @param D (minimum) Padding between the element and the lower boundary  
     * @param L (minimum) Padding between the element and the left boundary  
     * @param R (minimum) Padding between the element and the right boundary  
     * @param resetBoundarySize Should we reset the boundary if it's too small?
     *
     */
    void setPadding( int U = UNDEFINEDSIZE, int D = UNDEFINEDSIZE, 
                     int L = UNDEFINEDSIZE, int R = UNDEFINEDSIZE,
                     bool resetBoundarySize = true ) {

        if( U != UNDEFINEDSIZE ) { paddingU = U; }
        if( D != UNDEFINEDSIZE ) { paddingD = D; }
        if( L != UNDEFINEDSIZE ) { paddingL = L; }
        if( R != UNDEFINEDSIZE ) { paddingR = R; }

        if( resetBoundarySize )
        {

            if( size.x + paddingL + paddingR > boundarySize.x ) {
                boundarySize.x = size.x + paddingL + paddingR;
            }

            if( size.y + paddingU + paddingD > boundarySize.y ) {
                boundarySize.y = size.y + paddingL + paddingR;
            }

        }

        checkBoundary();
        resetAlignmentInBoundary();
        onRelayout();

    }

    /*******************************************************************************************/
    /**
     * @brief  Make sure that the element isn't too big for the boundary - called internally
     * 
     * @param throwErorr Should this throw an error if the boundary is exceeded
     *
     */
     bool checkBoundary( bool throwErorr = true ) {
        
        // first check if we have undefined boundary sizes (probably shouldn't happen)
        if( boundarySize.x == UNDEFINEDSIZE ) boundarySize.x = size.x;
        if( boundarySize.y == UNDEFINEDSIZE ) boundarySize.y = size.y;

        // if the size is undefined this always passes
        if( size.x != UNDEFINEDSIZE && size.x + paddingL + paddingR > boundarySize.x ) {
            if( throwErorr ) {
                DisplayError("GUI Error", "Element " + name + " exceeds its boundaries");
            }
            return false;
        }
        
        if( size.y != UNDEFINEDSIZE &&  size.y + paddingU + paddingD > boundarySize.y ) {
            if( throwErorr ) {
                DisplayError("GUI Error", "Element " + name + " exceeds its boundaries");
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
        boundaryOffset = ivec2(paddingL,paddingU);
        checkBoundary();
        onRelayout();

     }

     // TODO stop assuming that a a fixed sized element is centered (vertically and horizontally)
    /*******************************************************************************************/
    /**
     * @brief  Sets the elements position in the boundary appropriately
     * 
     */
     void resetAlignmentInBoundary() {
        // At the moment we're assuming that by default that the element is at the center of the boundary
        //  unless the padding is asymmetric
        boundaryOffset.x = (boundarySize.x - (size.x + paddingL + paddingR ))/2;
        boundaryOffset.y = (boundarySize.y - (size.y + paddingU + paddingD ))/2;
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
        checkBoundary();
        resetAlignmentInBoundary();
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
        checkBoundary();
        resetAlignmentInBoundary();
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
        checkBoundary();
        resetAlignmentInBoundary();
        onRelayout();

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

        if( resetBoundarySize )
        {
            //if( size.x + paddingL + paddingR > boundarySize.x ) {
                boundarySize.x = size.x + paddingL + paddingR;
            //}

            //if( size.y + paddingU + paddingD > boundarySize.y ) {
                boundarySize.y = size.y + paddingL + paddingR;
            //}
        }

        checkBoundary();
        resetAlignmentInBoundary();
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

        if( resetBoundarySize )
        {
            boundarySize.x = size.x + paddingL + paddingR;
        }
        
        checkBoundary();
        resetAlignmentInBoundary();
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

        if( resetBoundarySize )
        {
            boundarySize.y = size.y + paddingL + paddingR;
        }

        checkBoundary();
        resetAlignmentInBoundary();
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

};



} // namespace AHGUI

