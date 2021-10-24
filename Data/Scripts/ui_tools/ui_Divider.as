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
     * @brief  Updates the element  
     * 
     * @param delta Number of millisecond elapsed since last update
     * @param drawOffset Absolute offset from the upper lefthand corner (GUI space)
     * @param guistate The state of the GUI at this update
     *
     */
    void update( uint64 delta, ivec2 drawOffset, GUIState& guistate ) {

        // Simply pass this on to the children
        ivec2 currentDrawOffset = drawOffset;
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
     * @brief Rederive the regions for the various orientation containers - for internal use
     * 
     */
     void resetRegions() {

        // Reset the region tracking
        topLeftBoundStart = UNDEFINEDSIZE;   
        topLeftBoundEnd = UNDEFINEDSIZE;     
        centerBoundStart = UNDEFINEDSIZE;   
        centerBoundEnd = UNDEFINEDSIZE;     
        bottomRightBoundStart = UNDEFINEDSIZE;
        bottomRightBoundEnd = UNDEFINEDSIZE;
        
        // see which direction we're going
        if( orientation == DOVertical ) {

            // sum the top contents
            for( uint i = 0; i < topLeftContents.length(); i++ ) {

                if( topLeftBoundStart == UNDEFINEDSIZE ) {
                    topLeftBoundStart = 0;
                    topLeftBoundEnd = -1;
                }

                // if( topLeftContents[i].getBoundarySizeY() == UNDEFINEDSIZE ) {
                //     DisplayError("GUI Error", "Element with undefined size in vertical divider");
                // }

                if( topLeftContents[i].getBoundarySizeY() != UNDEFINEDSIZE ) {
                    // update the totals
                    topLeftBoundEnd += topLeftContents[i].getBoundarySizeY() - 1;

                    // // check to see if this element pushes the boundary of the divider
                    if( topLeftContents[i].getBoundarySizeX() > getBoundarySizeX() ) {
                        setSizeX( topLeftContents[i].getBoundarySizeX() );
                    }

                    // check to make sure the element boundary is the same as this container
                    if( topLeftContents[i].getBoundarySizeX() < getBoundarySizeX() ) {
                        topLeftContents[i].setBoundarySizeX( getBoundarySizeX() );
                    }

                }   
            }

            // As the center is one element, we just need to calculate from it
            if( centeredElement !is null && centeredElement.getBoundarySizeX() != UNDEFINEDSIZE ) {
                
                int dividerCenter = ((getBoundarySizeY() - 1)/2);

                centerBoundStart = dividerCenter - (centeredElement.getBoundarySizeY()/2);
                centerBoundEnd = centerBoundStart  + ( centeredElement.getBoundarySizeY() - 1 );

                // check to see if this element pushes the boundary of the divider
                if( centeredElement.getBoundarySizeX() > getBoundarySizeX() ) {
                    setSizeX( centeredElement.getBoundarySizeX() );
                }

                // check to make sure the element boundary is the same as this container
                if( centeredElement.getBoundarySizeX() < getBoundarySizeX() ) {
                    centeredElement.setBoundarySizeX( getBoundarySizeX() );
                }

            }

            // sum the bottom contents
            for( int i = int(bottomRightContents.length())-1; i >= 0 ; i-- ) {

                if( bottomRightBoundStart == UNDEFINEDSIZE ) {
                    bottomRightBoundEnd = getBoundarySizeY() - 1;
                    bottomRightBoundStart = bottomRightBoundEnd + 1;
                }
                
                // if( bottomRightContents[i].getBoundarySizeY() == UNDEFINEDSIZE ) {
                //     DisplayError("GUI Error", "Element with undefined size in vertical divider");
                // }

                if( bottomRightContents[i].getBoundarySizeX() != UNDEFINEDSIZE ) {
                    // update the totals
                    bottomRightBoundStart -= (bottomRightContents[i].getSizeY() - 1);

                    // check to see if this element pushes the boundary of the divider
                    if( bottomRightContents[i].getBoundarySizeX() > getBoundarySizeX() ) {
                        setSizeX( bottomRightContents[i].getBoundarySizeX() );
                    }

                    // check to make sure the element boundary is the same as this container
                    if( bottomRightContents[i].getBoundarySizeX() < getBoundarySizeX() ) {
                        bottomRightContents[i].setBoundarySizeX( getBoundarySizeX() );
                    }
                }

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

                // if( topLeftContents[i].getBoundarySizeX() == UNDEFINEDSIZE ) {
                //     DisplayError("GUI Error", "Element with undefined size in vertical divider");
                // }

                if( topLeftContents[i].getBoundarySizeX() != UNDEFINEDSIZE ) {
                    // update the totals
                    topLeftBoundEnd += topLeftContents[i].getBoundarySizeX()- 1;

                    // check to see if this element pushes the boundary of the divider
                    if( topLeftContents[i].getBoundarySizeY() > getBoundarySizeY() ) {
                        setSizeY( topLeftContents[i].getBoundarySizeY() );
                    }

                    // check to make sure the element boundary is the same as this container
                    if( topLeftContents[i].getBoundarySizeY() < getBoundarySizeY() ) {
                        topLeftContents[i].setBoundarySizeY( getBoundarySizeY() );
                    }
                }

            }

            // As the center is one element, we just need to calculate from it
            if( centeredElement !is null && centeredElement.getBoundarySizeY() != UNDEFINEDSIZE ) {
                
                int dividerCenter = ((getBoundarySizeX()- 1)/2);
                centerBoundStart = dividerCenter - (centeredElement.getBoundarySizeX()/2);
                centerBoundEnd = centeredElement.getBoundarySizeX() - 1;

                // check to see if this element pushes the boundary of the divider
                if( centeredElement.getBoundarySizeY() > getBoundarySizeY() ) {
                    setSizeY( centeredElement.getBoundarySizeY() );
                }

                // check to make sure the element boundary is the same as this container
                if( centeredElement.getBoundarySizeY() < getBoundarySizeY() ) {
                    centeredElement.setBoundarySizeY( getBoundarySizeY() );
                }

            }

            // sum the bottom/right contents
            for( int i = int(bottomRightContents.length())-1; i >= 0 ; i-- ) {

                if( bottomRightBoundStart == UNDEFINEDSIZE ) {
                    bottomRightBoundEnd = getBoundarySizeX() - 1;
                    bottomRightBoundStart = bottomRightBoundEnd + 1;
                }

                // if( bottomRightContents[i].getBoundarySizeX() == UNDEFINEDSIZE ) {
                //     DisplayError("GUI Error", "Element with undefined size in vertical divider");
                // }

                if( bottomRightContents[i].getBoundarySizeY() != UNDEFINEDSIZE ) {

                    // update the totals
                    bottomRightBoundStart -= (bottomRightContents[i].getBoundarySizeX() - 1);

                    // check to see if this element pushes the boundary of the divider
                    if( bottomRightContents[i].getBoundarySizeY() > getBoundarySizeY() ) {
                        setSizeY( bottomRightContents[i].getBoundarySizeY() );
                    }

                    // check to make sure the element boundary is the same as this container
                    if( bottomRightContents[i].getBoundarySizeY() < getBoundarySizeY() ) {
                        bottomRightContents[i].setBoundarySizeY( getBoundarySizeY() );
                    }

                }
            }
        }
     }

    
    /*******************************************************************************************/
    /**
     * @brief Check for overlapping/overflowing regions
     * 
     */
    void checkRegionOverflow() {

        // Print("topLeftBoundStart:" + topLeftBoundStart + "\n");
        // Print("topLeftBoundEnd:" + topLeftBoundEnd + "\n");
        // Print("centerBoundStart:" + centerBoundStart + "\n");
        // Print("centerBoundEnd:" + centerBoundEnd + "\n");
        // Print("bottomRightBoundStart:" + bottomRightBoundStart + "\n");
        // Print("bottomRightBoundEnd:" + bottomRightBoundEnd + "\n");

        // Do a three way comparison to see if the three regions overlap
        if( ( topLeftBoundEnd != UNDEFINEDSIZE && centerBoundStart != UNDEFINEDSIZE && 
              topLeftBoundEnd > centerBoundStart ) ||
            ( centerBoundEnd != UNDEFINEDSIZE && bottomRightBoundStart != UNDEFINEDSIZE && 
              centerBoundEnd > bottomRightBoundStart ) ||
            ( topLeftBoundEnd != UNDEFINEDSIZE && bottomRightBoundStart != UNDEFINEDSIZE && 
              topLeftBoundEnd > bottomRightBoundStart ) ) {

            //DisplayError("GUI Error", "Overlapping divider");

            //TODO: This should be a warning somehow
            //Print("Overlapping divider elements!\n");

        }

        // Now check that no region overflows the divider
        if( orientation == DOVertical ) {
            if( topLeftBoundEnd != UNDEFINEDSIZE && 
                topLeftBoundEnd - topLeftBoundStart > getBoundarySizeY() ) {
                
                DisplayError("GUI Error", "Overfilled divider in " + name );
            
            }

            if( centeredElement !is null ) { 
                if( centeredElement.getBoundarySizeY() > getBoundarySizeY() )
                {
                    DisplayError("GUI Error", "Overfilled divider in " + name );
                }
            }

            if( bottomRightBoundStart != UNDEFINEDSIZE &&
                bottomRightBoundEnd - bottomRightBoundStart > getBoundarySizeY() ) {
                
                DisplayError("GUI Error", "Overfilled divider in " + name );
            
            }
        }
        else {
            if( topLeftBoundEnd != UNDEFINEDSIZE && 
                topLeftBoundEnd - topLeftBoundStart > getBoundarySizeX() ) {
                
                DisplayError("GUI Error", "Overfilled divider in " + name );
            
            }

            if( centeredElement !is null ) { 
                if( centeredElement.getBoundarySizeX() > getBoundarySizeX() )
                {
                    DisplayError("GUI Error", "Overfilled divider in " + name );
                }
            }

            if( bottomRightBoundStart != UNDEFINEDSIZE &&
                bottomRightBoundEnd - bottomRightBoundStart > getBoundarySizeX() ) {
                
                DisplayError("GUI Error", "Overfilled divider in " + name );
            
            }
        }

    }

    /*******************************************************************************************/
    /**
     * @brief  When a resize, move, etc has happened do whatever is necessary
     * 
     */
     void doRelayout() {
        
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

        resetRegions();
        checkRegionOverflow();

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
            newSpacer.setSize( size.x, _size );
        }
        else {
            newSpacer.setSize( _size, size.y );
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

    //TODO: add expanding similarly aligned dividers if needed
    Divider@ addDivider( DividerDirection direction ) {
        if( orientation == DOVertical ) {
            return addDivider( direction, DOHorizontal, UNDEFINEDSIZE );
        }
        else {
            return addDivider( direction, DOVertical, UNDEFINEDSIZE );   
        }
    }

    Divider@ addDivider( DividerDirection direction, DividerOrientation newOrientation, int size  ) {
        
        if( size == UNDEFINEDSIZE ) {
            if( orientation == newOrientation ) {
                DisplayError("GUI Error", "Must specify a size embedding a co-aligned divider");
            }

            if( orientation == DOVertical ) {
                size = getSizeX();
            }
            else {
                size = getSizeY();
            }
        }

        // Create a new spacer object
        Divider@ newDivider = Divider(newOrientation); 
        
        // Set the coordinates based on the orientation
        if( orientation == DOVertical ) {
            newDivider.setSize( size, UNDEFINEDSIZE );
        }
        else {
            newDivider.setSize( UNDEFINEDSIZE, size );
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
    void addElement( Element@ newElement, DividerDirection direction = DDTopLeft ) {

        // Make sure this container has been properly initialized 
        // if( getSizeX() == UNDEFINEDSIZE || getSizeY() == UNDEFINEDSIZE ) {
        //     DisplayError("GUI Error", "Attempting to add to a container with undefined size");
        // }

        // Make sure the element has a name 
        if( newElement.name == "" ) {
            newElement.name = owner.getUniqueName();
        }

        // Which orientation is this container?
        if( orientation == DOVertical ) {
            
            // if( newElement.getSizeY() == UNDEFINEDSIZE ) {  
            //     DisplayError("GUI Error", "Undefined y size adding to vertical container " + name);
            // }

            // See if a size has already been defined or is too big
            // if( newElement.getBoundarySizeX() == UNDEFINEDSIZE ) {
            //     newElement.setBoundarySizeSizeX( getBoundarySizeX() );
            // }

            // if( newElement.getSizeX() > getSizeX() ) {
            //     DisplayError("GUI Error", "Overfilling vertical divider");
            // }

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

            // if( newElement.getSizeX() == UNDEFINEDSIZE ) {  
            //     DisplayError("GUI Error", "Undefined x size adding to horizontal container");
            // }

            // // See if a size has already been defined or is too big
            // if( newElement.getSizeY() == UNDEFINEDSIZE ) {
            //     newElement.setSizeY( getSizeY() );
            // }

            // if( newElement.getSizeY() > getSizeY() ) {
            //     DisplayError("GUI Error", "Overfilling horizontal divider");
            // }

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

                    if( centeredElement is null ) {
                        DisplayError("GUI Error", "Multiple centered elements added to divider");  
                    }

                    @centeredElement = @newElement;

                    break;
                }
                default:

            }   
        }

        // Rederive the regions and check for conflicts
        resetRegions();
        checkRegionOverflow();

        // Link to this element/owning GUI
        @newElement.owner = @owner;
        @newElement.parent = @this;

    }

    /*******************************************************************************************/
    /**
     * @brief  Destrcutor
     *
     */
    ~Divider() {
        topLeftContents.resize(0);
        bottomRightContents.resize(0);
        @centeredElement = null;
    }

}


} // namespace AHGUI

