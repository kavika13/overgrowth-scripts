#include "ui_tools/ui_support.as"
#include "ui_tools/ui_Element.as"

/*******
 *  
 * ui_Image.as
 *
 *Image element class for creating adhoc GUIs as part of the UI tools  
 *
 */

namespace AHGUI {

/*******************************************************************************************/
/**
 * @brief Any styled text element 
 *
 */
class Image : Element 
{

	HUDImage@ imageHandle;	//Handle to the 'HUD' image
	string imageFileName; 	//Filename for the image
	
	float R;    // Red 
    float G;    // Green 
    float B;    // Blue
    float A;    // Alpha

    ivec2 originalImageSize;

    /*******************************************************************************************/
    /**
     * @brief  Constructor
     *
     */
    Image() {
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
    Image(string _name) {
        super(name);
        setColor( 1.0, 1.0, 1.0, 1.0 );
    }

    /*******************************************************************************************/
    /**
     * @brief  Sets the source for the image
     * 
     * @param _fileName 
     *
     */
    void setImageFile( string _fileName ) {
        imageFileName = "Data/" + _fileName;

        // Load the image to get the size
        HUDImage@ tempHandle = hud.AddImage();
        tempHandle.SetImageFromPath( imageFileName );

        originalImageSize = ivec2( int(tempHandle.GetWidth()), 
        					       int(tempHandle.GetHeight() ) );

        setSize( originalImageSize );
    }

    /*******************************************************************************************/
    /**
     * @brief  Rescales the image to a specified width
     * 
     * @param newSize new x size   
     *
     */
    void scaleToSizeX( int newSize ) {
    	int newYSize = int( float(originalImageSize.y)/float(originalImageSize.x) * float(newSize) );
     	setSize( newSize, newYSize );
    }

    /*******************************************************************************************/
    /**
     * @brief  Rescales the image to a specified height
     * 
     * @param newSize new y size   
     *
     */
    void scaleToSizeY( int newSize ) {
    	int newXSize = int( float(originalImageSize.x)/float(originalImageSize.y) * float(newSize) );
     	setSize( newXSize, newSize );
    }

   	/*******************************************************************************************/
    /**
     * @brief  Set the color for the image
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

    	// Make sure we have an an image
    	if( imageFileName == "" ) return;

    	@imageHandle = hud.AddImage();
        imageHandle.SetImageFromPath( imageFileName );

        ivec2 GUIRenderPos = drawOffset + boundaryOffset;

		ivec2 screenRenderPos = GUIToScreen( GUIRenderPos );

		imageHandle.scale = 1;
     	imageHandle.scale.x *= (float(getSizeX())*GUItoScreenXScale)/float(originalImageSize.x);
    	imageHandle.scale.y *= (float(getSizeY())*GUItoScreenYScale)/float(originalImageSize.y);

     	imageHandle.position.x = screenRenderPos.x;
     	imageHandle.position.y = GetScreenHeight() - screenRenderPos.y - (originalImageSize.x * imageHandle.scale.y );
     	imageHandle.position.z = 0.0;
     	
     	imageHandle.color = vec4( R, G, B, A );

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

