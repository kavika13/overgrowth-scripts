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
     * @brief  Gets the name of the type of this element — for autonaming and debugging
     * 
     * @returns name of the element type as a string
     *
     */
    string getElementTypeName() {
        return "Text";
    }

    /*******************************************************************************************/
    /**
     * @brief  Constructor
     * 
     * @param _text String for the text
     * @param _fontName name of the font (assumed to be in Data/Fonts)
     * @param _fontSize height of the font
     * @param _R Red 
     * @param _G Green
     * @param _B Blue
     * @param _A Alpha
     *
     */
    Text(string _text, string _fontName, int _fontSize, float _R = 1.0, float _G = 1.0, float _B = 1.0, float _A = 1.0 ) {
        setText( _text );
        setFont( _fontName, _fontSize );
        setColor( _R, _G, _B, _A );
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

            setSize( int(float(screenSize.x) / GUItoScreenX()), 
                     int(float(screenSize.y) / GUItoScreenX()) );

            // Reset the boundary to the size
            setBoundarySize();

            ascenderRatio = metrics.ascenderRatio;

        }

    }

    /*******************************************************************************************/
    /**
     * @brief  Sets the font attributes 
     * 
     * @param _fontName name of the font (assumed to be in Data/Fonts)
     * @param _fontSize height of the font
     *
     */
    void setFont( string _fontName, int _fontSize ) {
        
        fontName = _fontName;
        GUIfontSize = _fontSize;
        screenFontSize = int(GUItoScreenY() * float(_fontSize));

        deriveMetrics();
        onRelayout();

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
        onRelayout();

    }

    /*******************************************************************************************/
    /**
     * @brief  Gets the current text
     * 
     * @returns String for the text
     *
     */
    string getText() {
        return text;
    }

    /*******************************************************************************************/
    /**
     * @brief  Rather counter-intuitively, this draws this object on the screen
     *
     * @param drawOffset Absolute offset from the upper lefthand corner (GUI space)
     *
     */
    void render( ivec2 drawOffset ) {

        // Make sure we're supposed draw 
        if( show ) {
        
            ivec2 GUIRenderPos = drawOffset + boundaryOffset + ivec2( paddingL, paddingU ) + drawDisplacement;

            ivec2 screenRenderPos = GUIToScreen( GUIRenderPos );

            DrawTextAtlas( "Data/Fonts/" + fontName + ".ttf", screenFontSize, 
                           kSmallLowercase, text, 
                           screenRenderPos.x, screenRenderPos.y + int(float(screenSize.y) * ascenderRatio),
                           color );
        }

        // Call the superclass to make sure any element specific rendering is done
        Element::render( drawOffset );

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

