#include "menu_common.as"
#include "music_load.as"

MusicLoad ml("Data/Music/menu.xml");

const int item_per_screen = 4;
const int rows_per_screen = 1;

IMGUI@ imGUI;
array<LevelInfo@> play_menu = {};

array<array<string> > difficulty_description = {
{"Experience the story of Overgrowth"},
{"Fight like a ninja rabbit"},
{"Prove your mastery of combat", " ", "Tutorials will be disabled"}
};

array<string> difficulty_logos = {
    "Textures/Thumbnails/difficulty/casual.png",
    "Textures/Thumbnails/difficulty/hardcore.png",
    "Textures/Thumbnails/difficulty/expert.png"
};

FontSetup description_font("Cella", 36 , HexColor("#CCCCCC"), true);
FontSetup subtitle_font("Cella", 36 , HexColor("#CCCCCC"), true);

IMDivider@ description_divider;
int current_difficulty_description = -1;

bool HasFocus() {
    return false;
}

void Initialize() {
    @imGUI = CreateIMGUI();
    // Start playing some music
    PlaySong("overgrowth_main");

    // We're going to want a 100 'gui space' pixel header/footer
	imGUI.setHeaderHeight(200);
    imGUI.setFooterHeight(200);

	imGUI.setFooterPanels(200.0f, 1400.0f);
    // Actually setup the GUI -- must do this before we do anything
    imGUI.setup();
    SetList();
    BuildUI();
	setBackGround();
	AddVerticalBar();
}

void SetList() {
    array<string> diff = GetConfigValueOptions("difficulty_preset");
    for( uint i = 0; i < diff.size(); i++ ) {
        LevelInfo li("", diff[i], difficulty_logos[i],i+1);
        play_menu.insertLast(li);
    }
}

void BuildUI() {
    IMDivider upperMainDiv("upperMainDiv", DOVertical);
    IMDivider mainDiv( "mainDiv", DOHorizontal );
	IMDivider header_divider( "header_div", DOHorizontal );
	header_divider.setAlignment(CACenter, CACenter);
	AddTitleHeader("Choose Difficulty", header_divider);
	imGUI.getHeader().setElement(header_divider);

    int initial_offset = 0;
    if( StorageHasInt32("play_menu-shift_offset") ) {
        initial_offset = StorageGetInt32("play_menu-shift_offset");
    }
    while( initial_offset >= int(play_menu.length()) ) {
        initial_offset -= item_per_screen;
        if( initial_offset < 0 ) {
            initial_offset = 0;
            break;
        }
    }

	float subtitle_width = 200;
	float subtitle_height = 100;

	IMContainer subtitle_container(subtitle_width, subtitle_height);
	subtitle_container.setAlignment(CACenter, CACenter);
	IMDivider subtitle_divider("subtitle_divider", DOVertical);
	subtitle_container.setElement(subtitle_divider);

	//subtitle_divider.setAlignment(CALeft, CACenter);
	//subtitle_divider.setZOrdering(5);
	//subtitle_divider.appendSpacer(15.0f);
    subtitle_divider.append(IMText("Note: You can change the difficulty at any point." , subtitle_font));
    //subtitle_divider.append(IMText("difficulty later in the settings." , subtitle_font));

    upperMainDiv.append(subtitle_container);

    // Add it to the main panel of the GUI
    imGUI.getMain().setElement( @upperMainDiv );

	CreateMenu(mainDiv, play_menu, "play_menu", initial_offset, item_per_screen, rows_per_screen, false, false, 2000.0f, 300.0f,false,false,false);

	float description_width = 200;
	float description_height = 150;

	IMContainer description_container(description_width, description_height);
	description_container.setAlignment(CACenter, CACenter);
	@description_divider = @IMDivider("description_divider", DOVertical);
	description_container.setElement(description_divider);

	//description_divider.setAlignment(CALeft, CACenter);
	//description_divider.setZOrdering(5);
	//description_divider.appendSpacer(15.0f);

    upperMainDiv.append(mainDiv);
    upperMainDiv.append(description_container);

    // Add it to the main panel of the GUI
    imGUI.getMain().setElement( @upperMainDiv );

    if(GetConfigValueBool("difficulty_set")) {
	    AddBackButton();
    }
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
        if( message.name == "run_file" ) {
            uint id = uint(message.getInt(0));
            if( id < play_menu.size() ){
                SetConfigValueString("difficulty_preset",play_menu[id].name);
                SetConfigValueBool("difficulty_set",true);
                this_ui.SendCallback( "back" );
            }
        } else if( message.name == "hover_leave_file" ) {
            if( current_difficulty_description == message.getInt(0) ) {
                description_divider.clear();
            }
            current_difficulty_description = -1;
        } else if( message.name == "hover_enter_file" ) {
            description_divider.clear();
            uint d_index = uint(message.getInt(0));
            current_difficulty_description = d_index;
            if( d_index < difficulty_description.size() ) {
                for( uint i = 0; i < difficulty_description[d_index].size(); i++ ) {
                    IMText@ description_t = @IMText(difficulty_description[d_index][i], description_font);
                    description_divider.append(description_t);
                }
            }
        } else if( message.name == "Back" ) {
            this_ui.SendCallback( "back" );
        } else if( message.name == "shift_menu" ){
            StorageSetInt32("play_menu-shift_offset", ShiftMenu(message.getInt(0)));
            SetControllerItemBeforeShift();
            BuildUI();
            SetControllerItemAfterShift(message.getInt(0));
		}
    }
	// Do the general GUI updating
    imGUI.update();
	UpdateController();
}

void Resize() {
    imGUI.doScreenResize(); // This must be called first
	setBackGround();
	AddVerticalBar();
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
