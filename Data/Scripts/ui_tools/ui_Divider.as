#include "ui_tools/ui_support.as"
#include "ui_tools/ui_Element.as"


/*******
 *  
 * ui_Divider.as
 *
 * Container element class for creating adhoc GUIs as part of the UI tools  
 *
 */

namespace AHGUI {

/*******************************************************************************************/
/**
 * @brief  Basic container class, holds other elements
 *
 */
class Divider : Element {
    
    array<Element@> topLeftContents; // elements in this container top/left
    array<Element@> bottomRightContents; // elements in this container topLeft
    Element@ centeredElement; // element in this container centered (only one allowed)

    int topLeftBoundStart;  // Start coordinate for the top/left container
    int topLeftBoundEnd;    // End coordinate for the top/left container
    int centerBoundStart;  // Start coordinate for the center element
    int centerBoundEnd;    // End coordinate for the center element
    int bottomRightBoundStart; // Start coordinate for the center element
    int bottomRightBoundEnd;   // End coordinate for the center element
    
    DividerOrientation orientation; // vertical by default
    
    /*******************************************************************************************/
    /**
     * @brief  Constructor
     *  
     * @param name Element name
     * @param _orientation The orientation of the container
     *
     */
    Divider( string name, DividerOrientation _orientation = DOVertical ) {
        orientation = _orientation;
        @centeredElement = null;
        super(name);
    }

    /*******************************************************************************************/
    /**
     * @brief  Constructor
     *  
     * @param name Element name
     * @param _orientation The orientation of the container
     *
     */
    Divider( DividerOrientation _orientation = DOVertical ) {
        orientation = _orientation;
        @centeredElement = null;
        super();
    }

    /*******************************************************************************************/
    /**
     * @brief  Gets the name of the type of this element — for autonaming and debugging
     * 
     * @returns name of the element type as a string
     *
     */
    string getElementTypeName() {
        return "Divider";
    }

    /*******************************************************************************************/
    /**
     * @brief  Clear the contents of this divider, leaving everything else the same
     * 
     */

    void clear() {
        topLeftContents.resize(0);
        @centeredElement = null;
        bottomRightContents.resize(0);
        setSize(UNDEFINEDSIZE,UNDEFINEDSIZE);
        onRelayout();
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

        ivec2 currentDrawOffset = drawOffset;

        // Do whatever the superclass wants
        Element::update( delta, currentDrawOffset, guistate );

        // Simply pass this on to the children
        for( uint i = 0; i < topLeftContents.length(); i++ ) {
            
            topLeftContents[i].update( delta, currentDrawOffset, guistate );
            
            if( orientation == DOVertical ) {
                currentDrawOffset.y += topLeftContents[i].getBoundarySizeY();
            }
            else {
                currentDrawOffset.x += topLeftContents[i].getBoundarySizeX();   
            }
        }

        if( centeredElement !is null ) {

            currentDrawOffset = drawOffset;

            if( orientation == DOVertical ) {
                currentDrawOffset.y += centerBoundStart;
            }
            else {
                currentDrawOffset.x += centerBoundStart;   
            }

            centeredElement.update( delta, currentDrawOffset, guistate );
        }

        currentDrawOffset = drawOffset;

        if( orientation == DOVertical ) {
            currentDrawOffset.y += bottomRightBoundStart;
        }
        else {
            currentDrawOffset.x += bottomRightBoundStart;   
        }

        for( uint i = 0; i < bottomRightContents.length(); i++ ) {

            bottomRightContents[i].update( delta, currentDrawOffset, guistate );

            if( orientation == DOVertical ) {
                currentDrawOffset.y += bottomRightContents[i].getBoundarySizeY();
            }
            else {
                currentDrawOffset.x += bottomRightContents[i].getBoundarySizeX();   
            }
        }
    }

