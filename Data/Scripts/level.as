#include "ui_effects.as"
#include "dialogue.as"

int controller_id = 0;
bool has_gui = false;
bool draw_settings = false;
bool has_display_text = false;
string display_text = "";
uint32 display_text_id;
string hotspot_image_string;
bool menu_paused = false;
bool allow_retry = true;
int hotspot_message_text_id = -1;

Dialogue dialogue;

class DialogueTextCanvas {
    string text;
    int obj_id;
    int canvas_id;
};

array<DialogueTextCanvas> dialogue_text_canvases;
array<int> number_text_canvases;

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
    dialogue.Init();

    int num_number_canvases = 9;
    number_text_canvases.resize(num_number_canvases);
    for(int i=0; i<num_number_canvases; ++i){
        number_text_canvases[i] = level.CreateTextElement();
        TextCanvasTexture @text = level.GetTextElement(number_text_canvases[i]);
        text.Create(32, 32);
        text.ClearTextCanvas();
        string font_str = "Data/Fonts/arial.ttf";
        TextStyle small_style;
        int font_size = 24;
        small_style.font_face_id = GetFontFaceID(font_str, font_size);
        text.SetPenColor(255,255,255,255);
        text.SetPenRotation(0.0f);
        TextMetrics metrics;
        string new_string = ""+(i+1);
        text.GetTextMetrics(new_string, small_style, metrics, UINT32MAX);
        text.SetPenPosition(vec2(16-metrics.advance_x/64.0f*0.5f, 24));
        text.AddText(new_string, small_style,UINT32MAX);
        text.UploadTextCanvasToTexture();
    }

    if( hotspot_message_text_id == -1 ) {
        hotspot_message_text_id = level.CreateTextElement();
        TextCanvasTexture @text = level.GetTextElement(hotspot_message_text_id);
        text.Create(GetScreenWidth()-(GetScreenWidth()/16)*2, 200);
    }
}

int HasCameraControl() {
    return dialogue.HasCameraControl()?1:0;
}
/*
void GUIDeleted(uint32 id){
    if(id == gui_id){
        has_gui = false;
    }
}
*/
bool HasFocus(){
    return has_gui;
}

void CharactersNoticeEachOther() {
    int num_chars = GetNumCharacters();
    for(int i=0; i<num_chars; ++i){
         MovementObject@ char = ReadCharacter(i);
         char.ReceiveMessage("set_omniscient true");
         for(int j=i+1; j<num_chars; ++j){
             MovementObject@ char2 = ReadCharacter(j);
             //Print("Telling characters " + char.GetID() + " and " + char2.GetID() + " to notice each other.\n");
             char.ReceiveMessage("notice " + char2.GetID());
             char2.ReceiveMessage("notice " + char.GetID());
         }
     }
}

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
        LoadLevel("back");
    } else if(token == "clearhud"){
	    hotspot_image_string.resize(0);
	} else if(token == "manual_reset"){
        level.SendMessage("reset");
    } else if(token == "reset"){
        dialogue.Init();
        ResetLevel();
    } else if(token == "displaytext"){
        //if(has_display_text){
        //    gui.RemoveGUI(display_hotspot_message_text_id);
        //}
        //display_hotspot_message_text_id = gui.AddGUI("text2","script_text.html",400,200, _GG_IGNORES_MOUSE);
        //token_iter.FindNextToken(msg);
        //gui.Execute(display_hotspot_message_text_id,"SetText(\""+token_iter.GetToken(msg)+"\")");
        
        has_display_text = true;
        token_iter.FindNextToken(msg);
        display_text = token_iter.GetToken(msg);

    }else if(token == "displayvideo"){
		//token_iter.FindNextToken(msg);
		//DebugText("awe", "" + msg, _fade);
        //gui_id = gui.AddGUI("video",token_iter.GetToken(msg),GetScreenWidth() - 200,GetScreenHeight() - 200,0);
        Log( error, "No Support for display video" );
    } else if(token == "removevideo"){
		//gui.RemoveGUI(gui_id);
        Log( error, "No Support for remove video" );
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
        Print("Received loadlevel message: "+token_iter.GetToken(msg)+"\n");
        LoadLevel(token_iter.GetToken(msg));
    } else if(token == "make_all_aware"){
        CharactersNoticeEachOther();
    } else if(token == "start_dialogue"){
		token_iter.FindNextToken(msg);
        dialogue.StartDialogue(token_iter.GetToken(msg));
    } else if(token == "open_menu") {
        if(!level.HasFocus()){
            /*if(EditorEnabled()){
                gui_id = gui.AddGUI("gamemenu","dialogs\\editorgamemenu.html",220,290,0);
            } else {
                if(allow_retry){
                    gui_id = gui.AddGUI("gamemenu","dialogs\\gamemenu.html",220,260,0);                    
                } else {
                    gui_id = gui.AddGUI("gamemenu","dialogs\\arenagamemenu.html",220,230,0);                     
                }
            }*/
            SetPaused(true);
            menu_paused = true;
            has_gui = true;
        }
    } else {
        dialogue.ReceiveMessage(msg);
    }
}

