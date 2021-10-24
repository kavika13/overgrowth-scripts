#include "dialogue.as"
#include "menu_common.as"
#include "settings.as"

int controller_id = 0;
bool has_gui = false;
bool toggle_gui = false;
bool draw_settings = false;
bool has_display_text = false;
string display_text = "";
uint32 display_text_id;
string hotspot_image_string;
bool menu_paused = false;
bool allow_retry = true;
bool non_tutorial_message = false;
string tutorial_message = "";
string tutorial_message_display = "";
float tutorial_opac = 0.0;
bool tutorial_enable = false;
float reset_time = -999.0f;

array<string> dialogue_queue;

Dialogue dialogue;
IMGUI@ imGUI;

string font_path = "Data/Fonts/Lato-Regular.ttf";
string name_font_path = "Data/Fonts/edosz.ttf";

class DialogueTextCanvas {
    string text;
    int obj_id;
    int canvas_id;
};

array<DialogueTextCanvas> dialogue_text_canvases;

void SaveHistoryState(SavedChunk@ chunk) {
    dialogue.SaveHistoryState(chunk);
}

void ReadChunk(SavedChunk@ chunk) {
    dialogue.ReadChunk(chunk);
}

void DrawDialogueTextCanvas(int obj_id){
    Object @obj = ReadObjectFromID(obj_id);
    ScriptParams@ params = obj.GetScriptParams();
    if(!params.HasParam("DisplayName")){
        return;
    }
    string new_string = params.GetString("DisplayName");

    int num_canvases = int(dialogue_text_canvases.size());
    int assigned_canvas = -1;
    for(int i=0; i<num_canvases; ++i){
        if(dialogue_text_canvases[i].obj_id == obj_id){
            assigned_canvas = i;
        }
    }
    if(assigned_canvas == -1){
        dialogue_text_canvases.resize(num_canvases+1);
        dialogue_text_canvases[num_canvases].obj_id = obj_id;
        dialogue_text_canvases[num_canvases].text = "";
        dialogue_text_canvases[num_canvases].canvas_id = level.CreateTextElement();
        TextCanvasTexture @text = level.GetTextElement(dialogue_text_canvases[num_canvases].canvas_id);
        text.Create(256, 256);
        assigned_canvas = num_canvases;
    }
    DialogueTextCanvas @assigned = dialogue_text_canvases[assigned_canvas];
    TextCanvasTexture @text = level.GetTextElement(assigned.canvas_id);
    if(assigned.text != new_string){
        text.ClearTextCanvas();
        string font_str = "Data/Fonts/arial.ttf";
        TextStyle small_style;
        int font_size = 24;
        small_style.font_face_id = GetFontFaceID(font_str, font_size);
        text.SetPenColor(255,255,255,255);
        text.SetPenRotation(0.0f);
        TextMetrics metrics;
        text.GetTextMetrics(new_string, small_style, metrics, UINT32MAX);
        text.SetPenPosition(vec2(128-metrics.advance_x/64.0f*0.5f, 210));
        text.AddText(new_string, small_style,UINT32MAX);
        text.UploadTextCanvasToTexture();
        assigned.text = new_string;
    }
    text.DebugDrawBillboard(obj.GetTranslation(), obj.GetScale().x, _delete_on_update);
}

void Init(string p_level_name) {
    @imGUI = CreateIMGUI();
    dialogue.Init();
	imGUI.setup();
}

int HasCameraControl() {
    return (dialogue.HasCameraControl() || menu_paused)?1:0;
}

bool HasFocus(){
    return has_gui;
}

void CharactersNoticeEachOther() {
    int num_chars = GetNumCharacters();
    for(int i=0; i<num_chars; ++i){
         MovementObject@ char = ReadCharacter(i);
         char.ReceiveScriptMessage("set_omniscient true");
     }
}

int GetDialogueCamRotY(){
    return int(dialogue.cam_rot.y+0.5);
}

float fade_out_start;
float fade_out_end = -1.0f;

