
#include "ui_tools.as"
#include "arena_meta_persistence.as"
#include "music_load.as"
#include "lugaru_campaign.as"

AHGUI::FontSetup titleFont("edosz", 125, HexColor("#fff"));
AHGUI::FontSetup labelFont("Inconsolata", 80 , HexColor("#fff"));
AHGUI::FontSetup labelFontLightGrey("Inconsolata", 80 , HexColor("#999"));
AHGUI::FontSetup labelFontGrey("Inconsolata", 80 , HexColor("#444"));
AHGUI::FontSetup backFont("edosz", 60 , HexColor("#fff"));


int title_spacing = 150;
int menu_item_spacing = 40;

MusicLoad ml("Data/Music/lugaru_new.xml");

AHGUI::MouseOverPulseColor buttonHover(
                                        HexColor("#ffde00"),
                                        HexColor("#ffe956"), .25 );

class LugaruMenuSimpleGUI : AHGUI::GUI {
    // fancy ribbon background coordinates
    ivec2 fgUpper1Position;
    ivec2 fgUpper2Position;
    ivec2 fgLower1Position;
    ivec2 fgLower2Position;
    ivec2 bgRibbonUp1Position;
    ivec2 bgRibbonUp2Position;
    ivec2 bgRibbonDown1Position;
    ivec2 bgRibbonDown2Position;
    
    LugaruMenuSimpleGUI()
    {
        super();
        Init();
    }

    string output;

    void ParseLine(const string& in line){
        string final;
        string quot = "&quot;";
        int line_len = line.length;
        if(line.substr(0,4) == "say "){
            int index = 4;
            while(line[index] != quot[4]){
                ++index;
            }
            ++index;
            int name_start = index;
            while(line[index] != quot[0]){
                ++index;
            }
            string name = line.substr(name_start + 1, index - name_start - 1);
            index += 5;
            while(line[index] != quot[4]){
                ++index;
            }
            ++index;
            int speech_start = index;
            int speech_end = line_len - 4;
            string speech = line.substr(speech_start + 1, speech_end - speech_start - 2);
            final = name + ": " + speech;
            output += final + "\n";
        }

    }

    void ParseDialogue(const string& in dialogue) {
        string line_end = "&#x0A;";
        int combo = 0;
        int combo_len = line_end.length;
        int dialogue_len = dialogue.length;
        int line_start = 0;
        output += "Dialogue:\n";
        for(int index=0;;){
            if(index == dialogue_len){
                ParseLine(dialogue.substr(line_start, index-line_start-combo_len));
                break;
            }
            if(dialogue[index] != line_end[combo]){
                combo = 0;
            } else {
                ++combo;
                if(combo == combo_len){
                    ParseLine(dialogue.substr(line_start, index-line_start-combo_len));
                    combo = 0;
                    line_start = index+1;
                }
            }
            ++index;
        }
        output += "\n\n";
    }

    void ExtractDialogue() {
        output = "";
        string extract_str = "<parameter name=\"Script\" type=\"string\" val='";
        int extract_len = extract_str.length;
        string new_str;
        for(int level_index=0, len=lugaru_levels.size(); level_index<len; ++level_index){
            if(!LoadFile("Data/Levels/"+lugaru_levels[level_index])){
                Print("Failed to load: "+"Data/Levels/"+lugaru_levels[level_index]+"\n");
            }
            output += lugaru_levels[level_index] + ":\n\n";
            while(true){
                new_str = GetFileLine();
                if(new_str == "end"){
                    break;
                }
                for(int curr_index = 0, max_index = new_str.length - extract_len; curr_index < max_index; ++curr_index){
                    int match = -1;
                    for(int cmp_index = 0; cmp_index < extract_len; ++cmp_index){
                        match = curr_index+cmp_index+1;
                        if(new_str[curr_index+cmp_index] != extract_str[cmp_index]){
                            match = -1;
                            break;
                        }
                    }
                    if(match != -1){
                        ParseDialogue(new_str.substr(match, new_str.length - match));
                        break;
                    }
                }
            }
            output += "\n\n";
        }
        StartWriteFile();
        AddFileString(output);
        WriteFileToWriteDir("lugaru_dialogues.txt");
    }

