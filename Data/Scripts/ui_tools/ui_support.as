/*******
 *  
 * ui_support.as
 *
 * A set of support function and defines for putting together `ad hoc'/overlay GUIs  
 *
 */

// All coordinates are specified in terms of a space 2560 x 1440
// (at the moment -- this assumes 16:9 ratio -- other ratios are a TODO)
// when rendering to the screen the projection is done automatically
// coordinates start at the top left of the screen 


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

    ivec2 opSub( const ivec2 &in other  ) {
        return ivec2( x - other.x, y - other.y );
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

const int UNDEFINEDSIZE = -1;

namespace AHGUI {

const int GUISpaceX = 2560;
const int GUISpaceY = 1440;



/*******************************************************************************************/
/**
 * @brief  Helper class to derive and contain the scaling factors and offsets between GUI space 
 *         and screen space
 * 
 */



class ScreenMetrics {
    


    float GUItoScreenXScale; // Scaling factor between screen width and GUI space width
    float GUItoScreenYScale; // Scaling factor between screen height and GUI space height
    ivec2 renderOffset; // Where to start rendering to get a 16x9 picture
    ivec2 screenSize; // what physical screen resolution are these values based on

    /*******************************************************************************************/
    /**
     * @brief  Constructor, for constructing
     * 
     */
    ScreenMetrics() {
        computeFactors();
    }

    /*******************************************************************************************/
    /**
     * @brief  Checks to see if the resolution has changed and if so rederive the values
     * 
     * @returns true if the resolution has changed, false otherwise
     *
     */
     bool checkMetrics() {
        if( screenSize.x != GetScreenWidth() || screenSize.y != GetScreenHeight() ) {
            computeFactors();
            return true;
        }
        else {
            return false;
        }


     }


    /*******************************************************************************************/
    /**
     * @brief  Computer various values this class is responsible for
     * 
     */
    void computeFactors() {
        GUItoScreenXScale = GUItoScreenX();
        GUItoScreenYScale = GUItoScreenY();
        renderOffset = getRenderOffset();
        screenSize = ivec2( GetScreenWidth(), GetScreenHeight() );

        // Print("computing metrics for screen size " + screenSize.toString() + "\n");
        // Print(" GUItoScreenXScale:" + GUItoScreenXScale + "\n");
        // Print(" GUItoScreenYScale:" + GUItoScreenYScale + "\n");
        // Print(" renderOffset:" + renderOffset.toString() + "\n");

    }

    //Figure out the largest 16 x 9 box we can fit on the screen (hopefully the whole screen)
    ivec2 get16x9Size() {

        ivec2 adjScreenSize;
        // see if we're wider than 16x9
        if( float(GetScreenWidth())/16.0 > (GetScreenHeight())/9.0 ) {
            // if so, we'll black out the sides
            adjScreenSize.y = GetScreenHeight();
            adjScreenSize.x = int((float(adjScreenSize.y)/ 9.0 ) * 16.0);
        }
        else {
            // otherwise we 'letterbox' up top (if needed)
            adjScreenSize.x = GetScreenWidth();
            adjScreenSize.y = int((float(adjScreenSize.x)/ 16.0 ) * 9.0);
        }

        return adjScreenSize;
    }


    float GUItoScreenX() {
        ivec2 screenSpace = get16x9Size();
        return ( float(screenSpace.x) / float(GUISpaceX) );
    }

    float GUItoScreenY() {
        ivec2 screenSpace = get16x9Size();
        return ( float(screenSpace.y) / float(GUISpaceY) );
    }

    ivec2 getRenderOffset() {
        ivec2 screenSpace = get16x9Size();
        return ivec2( (GetScreenWidth() - screenSpace.x )/2, (GetScreenHeight() - screenSpace.y )/2 );
    }

    ivec2 GUIToScreen( const ivec2 pos ) {
        return ivec2( int( float(pos.x) * GUItoScreenXScale ) + renderOffset.x,
                      int( float(pos.y) * GUItoScreenYScale ) + renderOffset.y );
    }

    ivec2 GUIToScreen( const int x, const int y ) {
        return ivec2( int( float(x) * GUItoScreenXScale ) + renderOffset.x,
                      int( float(y) * GUItoScreenYScale ) + renderOffset.y );
    }

}

// make a global pseudo-singleton
ScreenMetrics screenMetrics;

/*******************************************************************************************/
/**
 * @brief  Helper to draw a monocromatic box 
 * 
 *  
 *
 */
void drawDebugBox( bool GUISpace, ivec2 pos, ivec2 size, float R = 1.0f, float G = 1.0f, float B = 1.0f, float A = 1.0f ) {

    // Check to see if the coordinates are in GUI Space (if not it's in screen space)
    if( GUISpace ) {
        pos = screenMetrics.GUIToScreen( pos );
        size.x = int( float(size.x) * screenMetrics.GUItoScreenXScale );
        size.y = int( float(size.y) * screenMetrics.GUItoScreenYScale );
    }

    HUDImage @boximage = hud.AddImage();
    boximage.SetImageFromPath("Data/Textures/ui/whiteblock.tga");

    boximage.scale = 1;
    boximage.scale.x *= size.x;
    boximage.scale.y *= size.y;

    boximage.position.x = pos.x;
    boximage.position.y = GetScreenHeight() - pos.y - (boximage.GetWidth() * boximage.scale.y );
    boximage.position.z = 1.0;// 0.1f;

    boximage.color = vec4( R, G, B, A );  

}


} // namespace AHGUI


/*******************************************************************************************/
/**
 * @brief Enums for various options, out of the namespace for sanities sake, they should 
 *        be easily unique
 *
 */
enum DividerOrientation {
    DOVertical,  // self explanatory 
    DOHorizontal // also self explanatory 
}

// When placing an element in a divider, which direction is it coming from
//  right now a container can only have one centered element
enum DividerDirection {
    DDTopLeft = 0,
    DDTop = 0,
    DDLeft = 0,
    DDCenter = 1,
    DDBottomRight = 2,
    DDBottom = 2,
    DDRight = 2
}

// When the boundary of an element is bigger than itself, how should it align itself
enum BoundaryAlignment {
    BATop = 0,
    BALeft = 0,
    BACenter = 1,
    BARight = 2,
    BABottom = 2

}

