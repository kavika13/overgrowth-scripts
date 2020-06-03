#include "ui_effects.as"

int controller_id = 0;
bool has_gui = false;
uint32 gui_id;
bool has_display_text = false;
uint32 display_text_id;
string hotspot_image_string;

class Dialogue {
    array<string> strings;
    int index;
    int text_id;
    bool has_cam_control;
    bool show_dialogue;
    string dialogue_text;
    string dialogue_name;
    vec3 cam_pos;
    vec3 cam_rot;
    float cam_dist;
    bool show_editor_info;

    void Init() {
        index = 0;
        Print("Initializing dialogue\n");
        text_id = level.CreateTextElement();
        TextCanvasTexture @text = level.GetTextElement(text_id);
        text.Create(GetScreenWidth(), 200);
        has_cam_control = false;
        show_dialogue = false;
        show_editor_info = false;
        
        strings.push_back("send_character_message 1 \"set_dialogue_control true\"");
        strings.push_back("send_character_message 1 \"set_head_target -46.2863 27.8954 63.8843 1.0\"");
        strings.push_back("set_character_pos 1 -44.0831 26.6523 58.5592");
        strings.push_back("set_cam_control true");
        strings.push_back("set_cam_distance 0");
        strings.push_back("set_cam_pos -43.3936 27.2684 58.8805");
        strings.push_back("set_cam_rot 7.5 -296 0");
        strings.push_back("set_dialogue_visible true");
        strings.push_back("set_dialogue_name \"Chris\"");
        strings.push_back("set_dialogue_text \"Hello there! How can I help you?\"");
        strings.push_back("wait_for_click");

        strings.push_back("set_cam_pos -44.8893 27.7884 58.2774");
        strings.push_back("set_cam_rot -14.5 -488.5 0");
        strings.push_back("set_dialogue_text \"Oh, my mistake -- I guess I'm talking to myself.\"");
        strings.push_back("wait_for_click");

        strings.push_back("send_character_message 1 \"set_dialogue_control false\"");
        strings.push_back("set_cam_control false");
        strings.push_back("set_dialogue_visible false");
    }

    void Process() {
        bool stop = false;
        while(!stop){
            if(index < int(strings.size())){
                stop = ProcessString(strings[index]);
                ++index;
            } else {
                stop = true;
                index = 0;
            }
        }
    }

    void Update() {
        if(has_cam_control){
            camera.SetXRotation(cam_rot.x);
            camera.SetYRotation(cam_rot.y);
            camera.SetZRotation(cam_rot.z);
            camera.SetPos(cam_pos);
            camera.SetDistance(cam_dist);
        }
    }

    bool ProcessString(const string &in msg) {        
        TokenIterator token_iter;
        token_iter.Init();
        if(!token_iter.FindNextToken(msg)){
            return false;
        }
        string token = token_iter.GetToken(msg);
        if(token == "set_cam_control"){
            token_iter.FindNextToken(msg);
            token = token_iter.GetToken(msg);
            if(token == "true"){
                has_cam_control = true;
            } else if(token == "false"){
                has_cam_control = false;
            }
        } else if(token == "set_cam_pos"){
            token_iter.FindNextToken(msg);
            token = token_iter.GetToken(msg);
            cam_pos.x = atof(token);
            token_iter.FindNextToken(msg);
            token = token_iter.GetToken(msg);
            cam_pos.y = atof(token);
            token_iter.FindNextToken(msg);
            token = token_iter.GetToken(msg);
            cam_pos.z = atof(token);
        } else if(token == "set_cam_distance"){
            token_iter.FindNextToken(msg);
            token = token_iter.GetToken(msg);
            cam_dist = atof(token);
        } else if(token == "set_cam_rot"){
            token_iter.FindNextToken(msg);
            token = token_iter.GetToken(msg);
            cam_rot.x = atof(token);
            token_iter.FindNextToken(msg);
            token = token_iter.GetToken(msg);
            cam_rot.y = atof(token);
            token_iter.FindNextToken(msg);
            token = token_iter.GetToken(msg);
            cam_rot.z = atof(token);
        } else if(token == "set_dialogue_visible"){
            token_iter.FindNextToken(msg);
            token = token_iter.GetToken(msg);
            if(token == "true"){
                show_dialogue = true;
            } else if(token == "false"){
                show_dialogue = false;
            }
	    } else if(token == "set_dialogue_text"){
            token_iter.FindNextToken(msg);
            token = token_iter.GetToken(msg);
            dialogue_text = token;
        } else if(token == "set_dialogue_name"){
            token_iter.FindNextToken(msg);
            token = token_iter.GetToken(msg);
            dialogue_name = token;
        } else if(token == "send_character_message"){
            token_iter.FindNextToken(msg);
            token = token_iter.GetToken(msg);
            int id = atoi(token);
            MovementObject@ mo = ReadCharacterID(id);
            token_iter.FindNextToken(msg);
            token = token_iter.GetToken(msg);
            Print("Sending message: "+token+" to character "+id+"\n");
            mo.ReceiveMessage(token);
        } else if(token == "set_character_pos"){
            token_iter.FindNextToken(msg);
            token = token_iter.GetToken(msg);
            int id = atoi(token);
            vec3 pos;
            token_iter.FindNextToken(msg);
            token = token_iter.GetToken(msg);
            pos.x = atof(token);
            token_iter.FindNextToken(msg);
            token = token_iter.GetToken(msg);
            pos.y = atof(token);
            token_iter.FindNextToken(msg);
            token = token_iter.GetToken(msg);
            pos.z = atof(token);
            MovementObject@ mo = ReadCharacterID(id);
            mo.position = pos;
        } else if(token == "wait_for_click"){
            return true;
        }
        return false;
    }

