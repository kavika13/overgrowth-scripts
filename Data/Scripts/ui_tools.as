/*******
 *  
 * ui_tool.as
 *
 * A set of tools for putting together `ad hoc'/overlay GUIs  
 *
 */

// All coordinates are specified in terms of a space 2560 x 1440
// (at the moment -- this assumes 16:9 ratio -- other ratios are a TODO)
// when rendering to the screen the projection is done automatically
// coordinates start at the top left of the screen 

namespace AHGUI {

const int GUISpaceX = 2560;
const int GUISpaceY = 1440;
const int UNDEFINEDSIZE = -1;

 class ivec2 {
    int x;
    int y;

    ivec2() {
        x = 0;
        y = 0;
    }

    ivec2( int _x, int _y ) {
        x = _x;
        y = _y;
    }

    ivec2( const ivec2 &in other ) {
        x = other.x;
        y = other.y;
    }

    ivec2 opAdd( const ivec2 &in other  ) {
        return ivec2( x + other.x, y + other.y );
    }

    ivec2@ opAddAssign( const ivec2 &in other  ) {
        x += other.x;
        y += other.y;
        return this;
    }

    ivec2@ opSubAssign( const ivec2 &in other  ) {
        x -= other.x;
        y -= other.y;
        return this;
    }

    ivec2@ opMulAssign( float factor  ) {
        x = int( float(x) * factor );
        y = int( float(y) * factor );
        return this;
    }

    ivec2@ opDivAssign( float factor  ) {
        x = int( float(x)/factor );
        y = int( float(y)/factor );
        return this;
    }

    ivec2 opSub( const ivec2 &in other  ) {
        return ivec2( x - other.x, y - other.y );
    }

    ivec2 opDiv( float factor ) {
        return ivec2( int(float(x)/factor), int(float(y)/factor) );
    }

    ivec2 opMul( float factor ) {
        return ivec2( int(float(x) * factor), int(float(y) * factor) );
    }

    ivec2 opMul_r( float factor ) {
        return ivec2( int(float(x) * factor), int(float(y) * factor) );
    }

    string toString() {
        return "(" + x + "," + y + ")"; 
    }
}
/*******************************************************************************************/
/**
 * @brief  Defines a (axis aligned) 'box' 
 *
 */
class Region {
    ivec2 UL;   // upper left coordinate 
    ivec2 LR;   // lower right coordinate 
    ivec2 size; // dimensions of the region

    /*******************************************************************************************/
    /**
     * @brief  Constructor
     * 
     */
     Region() {
        size.x = UNDEFINEDSIZE;
        size.y = UNDEFINEDSIZE;
     }


    /*******************************************************************************************/
    /**
     * @brief  Gets the effective size (i.e. undefined sizes are 0)  
     * 
     * @param _size 2d size vector (-1 element implies undefined - or use UNDEFINEDSIZE)
     *
     * @returns adjusted size vector
     *
     */
    ivec2 getEffectiveSize() {
        ivec2 effectiveSize(0,0);

        if( size.x != UNDEFINEDSIZE ) {
            effectiveSize.x = size.x;
        }

        if( size.y != UNDEFINEDSIZE ) {
            effectiveSize.y = size.y;
        }

        return effectiveSize;
    }

    /*******************************************************************************************/
    /**
     * @brief  Sets the lower right coordinate based on the size — called internally
     * 
     */
     void resetLR() {
        const ivec2 adjust( -1, -1 );
        LR = UL + getEffectiveSize() + adjust;
     }

    /*******************************************************************************************/
    /**
     * @brief  Sets the size based on upper left and lower right coordinates — called internally
     * 
     */
     void resetSize() {
        size.x = ( LR.x - UL.x ) + 1;
        size.y = ( LR.y - UL.y ) + 1;
     }

    /*******************************************************************************************/
    /**
     * @brief  Sets the size of the region  
     * 
     * @param _size 2d size vector (-1 element implies undefined - or use UNDEFINEDSIZE)
     *
     */
    void setSize( const ivec2 _size ) {
        size = _size;
        resetLR();
    }