float fade_in_start;
float fade_in_end = -1.0f;


void ReceiveMessage(string msg) {
    TokenIterator token_iter;
    token_iter.Init();
    if(!token_iter.FindNextToken(msg)){
        return;
    }
    string token = token_iter.GetToken(msg);
    if(token == "cleartext"){
        has_display_text = false;
    } else if(token == "dispose_level"){
        has_gui = false;
    } else if(token == "disable_retry"){
        allow_retry = false;
    } else if(token == "go_to_main_menu"){
        LoadLevel("back_to_menu");
    } else if(token == "clearhud"){
	    hotspot_image_string.resize(0);
	} else if(token == "manual_reset"){
        level.SendMessage("reset");
    } else if(token == "reset"){
        Log(info,"Level script received \"reset\"");
        dialogue.Init();
        dialogue_queue.resize(0);
        tutorial_opac = 0.0;
        tutorial_message = "";
        tutorial_message_display = "";
        ResetLevel();
        fade_in_start = the_time;
        fade_in_end = the_time+0.4f;
        reset_time = the_time;
    } else if(token == "tutorial_enable"){
        tutorial_enable = true;
    } else if(token == "displaytext"){
        has_display_text = true;
        token_iter.FindNextToken(msg);
        display_text = token_iter.GetToken(msg);

    } else if(token == "tutorial"){
        non_tutorial_message = false;
        token_iter.FindNextToken(msg);
        string new_tutorial_message = msg.substr(9);
        if(tutorial_message != new_tutorial_message){
            tutorial_opac -= time_step;
            if(tutorial_opac <= 0.0f){
                tutorial_opac = 0.0f;
                tutorial_message = new_tutorial_message;
                AnalyzeForLineBreaks(tutorial_message, tutorial_message_display, int(GetScreenWidth() * 0.7));
            }
        } else {
            tutorial_opac = min(1.0, tutorial_opac+time_step);
        }
    }else if(token == "screen_message") {
        non_tutorial_message = true;
        token_iter.FindNextToken(msg);
        string new_tutorial_message = msg.substr(15);
        if(tutorial_message != new_tutorial_message){
            tutorial_opac -= time_step;
            if(tutorial_opac <= 0.0f){
                tutorial_opac = 0.0f;
                tutorial_message = new_tutorial_message;
                AnalyzeForLineBreaks(tutorial_message, tutorial_message_display, int(GetScreenWidth() * 0.7));
            }
        } else {
            tutorial_opac = min(1.0, tutorial_opac+time_step);
        }
    }else if(token == "displaygui"){
        /*token_iter.FindNextToken(msg);
        gui_id = gui.AddGUI("displaygui_call",token_iter.GetToken(msg),220,250,0);
        has_gui = true;*/
    } else if(token == "displayhud"){
		if(hotspot_image_string.length() == 0){
		    token_iter.FindNextToken(msg);
            hotspot_image_string = token_iter.GetToken(msg);
		}
    } else if(token == "loadlevel"){
		token_iter.FindNextToken(msg);
        Log(info,"Received loadlevel message: "+token_iter.GetToken(msg));
        LoadLevel(token_iter.GetToken(msg));
    } else if(token == "make_all_aware"){
        CharactersNoticeEachOther();
    } else if(token == "start_dialogue"){
		token_iter.FindNextToken(msg);
        dialogue_queue.push_back(token_iter.GetToken(msg));
        if(fade_out_end == -1.0f){
            dialogue.UpdatedQueue();
        }
    } else if(token == "start_dialogue_fade"){
        token_iter.FindNextToken(msg);
        dialogue_queue.push_back(token_iter.GetToken(msg));
        if(reset_time < the_time - 0.1){
            const float fade_time = 0.2f;
            fade_out_start = the_time;
            fade_out_end = the_time+fade_time;
            fade_in_start = the_time+fade_time;
            fade_in_end = the_time+fade_time*2.0f;
        } else {
            dialogue.UpdatedQueue(); // Don't fade if we are resetting            
        }
    } else if(token == "open_menu") {
		if(!has_gui){
			toggle_gui = true;
			SetPaused(true);
			menu_paused = true;
		}else{
			if(draw_settings){
				ProcessSettingsMessage(IMMessage("back"));
			}else{
				toggle_gui = true;
			}
		}
    } else {
        dialogue.ReceiveMessage(msg);
    }
}