    /*******************************************************************************************/
    /**
     * @brief  Rather counter-intuitively, this draws this object on the screen
     *
     * @param drawOffset Absolute offset from the upper lefthand corner (GUI space)
     *
     */
    void render( ivec2 drawOffset ) {

        // Simply pass this on to the children
        ivec2 currentDrawOffset = drawOffset + drawDisplacement;
        for( uint i = 0; i < topLeftContents.length(); i++ ) {
            
            topLeftContents[i].render( currentDrawOffset );
            
            if( orientation == DOVertical ) {
                currentDrawOffset.y += topLeftContents[i].getBoundarySizeY();
            }
            else {
                currentDrawOffset.x += topLeftContents[i].getBoundarySizeX();   
            }
        }

        if( centeredElement !is null ) {

            currentDrawOffset = drawOffset + drawDisplacement;

            if( orientation == DOVertical ) {
                currentDrawOffset.y += centerBoundStart;
            }
            else {
                currentDrawOffset.x += centerBoundStart;   
            }

            centeredElement.render( currentDrawOffset );
        }

        currentDrawOffset = drawOffset + drawDisplacement;

        if( orientation == DOVertical ) {
            currentDrawOffset.y += bottomRightBoundStart;
        }
        else {
            currentDrawOffset.x += bottomRightBoundStart;   
        }

        for( uint i = 0; i < bottomRightContents.length(); i++ ) {

            bottomRightContents[i].render( currentDrawOffset );

            if( orientation == DOVertical ) {
                currentDrawOffset.y += bottomRightContents[i].getBoundarySizeY();
            }
            else {
                currentDrawOffset.x += bottomRightContents[i].getBoundarySizeX();   
            }
        }

        // Do whatever the superclass wants 
        Element::render( drawOffset );

    }

