#include "menu_common.as"
#include "music_load.as"

MusicLoad ml("Data/Music/menu.xml");

IMGUI imGUI;

array<LevelInfo@> campaign_levels = {};

bool HasFocus() {
    return false;
}

void Initialize() {
    // Start playing some music
    PlaySong("overgrowth_main");

    // We're going to want a 100 'gui space' pixel header/footer
    imGUI.setHeaderHeight(200);
    imGUI.setFooterHeight(200);

    // Actually setup the GUI -- must do this before we do anything
    imGUI.setup();

    IMDivider mainDiv( "mainDiv", DOHorizontal );
    mainDiv.setAlignment(CACenter, CACenter);
    CreateMenu(mainDiv, campaign_levels, "main_campaign", 0);
    // Add it to the main panel of the GUI
    imGUI.getMain().setElement( @mainDiv );
	IMDivider header_divider( "header_div", DOHorizontal );
	AddTitleHeader(Main Campaign, header_divider);
	imGUI.getHeader().setElement(header_divider);
    AddBackButton();
	setBackGround();
}

void Dispose() {
	imGUI.clear();
}

bool CanGoBack() {
    return true;
}

void Update() {
	UpdateKeyboardMouse();
    // process any messages produced from the update
    while( imGUI.getMessageQueueSize() > 0 ) {
        IMMessage@ message = imGUI.getNextMessage();

        /*Log( info, "Got processMessage " + message.name );*/

        if( message.name == "load_level" )
        {
            this_ui.SendCallback( "Data/Levels/" + message.getString(0) );
        }
		if( message.name == "Back" )
		{
			this_ui.SendCallback( "back" );
		}
		else if( message.name == "shift_menu" ){
			ShiftMenu(message.getInt(0));
		}
    }
	// Do the general GUI updating
    imGUI.update();
	UpdateController();
}

void Resize() {
    imGUI.doScreenResize(); // This must be called first
	setBackGround();
}

void ScriptReloaded() {
    // Clear the old GUI
    imGUI.clear();
    // Rebuild it
    Initialize();
}

void DrawGUI() {
    imGUI.render();
}

void Draw() {
}

void Init(string str) {
}
