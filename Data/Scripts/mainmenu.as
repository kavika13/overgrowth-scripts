#include "music_load.as"
#include "menu_common.as"
#include "campaign_common.as"

MusicLoad ml("Data/Music/menu.xml");

IMGUI@ imGUI;

bool HasFocus() {
    return false;
}

void Initialize() {
    @imGUI = CreateIMGUI();
    // Start playing some music
    PlaySong("overgrowth_main");

    // We're going to want a 100 'gui space' pixel header/footer
    imGUI.setFooterHeight(200);

    // Actually setup the GUI -- must do this before we do anything
    imGUI.setup();
    BuildUI();
	if(GetInterlevelData("background") == ""){
		SetInterlevelData("background", GetRandomBackground());
	}
	setBackGround();
	AddVerticalBar();
	controller_wraparound = true;
}

void BuildUI(){
    IMDivider mainDiv( "mainDiv", DOHorizontal );
    mainDiv.append(IMSpacer(DOHorizontal, 200));
    mainDiv.setAlignment(CARight, CATop);

    IMDivider left_panel("left_panel", DOVertical);
    left_panel.setAlignment(CALeft, CACenter);
    mainDiv.append(left_panel);

    IMImage logo("Textures/ui/menus/main/overgrowth.png");
    IMDivider logo_holder(DOVertical);
    IMDivider logo_holder_holder(DOHorizontal);
    logo_holder_holder.setSize(vec2(UNDEFINEDSIZE,UNDEFINEDSIZE));
    logo_holder.append(IMSpacer(DOVertical, 50));
    logo_holder.append(logo);
    logo_holder_holder.append(logo_holder);
    left_panel.append(logo_holder);

    left_panel.append(IMSpacer(DOVertical, 100));
    IMDivider horizontal_buttons_holder(DOHorizontal);
    horizontal_buttons_holder.append(IMSpacer(DOHorizontal, 75));
    IMDivider buttons_holder(DOVertical);
    buttons_holder.append(IMSpacer(DOHorizontal, 200));
    buttons_holder.setAlignment(CACenter, CACenter);
    horizontal_buttons_holder.append(buttons_holder);
    left_panel.append(horizontal_buttons_holder);

    string last_campaign_id = GetGlobalSave().GetValue("last_campaign_played");
    Campaign camp = GetCampaign(last_campaign_id);  
    if(camp.GetLevels().size() > 0 ) {
        AddButton("Continue", buttons_holder, forward_chevron);
    }

    AddButton("Play", buttons_holder, play_icon);
    AddButton("Settings", buttons_holder, settings_icon);
    AddButton("Mods",     buttons_holder, mods_icon);
    AddButton("Exit",     buttons_holder, exit_icon);

    // Align the contained element to the left
    imGUI.getMain().setAlignment( CALeft, CATop );

    // Add it to the main panel of the GUI
    imGUI.getMain().setElement( @mainDiv );
}

void Dispose() {
    imGUI.clear();
}

bool CanGoBack() {
    return true;
}

void Update() {
    // process any messages produced from the update
    while( imGUI.getMessageQueueSize() > 0 ) {
        IMMessage@ message = imGUI.getNextMessage();

		if( message.name == "run_file" )
        {
            this_ui.SendCallback(message.getString(0));
        }
        else if( message.name == "Editor" )
        {
            LoadEditorLevel();
        }
        else if( message.name == "Credits" )
        {
            this_ui.SendCallback( "credits.as" );
        }
        else if( message.name == "Mods" )
        {
            this_ui.SendCallback( "mods" );
        }
        else if( message.name == "Play" ) 
        {
            this_ui.SendCallback( "play_menu.as" );
        }
        else if( message.name == "Continue" )
        {
            string campaign_id = GetGlobalSave().GetValue("last_campaign_played");
            string level_id = GetGlobalSave().GetValue("last_level_played");

            SetCampaignID(campaign_id);
            LoadLevelID(level_id);
        }
        else if( message.name == "Exit" )
        {
            this_ui.SendCallback( "exit" );
        }
        else if( message.name == "Settings" )
        {
			this_ui.SendCallback( "main_menu_settings.as" );
        }
        else if( message.name == "Credits" ) 
        {
            this_ui.SendCallback( "credits.as" );
        }
        else if( message.name == "News" ) 
        {
            Log( info, "Placeholder for news button" );
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