    /*******************************************************************************************/
    /**
     * @brief  Sets the size of the region 
     * 
     * @param x x dimension size (-1 implies undefined - or use UNDEFINEDSIZE)
     * @param y y dimension size (-1 implies undefined - or use UNDEFINEDSIZE)
     *
     */
    void setSize( const int x, const int y ) {
        ivec2 newSize( x, y );
        setSize( newSize ); 
    }

    /*******************************************************************************************/
    /**
     * @brief  Sets the x dimension of a region
     * 
     * @param x x dimension size (-1 implies undefined - or use UNDEFINEDSIZE)
     *
     */
    void setSizeX( const int x ) {
        ivec2 newSize( x, size.y );
        setSize( newSize ); 
    }   

    /*******************************************************************************************/
    /**
     * @brief  Sets the y dimension of a region
     * 
     * @param y y dimension size (-1 implies undefined - or use UNDEFINEDSIZE)
     *
     */
    void setSizeY( const int y ) {
        ivec2 newSize( size.x, y );
        setSize( newSize ); 
    }     

    /*******************************************************************************************/
    /**
     * @brief  Sets the position (from upper left) 
     * 
     * @param pos position vector
     *
     */
    void setPosition( ivec2 pos ) {
        
        if( pos.x < 0 || pos.y < 0 ) {
            DisplayError("GUI Error", "Bad position in setPosition");
        }

        UL = pos;
        resetLR();
    }

    /*******************************************************************************************/
    /**
     * @brief  Sets the position (from upper left)  
     * 
     * @param x x coordinate 
     * @param y y coordinate
     *
     */
    void setPosition( int x, int y ) {
        ivec2 newPos( x, y );
        setPosition( newPos );
    }

    /*******************************************************************************************/
    /**
     * @brief Helper function for overlaps -- makes things a little cleaner
     * 
     * @param min smallest point
     * @param max largest point
     *
     */
    bool inSpan( const int &in value, const int &in min, const int &in max ) {
        return ( value >= min ) && ( value <= max );
    }

    /*******************************************************************************************/
    /**
     * @brief determine if this region overlaps with another
     * 
     * @param other Region to compare with
     * 
     * @returns true if overlaps, false otherwise
     * 
     */
    bool overlaps( const Region &in other ) {

        if( size.x == UNDEFINEDSIZE || size.y == UNDEFINEDSIZE ||
            other.size.x == UNDEFINEDSIZE || other.size.y == UNDEFINEDSIZE  ) {

            // Undefined sizes never overlap
            return false;
        }


        bool xOverlap = inSpan(UL.x, other.UL.x, other.LR.x) ||
                        inSpan(other.UL.x, UL.x, LR.x);

        bool yOverlap = inSpan(UL.y, other.UL.y, other.LR.y) ||
                        inSpan(other.UL.y, UL.y, LR.y);

        return xOverlap && yOverlap;

    }

    /*******************************************************************************************/
    /**
     * @brief Derive a region 
     *
     *  Note: if one region has both dimensions undefined the result will be the second
     *        any other configuration will be an error
     * 
     * @param other Region to compare to you
     * 
     * @returns true if overlaps, false otherwise
     * 
     */

    Region combineWith( const Region &in other ) {
        Region newRegion; 

        // first check to see if either region is completely undefined 
        if( size.x == UNDEFINEDSIZE && size.y == UNDEFINEDSIZE  ) {
            if( other.size.x == UNDEFINEDSIZE || other.size.y == UNDEFINEDSIZE ) { 
                DisplayError("GUI Error", "Cannot bound a region with undefined size");
            }
            else {
                newRegion.UL = other.UL;
                newRegion.LR = other.LR;
                newRegion.size = other.size;
            }
            return newRegion;
        }

        if( other.size.x == UNDEFINEDSIZE && other.size.y == UNDEFINEDSIZE  ) {
            if( size.x == UNDEFINEDSIZE || size.y == UNDEFINEDSIZE ) { 
                DisplayError("GUI Error", "Cannot bound a region with undefined size");
            }
            else {
                newRegion.UL = UL;
                newRegion.LR = LR;
                newRegion.size = size;
            }
            return newRegion;
        }


        // Now check to see if this violates the no-partial undefined condition
        if( size.x == UNDEFINEDSIZE || size.y == UNDEFINEDSIZE ||
            other.size.x == UNDEFINEDSIZE || other.size.y == UNDEFINEDSIZE ) {
            DisplayError("GUI Error", "Cannot bound a region with undefined size");
        }
        else {

            // finally we can find the region
            newRegion.UL.x = min( UL.x, other.UL.x );
            newRegion.UL.y = min( UL.y, other.UL.y );
            newRegion.LR.x = max( LR.x, other.LR.x );
            newRegion.LR.y = max( LR.y, other.LR.y );

            newRegion.resetSize();

            
        }
        return newRegion;

    }

}


/*******************************************************************************************/
/**
 * @brief  Base class for all AdHoc Gui elements
 *
 */
class Element {

