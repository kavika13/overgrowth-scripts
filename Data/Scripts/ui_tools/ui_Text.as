#include "ui_tools/ui_support.as"
#include "ui_tools/ui_Element.as"

/*******
 *  
 * ui_Text.as
 *
 * Text element class for creating adhoc GUIs as part of the UI tools  
 *
 */

namespace AHGUI {

/*******************************************************************************************/
/**
 * @brief Any styled text element 
 *
 */
class Text : Element 
{

    string text;        // Actual text to render
    int GUIfontSize;    // Height of the text (GUI space)
    int screenFontSize; // Height of the text (screen space)
    string fontName;    // Name for the font 
    ivec2 screenSize;   // Bit of a hack as we need the screen height for getting the right metrics
    float ascenderRatio;// How much of the font is ascender    
    float R;    // Red 
    float G;    // Green 
    float B;    // Blue
    float A;    // Alpha

    /*******************************************************************************************/
    /**
     * @brief  Constructor
     *
     */
    Text() {
        super();
        setColor( 1.0, 1.0, 1.0, 1.0 );
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
        setColor( 1.0, 1.0, 1.0, 1.0 );
    }

    /*******************************************************************************************/
    /**
     * @brief  Derives the various metrics for this text element
     * 
     */
    void deriveMetrics() {

        // only bother if we have text
        if( text != "" && fontName != "" ) {

            TextMetrics metrics = GetTextAtlasMetrics("Data/Fonts/" + fontName + ".ttf", 
                                                      screenFontSize, kSmallLowercase, text );
            screenSize.x = metrics.bounds_x;
            screenSize.y = metrics.bounds_y;

            setSize( int(float(screenSize.x) / GUItoScreenY()), 
                     int(float(screenSize.y) / GUItoScreenY()) );

            ascenderRatio = metrics.ascenderRatio;

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
        GUIfontSize = _fontSize;
        screenFontSize = int(GUItoScreenY() * float(_fontSize));

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

    /*******************************************************************************************/
    /**
     * @brief  Set the color for the text
     *  
     * @param _R Red 
     * @param _G Green
     * @param _B Blue
     * @param _A Alpha
     *
     */
    void setColor( float _R, float _G, float _B, float _A = 1.0f ) {
        R = _R;
        G = _G;
        B = _B;
        A = _A;
    } 

    /*******************************************************************************************/
    /**
     * @brief  Sets the red value
     * 
     * @param value Color value  
     *
     */
     void setR( float value ) {
        R = value;
     }

    /*******************************************************************************************/
    /**
     * @brief  Gets the red value
     * 
     * @returns Color value
     *
     */
     float getR() {
        return R;
     }

    /*******************************************************************************************/
    /**
     * @brief Sets the green value
     * 
     * @param value Color value  
     *
     */
     void setG( float value ) {
        G = value;
     }

    /*******************************************************************************************/
    /**
     * @brief Gets the green value
     * 
     * @returns Color value
     *
     */
     float getG() {
        return G;
     }

    /*******************************************************************************************/
    /**
     * @brief Sets the blue value
     * 
     * @param value Color value  
     *
     */
     void setB( float value ) {
        B = value;
     }

    /*******************************************************************************************/
    /**
     * @brief Gets the blue value
     * 
     * @returns Color value
     *
     */
     float getB() {
        return B;
     }

    /*******************************************************************************************/
    /**
     * @brief Sets the alpha value
     * 
     * @param value Color value  
     *
     */
     void setAlpha( float value ) {
        A = value;
     }

    /*******************************************************************************************/
    /**
     * @brief Gets the alpha value
     * 
     * @returns Color value
     *
     */
     float getAlpha() {
        return A;
     }

    /*******************************************************************************************/
    /**
     * @brief  Rather counter-intuitively, this draws this object on the screen
     *
     * @param drawOffset Absolute offset from the upper lefthand corner (GUI space)
     *
     */
    void render( ivec2 drawOffset ) {

        // Print( "Screen resolution: " + GetScreenWidth() + ", " + GetScreenHeight() + "\n");

        // Print( "GUISpace: " + GUISpaceX + ", " + GUISpaceY + "\n");

        // Print( "Text size (GUI): " + size.toString() + "\n" );
        // Print( "Boundary size (GUI): " + boundarySize.toString() + "\n" );

        // Print( "Draw offset (GUI): " + drawOffset.toString() + "\n" );
        // Print( "Boundary offset (GUI): " + boundaryOffset.toString() + "\n" );

        ivec2 GUIRenderPos = drawOffset + boundaryOffset;

        // Print( "Render position (GUI): " + GUIRenderPos.toString() + "\n" );

        ivec2 screenRenderPos = GUIToScreen( GUIRenderPos );

        // Print( "Render position (Screen): " + screenRenderPos.toString() + "\n" );

        // ivec2 sixteenByNine = get16x9Size();
        // Print( "16x9 region: " + sixteenByNine.toString() + "\n");

        // Print( "Font height (GUI): " + GUIfontSize + " Font height (screen): " + screenFontSize + "\n" );
        // ivec2 elemSize = getSize();
        // Print( "Element size: " + elemSize.toString() + "\n" );

        // Print( "Aspect compensation offset: " + renderOffset.toString() + "\n" );
        // Print( "Compensated render position (Screen): " + screenRenderPos.toString() + "\n" );
        // Print( "Ascender ratio: " + ascenderRatio + "\n" );        

        // ivec2 debugBoxSize( screenFontSize, screenFontSize );
        // drawDebugBox( screenRenderPos, debugBoxSize, 0.0, 0.0, 0.5, 0.5 );

        DrawTextAtlas( "Data/Fonts/" + fontName + ".ttf", screenFontSize, 
                      kSmallLowercase, text, 
                      screenRenderPos.x, screenRenderPos.y + int(float(screenSize.y) * ascenderRatio),
                      vec4( R, G, B, A ) );

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

        Element::update( delta, drawOffset, guistate );
    
    }

}

} // namespace AHGUI