    void Init()
    {
        PlaySong("lugaru_menu");
        
        //ExtractDialogue();

        // Initialize the extra layers (one in front, one behind)
        setBackgroundLayers(1);
        setForegroundLayers(1);

        // given that this has to fill the whole screen this is one of the few places 
        //  where you should ever have to reference the size of the screen
        fgUpper1Position =      ivec2( 0,    0 );
        fgUpper2Position =      ivec2( 2560, 0 );
        fgLower1Position =      ivec2( 0,    AHGUI::screenMetrics.GUISpaceY/2 );
        fgLower2Position =      ivec2( 2560, AHGUI::screenMetrics.GUISpaceY/2 );
        bgRibbonUp1Position =   ivec2( 0, 0 );
        bgRibbonUp2Position =   ivec2( 0, AHGUI::screenMetrics.GUISpaceY );
        bgRibbonDown1Position = ivec2( 0, 0 );
        bgRibbonDown2Position = ivec2( 0, -AHGUI::screenMetrics.GUISpaceY );

        // get references to the foreground and background containers
        AHGUI::Container@ background = getBackgroundLayer( 0 );
        AHGUI::Container@ foreground = getForegroundLayer( 0 );

        // Make a new image 
        AHGUI::Image blueBackground("Textures/ui/challenge_mode/blue_gradient_c_nocompress.tga");
        // fill the screen
        blueBackground.setSize(2560, AHGUI::screenMetrics.GUISpaceY);
        blueBackground.setColor( 1.0,1.0,1.0,0.8 );
        // Call it blueBG and give it a z value of 1 to put it furthest behind
        background.addFloatingElement( blueBackground, "blueBG", ivec2( 0, 0 ), 1 );  

        vec4 fgColor( 0.7,0.7,0.7,0.7 );

        // Make a new image for half the upper image
        AHGUI::Image fgImageUpper1("Textures/ui/challenge_mode/red_gradient_border_c.tga");
        fgImageUpper1.setSize(2560, AHGUI::screenMetrics.GUISpaceY/2);
        fgImageUpper1.setColor( fgColor );
        // use only the top half(ish) of the image
        fgImageUpper1.setImageOffset( ivec2(0,0), ivec2(1024, 600) );
        // flip it upside down 
        fgImageUpper1.setRotation( 180 );
        // Call it gradientUpper1 
        foreground.addFloatingElement( fgImageUpper1, "gradientUpper1", fgUpper1Position, 2 );

        // repeat for a second image so we can scroll unbrokenly  
        AHGUI::Image fgImageUpper2("Textures/ui/challenge_mode/red_gradient_border_c.tga");
        fgImageUpper2.setSize(2560, AHGUI::screenMetrics.GUISpaceY/2);
        fgImageUpper2.setColor( fgColor );
        fgImageUpper2.setImageOffset( ivec2(0,0), ivec2(1024, 600) );
        fgImageUpper2.setRotation( 180 );
        foreground.addFloatingElement( fgImageUpper2, "gradientUpper2", fgUpper2Position, 2 );        

        // repeat again for the bottom image(s) (not flipped this time)
        AHGUI::Image bgImageLower1("Textures/ui/challenge_mode/red_gradient_border_c.tga");
        bgImageLower1.setSize(2560, AHGUI::screenMetrics.GUISpaceY/2);
        bgImageLower1.setColor( fgColor );
        bgImageLower1.setImageOffset( ivec2(0,0), ivec2(1024, 600) );
        foreground.addFloatingElement( bgImageLower1, "gradientLower1", fgLower1Position, 2 ); 

        AHGUI::Image fgImageLower2("Textures/ui/challenge_mode/red_gradient_border_c.tga");
        fgImageLower2.setSize(2560, AHGUI::screenMetrics.GUISpaceY/2);
        fgImageLower2.setColor( fgColor );
        fgImageLower2.setImageOffset( ivec2(0,0), ivec2(1024, 600) );
        foreground.addFloatingElement( fgImageLower2, "gradientLower2", fgLower2Position, 2 );   

        AHGUI::Divider@ header = root.addDivider( DDTop, DOHorizontal, ivec2( 2560, 200 ) );
        header.setName("headerdiv");

        AHGUI::Divider@ mainpane = root.addDivider( DDTop,
                                                    DOVertical,
                                                    ivec2( 2560, 1040 ) );
        mainpane.addSpacer(title_spacing,DDTop);

        AHGUI::Text titleText = AHGUI::Text("Lugaru", titleFont);
        mainpane.addElement(titleText,DDTop);

        mainpane.addSpacer(title_spacing,DDTop);

        AHGUI::Divider@ levels = mainpane.addDivider( DDTop,
                                                    DOHorizontal,
                                                    ivec2( 0, 0 ) );

        {
            SavedLevel @level = save_file.GetSavedLevel("lugaru_campaign");
            string curr_level = level.GetValue("current_level");
            string highest_level = level.GetValue("highest_level");
            Print("curr_level: "+curr_level+"\n");
            Print("highest_level: "+highest_level+"\n");
            int highest_level_id = 0;            
            if(highest_level != ""){
                highest_level_id = atoi(highest_level);
            }
            Print("highest_level_id: "+highest_level_id+"\n");

            if(curr_level != ""){
                string temp = "Data/Levels/";
                if(temp.length < curr_level.length){
                    curr_level = curr_level.substr(temp.length, curr_level.length - temp.length);
                }
            } else {
                curr_level = lugaru_levels[0];
            }
            Print("curr_level: "+curr_level+"\n");

            int curr_level_id = 0;
            for(int i=0, len=lugaru_levels.size(); i<len; ++i) {
                if(lugaru_levels[i] == curr_level){
                    curr_level_id = i;
                }
            }
            Print("curr_level_id: "+curr_level_id+"\n");

            if(curr_level_id > highest_level_id){
                highest_level_id = curr_level_id;
                level.SetValue("highest_level", ""+highest_level_id);  
                save_file.WriteInPlace();
            }
            Print("highest_level_id: "+highest_level_id+"\n");

            bool hit_curr_level = false;
            for(int i=1, len=lugaru_levels.size()+1; i<len; ++i) {
                string label = "";
                if(i<10){
                    label = label + "0";
                }
                label = label + i;
                AHGUI::Text buttonText;
                if(i-1 == curr_level_id) {
                    buttonText = AHGUI::Text(label, labelFont);
                    buttonText.addMouseOverBehavior( buttonHover );
                    buttonText.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick(lugaru_levels[i-1]) );
                } else {
                    if(!hit_curr_level){
                        buttonText = AHGUI::Text(label, labelFontLightGrey);
                        buttonText.addMouseOverBehavior( buttonHover );
                        buttonText.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick(lugaru_levels[i-1]) );
                    } else {                  
                        buttonText = AHGUI::Text(label, labelFontGrey);      
                    }
                }
                if(i-1 == highest_level_id){
                    hit_curr_level = true;
                }
                levels.addElement(buttonText, DDTop);
                levels.addElement(AHGUI::Text(" ", labelFont), DDTop);
                if(i==10 || i==20){
                    @levels = mainpane.addDivider( DDTop,
                                                  DOHorizontal,
                                                  ivec2( 0, 0 ) );
                }
            }
        }

        AHGUI::Divider@ footer = root.addDivider( DDBottom, DOHorizontal, ivec2( 2560, 200 ) );
        footer.setName("footerdiv");

        footer.addSpacer( 175, DDLeft );
        footer.addSpacer( 175, DDRight );


        array<string> sub_names = {"backimage", "backtext"};
        AHGUI::MouseOverPulseColorSubElements buttonHoverSubElements( 
                                        HexColor("#ffde00"), 
                                        HexColor("#ffe956"), .25, sub_names );

        AHGUI::Divider@ backDivider = footer.addDivider( DDLeft, DOHorizontal, ivec2( 200, UNDEFINEDSIZEI ) );

        backDivider.addLeftMouseClickBehavior( AHGUI::FixedMessageOnClick("back") );
        backDivider.addMouseOverBehavior( buttonHoverSubElements, "mouseover" );
        backDivider.setName("backdivider");

        AHGUI::Image backImage("Textures/ui/arena_mode/left_arrow.png");
        backImage.scaleToSizeX(75);
        backImage.addUpdateBehavior( AHGUI::FadeIn( 1000, @inSine ) );
        backImage.setName("backimage");

        backDivider.addElement( backImage, DDLeft);  
        backDivider.addSpacer(30, DDLeft);

        AHGUI::Text backText( "Back", backFont );
        backText.addUpdateBehavior( AHGUI::FadeIn( 1000, @inSine ) );
        backText.setName("backtext");
        
        backDivider.addElement( backText, DDLeft );
        



    }

    void processMessage( AHGUI::Message@ message ) {
        if( message.name == "back" ) {
            this_ui.SendCallback( "back" );
        } else {
            this_ui.SendCallback( message.name );
        }
    }

    void Update() {
        // Update the background images (we could have made this into a behavior)
        // Calculate the new positions
        fgUpper1Position.x -= 2;
        fgUpper2Position.x -= 2;
        fgLower1Position.x -= 1;
        fgLower2Position.x -= 1;

        // wrap the images around
        if( fgUpper1Position.x == 0 ) {
            fgUpper2Position.x = 2560;
        }

        if( fgUpper2Position.x == 0 ) {
            fgUpper1Position.x = 2560;
        }

        if( fgLower1Position.x == 0 ) {
            fgLower2Position.x = 2560;
        }

        if( fgLower2Position.x == 0 ) {
            fgLower1Position.x = 2560;
        }

        if( bgRibbonDown1Position.y == 0 ) {
            bgRibbonDown2Position.y = -AHGUI::screenMetrics.GUISpaceY;
        }

        if( bgRibbonDown2Position.y == 0 ) {
            bgRibbonDown1Position.y = -AHGUI::screenMetrics.GUISpaceY;
        }

        // Get a reference to the first (and only) background container
        AHGUI::Container@ background = getBackgroundLayer( 0 );
        AHGUI::Container@ foreground = getForegroundLayer( 0 );

        // Update the images position in the container
        foreground.moveElement( "gradientUpper1", fgUpper1Position );
        foreground.moveElement( "gradientUpper2", fgUpper2Position );
        foreground.moveElement( "gradientLower1", fgLower1Position );
        foreground.moveElement( "gradientLower2", fgLower2Position );

        // Update the GUI 
        AHGUI::GUI::update();
    }

    void render() {
        // hud.Draw();

        AHGUI::GUI::render();
    }

}

LugaruMenuSimpleGUI lugaru_menu_simple_gui;

bool HasFocus() {
    return false;
}

void Initialize() {
}

void Dispose() {
}

bool CanGoBack() {
    return true;
}

void Update() {
    lugaru_menu_simple_gui.Update();
}

void DrawGUI() {
    lugaru_menu_simple_gui.render();
}

void Draw() {
}

void Init(string str) {
}

void StartMainMenu() {

}