    Region region;  // where is this element (in 'GUI space', relative to the current container )
    string name;    // name to refer to this object by -- incumbent on the programmer to make sure they're unique
    
    Element@ parent; // null if 'root'
    GUI@ owner;      // what GUI owns this element

    /*******************************************************************************************/
    /**
     * @brief  Constructor
     * 
     * @param _name Name for this object (incumbent on the programmer to make sure they're unique)
     *
     */
    Element( string _name ) {
        name = _name;
    }

    /*******************************************************************************************/
    /**
     * @brief  Constructor
     * 
     */
    Element() {
        name = "";
    }

    /*******************************************************************************************/
    /**
     * @brief  Rather counter-intuitively, this draws this object on the screen
     *
     */
    void render() {
    }

    /*******************************************************************************************/
    /**
     * @brief  Updates the element  
     * 
     * @param delta Number of millisecond elapsed since last update
     *
     */
    void update(uint64 delta) {
        // Just draw this element
        render();
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
     * @brief  Sets the size of the region  
     * 
     * @param _size 2d size vector (-1 element implies undefined - or use UNDEFINEDSIZE)
     *
     */
    void setSize( const ivec2 _size ) {
        region.setSize( _size );
    }

    /*******************************************************************************************/
    /**
     * @brief  Sets the size of the region 
     * 
     * @param x x dimension size (-1 implies undefined - or use UNDEFINEDSIZE)
     * @param y y dimension size (-1 implies undefined - or use UNDEFINEDSIZE)
     *
     */
    void setSize( const int x, const int y ) {
        region.setSize( x, y ); 
    }

    /*******************************************************************************************/
    /**
     * @brief  Sets the x dimension of a region
     * 
     * @param x x dimension size (-1 implies undefined - or use UNDEFINEDSIZE)
     *
     */
    void setSizeX( const int x ) {
        region.setSizeX( x ); 
    }   

    /*******************************************************************************************/
    /**
     * @brief  Sets the y dimension of a region
     * 
     * @param y y dimension size (-1 implies undefined - or use UNDEFINEDSIZE)
     *
     */
    void setSizeY( const int y ) {
        region.setSizeY( y ); 
    }  

    /*******************************************************************************************/
    /**
     * @brief  Gets the size vector
     * 
     * @returns The size vector 
     *
     */
    ivec2 getSize() {
        return region.size;
    }

    /*******************************************************************************************/
    /**
     * @brief  Gets the size x component
     * 
     * @returns The x size
     *
     */
    int getSizeX() {
        return region.size.x;
    }

    /*******************************************************************************************/
    /**
     * @brief  Gets the size y component
     * 
     * @returns The y size
     *
     */
    int getSizeY() {
        return region.size.y;
    }

};

/*******************************************************************************************/
/**
 * @brief Blank space
 *
 */
class Spacer : Element 
{
    /*******************************************************************************************/
    /**
     * @brief  Constructor
     *
     */
    Spacer() {
        super();
    }
}


/*******************************************************************************************/
/**
 * @brief Any styled text element 
 *
 */
class Text : Element 
{

    string text;            // Actual text to render
    int fontSize;           // Height of the text
    string fontName;        // Name for the font 
    int textureId;          // id for the texture
    TextStyle GUIstyle;     // Style instance for this text in GUI space
    TextStyle screenStyle;  // Style instance for this text in screen space 

    /*******************************************************************************************/
    /**
     * @brief  Constructor
     *
     */
    Text() {
        // TODO - sort out the text texturing, will this cause problems? When is this released
        // textureId = level.CreateTextElement();
        // TextCanvasTexture @text = level.GetTextElement(textureId);
        // text.Create(512, 512);
        super();
    }