    /*******************************************************************************************/
    /**
     * @brief Rederive the regions for the various orientation containers - for internal use
     * 
     */
     void checkRegions() {

        // Reset the region tracking
        topLeftBoundStart = UNDEFINEDSIZE;   
        topLeftBoundEnd = UNDEFINEDSIZE; 
        int topLeftSize = 0;  
        centerBoundStart = UNDEFINEDSIZE;   
        centerBoundEnd = UNDEFINEDSIZE;     
        int centerSize = 0;
        bottomRightBoundStart = UNDEFINEDSIZE;
        bottomRightBoundEnd = UNDEFINEDSIZE;
        int bottomRightSize = 0;
        
        // see which direction we're going
        if( orientation == DOVertical ) {

            // sum the top contents
            for( uint i = 0; i < topLeftContents.length(); i++ ) {

                if( topLeftBoundStart == UNDEFINEDSIZE ) {
                    topLeftBoundStart = 0;
                    topLeftBoundEnd = -1;
                }

                if( topLeftContents[i].getBoundarySizeY() != UNDEFINEDSIZE ) {
                    // update the totals
                    topLeftSize += topLeftContents[i].getBoundarySizeY();
                    topLeftBoundEnd += topLeftContents[i].getBoundarySizeY() - 1;

                    // // check to see if this element pushes the boundary of the divider
                    if( topLeftContents[i].getBoundarySizeX() > getBoundarySizeX() ) {
                        setSizeX( topLeftContents[i].getBoundarySizeX() );
                    }

                    // check to make sure the element boundary is the same as this container
                    if( topLeftContents[i].getBoundarySizeX() < getBoundarySizeX() ) {
                        // Respect the element's max boundary 
                        //if( getBoundarySizeX() <= topLeftContents[i].getBoundaryMaxX() ) {
                            topLeftContents[i].setBoundarySizeX( getBoundarySizeX() );    
                        //}
                        
                    }

                }   
            }

            // As the center is one element, we just need to calculate from it
            if( centeredElement !is null && centeredElement.getBoundarySizeY() != UNDEFINEDSIZE ) {
                
                int dividerCenter = ((getBoundarySizeY() - 1)/2);

                centerBoundStart = dividerCenter - (centeredElement.getBoundarySizeY()/2);
                centerBoundEnd = centerBoundStart  + ( centeredElement.getBoundarySizeY() - 1 );

                centerSize = centeredElement.getBoundarySizeY();

                // check to see if this element pushes the boundary of the divider
                if( centeredElement.getBoundarySizeX() > getBoundarySizeX() ) {
                    setSizeX( centeredElement.getBoundarySizeX() );
                }

                // check to make sure the element boundary is the same as this container
                if( centeredElement.getBoundarySizeX() < getBoundarySizeX() ) {
                    // Respect the element's max boundary 
                    //if( getBoundarySizeX() <= centeredElement.getBoundaryMaxX() ) {
                        centeredElement.setBoundarySizeX( getBoundarySizeX() );
                    //}
                }
            }

            
            // sum the bottom contents
            for( int i = int(bottomRightContents.length())-1; i >= 0 ; i-- ) {

                if( bottomRightBoundStart == UNDEFINEDSIZE ) {
                    bottomRightBoundEnd = getBoundarySizeY() - 1;
                    bottomRightBoundStart = bottomRightBoundEnd + 1;
                }

                if( bottomRightContents[i].getBoundarySizeY() != UNDEFINEDSIZE ) {
                    
                    // update the totals
                    bottomRightBoundStart -= (bottomRightContents[i].getSizeY() - 1);
                    bottomRightSize += bottomRightContents[i].getBoundarySizeY();

                    // check to see if this element pushes the boundary of the divider
                    if( bottomRightContents[i].getBoundarySizeX() > getBoundarySizeX() ) {
                        setSizeX( bottomRightContents[i].getBoundarySizeX() );
                    }

                    // check to make sure the element boundary is the same as this container
                    if( bottomRightContents[i].getBoundarySizeX() < getBoundarySizeX() ) {
                        // Respect the element's max boundary 
                        //if( getBoundarySizeX() <= bottomRightContents[i].getBoundaryMaxX() ) {
                            bottomRightContents[i].setBoundarySizeX( getBoundarySizeX() );
                        //}
                    }
                }
            }

            // Now we check that this all fits in the divider 
            int neededSize = 0;
            // The math is different if we have a center element 
            if( centeredElement !is null && centerSize > 0  ) {
                // we have a centered element
                // figure out how much size we need for this divider
                int halfCenter = centerSize / 2;
                int topLeftHalf = halfCenter + topLeftSize;
                int bottomRightHalf = halfCenter + bottomRightSize;

                neededSize = max( topLeftHalf * 2, bottomRightHalf * 2 );
            }
            else {
                // we don't have a centered element
                neededSize = topLeftSize + bottomRightSize;
            }

            // Check to see if we have enough size in this divider
            if( neededSize > getSizeY() ) {
                // Try changing the size of the divider
                //  This is likely going to fail and throw an error, but let's
                //  let the system decide
                setSizeY( neededSize );
            }

        }
        else {

            // horizontal layout 

            // sum the left contents
            for( uint i = 0; i < topLeftContents.length(); i++ ) {

                if( topLeftBoundStart == UNDEFINEDSIZE ) {
                    topLeftBoundStart = 0;
                    topLeftBoundEnd = -1;
                }

                if( topLeftContents[i].getBoundarySizeX() != UNDEFINEDSIZE ) {
                    // update the totals
                    topLeftBoundEnd += topLeftContents[i].getBoundarySizeX()- 1;
                    topLeftSize += topLeftContents[i].getBoundarySizeX();

                    // check to see if this element pushes the boundary of the divider
                    if( topLeftContents[i].getBoundarySizeY() > getBoundarySizeY() ) {
                        setSizeY( topLeftContents[i].getBoundarySizeY() );
                    }

                    // check to make sure the element boundary is the same as this container
                    if( topLeftContents[i].getBoundarySizeY() < getBoundarySizeY() ) {
                        // Respect the element's max boundary 
                        //if( getBoundarySizeY() <= topLeftContents[i].getBoundaryMaxY() ) {
                            topLeftContents[i].setBoundarySizeY( getBoundarySizeY() );
                        //}
                    }
                }
            }

            // As the center is one element, we just need to calculate from it
            if( centeredElement !is null && centeredElement.getBoundarySizeX() != UNDEFINEDSIZE ) {
                
                int dividerCenter = ((getBoundarySizeX()- 1)/2);
                centerBoundStart = dividerCenter - (centeredElement.getBoundarySizeX()/2);
                centerBoundEnd = centeredElement.getBoundarySizeX() - 1;
                centerSize = centeredElement.getBoundarySizeX();

                // check to see if this element pushes the boundary of the divider
                if( centeredElement.getBoundarySizeY() > getBoundarySizeY() ) {
                    setSizeY( centeredElement.getBoundarySizeY() );
                }

                // check to make sure the element boundary is the same as this container
                if( centeredElement.getBoundarySizeY() < getBoundarySizeY() ) {
                    // Respect the element's max boundary 
                    //if( getBoundarySizeY() <= centeredElement.getBoundaryMaxY() ) {
                        centeredElement.setBoundarySizeY( getBoundarySizeY() );
                    //}
                }
            }

            // sum the bottom/right contents
            for( int i = int(bottomRightContents.length())-1; i >= 0 ; i-- ) {

                if( bottomRightBoundStart == UNDEFINEDSIZE ) {
                    bottomRightBoundEnd = getBoundarySizeX() - 1;
                    bottomRightBoundStart = bottomRightBoundEnd + 1;
                }                

                if( bottomRightContents[i].getBoundarySizeX() != UNDEFINEDSIZE ) {

                    // update the totals
                    bottomRightBoundStart -= (bottomRightContents[i].getBoundarySizeX() - 1);
                    bottomRightSize += bottomRightContents[i].getBoundarySizeX();

                    // check to see if this element pushes the boundary of the divider
                    if( bottomRightContents[i].getBoundarySizeY() > getBoundarySizeY() ) {
                        setSizeY( bottomRightContents[i].getBoundarySizeY() );
                    }

                    // check to make sure the element boundary is the same as this container
                    if( bottomRightContents[i].getBoundarySizeY() < getBoundarySizeY() ) {
                        // Respect the element's max boundary 
                        //if( getBoundarySizeY() <= bottomRightContents[i].getBoundaryMaxY() ) {
                            bottomRightContents[i].setBoundarySizeY( getBoundarySizeY() );
                        //}
                    }
                }
            }

            // Now we check that this all fits in the divider 
            int neededSize = 0;
            // The math is different if we have a center element 
            if( centeredElement !is null && centerSize > 0  ) {
                // we have a centered element
                // figure out how much size we need for this divider
                int halfCenter = centerSize / 2;
                int topLeftHalf = halfCenter + topLeftSize;
                int bottomRightHalf = halfCenter + bottomRightSize;

                neededSize = max( topLeftHalf * 2, bottomRightHalf * 2 );
            }
            else {
                // we don't have a centered element
                neededSize = topLeftSize + bottomRightSize;
            }

            // Check to see if we have enough size in this divider
            if( neededSize > getSizeX() ) {
                // Try changing the size of the divider
                //  This is likely going to fail and throw an error, but let's
                //  let the system decide
                setSizeX( neededSize );
            }

        }
     }


