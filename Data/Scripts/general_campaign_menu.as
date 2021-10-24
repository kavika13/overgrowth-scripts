#include "menu_common.as"
#include "music_load.as"

MusicLoad ml("Data/Music/menu.xml");

IMGUI@ imGUI;

bool HasFocus() {
    return false;
}

const int item_per_screen = 4;
const int rows_per_screen = 3;

string this_campaign_name = "custom_campaign";

array<LevelInfo@> level_list;
bool is_linear;

void LoadModCampaign() {
    string modid = GetInterlevelData("current_mod_campaign");
    this_campaign_name = modid;
    level_list.removeRange(0, level_list.length());
    array<ModID>@ active_sids = GetActiveModSids();
    for( uint i = 0; i < active_sids.length(); i++ ) {
        if( ModGetID(active_sids[i]) == modid ) {
            array<ModLevel>@ campaign_levels = ModGetCampaignLevels(active_sids[i]);
			Campaign c = ModGetCampaign(active_sids[i]);
			is_linear = c.IsLinear();
            for( uint k = 0; k < campaign_levels.length(); k++ ) {
                level_list.insertLast(LevelInfo(
                    campaign_levels[k].GetPath(),
                    campaign_levels[k].GetTitle(),
                    campaign_levels[k].GetThumbnail()));
            }
        }
    }
}

string GetModTitle() {
    string modid = GetInterlevelData("current_mod_campaign");
    array<ModID>@ active_sids = GetActiveModSids();
    for( uint i = 0; i < active_sids.length(); i++ ) {
        if( ModGetID(active_sids[i]) == modid ) {
            Campaign c = ModGetCampaign(active_sids[i]);
            return c.GetTitle();
        }
    }
    return "";
}

bool GetModIsLinear() {
    string modid = GetInterlevelData("current_mod_campaign");
    array<ModID>@ active_sids = GetActiveModSids();
    for( uint i = 0; i < active_sids.length(); i++ ) {
        if( ModGetID(active_sids[i]) == modid ) {
            Campaign c = ModGetCampaign(active_sids[i]);
            return c.IsLinear();
        }
    }
    return true;
}

void Initialize() {
    @imGUI = CreateIMGUI();
    LoadModCampaign();

    // Start playing some music
    PlaySong("overgrowth_main");

    // We're going to want a 100 'gui space' pixel header/footer
    imGUI.setHeaderHeight(200);
    imGUI.setFooterHeight(200);

    // Actually setup the GUI -- must do this before we do anything
    imGUI.setup();
    BuildUI();
	// setup our background
	setBackGround();
}

void BuildUI(){
    int initial_offset = 0;
    if( StorageHasInt32( this_campaign_name + "-shift_offset" )){
        initial_offset = StorageGetInt32( this_campaign_name + "-shift_offset" );
    }
    while( initial_offset >= int(level_list.length()) ) {
        initial_offset -= item_per_screen;
        if( initial_offset < 0 ) {
            initial_offset = 0;
            break;
        }
    }
    IMDivider mainDiv( "mainDiv", DOHorizontal );
    mainDiv.setAlignment(CACenter, CACenter);
    bool is_linear = GetModIsLinear();
    CreateMenu(mainDiv, level_list, this_campaign_name, initial_offset, item_per_screen, rows_per_screen, is_linear, is_linear);
    // Add it to the main panel of the GUI
    imGUI.getMain().setElement( @mainDiv );
	IMDivider header_divider( "header_div", DOHorizontal );
	AddTitleHeader(GetModTitle(), header_divider);
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
            SetInterlevelData("current_level", "Data/Levels/" + message.getString(0));
            this_ui.SendCallback(message.getString(0));
        }
        else if( message.name == "shift_menu" ){
            StorageSetInt32( this_campaign_name + "-shift_offset", ShiftMenu(message.getInt(0)));
            SetControllerItemBeforeShift();
            BuildUI();
            SetControllerItemAfterShift(message.getInt(0));
		}
        else if( message.name == "refresh_menu_by_name" ){
			string current_controller_item_name = GetCurrentControllerItemName();
			BuildUI();
			SetCurrentControllerItem(current_controller_item_name);
		}
		else if( message.name == "refresh_menu_by_id" ){
			int index = GetCurrentControllerItemIndex();
			BuildUI();
			SetCurrentControllerItem(index);
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