    /*******************************************************************************************/
    /**
     * @brief  Constructor
     * 
     * @param _name Name for this object (incumbent on the programmer to make sure they're unique)
     *
     */
    Text(string _name) {
        super(name);
    }

    /*******************************************************************************************/
    /**
     * @brief  Derives the various metrics for this text element
     * 
     */
    void deriveMetrics() {

        // only bother if we have text
        if( text != "" ) {
            GUIstyle.font_face_id = GetFontFaceID("Data/Fonts/" + fontName, 
                                                  fontSize);
        } 

    }



    /*******************************************************************************************/
    /**
     * @brief  Sets the font attributes 
     * 
     * @param fontName name of the font (assumed to be in Data/Fonts)
     * @param fontSize height of the font
     *
     */
    void setFont( string _fontName, int _fontSize ) {
        
        fontName = _fontName;
        fontSize = _fontSize;
        deriveMetrics();

    }


    /*******************************************************************************************/
    /**
     * @brief  Sets the actual text 
     * 
     * @param _text String for the text
     *
     */
    void setText( string _text ) {
        text = _text;
        deriveMetrics();
    }

}

/*******************************************************************************************/
/**
 * @brief  Basic container class, holds other elements
 *
 */
enum DividerOrientation {
    DOVertical,  // self explanatory 
    DOHorizontal // also self explanatory 
}

// When placing an element in a divider, which direction is it coming from
//  right now a container can only have one centered element
enum DividerDirection {
    DDTopLeft,
    DDBottomRight,
    DDCenter
}

class Divider : Element {
    
    array<Element@> topLeftContents; // elements in this container top/left
    array<Element@> bottomRightContents; // elements in this container topLeft
    Element@ centeredElement; // element in this container centered (only one allowed)

    Region topLeftRegion;  // region covered by top/left elements
    Region bottomRightRegion; // region covered by bottom/right elements

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
        super(name);
    }


    /*******************************************************************************************/
    /**
     * @brief  Updates the element  
     * 
     * @param delta Number of millisecond elapsed since last update
     *
     */
    void update(uint64 delta) {

        // Simply pass this on to the children
        for( uint i = 0; i < topLeftContents.length(); i++ ) {
            topLeftContents[i].update( delta );
        }

        if( centeredElement !is null ) {
            centeredElement.update( delta );
        }

        for( uint i = 0; i < bottomRightContents.length(); i++ ) {
            bottomRightContents[i].update( delta );
        }

    }

    /*******************************************************************************************/
    /**
     * @brief Rederive the regions for the various orientation containers - for internal use
     * 
     */
     void resetRegions() {
        
        // Reset the regions
        topLeftRegion = Region();
        bottomRightRegion = Region();

        // sum the top/left contents
        for( uint i = 0; i < topLeftContents.length(); i++ ) {
            topLeftRegion = topLeftRegion.combineWith( topLeftContents[i].region );
        }
        // As the center is one element, we don't need to aggregate it

        // sum the bottom/right contents
        for( uint i = 0; i < bottomRightContents.length(); i++ ) {
            bottomRightRegion = bottomRightRegion.combineWith( bottomRightContents[i].region );
        }

     }

    
    /*******************************************************************************************/
    /**
     * @brief Check for overlapping regions
     * 
     */
    void checkRegionOverlap() {

        // Do a three way comparison
        if( topLeftRegion.overlaps( centeredElement.region ) ||
            topLeftRegion.overlaps( bottomRightRegion ) ||
            centeredElement.region.overlaps( bottomRightRegion ) ) {

            DisplayError("GUI Error", "Overfilled divider");
        }

    }


    /*******************************************************************************************/
    /**
     * @brief  Determine if a given element can fit in this divider
     *  
     * @param name Name for this element 
     * @param size Size of the element in terms of guispace pixels
     * @param direction Side of the container to add to 
     *
     * @returns the space object created, just in case you need it
     *
     */
    Element@ addSpacer( string name, int size, DividerDirection direction = DDTopLeft ) {
        
        // Create a new spacer object
        Spacer newSpacer; 
        
        // Set the coordinates based on the orientation
        if( orientation == DOVertical ) {
            newSpacer.setSize( UNDEFINEDSIZE, size );
        }
        else {
            newSpacer.setSize( size, UNDEFINEDSIZE );
        }

        // Add this to the divider
        addElement( newSpacer, direction );

        // return a reference to this object in case the
        //  user needs to reference it (get the name, etc)
        return newSpacer;

    }