void DrawGUI() {
    EnterTelemetryZone("level.as DrawGUI()");
    if(hotspot_image_string.length() != 0){
        HUDImage@ image = hud.AddImage();
        image.SetImageFromPath(hotspot_image_string);
        image.position = vec3(700,200,0);
    }
    EnterTelemetryZone("dialogue.Display()");
    dialogue.Display();
    LeaveTelemetryZone();
    LeaveTelemetryZone();
}


void AnalyzeForLineBreaks(string &in input, string &out output, int space){
    int font_size = dialogue.GetFontSize();
    TextMetrics metrics = GetTextAtlasMetrics(font_path, font_size, 0, input);
    float threshold = GetScreenWidth() - kTextLeftMargin - font_size - kTextRightMargin;
    string final;
    string first_line = input;
    string second_line;
    while(first_line.length() > 0){
        while(metrics.bounds_x > threshold){
            int last_space = first_line.findLastOf(" ");
            second_line.insert(0, first_line.substr(last_space));
            first_line.resize(last_space);
            metrics = GetTextAtlasMetrics(font_path, font_size, 0, first_line);
        }
        final += first_line + "\n";
        first_line = second_line.substr(1);
        second_line = "";
        metrics = GetTextAtlasMetrics(font_path, font_size, 0, first_line);
    }
    output = final.substr(0, final.length()-1);
}



void DrawGUI2() {
    EnterTelemetryZone("dialogue.Display2()");
    dialogue.Display2();
    LeaveTelemetryZone();

    if(tutorial_enable && !MediaMode()){
        if(dialogue.has_cam_control){
            tutorial_opac = 0.0;
        }
        //DebugText("tutorial_opac","tutorial_opac: "+tutorial_opac, 0.5f);
        //DebugText("tutorial_message_display", "tutorial_message_display: "+tutorial_message_display, 0.5f);
        if( tutorial_message_display != "" && tutorial_opac > 0.0f && !dialogue.has_cam_control) {
            int font_size = dialogue.GetFontSize();

            vec2 pos(GetScreenWidth() *0.5, GetScreenHeight() *0.2);
            TextMetrics metrics = GetTextAtlasMetrics(font_path, font_size, 0, tutorial_message_display);
            pos.x -= metrics.bounds_x * 0.5;
            DrawTextAtlas(font_path, font_size, 0, tutorial_message_display, 
                          int(pos.x+2), int(pos.y+2), vec4(vec3(0.0f), tutorial_opac * 0.5));
            DrawTextAtlas(font_path, font_size, 0, tutorial_message_display, 
                          int(pos.x), int(pos.y), vec4(vec3(1.0f), tutorial_opac));
        }
    }

    if( has_display_text && !MediaMode() ) {
        int font_size = dialogue.GetFontSize();
        vec2 pos(GetScreenWidth() *0.5, GetScreenHeight() *0.2);
        TextMetrics metrics = GetTextAtlasMetrics(font_path, font_size, 0, display_text);
        pos.x -= metrics.bounds_x * 0.5;
        DrawTextAtlas(font_path, font_size, 0, display_text, 
                      int(pos.x+2), int(pos.y+2), vec4(vec3(0.0f), 0.5));
        DrawTextAtlas(font_path, font_size, 0, display_text, 
                      int(pos.x), int(pos.y), vec4(vec3(1.0f), 1.0));
    }    

    if(level.WaitingForInput()){
        fade_in_start = the_time;
        fade_in_end = the_time + 0.2;
    }

    if(fade_out_end != -1.0f){        
        float blackout_amount = min(1.0, 1.0 - ((fade_out_end - the_time) / (fade_out_end - fade_out_start)));
        HUDImage @blackout_image = hud.AddImage();
        blackout_image.SetImageFromPath("Data/Textures/diffuse.tga");
        blackout_image.position.y = (GetScreenWidth() + GetScreenHeight())*-1.0f;
        blackout_image.position.x = (GetScreenWidth() + GetScreenHeight())*-1.0f;
        blackout_image.position.z = -2.0f;
        blackout_image.scale = vec3(GetScreenWidth() + GetScreenHeight())*2.0f;
        blackout_image.color = vec4(0.0f,0.0f,0.0f,blackout_amount);
        if(fade_out_end <= the_time){
            dialogue.UpdatedQueue();
            fade_out_end = -1.0f;
        }
    } else if(fade_in_end != -1.0f){        
        float blackout_amount = min(1.0, ((fade_in_end - the_time) / (fade_in_end - fade_in_start)));
        HUDImage @blackout_image = hud.AddImage();
        blackout_image.SetImageFromPath("Data/Textures/diffuse.tga");
        blackout_image.position.y = (GetScreenWidth() + GetScreenHeight())*-1.0f;
        blackout_image.position.x = (GetScreenWidth() + GetScreenHeight())*-1.0f;
        blackout_image.position.z = -2.0f;
        blackout_image.scale = vec3(GetScreenWidth() + GetScreenHeight())*2.0f;
        blackout_image.color = vec4(0.0f,0.0f,0.0f,blackout_amount);
        if(fade_in_end <= the_time){
            fade_in_end = -1.0f;
        }
    }
}