    /*******************************************************************************************/
    /**
     * @brief  When a resize, move, etc has happened do whatever is necessary
     * 
     */
     void doRelayout() {

        // Invoke the elements relayout
        Element::doRelayout();
        
        // First pass this down to the children
        for( uint i = 0; i < topLeftContents.length(); i++ ) {
            topLeftContents[i].doRelayout();
        }

        if( centeredElement !is null ) {
            centeredElement.doRelayout();
        }

        for( uint i = 0; i < bottomRightContents.length(); i++ ) {
            bottomRightContents[i].doRelayout();
        }

        checkRegions();

     }


    /*******************************************************************************************/
    /**
     * @brief Convenience function to add a spacer element to this divider
     *  
     * @param size Size of the element in terms of GUI space pixels
     * @param direction Side of the container to add to 
     *
     * @returns the space object created, just in case you need it
     *
     */
    Spacer@ addSpacer( int _size, DividerDirection direction = DDTopLeft ) {
        
        // Create a new spacer object
        Spacer@ newSpacer = Spacer(); 
        
        // Set the coordinates based on the orientation
        if( orientation == DOVertical ) {
            newSpacer.setSize( UNDEFINEDSIZE, _size );
        }
        else {
            newSpacer.setSize( _size, UNDEFINEDSIZE );
        }

        // Add this to the divider
        addElement( newSpacer, direction );

        // return a reference to this object in case the
        //  user needs to reference it (get the name, etc)
        return newSpacer;

    }

    /*******************************************************************************************/
    /**
     * @brief Convenience function to add a sub-divider
     *  
     * @param direction Side of the container to add to 
     * @param newOrientation Orientation of the new divider ( defaults to opposite of the host )
     * @param size Size of the element in terms of GUI space pixels (optional if in opposite direction of the host)
     *
     * @returns the space object created, just in case you need it
     *
     */

