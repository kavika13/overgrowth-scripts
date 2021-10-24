#include "menu_common.as"
#include "music_load.as"

MusicLoad ml("Data/Music/lugaru_new.xml");

IMGUI imGUI;
array<LevelInfo@> custom_levels;
LevelSearch search;

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
	
	ResetLevelList();

    IMDivider mainDiv( "mainDiv", DOHorizontal );
    mainDiv.setAlignment(CACenter, CACenter);
	CreateMenu(mainDiv, custom_levels, "custom_levels", 0, 4, 3, false, false);
    // Add it to the main panel of the GUI
    imGUI.getMain().setElement( @mainDiv );
	
	AddCustomLevelsHeader();
	search.SetCollection(custom_levels);
	
    AddBackButton();
	
	setBackGround();
}

void ResetLevelList(){
	custom_levels.resize(0);
	array<ModID>@ active_sids = GetActiveModSids();
	Print("There are " + active_sids.size() + " mods active\n");
    for( uint i = 0; i < active_sids.length(); i++ ) {
        array<ModLevel>@ menu_items = ModGetSingleLevels(active_sids[i]); 
        for( uint k = 0; k < menu_items.length(); k++ ) {
			custom_levels.insertLast(LevelInfo(menu_items[k].GetPath(), menu_items[k].GetTitle(), menu_items[k].GetThumbnail()));
        }
    }
}

void AddCustomLevelsHeader(){
	IMContainer header_container(2560, 200);
	IMDivider header_divider( "header_div", DOHorizontal );
	header_container.setElement(header_divider);
	//header_container.setAlignment(CACenter, CACenter);
	
	AddTitleHeader("Custom Levels", header_divider);
	AddSearchbar(header_divider, @search);
	imGUI.getHeader().setElement(header_divider);
}

void Dispose() {
	imGUI.clear();
}

bool CanGoBack() {
    return true;
}

void Update() {

	if(!search.active){
		UpdateController();
	}
	search.Update();
	UpdateKeyboardMouse();
    // process any messages produced from the update
    while( imGUI.getMessageQueueSize() > 0 ) {
        IMMessage@ message = imGUI.getNextMessage();

        //Log( info, "Got processMessage " + message.name );

        if( message.name == "Back" )
        {
            this_ui.SendCallback( "back" );
        }
        else if( message.name == "load_level" )
        {
            this_ui.SendCallback( "Data/Levels/" + message.getString(0) );
        }
		else if( message.name == "shift_menu" ){
			ClearControllerItems();
			ShiftMenu(message.getInt(0));
			AddCustomLevelsHeader();
			AddBackButton();
			search.ShowSearchResults();
		}
		else if( message.name == "run_file" ) 
        {
            this_ui.SendCallback(message.getString(0));
        }
		else if( message.name == "refresh_menu_by_name" ){
			string current_controller_item_name = GetCurrentControllerItemName();
			ClearControllerItems();
			IMDivider mainDiv( "mainDiv", DOHorizontal );
			CreateMenu(mainDiv, custom_levels, "custom_levels", 0);
			imGUI.getMain().setElement(mainDiv);
			AddCustomLevelsHeader();
		    AddBackButton();
			SetCurrentControllerItem(current_controller_item_name);
			search.ShowSearchResults();
		}
		else if( message.name == "refresh_menu_by_id" ){
			int index = GetCurrentControllerItemIndex();
			ClearControllerItems();
			IMDivider mainDiv( "mainDiv", DOHorizontal );
			CreateMenu(mainDiv, custom_levels, "custom_levels", 0);
			imGUI.getMain().setElement(mainDiv);
			AddCustomLevelsHeader();
		    AddBackButton();
			SetCurrentControllerItem(index);
			search.ShowSearchResults();
		}
		else if( message.name == "activate_search" ){
			search.Activate();
		}
		else if( message.name == "clear_search_results" ){
			ClearControllerItems();
			ResetLevelList();
			search.ResetSearch();
			imGUI.receiveMessage( IMMessage("refresh_menu_by_id") );
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

class LevelSearch : Search{
	array<LevelInfo@>@ collection;
	LevelSearch(){
		
	}
	void SetCollection(array<LevelInfo@>@ _collection){
		@collection = @_collection;
	}
	void GetSearchResults(string query){
		collection.resize(0);
		array<ModID>@ active_sids = GetActiveModSids();
	    for( uint i = 0; i < active_sids.length(); i++ ) {
	        array<ModLevel>@ menu_items = ModGetSingleLevels(active_sids[i]); 
	        for( uint k = 0; k < menu_items.length(); k++ ) {
				if(ToLowerCase(menu_items[k].GetTitle()).findFirst(query) != -1){
					//Print("Adding " + menu_items[k].GetPath() + "\n");
					collection.insertLast(LevelInfo(menu_items[k].GetPath(), menu_items[k].GetTitle(), menu_items[k].GetThumbnail()));
					continue;
				}
	        }
	    }
	}
}
