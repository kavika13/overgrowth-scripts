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

namespace AHGUI {

const int GUISpaceX = 2560;
const int GUISpaceY = 1440;
const int UNDEFINEDSIZE = -1;



/*******************************************************************************************/
/**
 * @brief  Helper functions to get the scaling factors and offsets between GUI space 
 *         and screen space
 * 
 */

//Figure out the largest 16 x 9 box we can fit on the screen (hopefully the whole screen)
// TODO: math for the odd case where the screen is *wider* than 16:9 
ivec2 get16x9Size() {

    ivec2 adjScreenSize;
    adjScreenSize.x = GetScreenWidth();
    adjScreenSize.y = int((float(adjScreenSize.x)/ 16.0 ) * 9.0);

    return adjScreenSize;
}


float GUItoScreenX() {

    ivec2 screenSpace = get16x9Size();
    return ( float(screenSpace.x) / float(GUISpaceX) );

}

float GUItoScreenXScale = GUItoScreenX();
float GUItoScreenYScale = GUItoScreenY();

float GUItoScreenY() {

    ivec2 screenSpace = get16x9Size();
    return ( float(screenSpace.y) / float(GUISpaceY) );

}

ivec2 getRenderOffset() {
    ivec2 screenSpace = get16x9Size();
    return ivec2( 0, (GetScreenHeight() - screenSpace.y )/2 );
}

ivec2 renderOffset = getRenderOffset();

ivec2 GUIToScreen( const ivec2 pos ) {
    return ivec2( int( float(pos.x) * GUItoScreenXScale ) + renderOffset.x,
                  int( float(pos.y) * GUItoScreenYScale ) + renderOffset.y );
}

ivec2 GUIToScreen( const int x, const int y ) {
    return ivec2( int( float(x) * GUItoScreenXScale ) + renderOffset.x,
                  int( float(y) * GUItoScreenYScale ) + renderOffset.y );
}



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
        pos = GUIToScreen( pos );
        size.x = int( float(size.x) * GUItoScreenXScale );
        size.y = int( float(size.y) * GUItoScreenYScale );
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
    DDTopLeft,
    DDBottomRight,
    DDCenter
}