void DrawGUI3() {
    if(has_gui){
        EnterTelemetryZone("imGUI.render()");
        imGUI.render();
    }
}


void Update(int paused) {
    const bool kDialogueQueueDebug = false;
    if(kDialogueQueueDebug){
        string str;
        for(int i=0, len=dialogue_queue.size(); i<len; ++i){
            str += "\""+dialogue_queue[i] + "\" ";
        }   
	   DebugText("dialogue_queue", "Dialogue queue("+dialogue_queue.size()+"): " + str, 0.5f);
	}
    if(!has_gui && toggle_gui){
		AddPauseMenu();
		toggle_gui = false;
		has_gui = true;
	}
	else if(has_gui && toggle_gui){
		imGUI.clear();
		toggle_gui = false;
		has_gui = false;
	}
	
    if(level.HasFocus()){
        SetGrabMouse(false);
    } else {
        if(menu_paused){
            SetPaused(false);
            menu_paused = false;
        }
    }
	
	// process any messages produced from the update
    while( imGUI.getMessageQueueSize() > 0 ) {
        IMMessage@ message = imGUI.getNextMessage();
		if( message.name == "" ){return;}
        //Log( info, "Got processMessage " + message.name );
		if(draw_settings){
			if( message.name == "Back" ){
				draw_settings = false;
				category_elements.resize(0);
				AddPauseMenu();
			}else{
				ProcessSettingsMessage(message);
			}
		}
        if( message.name == "Continue" )
        {
            toggle_gui = true;
        }
        else if( message.name == "Settings" )
        {
			draw_settings = true;
			ResetController();
			BuildUI();
        }
		else if( message.name == "Retry")
		{
			toggle_gui = true;
			level.SendMessage("reset");
		}
		else if( message.name == "Main Menu")
		{
			toggle_gui = true;
			level.SendMessage("go_to_main_menu");
		}
		else if( message.name == "Media Mode")
		{
			toggle_gui = true;
			SetMediaMode(true);
		}
    }

    if( non_tutorial_message == false && tutorial_message.length() > 0 && GetConfigValueBool("tutorials") == false ) {
        level.SendMessage("tutorial");
    }

    if(paused == 0){
        if(DebugKeysEnabled() && GetInputPressed(controller_id, "l")){
            Log(info,"Reset key pressed");
            level.SendMessage("manual_reset");
        }

        if(DebugKeysEnabled() && GetInputDown(controller_id, "x")){  
            int num_items = GetNumItems();
            for(int i=0; i<num_items; i++){
                ItemObject@ item_obj = ReadItem(i);
                item_obj.CleanBlood();
            }
        }
        EnterTelemetryZone("Update dialogue");
        dialogue.Update();
        LeaveTelemetryZone();
        EnterTelemetryZone("SetAnimUpdateFreqs");
        SetAnimUpdateFreqs();
        LeaveTelemetryZone();
    }
	if(has_gui){
		UpdateSettings();
		imGUI.update();
		UpdateController();
	}
}