    Divider@ addDivider( DividerDirection direction, DividerOrientation newOrientation, ivec2 size = ivec2( UNDEFINEDSIZE, UNDEFINEDSIZE ) ) {
        
        // Create a new spacer object
        Divider@ newDivider = Divider(newOrientation); 
        
        // Set the coordinates based on the orientation
        if( orientation == DOVertical ) {
                
            // If the user hasn't specified a size, set it to the width of the container
            if( size.x == UNDEFINEDSIZE ) {
                size.x = getSizeX();
            }

            newDivider.setSize( size );

            // Inherit the max size, if we don't have a max size
            if( size.y == UNDEFINEDSIZE ) {
                size.y = getBoundaryMaxY();
            }

            newDivider.setBoundaryMax( size ); 

        }
        else {
            
            // If the user hasn't specified a size, set it to the height of the container
            if( size.y == UNDEFINEDSIZE ) {
                size.y = getSizeY();
            }

            newDivider.setSize( size );

            // Inherit the max size, if we don't have a max size
            if( size.x == UNDEFINEDSIZE ) {
                size.x = getBoundaryMaxX();
            }

            newDivider.setBoundaryMax( size ); 
        
        }

        // Add this to the divider
        addElement( newDivider, direction );

        // return a reference to this object in case the
        //  user needs to reference it (get the name, etc)
        return newDivider;

    }

    /*******************************************************************************************/
    /**
     * @brief Adds an element to the divider 
     *  
     * @param newElement Element to add  
     * @param direction Portion of the divider to add to (default top/left)
     *
     */
    void addElement( Element@ newElement, DividerDirection direction = DDCenter ) {

        // Make sure the element has a name 
        if( newElement.name == "" ) {
            newElement.name = owner.getUniqueName( getElementTypeName() );
        }

        // Which orientation is this container?
        if( orientation == DOVertical ) {

            switch( direction ) {
                
                case DDTopLeft: {

                    topLeftContents.insertLast( newElement );
                    break;    
                }

                case DDBottomRight: {

                    bottomRightContents.insertAt( 0, newElement );
                    break;
                }

                case DDCenter: {

                    if( centeredElement !is null ) {
                        DisplayError("GUI Error", "Multiple centered elements added to divider");  
                    }

                    @centeredElement = @newElement;

                    break;
                }
                default:

            }   
        }
        else {

            switch( direction ) {

                case DDTopLeft: {

                    topLeftContents.insertLast( newElement );
                    break;    
                }

                case DDBottomRight: {

                    bottomRightContents.insertAt( 0, newElement );
                    break;
                }

                case DDCenter: {

                    if( centeredElement !is null ) {
                        DisplayError("GUI Error", "Multiple centered elements added to divider");  
                    }

                    @centeredElement = @newElement;

                    break;
                }
                default:

            }   
        }

        // Link to this element/owning GUI
        @newElement.owner = @owner;
        @newElement.parent = @this;

        // Signal that something new has changed
        onRelayout();

    }

    Element@ findElement( string elementName ) {
        // Check if this is the droid we're looking for
        if( name == elementName ) {
            return this;
        }
        else {
            // If not, pass the request onto the children
        
            for( uint i = 0; i < topLeftContents.length(); i++ ) {
            
                Element@ results = topLeftContents[i].findElement( elementName );

                if( results !is null ) {
                    return results;
                }

            }

            if( centeredElement !is null ) {

                Element@ results = centeredElement.findElement( elementName );

                if( results !is null ) {
                    return results;
                }
            }


            for( uint i = 0; i < bottomRightContents.length(); i++ ) {


                Element@ results = bottomRightContents[i].findElement( elementName );

                if( results !is null ) {
                    return results;
                }

            }

            // if we've got this, far we don't have it and so report
            return null;
        }
    }


    /*******************************************************************************************/
    /**
     * @brief  Destructor
     *
     */
    ~Divider() {
        topLeftContents.resize(0);
        bottomRightContents.resize(0);
        @centeredElement = null;
    }



}


} // namespace AHGUI