    /*******************************************************************************************/
    /**
     * @brief Adds an element to the divider 
     *  
     * @param newElement Element to add  
     * @param direction Portion of the divider to add to (default top/left)
     *
     */
    void addElement( Element &newElement, DividerDirection direction = DDTopLeft ) {

        // Make sure the element has a name 
        if( newElement.name == "" ) {
            newElement.name = owner.getUniqueName();
        }

        // Which orientation is this container?
        if( orientation == DOVertical ) {
            
            if( newElement.getSizeY() == UNDEFINEDSIZE ) {  
                DisplayError("GUI Error", "Undefined y size adding to vertical container");
            }

            // See if a size has already been defined or is too big
            if( newElement.getSizeX() == UNDEFINEDSIZE ) {
                newElement.setSizeX( region.size.x );
            }

            if( newElement.getSizeX() > region.size.x ) {
                DisplayError("GUI Error", "Overfilling vertical divider");
            }

            switch( direction ) {
                
                case DDTopLeft: {

                    topLeftContents.insertLast( newElement );
                    break;    
                }

                case DDBottomRight: {

                    bottomRightContents.insertLast( newElement );
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
        else {
            if( newElement.getSizeX() == UNDEFINEDSIZE ) {  
                DisplayError("GUI Error", "Undefined x size adding to horizontal container");
            }

            // See if a size has already been defined or is too big
            if( newElement.getSizeY() == UNDEFINEDSIZE ) {
                newElement.setSizeY( region.size.y );
            }

            if( newElement.getSizeY() > region.size.y ) {
                DisplayError("GUI Error", "Overfilling horizontal divider");
            }

            switch( direction ) {

                case DDTopLeft: {

                    topLeftContents.insertLast( newElement );
                    break;    
                }

                case DDBottomRight: {

                    bottomRightContents.insertLast( newElement );
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
        checkRegionOverlap();

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

/*******************************************************************************************/
/**
 * @brief One thing to rule them all
 *
 */
class GUI {

    Divider@ root;  // Root of the UI, holds all the contents 
    uint64 lastUpdateTime; // When was this last updated (ms)
    uint elementCount; // Counter for naming unnamed elements
    Region GUISpace;   // region representing the abstract 'GUI space'
    Region screenSpace; // region representing the actual screen

    /*******************************************************************************************/
    /**
     * @brief Constructor
     *  
     * @param mainOrientation The orientation of the container
     *
     */
    GUI( DividerOrientation mainOrientation = AHGUI::DividerOrientation::DOVertical ) {
        Divider newRoot( "root", mainOrientation );
        @newRoot.owner = @this;
        @newRoot.parent = null;
        @root = @newRoot;
        lastUpdateTime = 0;

        GUISpace.setPosition( 0, 0 );
        GUISpace.setSize( GUISpaceX, GUISpaceY );

        screenSpace.setPosition( 0, 0 );
        screenSpace.setSize( GetScreenWidth(), GetScreenHeight() );

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
     * @brief  Updates the gui  
     * 
     */

    int count = 0;

    void update() {
        // If we haven't updated yet, set the time
        if( lastUpdateTime == 0 ) {
            lastUpdateTime = uint64( the_time * 1000 );
        }

        count = ( count + 1 ) % 8;

        DrawTextAtlas("Data/Fonts/OpenSans-Regular.ttf", 600, kSmallLowercase, "The Quick Brown fox jumped over the lazy sleeping dog", 
                      5, 599, vec4(vec3(1.0f), 0.7f));

        TextMetrics metrics = GetTextAtlasMetrics("Data/Fonts/OpenSans-Regular.ttf", 600, kSmallLowercase, "The Quick Brown fox jumped over the lazy sleeping dog");

        Print("Size x = " + metrics.bounds_x + " Size y = " + metrics.bounds_y + "\n" );

        // Calculate the delta time 
        uint64 delta = uint64( the_time * 1000 ) - lastUpdateTime;

        // Now pass this on to the children
        root.update( uint64( the_time * 1000 ) );

        hud.Draw();

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

