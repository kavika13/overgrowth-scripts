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
     * @param imageName Filename for the image
     *
     */
    Image(string imageName) {
        super();
        setImageFile( imageName );
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
        return "Image";
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
        
        // Reset the boundary to the size
        //setBoundarySize();
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
     * @brief  Rather counter-intuitively, this draws this object on the screen
     *
     * @param drawOffset Absolute offset from the upper lefthand corner (GUI space)
     *
     */
    void render( ivec2 drawOffset ) {

    	// Make sure we have an an image and we're supposed draw it
    	if( imageFileName != "" && show ) {
	    	
	    	@imageHandle = hud.AddImage();
	        imageHandle.SetImageFromPath( imageFileName );

	        ivec2 GUIRenderPos = drawOffset + boundaryOffset + drawDisplacement;

			ivec2 screenRenderPos = screenMetrics.GUIToScreen( GUIRenderPos );

			imageHandle.scale = 1;
	     	imageHandle.scale.x *= (float(getSizeX())*screenMetrics.GUItoScreenXScale)/float(originalImageSize.x);
	    	imageHandle.scale.y *= (float(getSizeY())*screenMetrics.GUItoScreenYScale)/float(originalImageSize.y);

	     	imageHandle.position.x = screenRenderPos.x;
	     	imageHandle.position.y = GetScreenHeight() - screenRenderPos.y - (originalImageSize.x * imageHandle.scale.y );
	     	imageHandle.position.z = 0.0;
	     	
	     	imageHandle.color = color;

	     	//hud.Draw();

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

