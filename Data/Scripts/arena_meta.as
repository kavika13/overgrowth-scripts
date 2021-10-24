#include "ui_effects.as"
#include "arena_meta_persistence.as"

enum GUIState {
    kSelection,
    kConfirmation
};

GUIState gui_state;

class ArenaMeta {
    int gui_id;
    RibbonBackground ribbon_background;
    float visible;
    float target_visible;
    IMUIContext imui_context;

    void Initialize(){
        gui_id = -1;
        visible = 0.0f;
        target_visible = 1.0f;
        ribbon_background.Init();
        imui_context.Init();
    }

    void Update(){
        visible = UpdateVisible(visible, target_visible);
        
        if(gui_state == kSelection && GetInputPressed(0,'esc')){
            this_ui.SendCallback("back");
        }

        ribbon_background.Update();
    }

    bool Button(int i, string str, bool enable) {
    
        int column = i/12;
        int row = i%12;
        UIState state;
        
        bool button_pressed = false;

        if( enable ) {
            button_pressed = imui_context.DoButton(i, 
                vec2(GetScreenWidth()*0.5 - 130  + column * 200, GetScreenHeight()*0.5 + 73 - 40*row),
                vec2(GetScreenWidth()*0.5 - 130  + column * 200 + 300, GetScreenHeight()*0.5 + 73 + 35 - 40*row),
                state);
        }
        
        vec4 color(1.0f);
        
        if( enable ) {

            switch(state) {
                case kHot:
                    color.a = 0.9;
                    break;
                case kActive:
                    color.a = 1.0;
                    break;
                default:
                    color.a = 0.8;
                    break;
            }
        }
        else {
            color.a = 0.2;
        }

        hud.Draw();
        color.x = 0.5;
        color.z = 0.5;
        DrawTextAtlas("Data/Fonts/OpenSans-Regular.ttf", 32, kSmallLowercase, str, 
                      int(GetScreenWidth() * 0.5 - 130 + column * 200), 
                      int(GetScreenHeight() * 0.5 - 73 + 40 * row), 
                      color);
        return button_pressed;
    }

    void DrawConfirmation() {
        hud.Draw();

        DrawTextAtlas("Data/Fonts/OpenSans-Regular.ttf", 18, kSmallLowercase, "Arena Mode (v1.5)", 
                      int(GetScreenWidth() * 0.5 - 300), int(GetScreenHeight() * 0.5 - 238), vec4(vec3(1.0f), 0.7f));
        
        DrawTextAtlas("Data/Fonts/OpenSans-Regular.ttf", 24, kSmallLowercase, "Are you sure you want to erase current progress?", 
                      int(GetScreenWidth() * 0.5 - 200), int(GetScreenHeight() * 0.5 - 173), vec4(vec3(1.0f, 0.2f, 0.2f), 0.9f));

        if(Button(0, "Yes", true)) {
            global_data.Reset();
            StartArena();
        }

        if( Button(1, "Cancel", true)){
            gui_state = kSelection;
        }

        
    }

    void DrawSelection() {
        
        hud.Draw();

        DrawTextAtlas("Data/Fonts/OpenSans-Regular.ttf", 18, kSmallLowercase, "Arena Mode (v1.5)", 
                      int(GetScreenWidth() * 0.5 - 300), int(GetScreenHeight() * 0.5 - 238), vec4(vec3(1.0f), 0.7f));
        
        if(Button(0, "New Campaign", true)) {
        
            if( !global_data.campaign_started ) {
                StartArena();
            }
            else {
                gui_state = kConfirmation;
            }
        
        }

        if( Button(1, "Continue Campaign", global_data.campaign_started)){
            StartArena();
        }

        if( global_data.campaign_started ) {

            DrawTextAtlas("Data/Fonts/OpenSans-Regular.ttf", 28, kSmallLowercase, "Fan Base: " + global_data.fan_base, 
                      int(GetScreenWidth() * 0.5 - 130), int(GetScreenHeight() * 0.5 + 65), vec4(0.0, 0.7, 0.7, 0.7f));

            DrawTextAtlas("Data/Fonts/OpenSans-Regular.ttf", 28, kSmallLowercase, "Player Skill: " + global_data.player_skill, 
                      int(GetScreenWidth() * 0.5 - 130), int(GetScreenHeight() * 0.5 + 95), vec4(0.0, 0.7, 0.7, 0.7f));

        }

        UIState state;
        if( imui_context.DoButton(2, 
                 vec2(int(GetScreenWidth() * 0.5 - 300),  50 ),
                 vec2(int(GetScreenWidth() * 0.5 - 200 ), 70 ),
                 state) )
        {
            this_ui.SendCallback("back");
        }

        vec4 color(1.0f);
        
        switch(state) {
            case kHot:
                color.a = 0.9;
                break;
            case kActive:
                color.a = 1.0;
                break;
            default:
                color.a = 0.8;
                break;
        }
        

        DrawTextAtlas("Data/Fonts/OpenSans-Regular.ttf", 24, kSmallLowercase, "Main Menu", 
                      int(GetScreenWidth() * 0.5 - 300), 
                  int(GetScreenHeight() - 50), 
                      color);

        hud.Draw();

    }

    void StartArena() {
        global_data.campaign_started = true;
        global_data.WritePersistentInfo();

        // array<string> arenaNames = {"cage_arena.xml", "Cave_Arena.xml", "courtyard_cage_arena.xml", 
        //                             "crevice_arena.xml", "great_wall_arena.xml", "Magma_Arena.xml", 
        //                             "mountainside_crater.xml", "multirena_dev_copy.xml", "risingwater_arena.xml", 
        //                             "subterranean_arena.xml", "tower_summit_arena.xml", "waterfall_arena_v2.xml", 
        //                             "waterfall_arena.xml"};
        
        //array<string> arenaNames = {"Cave_Arena.xml", "stucco_courtyard_arena.xml", "waterfall_arena.xml", "Magma_Arena.xml"};

        array<string> arenaNames = {"Cave_Arena.xml", "waterfall_arena.xml", "Magma_Arena.xml"};

        //array<string> arenaNames = {"Cave_Arena.xml", "Magma_Arena.xml"};
        
        uint arenaChoice = rand()%arenaNames.length();                                  

        string nextArena = arenaNames[ arenaChoice ];

        // Write to the session that we're in an arena series
        JSONValue arenaSession = global_data.getSessionParameters();        
        arenaSession["arena_series"] = JSONValue("true");
        global_data.setSessionParameters( arenaSession );

        // Tell the energy to load switch to this level
        this_ui.SendCallback("arenas/" + nextArena );

    }

    void DrawGUI() {

        imui_context.UpdateControls();
        ribbon_background.DrawGUI(visible);
        
        switch(gui_state) {

            case kConfirmation:
                DrawConfirmation();
                break;
            case kSelection:
            default:
                DrawSelection();
            break;
        }

    }

}

ArenaMeta arena_meta;

bool HasFocus(){
    return false;
}

void Initialize(){
    arena_meta.Initialize();
}

void Update(){
    arena_meta.Update();
}

void DrawGUI(){
    arena_meta.DrawGUI();
}

void Draw(){
}

void Init(string str){
}

void StartArenaMeta(){
    global_data.ReadPersistentInfo();
    gui_state = kSelection;
}