const float _max_anim_frames_per_second = 100.0f;

void SetAnimUpdateFreqs() {
    int num = GetNumCharacters();
    array<float> framerate_request(num);
    vec3 cam_pos = camera.GetPos();
    float total_framerate_request = 0.0f;
    for(int i=0; i<num; ++i){
        MovementObject@ char = ReadCharacter(i);
        if(char.controlled || char.QueryIntFunction("int NeedsAnimFrames()") == 0){
            continue;
        }
        float dist = distance(char.position, cam_pos);
        framerate_request[i] = 120.0f/max(2.0f,min(dist*0.5f,32.0f));
        framerate_request[i] = max(15.0f,framerate_request[i]);
        total_framerate_request += framerate_request[i];
    }
    float scale = 1.0f;
    if(total_framerate_request != 0.0f){
        scale *= _max_anim_frames_per_second/total_framerate_request;
    }
    for(int i=0; i<num; ++i)
{        MovementObject@ char = ReadCharacter(i);
        //DebugText("update_script_period"+i, i+" script period: "+char.update_script_period, 0.5);
        //DebugText("update_script_counter"+i, i+" script counter: "+char.update_script_counter, 0.5);
        //DebugText("anim_update_period"+i, i+" anim_update_period: "+char.rigged_object().anim_update_period, 0.5);
        //DebugText("curr_anim_update_time"+i, i+" curr_anim_update_time: "+char.rigged_object().curr_anim_update_time, 0.5);
        int needs_anim_frames = char.QueryIntFunction("int NeedsAnimFrames()");
        if(char.controlled || needs_anim_frames==0){
            continue;
        }
        int period = int(120.0f/(framerate_request[i]*scale));
        period = int(min(10,max(4, period)));
        if(needs_anim_frames == 2){
            period = min(period, 4);
        }
        if(char.GetIntVar("tether_id") != -1){
            char.rigged_object().SetAnimUpdatePeriod(2);
            char.SetScriptUpdatePeriod(2);
        } else {
            char.rigged_object().SetAnimUpdatePeriod(period);
            char.SetScriptUpdatePeriod(4);
        }
    }
}

int GetPlayerCharacterID() {
    int num = GetNumCharacters();
    for(int i=0; i<num; ++i){
        MovementObject@ char = ReadCharacter(i);
        if(char.controlled){
            return i;
        }
    }
    return -1;
}

void HotspotEnter(string str, MovementObject @mo) {
    if(str == "Stop"){
        level.SendMessage("reset");
    }
}

void HotspotExit(string str, MovementObject @mo) {
}

JSON getArenaSpawns() {
    JSON testValue;

    Log(info,"Starting getArenaSpawns");

    JSONValue jsonArray( JSONarrayValue );

    // Go through and record all possible spawn locations, store them by name
    dictionary spawnLocations; // All the spawn locations map from name to object id
    array<int> @allObjectIds = GetObjectIDs();
    for( uint objectIndex = 0; objectIndex < allObjectIds.length(); objectIndex++ ) {
        Object @obj = ReadObjectFromID( allObjectIds[ objectIndex ] );
        ScriptParams@ params = obj.GetScriptParams();
        if(params.HasParam("Name") && params.GetString("Name") == "arena_spawn" ) {
            if(params.HasParam("LocName") ) {
                string LocName = params.GetString("LocName");
                if( LocName != "" ) {
                    if( spawnLocations.exists( LocName ) ) {
                        DisplayError("Error", "Duplicate spawn location " + LocName );
                    }
                    else {
                        spawnLocations[ LocName ] = allObjectIds[ objectIndex ];
                        jsonArray.append( JSONValue( LocName ) );
                    }
                }
            }
        }
    }

    testValue.getRoot() = jsonArray;

    Log(info,"Done getArenaSpawns");

    return testValue;

}

