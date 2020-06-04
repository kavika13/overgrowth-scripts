#include "menu_common.as"
#include "music_load.as"

MusicLoad ml("Data/Music/lugaru_new.xml");

IMGUI imGUI;

const int item_per_screen = 4;
const int rows_per_screen = 3;

array<LevelInfo@> lugaru_levels = {	LevelInfo("LugaruStory/Village.xml",          "Village",        "Textures/lugarumenu/smallest_Village.jpg"),
								LevelInfo("LugaruStory/Village_2.xml",        "Village 2",			"Textures/lugarumenu/smallest_Village_2.jpg"),
								LevelInfo("LugaruStory/Wanderer.xml",         "Wanderer",			"Textures/lugarumenu/smallest_Wanderer.jpg"),
								LevelInfo("LugaruStory/Village_3.xml",        "Village 3",			"Textures/lugarumenu/smallest_Village_3.jpg"),
								LevelInfo("LugaruStory/Clearing.xml",         "Clearing",			"Textures/lugarumenu/smallest_Clearing.jpg"),
								LevelInfo("LugaruStory/Raider_patrol.xml",    "Raider Patrol",		"Textures/lugarumenu/smallest_Raider_patrol.jpg"),
								LevelInfo("LugaruStory/Raider_camp.xml",      "Raider Camp",  		"Textures/lugarumenu/smallest_Raider_camp.jpg"),
								LevelInfo("LugaruStory/Raider_sentries.xml",  "Raider Sentries",	"Textures/lugarumenu/smallest_Raider_sentries.jpg"),
								LevelInfo("LugaruStory/Raider_base.xml",      "Raider Base",		"Textures/lugarumenu/smallest_Raider_base.jpg"),
								LevelInfo("LugaruStory/Raider_base_2.xml",    "Raider Base 2",		"Textures/lugarumenu/smallest_Raider_base_2.jpg"),
								LevelInfo("LugaruStory/Rocky_hall.xml",       "Rocky Hall",		 	"Textures/lugarumenu/smallest_Rocky_hall.jpg"),
								LevelInfo("LugaruStory/Heading_north.xml",    "Heading North",		"Textures/lugarumenu/smallest_Heading_north.jpg"),
								LevelInfo("LugaruStory/Heading_north_2.xml",  "Heading North 2",	"Textures/lugarumenu/smallest_Heading_north_2.jpg"),
								LevelInfo("LugaruStory/Jack's_camp.xml",      "Willow's Camp",		"Textures/lugarumenu/smallest_Jack's_camp.jpg"),
								LevelInfo("LugaruStory/Jack's_camp_2.xml",    "Willow's Duel",		"Textures/lugarumenu/smallest_Jack's_camp_2.jpg"),
								LevelInfo("LugaruStory/Rocky_hall_2.xml",     "Rocky Hall 2",		"Textures/lugarumenu/smallest_Rocky_hall_2.jpg"),
								LevelInfo("LugaruStory/Rocky_hall_3.xml",     "Rocky Hall 3",		"Textures/lugarumenu/smallest_Rocky_hall_3.jpg"),
								LevelInfo("LugaruStory/To_alpha_wolf.xml",    "To Alpha Wolf",		"Textures/lugarumenu/smallest_To_alpha_wolf.jpg"),
								LevelInfo("LugaruStory/To_alpha_wolf_2.xml",  "To Alpha Wolf 2",	"Textures/lugarumenu/smallest_To_alpha_wolf_2.jpg"),
								LevelInfo("LugaruStory/Wolf_den.xml",         "Wolf Den",			"Textures/lugarumenu/smallest_Wolf_den.jpg"),
								LevelInfo("LugaruStory/Wolf_den_2.xml",       "Wolf Den 2",			"Textures/lugarumenu/smallest_Wolf_den_2.jpg"),
								LevelInfo("LugaruStory/Rocky_hall_4.xml",     "Rocky Hall 4",		"Textures/lugarumenu/smallest_Rocky_hall_4.jpg")};

bool HasFocus() {
    return false;
}

void Initialize() {

    // Start playing some music
    PlaySong("lugaru_menu");

    // We're going to want a 100 'gui space' pixel header/footer
    imGUI.setHeaderHeight(200);
    imGUI.setFooterHeight(200);

    // Actually setup the GUI -- must do this before we do anything
    imGUI.setup();
    BuildUI();
	setBackGround();
}

void BuildUI(){
    int initial_offset = 0;
    if( StorageHasInt32("lugaru_menu-shift_offset") ) {
        initial_offset = StorageGetInt32("lugaru_menu-shift_offset");
    }
    while( initial_offset >= int(lugaru_levels.length()) ) {
        initial_offset -= 4;
        if( initial_offset < 0 ) {
            initial_offset = 0;
            break;
        }
    }
    IMDivider mainDiv( "mainDiv", DOHorizontal );
    mainDiv.setAlignment(CACenter, CACenter);
    CreateMenu(mainDiv, lugaru_levels, "lugaru_campaign", initial_offset, item_per_screen, rows_per_screen);
    // Add it to the main panel of the GUI
    imGUI.getMain().setElement( @mainDiv );
	IMDivider header_divider( "header_div", DOHorizontal );
	AddTitleHeader("Lugaru", header_divider);
	imGUI.getHeader().setElement(header_divider);
    AddBackButton();
}

void Dispose() {
	imGUI.clear();
}

bool CanGoBack() {
    return true;
}

void Update() {

	UpdateController();
	UpdateKeyboardMouse();
    // process any messages produced from the update
    while( imGUI.getMessageQueueSize() > 0 ) {
        IMMessage@ message = imGUI.getNextMessage();

        //Log( info, "Got processMessage " + message.name );

        if( message.name == "Back" )
        {
            this_ui.SendCallback( "back" );
        }
		else if( message.name == "run_file" ) 
        {
            this_ui.SendCallback(message.getString(0));
        }
		else if( message.name == "shift_menu" ){
			StorageSetInt32("lugaru_menu-shift_offset", ShiftMenu(message.getInt(0)));
            SetControllerItemBeforeShift();
            BuildUI();
            SetControllerItemAfterShift(message.getInt(0));
		}
    }
	// Do the general GUI updating
	imGUI.update();
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
