#include "ui_tools/ui_support.as"
#include "ui_tools/ui_Element.as"
#include "ui_tools/ui_GUI.as"

/*******
 *  
 * ui_behaviors.as
 *
 * A collection of useful behaviors for the UI tools  
 *
 */

/*************************************
 *****************
 *******
 *  
 * update behaviors 
 *
 *******/



/*************************************
 *****************
 *******
 *  
 * mouse over behaviors 
 *
 *******/


/*************************************
 *****************
 *******
 *  
 * mouse click behaviors 
 *
 *******/

/**
 * Sends a specific message on click (mouse *up*)
 **/

class FixedMessageOnClick : AHGUI::MouseClickBehavior {

    AHGUI::Message@ theMessage;

    /*******************************************************************************************/
    /**
     * @brief  Various constructors
     *
     */
    FixedMessageOnClick( string messageName ) {
        @theMessage = @AHGUI::Message(messageName);
    }

    FixedMessageOnClick( string messageName, int param ) {
        @theMessage = @AHGUI::Message(messageName, param);
    }

    FixedMessageOnClick( string messageName, string param ) {
        @theMessage = @AHGUI::Message(messageName, param);
    }

    FixedMessageOnClick( string messageName, float param ) {
        @theMessage = @AHGUI::Message(messageName, param);
    }

    bool onUp( AHGUI::Element@ element, uint64 delta, ivec2 drawOffset, AHGUI::GUIState& guistate ) {
        if( element.owner !is null  ) {
        	element.owner.receiveMessage( theMessage );
        }
        return true;
    }

}



