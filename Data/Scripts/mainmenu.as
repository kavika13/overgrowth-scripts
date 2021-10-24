#include "ui_effects.as"
#include "ui_tools.as"
#include "arena_meta_persistence.as"

AHGUI::FontSetup labelFont("edosz", 100,HexColor("#fff"));
AHGUI::FontSetup versionFont("edosz", 65, HexColor("#fff"));

int title_spacing = 150;
int menu_item_spacing = 40;

AHGUI::MouseOverPulseColor buttonHover(
                                        HexColor("#ffde00"),
                                        HexColor("#ffe956"), .25 );

class MainMenuGUI : AHGUI::GUI {
    RibbonBackground ribbon_background;

    MainMenuGUI()
    {
        super();

        ribbon_background.Init();

        Init();
    }

    void Init()
    {
        AHGUI::Divider@ mainpane = root.addDivider( DDTop,
                                                    DOVertical,
                                                    ivec2( UNDEFINEDSIZE, 1140 ) );

        /*
        AHGUI::Image alphasticker = AHGUI::Image("Textures/ui/main_menu/alphasticker.png");
        alphasticker.scaleToSizeX( 350 );
        mainpane.addFloatingElement( alphasticker, "alphasticker", ivec2( 2100, 100 ));
        */

        AHGUI::Text alphaversion = AHGUI::Text( GetBuildVersionShort().split("-")[0], versionFont );
        mainpane.addFloatingElement( alphaversion, "alphaversion", ivec2( 1800, 300 ));

        AHGUI::Image titleImage = AHGUI::Image("Textures/ui/main_menu/overgrowth.png");
        mainpane.addElement(titleImage,DDTop);

        mainpane.addSpacer(title_spacing,DDTop);

        {
            AHGUI::Text buttonText = AHGUI::Text("Arena Mode", labelFont);
            buttonText.addMouseOverBehavior( buttonHover );
            buttonText.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick("arena") );
            mainpane.addElement(buttonText, DDTop);

            mainpane.addSpacer( menu_item_spacing, DDTop ) ;
        }

        {
            AHGUI::Text buttonText = AHGUI::Text("Editor", labelFont);
            buttonText.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick("old_alpha_menu") );
            buttonText.addMouseOverBehavior( buttonHover );
            mainpane.addElement(buttonText, DDTop);

            mainpane.addSpacer( menu_item_spacing, DDTop ) ;
        }

		/*
        {
            AHGUI::Text buttonText = AHGUI::Text("Lugaru", labelFont);
            buttonText.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick("lugaru") );
            buttonText.addMouseOverBehavior( buttonHover );
            mainpane.addElement(buttonText, DDTop);

            mainpane.addSpacer( menu_item_spacing, DDTop ) ;
        }
		*/

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
        }
    }

    void processMessage( AHGUI::Message@ message )
    {
        Log( info, "Got processMessage " + message.name );
        if( message.name == "arena" )
        {
            global_data.clearSessionProfile();
            global_data.clearArenaSession();
            this_ui.SendCallback( "arena_meta.as" );
        }
        else if( message.name == "lugaru" )
        {
			this_ui.SendCallback( "lugaru_menu.as" );
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
            this_ui.SendCallback( "back" );
        }
        else if( message.name == "settings" )
        {
            OpenSettings(context);
        }
    }

    void update()
    {
        //Other things here, before

        AHGUI::GUI::update();
    }

    void render() {
        ribbon_background.Update();
        ribbon_background.DrawGUI(1.1f);
        hud.Draw();

        AHGUI::GUI::render();
    }

}

MainMenuGUI mainmenuGUI;
// Comment out the above and uncomment to enable the new feature demo
//NewFeaturesExampleGUI exampleGUI;

bool HasFocus() {
    return false;
}

void Initialize() {

}

void Dispose() {
    CloseSettings();
}

bool CanGoBack() {
    return not CloseSettings();
}

void Update() {
    mainmenuGUI.update();
}

void DrawGUI() {
    mainmenuGUI.render();
}

void Draw() {
}

void Init(string str) {
}

void StartMainMenu() {

}
