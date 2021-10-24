#include "ui_effects.as"
#include "ui_tools.as"
#include "arena_meta_persistence.as"
#include "music_load.as"

AHGUI::FontSetup labelFont("edosz", 70,HexColor("#fff"));
AHGUI::FontSetup versionFont("edosz", 65, HexColor("#fff"));

int title_spacing = 100;
int menu_item_spacing = 20;

MusicLoad ml("Data/Music/menu.xml");

AHGUI::MouseOverPulseColor buttonHover(
                                        HexColor("#ffde00"),
                                        HexColor("#ffe956"), .25 );

bool draw_settings = false;

class MainMenuGUI : AHGUI::GUI {
    RibbonBackground ribbon_background;

    MainMenuGUI()
    {
        //restrict16x9(false);

        super();

        ribbon_background.Init();

        Init();
    }

    void Init()
    {
        AHGUI::Divider@ mainpane = root.addDivider( DDTop,
                                                    DOVertical,
                                                    ivec2( UNDEFINEDSIZEI, 1140 ) );

        /*
        AHGUI::Image alphasticker = AHGUI::Image("Textures/ui/main_menu/alphasticker.png");
        alphasticker.scaleToSizeX( 350 );
        mainpane.addFloatingElement( alphasticker, "alphasticker", ivec2( 2100, 100 ));
        */

        /* 
        // TODO: Why is this making it crash on MAC?? -David
        AHGUI::Text alphaversion = AHGUI::Text( GetBuildVersionShort().split("-")[0], versionFont );
        mainpane.addFloatingElement( alphaversion, "alphaversion", ivec2( 1800, 300 ));
        */

        AHGUI::Image titleImage = AHGUI::Image("Textures/ui/main_menu/overgrowth.png");
        mainpane.addElement(titleImage,DDTop);

        mainpane.addSpacer(title_spacing,DDTop);

        {
            AHGUI::Text buttonText = AHGUI::Text("Lugaru", labelFont);
            buttonText.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick("lugaru") );
            buttonText.addMouseOverBehavior( buttonHover );
            mainpane.addElement(buttonText, DDTop);

            mainpane.addSpacer( menu_item_spacing, DDTop ) ;
        }

        {
            AHGUI::Text buttonText = AHGUI::Text("Tutorial", labelFont);
            buttonText.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick("tutorial") );
            buttonText.addMouseOverBehavior( buttonHover );
            mainpane.addElement(buttonText, DDTop);

            mainpane.addSpacer( menu_item_spacing, DDTop ) ;
        }

        {
            AHGUI::Text buttonText = AHGUI::Text("Arena", labelFont);
            buttonText.addMouseOverBehavior( buttonHover );
            buttonText.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick("arena") );
            mainpane.addElement(buttonText, DDTop);

            mainpane.addSpacer( menu_item_spacing, DDTop ) ;
        }

        {
            AHGUI::Text buttonText = AHGUI::Text("Versus", labelFont);
            buttonText.addMouseOverBehavior( buttonHover );
            buttonText.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick("versus") );
            mainpane.addElement(buttonText, DDTop);

            mainpane.addSpacer( menu_item_spacing, DDTop ) ;
        }
/*
        {
            AHGUI::Text buttonText = AHGUI::Text("Editor", labelFont);
            buttonText.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick("old_alpha_menu") );
            buttonText.addMouseOverBehavior( buttonHover );
            mainpane.addElement(buttonText, DDTop);

            mainpane.addSpacer( menu_item_spacing, DDTop ) ;
        }

        {
            AHGUI::Text buttonText = AHGUI::Text("Settings", labelFont);
            buttonText.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick("settings") );
            buttonText.addMouseOverBehavior( buttonHover );
            mainpane.addElement(buttonText, DDTop);

            mainpane.addSpacer( menu_item_spacing, DDTop ) ;
        }

        {
            AHGUI::Text buttonText = AHGUI::Text("Mods", labelFont);
            buttonText.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick("mods") );
            buttonText.addMouseOverBehavior( buttonHover );
            mainpane.addElement(buttonText, DDTop);

            mainpane.addSpacer( menu_item_spacing, DDTop ) ;
        }

        {
            AHGUI::Text buttonText = AHGUI::Text("Credits", labelFont);
            buttonText.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick("credits") );
            buttonText.addMouseOverBehavior( buttonHover );
            mainpane.addElement(buttonText, DDTop);

            mainpane.addSpacer( menu_item_spacing, DDTop ) ;
        }

        {
            AHGUI::Text buttonText = AHGUI::Text("Exit", labelFont);
            buttonText.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick("exit") );
            buttonText.addMouseOverBehavior( buttonHover );
            mainpane.addElement(buttonText, DDTop);

            mainpane.addSpacer( menu_item_spacing, DDTop ) ;
        }*/
    }

    void processMessage( AHGUI::Message@ message )
    {
        Log( info, "Got processMessage " + message.name );
        if( message.name == "arena" )
        {
            // global_data.clearSessionProfile();
            // global_data.clearArenaSession();
            // this_ui.SendCallback( "arena_meta.as" );

            global_data.clearSessionProfile();
            global_data.clearArenaSession();
            this_ui.SendCallback( "arena_simple.as" );
        }
        else if( message.name == "versus" )
        {
            this_ui.SendCallback("Project60/22_grass_beach.xml");
        }
        else if( message.name == "lugaru" )
        {
			this_ui.SendCallback( "lugaru_menu_simple.as" );
        }
		else if( message.name == "tutorial" )
        {
			this_ui.SendCallback("tutorial.xml");
        }
		else if( message.name == "credits" )
        {
			this_ui.SendCallback( "credits.as" );
        }
        else if( message.name == "mods" )
        {
            this_ui.SendCallback( "mods" );
        }
        else if( message.name == "old_alpha_menu" )
        {
            this_ui.SendCallback( "old_alpha_menu" );
        }
        else if( message.name == "exit" )
        {
            this_ui.SendCallback( "exit" );
        }
        else if( message.name == "settings" )
        {
            draw_settings = true;
        }
    }

    void update()
    {
        //Other things here, before

        AHGUI::GUI::update();
    }


    void render() {
        EnterTelemetryZone("MainMenuGUI::render()");

        EnterTelemetryZone("ribbon_background.Update()");
        ribbon_background.Update();
        LeaveTelemetryZone();

        EnterTelemetryZone("ribbon_background.DrawGUI");
        ribbon_background.DrawGUI(1.1f);
        LeaveTelemetryZone();

        EnterTelemetryZone("hud.Draw()");
        hud.Draw();
        LeaveTelemetryZone();

        EnterTelemetryZone("AHGUI::GUI::render()");
        AHGUI::GUI::render();
        LeaveTelemetryZone();

        LeaveTelemetryZone();

        if(draw_settings){
            ImGui_Begin("Settings", draw_settings);
            ImGui_DrawSettings();
            ImGui_End();
        }
    }

}

MainMenuGUI@ mainmenuGUI = @MainMenuGUI();
// Comment out the above and uncomment to enable the new feature demo
//NewFeaturesExampleGUI exampleGUI;

bool HasFocus() {
    return false;
}

void Initialize() {
    PlaySong("overgrowth_main");
}

void Dispose() {
}

bool CanGoBack() {
    return false;
}

void Update() {

    mainmenuGUI.update();
}

void DrawGUI() {
    EnterTelemetryZone("DrawGUI");
    mainmenuGUI.render();
    LeaveTelemetryZone();
}

void Draw() {
}

void Init(string str) {
}

void StartMainMenu() {

}
