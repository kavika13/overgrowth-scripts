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

        DrawTextAtlas("Data/Fonts/OpenSans-Regular.ttf", 36, kSmallLowercase, "Arena Mode (v1)", 
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

        DrawTextAtlas("Data/Fonts/OpenSans-Regular.ttf", 36, kSmallLowercase, "Arena Mode (v1)", 
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
        this_ui.SendCallback("arenas/multirena_dev_copy.xml");
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


