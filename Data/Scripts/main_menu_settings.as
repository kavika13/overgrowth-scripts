#include "menu_common.as"
#include "music_load.as"
#include "settings.as"

MusicLoad ml("Data/Music/menu.xml");

IMGUI@ imGUI;



bool HasFocus() {
    return false;
}

void Initialize() {
    @imGUI = CreateIMGUI();
    // Start playing some music
    PlaySong("overgrowth_main");

    // Actually setup the GUI -- must do this before we do anything
    imGUI.setup();
    BuildUI("Graphics");
    setBackGround();
}

void Dispose() {
    imGUI.clear();
    SaveConfig();
}

bool CanGoBack() {
    return true;
}

void Update() {
    UpdateSettings();
    // process any messages produced from the update
    while( imGUI.getMessageQueueSize() > 0 ) {
        IMMessage@ message = imGUI.getNextMessage();
        //Log( info, "Got processMessage " + message.name );
        if( message.name == "Back" ){
            this_ui.SendCallback( "back" );
        }else{
            ProcessSettingsMessage(message);
        }
    }
    // Do the general GUI updating
    imGUI.update();
    UpdateController();
}


void Resize() {
    imGUI.doScreenResize(); // This must be called first
    setBackGround();
    
    checkCustomResolution();
    SwitchSettingsScreen(current_screen);
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