    bool HasCameraControl() {
        return has_cam_control;
    }

    void Display() {
        if(show_dialogue){
            // Draw text background
            HUDImage @blackout_image = hud.AddImage();
            blackout_image.SetImageFromPath("Data/Textures/diffuse.tga");
            blackout_image.position.y = 0;
            blackout_image.position.x = 0.0f;
            blackout_image.position.z = -2.0f;
            blackout_image.scale = vec3(GetScreenWidth()/16.0f, 200.0f/16.0f, 1.0f);
            blackout_image.color = vec4(0.0f,0.0f,0.0f,1.0f);

            // Set up font style and canvas
            TextCanvasTexture @text = level.GetTextElement(text_id);
            text.ClearTextCanvas();
            string font_str = "Data/Fonts/arial.ttf";
            TextStyle small_style, big_style;
            small_style.font_face_id = GetFontFaceID(font_str, 24);

            // Draw speaker name to canvas
            vec2 pen_pos = vec2(0,24);
            text.SetPenPosition(pen_pos);
            text.SetPenColor(255,255,255,160);
            text.SetPenRotation(0.0f);
            text.AddText(dialogue_name+":", small_style);
        
            // Draw dialogue text to canvas
            text.SetPenColor(255,255,255,255);
            int br_size = 24;
            pen_pos.x += 40;
            pen_pos.y += br_size;
            text.SetPenPosition(pen_pos);
            text.AddText(dialogue_text, small_style);

            // Draw text canvas to screen
            text.UploadTextCanvasToTexture();
            HUDImage @text_image = hud.AddImage();
            text_image.SetImageFromText(level.GetTextElement(text_id)); 
            text_image.position.x = 30;
            text_image.position.y = 0;
            text_image.position.z = 4;
            text_image.color = vec4(1,1,1,1);
        }

        if(show_editor_info){
            DebugText("01 Camera pos", "Camera pos: "+camera.GetPos().x+", "+camera.GetPos().y+", "+camera.GetPos().z, 0.5f);
            DebugText("01 Camera rot", "Camera rot: "+camera.GetXRotation()+", "+camera.GetYRotation()+", "+camera.GetZRotation(), 0.5f);

            array<int> @object_ids = GetObjectIDs();
            int num_objects = object_ids.length();
            for(int i=0; i<num_objects; ++i){
                Object @obj = ReadObjectFromID(object_ids[i]);
                if(obj.GetType() == _movement_object){
                    if(obj.IsSelected()){
                        DebugText("02 Selected character", "Selected character: "+object_ids[i], 0.5f);
                        MovementObject@ mo = ReadCharacterID(object_ids[i]);
                        DebugText("021 Character pos:", "Camera pos: "+mo.position.x+", "+mo.position.y+", "+mo.position.z, 0.5f);
                    }
                }
                if(obj.GetType() == _path_point_object){
                    if(obj.IsSelected()){
                        vec3 pos = obj.GetTranslation();
                        DebugText("022 Waypoint pos:", "Waypoint pos: "+pos.x+", "+pos.y+", "+pos.z, 0.5f);
                    }
                }
            }
        }
    }
};

Dialogue dialogue;

void Init(string p_level_name) {
    dialogue.Init();
    dialogue.strings.push_back("Test test");
}

int HasCameraControl() {
    return dialogue.HasCameraControl()?1:0;
}

void GUIDeleted(uint32 id){
    if(id == gui_id){
        has_gui = false;
    }
    if(id == display_text_id){
        has_display_text = false;
    }
}

bool HasFocus(){
    return has_gui;
}

