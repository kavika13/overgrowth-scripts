#include "ui_effects.as"

int controller_id = 0;
bool has_gui = false;
uint32 gui_id;
bool has_display_text = false;
uint32 display_text_id;
string hotspot_image_string;

void Init(string p_level_name) {
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