void SetWindowDimensions(int w, int h)
{
    dialogue.ResizeUpdate(w,h);
	imGUI.doScreenResize();
}

void AddPauseMenu(){
	float background_height = 1200;
	float background_width = 1200;
	float header_width = 550;
	float header_height = 128;

	imGUI.clear();
    imGUI.setup();
	ResetController();
	category_elements.resize(0);
	@current_item = null;

	string ingame_menu_background = "Textures/ui/menus/main/inGameMenu-bg.png";

	IMContainer background_container(background_width, background_height);
	float middle_x = background_container.getSizeX() / 2.0f;
	float middle_y = background_container.getSizeY() / 2.0f;
	background_container.setAlignment(CACenter, CACenter);
	IMImage menu_background(ingame_menu_background);

    if(kAnimateMenu){
    	menu_background.addUpdateBehavior(IMMoveIn ( move_in_time, vec2(0, move_in_distance * -1), inQuartTween ), "");
	}

	menu_background.scaleToSizeX(450);
	menu_background.setZOrdering(0);
	menu_background.setColor(vec4(0,0,0,0.85f));
	background_container.addFloatingElement(menu_background, "menu_background", vec2(middle_x - menu_background.getSizeX() / 2.0f, middle_y - menu_background.getSizeY() / 2.0f), 0);
	
	IMDivider mainDiv( "mainDiv", DOVertical );
	background_container.setElement(mainDiv);
    mainDiv.setAlignment(CACenter, CACenter);
	
    IMDivider buttons_holder(DOVertical);
	buttons_holder.setSizeX(1200);
	buttons_holder.setBorderColor(vec4(1,0,0,1));

    IMImage header_background( brushstroke_background );
    if(kAnimateMenu){
    	header_background.addUpdateBehavior(IMMoveIn ( move_in_time, vec2(0, move_in_distance * -1), inQuartTween ), "");
    }
	header_background.scaleToSizeX(header_width);
    header_background.setColor(button_background_color);
    IMDivider header_holder("header_holder", DOHorizontal);
    IMText header_text("Game Menu", button_font);
    if(kAnimateMenu){
    	header_text.addUpdateBehavior(IMMoveIn ( move_in_time, vec2(0, move_in_distance * -1), inQuartTween ), "");
    }
	IMContainer header_container(header_background.getSizeX(), header_background.getSizeY());
    header_container.setElement(header_text);
    header_container.setAlignment(CACenter, CACenter);
    header_text.setZOrdering(3);
    header_container.setBorderColor(vec4(1,0,0,1));
    header_container.addFloatingElement(header_background, "background", vec2(0.0f, (0.0f)), 1);
    header_holder.append(header_container);
    buttons_holder.append(header_holder);

	buttons_holder.append(IMSpacer(DOVertical, 25.0f));

    buttons_holder.setAlignment(CACenter, CACenter);
    mainDiv.append(buttons_holder);
    AddButton("Continue", buttons_holder, 30, forward_chevron);
    AddButton("Retry", buttons_holder, 30, retry_icon);
    AddButton("Settings", buttons_holder, 30, settings_icon);
	if(EditorEnabled()){
		AddButton("Media Mode", buttons_holder, 30, media_icon);
	}
    AddButton("Main Menu", buttons_holder, 30, exit_icon);
	
	buttons_holder.append(IMSpacer(DOVertical, 100.0f));
	imGUI.getMain().setElement(@background_container);
	controller_wraparound = true;
}

bool DialogueCameraControl() {
    return dialogue.has_cam_control;
}