void ReceiveMessage(string msg) {
    TokenIterator token_iter;
    token_iter.Init();
    if(!token_iter.FindNextToken(msg)){
        return;
    }
    string token = token_iter.GetToken(msg);
    if(token == "cleartext"){
        if(has_display_text){
            gui.RemoveGUI(display_text_id);
            has_display_text = false;
        }
    } else if(token == "dispose_level"){
        gui.RemoveAll();
        has_gui = false;
    } else if(token == "go_to_main_menu"){
        level.SendMessage("dispose_level");
        LoadLevel("mainmenu");
    } else if(token == "clearhud"){
	    hotspot_image_string.resize(0);
	} else if(token == "manual_reset"){
        level.SendMessage("reset");
    } else if(token == "reset"){
        ResetLevel();
    } else if(token == "displaytext"){
        if(has_display_text){
            gui.RemoveGUI(display_text_id);
        }
        display_text_id = gui.AddGUI("text2","script_text.html",400,200, _GG_IGNORES_MOUSE);
        token_iter.FindNextToken(msg);
        gui.Execute(display_text_id,"SetText(\""+token_iter.GetToken(msg)+"\")");
        has_display_text = true;
    } else if(token == "displaygui"){
        token_iter.FindNextToken(msg);
        gui_id = gui.AddGUI("displaygui_call",token_iter.GetToken(msg),220,250,0);
        has_gui = true;
    } else if(token == "displayhud"){
		if(hotspot_image_string.length() == 0){
		    token_iter.FindNextToken(msg);
            hotspot_image_string = token_iter.GetToken(msg);
		}
    } else if(token == "loadlevel"){
        level.SendMessage("dispose_level");
		token_iter.FindNextToken(msg);
        LoadLevel(token_iter.GetToken(msg));
    }
}

void DrawGUI() {
    if(hotspot_image_string.length() != 0){
        HUDImage@ image = hud.AddImage();   
        image.SetImageFromPath(hotspot_image_string);
        image.position = vec3(700,200,0);
    }
    dialogue.Display();
}

void Update() {  
    if(level.HasFocus()){
        SetGrabMouse(false);
    }

    if(has_gui){
        string callback = gui.GetCallback(gui_id);
        while(callback != ""){
            Print("AS Callback: "+callback+"\n");
            if(callback == "retry"){
                gui.RemoveGUI(gui_id);
                has_gui = false;
                level.SendMessage("reset");
                break;
            }
            if(callback == "continue"){
                gui.RemoveGUI(gui_id);
                has_gui = false;
                break;
            }
            if(callback == "mainmenu"){
                level.SendMessage("go_to_main_menu");
                break;
            }
            if(callback == "settings"){
                gui.RemoveGUI(gui_id);
                gui_id = gui.AddGUI("gamemenu","settings\\settings.html",600,600,0);
                has_gui = true;
                break;
            }
            callback = gui.GetCallback(gui_id);
        }
    }
    if(!has_gui && GetInputDown(controller_id, "esc") && GetPlayerCharacterID() == -1){
        gui_id = gui.AddGUI("gamemenu","dialogs\\gamemenu.html",220,270,0);
        has_gui = true;
    }
    if(GetInputPressed(controller_id, "l")){
        level.SendMessage("manual_reset");
    }

    if(GetInputDown(controller_id, "x")){  
        int num_items = GetNumItems();
        for(int i=0; i<num_items; i++){
            ItemObject@ item_obj = ReadItem(i);
            item_obj.CleanBlood();
        }
    }

    if(GetInputPressed(controller_id, "k")){
        dialogue.Process();   
    }

    dialogue.Update();

    SetAnimUpdateFreqs();
}

const float _max_anim_frames_per_second = 100.0f;

void SetAnimUpdateFreqs() {
    int num = GetNumCharacters();
    array<float> framerate_request(num);
    vec3 cam_pos = camera.GetPos();
    float total_framerate_request = 0.0f;
    for(int i=0; i<num; ++i){
        MovementObject@ char = ReadCharacter(i);
        if(char.controlled){
            continue;
        }
        float dist = distance(char.position, cam_pos);
        framerate_request[i] = 120.0f/max(4.0f,min(dist*0.5f,32.0f));
        total_framerate_request += framerate_request[i];
    }
    float scale = 1.0f;
    if(total_framerate_request > _max_anim_frames_per_second){
        scale *= _max_anim_frames_per_second/total_framerate_request;
    }
    for(int i=0; i<num; ++i){
        MovementObject@ char = ReadCharacter(i);
        if(char.controlled){
            continue;
        }
        int period = 120.0f/(framerate_request[i]*scale);
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