void DrawGUI() {
    if(has_gui){
        ImGui_Begin("Menu");
        if(ImGui_Button("Continue")){
            has_gui = false;
        }
        if(allow_retry){
            if(ImGui_Button("Reset Level")){
                has_gui = false;
                level.SendMessage("reset");
            }
        }
        if(ImGui_Button("Settings")){
            draw_settings = true;
        }
        if(EditorEnabled()){
            if(ImGui_Button("Media Mode")){
                SetMediaMode(true);
                has_gui = false;
            }
        }
        if(ImGui_Button("Main Menu")){
            level.SendMessage("go_to_main_menu");
        }
        ImGui_End();
        if(draw_settings){
            ImGui_Begin("Settings", draw_settings);
            ImGui_DrawSettings();
            ImGui_End();
        }
    } else {
        draw_settings = false;
    }
    if(hotspot_image_string.length() != 0){
        HUDImage@ image = hud.AddImage();
        image.SetImageFromPath(hotspot_image_string);
        image.position = vec3(700,200,0);
    }
    dialogue.Display();

    /************************************/
    if( has_display_text ) {
        HUDImage @blackout_image = hud.AddImage();
        blackout_image.SetImageFromPath("Data/Textures/diffuse_hud.tga");
        blackout_image.position.y = GetScreenHeight()/2.0f-GetScreenHeight()/4.0f/2.0f;
        blackout_image.position.x = 0.0f;
        blackout_image.position.z = -2.0f;
        blackout_image.scale = vec3(GetScreenWidth()/16.0f, GetScreenHeight()/16.0f/4.0f, 1.0f);
        blackout_image.color = vec4(0.0f,0.0f,0.0f,0.4f);

        int font_size = int(max(18, min(GetScreenHeight() / 30, GetScreenWidth() / 50)));
    
        TextCanvasTexture @text = level.GetTextElement(hotspot_message_text_id);
        text.ClearTextCanvas();
        string font_str = "Data/Fonts/arial.ttf";
        TextStyle small_style;
        small_style.SetAlignment(1);
        small_style.font_face_id = GetFontFaceID(font_str, font_size);

        // Draw speaker name to canvas
        vec2 pen_pos = vec2(0,font_size);
        text.SetPenPosition(pen_pos);
        text.SetPenColor(255,255,255,160);
        text.SetPenRotation(0.0f);
    
        // Draw dialogue text to canvas
        text.SetPenColor(255,255,255,255);
        text.SetPenPosition(pen_pos);

        //uint len_in_bytes = GetLengthInBytesForNCodepoints(dialogue_text,uint(dialogue_text_disp_chars));
        //string display_dialogue_text = dialogue_text.substr(0,int(len_in_bytes));
        
        text.AddTextMultiline(display_text, small_style, UINT32MAX);

        // Draw text canvas to screen
        text.UploadTextCanvasToTexture();

       // TextMetrics metrics;

       // text.GetTextMetrics(display_text, small_style, metrics, UINT32MAX);

        HUDImage @text_image = hud.AddImage();
        text_image.SetImageFromText(level.GetTextElement(hotspot_message_text_id)); 
        text_image.position.x = GetScreenWidth()/16;//GetScreenWidth()/2.0f - (display_text.length()/2.0f)*8.0f;
        text_image.position.y = GetScreenHeight()/2.0f-100;
        text_image.position.z = 4;
        text_image.color = vec4(1,1,1,1);

    }
    /**********************************/
}

void Update(int paused) {  

    if(level.HasFocus()){
        SetGrabMouse(false);
    } else {
        if(menu_paused){
            SetPaused(false);
            menu_paused = false;
        }
    }

    /*SetSunColor(vec3(sin(the_time*1.35)*0.5f+0.5f, sin(the_time*1.15)*0.5f+0.5f, sin(the_time*1.75)*0.5f+0.5f)*3.0f);
    SetSunPosition(vec3(sin(the_time), 1.0, cos(the_time)));
    SetSunAmbient((sin(the_time*1.25)*0.5f+0.5f) * 3.0);
    SetFlareDiffuse((1.0f - (sin(the_time*1.25)*0.5f+0.5f)) * 5.0);
    SetSkyTint(vec3(sin(the_time*1.3)*0.5f+0.5f, sin(the_time*1.1)*0.5f+0.5f, sin(the_time*1.7)*0.5f+0.5f)*3.0f);
    */
    /*
    SetSunColor(vec3(0.0f));
    SetSkyTint(vec3(0.0f));
    SetSunAmbient(3.0);*/

    if(paused == 0){
        if(DebugKeysEnabled() && GetInputPressed(controller_id, "l")){
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

    Print("Starting getArenaSpawns\n");

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

    Print("Done getArenaSpawns\n");

    return testValue;

}

void SetWindowDimensions(int w, int h)
{
    dialogue.ResizeUpdate(w,h);
    TextCanvasTexture @text = level.GetTextElement(hotspot_message_text_id);
    text.Create(w-(w/16)*2, 200);
}
