int dialogue_text_billboard_id;

const float pi = 3.14159265359;

enum ProcessStringType { kInGame, kInEditor };

// What actions can be triggered from a dialogue script line
enum ObjCommands {
    kUnknown,
    kCamera,
    kHeadTarget,
    kEyeTarget,
    kChestTarget,
    kCharacter,
    kCharacterDialogueControl,
    kDialogueVisible,
    kDialogueName,
    kSetDialogueText,
    kAddDialogueText,
    kCharacterStartTalking,
    kCharacterStopTalking,
    kWait,
    kWaitForClick,
    kSetCamControl,
    kSetAnimation,
    kSay
};

class ScriptElement {
    string str; // The raw string
    bool visible; // Display this line in editor?
    bool locked; // Allow changes?
    bool record_locked; 
    int spawned_id; // ID of the object associated with this script line
    // Pre-tokenized
    ObjCommands obj_command;
    array<string> params;
}

class CharRecord {
    int last_pos;
    int last_head;
    int last_eye;
    int last_torso;
    int last_anim;

    CharRecord() {
        last_pos = -1;
        last_head = -1;
        last_eye = -1;
        last_torso = -1;
        last_anim = -1;
    }
};

enum SayParseState {kStart, kInBracket, kContinue};

uint old_input_mode;

class Dialogue {
    // Contains information from undo/redo
    string history_str;
    // This state is important for undo/redo
    int dialogue_obj_id;
    int selected_line;
    array<ScriptElement> strings;
    array<ScriptElement> sub_strings;
    bool recording;

    array<string> dialogue_poses;
    int index; // which dialogue element is being executed
    int sub_index;
    int text_id = -1; // ID for dialogue text canvas texture
    int text_id_position_x = 50;
    bool has_cam_control;
    bool show_dialogue;
    bool waiting_for_dialogue;
    bool is_waiting_time;
    bool skip_dialogue;
    float wait_time;
    string dialogue_text;
    float dialogue_text_disp_chars;
    string dialogue_name;
    vec3 cam_pos;
    vec3 cam_rot;
    float cam_zoom;
    int say_char;
    bool clear_on_complete;

    bool show_editor_info;
    int editor_text_id = -1; // ID of editor text canvas texture
    bool text_dirty;
    int set_animation_char_select;
    int set_animation_pose_select;
	bool edit_mode;
    int input_mode_id = -1;
	string edit_text;

    float init_time;
    float start_time = 0.0;

    void SetRecording(bool val){
        if(recording != val){
            recording = val;
            RibbonItemSetToggled("dialogue_recording", val);
            
            text_dirty = true;
            HandleSelectedString(selected_line);
            UpdateRecordLocked();
            ClearUnselectedObjects();
        }
    }

    // Adds an extra '\' before '\' or '"' characters in string
    string EscapeString(const string &in str){
        int str_len = int(str.length());
        string new_str;
        for(int i=0; i<str_len; ++i){
            if(str[i] == 92 || str[i] == 34){
                new_str += "\\";
            }
            new_str.resize(new_str.length()+1);
            new_str[new_str.length()-1] = str[i];
        }
        return new_str;
    }

    // Play dialogue with given name
    void StartDialogue(const string &in name){
        start_time = the_time;
        array<int> @object_ids = GetObjectIDs();
        int num_objects = object_ids.length();
        for(int i=0; i<num_objects; ++i){
            Object @obj = ReadObjectFromID(object_ids[i]);
            ScriptParams@ params = obj.GetScriptParams();
            if(obj.GetType() == _placeholder_object && params.HasParam("Dialogue") && params.HasParam("DisplayName") && params.GetString("DisplayName") == name){
                SetDialogueObjID(object_ids[i]);
                Play();
                clear_on_complete = true;
            }
        }
    }

    void NotifyDeleted(int id){
        if(dialogue_obj_id == id){
            ClearEditor();
        }
        // Delete connectors if dialogue object is deleted
		if(ObjectExists(id)){
			Object @obj = ReadObjectFromID(id);
			ScriptParams@ params = obj.GetScriptParams();
			if(obj.GetType() == _placeholder_object && params.HasParam("Dialogue") && params.HasParam("NumParticipants")){
				int num_connectors = params.GetInt("NumParticipants");
				for(int j=1; j<=num_connectors; ++j){
					if(params.HasParam("obj_"+j)){
						int obj_id = params.GetInt("obj_"+j);
						if(ObjectExists(obj_id)){
                            Log( info, "Test" );                
							DeleteObjectID(obj_id);
						}
					}
				}
			}
		}
		// To be sure...
		if (edit_mode) {
			StopTextInput();
			edit_mode = false;
            Log(info, "Ending input limitation");
		}
    }

    void UpdateRecordLocked() {
        if(dialogue_obj_id == -1 || !ObjectExists(dialogue_obj_id)){
            return;
        }
        int num_strings = int(strings.size());
        for(int i=0; i<num_strings; ++i){
            strings[i].record_locked = false;
        }
        if(recording){
            Object @obj = ReadObjectFromID(dialogue_obj_id);
            ScriptParams @params = obj.GetScriptParams();
            int num_participants = params.GetInt("NumParticipants");

            int num_lines = int(strings.size());
            int next_wait = num_lines-1;
            for(int i=num_lines-1; i>=selected_line; --i){
                if(strings[i].obj_command == kWaitForClick || strings[i].obj_command == kSay){
                    next_wait = i;
                }
            }

            int last_cam_update = -1;
            array<CharRecord> char_record;
            char_record.resize(num_participants);
            for(int i=0; i<next_wait; ++i){
                switch(strings[i].obj_command){
                case kCamera:
                    last_cam_update = i;
                    break;
                case kCharacter:{
                    int which_char = atoi(strings[i].params[0]);
                    char_record[which_char-1].last_pos = i;
                    break;}
                case kHeadTarget:{
                    int which_char = atoi(strings[i].params[0]);
                    char_record[which_char-1].last_head = i;
                    break;}
                case kEyeTarget:{
                    int which_char = atoi(strings[i].params[0]);
                    char_record[which_char-1].last_eye = i;
                    break;}
                case kChestTarget:{
                    int which_char = atoi(strings[i].params[0]);
                    char_record[which_char-1].last_torso = i;
                    break;}
                case kSetAnimation:{
                    int which_char = atoi(strings[i].params[0]);
                    char_record[which_char-1].last_anim = i;
                    break;}
                }
            }
            if(last_cam_update != -1){
                strings[last_cam_update].record_locked = true;
            }
            for(int i=0; i<num_participants; ++i){
                if(char_record[i].last_pos != -1){
                    strings[char_record[i].last_pos].record_locked = true;
                }
                if(char_record[i].last_anim != -1){
                    strings[char_record[i].last_anim].record_locked = true;
                }
                if(char_record[i].last_torso != -1){
                    strings[char_record[i].last_torso].record_locked = true;
                }
                if(char_record[i].last_head != -1){
                    strings[char_record[i].last_head].record_locked = true;
                }
                if(char_record[i].last_eye != -1){
                    strings[char_record[i].last_eye].record_locked = true;
                }
            }
            for(int i=0; i<num_lines; ++i){
                if(strings[i].record_locked){
                    CreateEditorObj(strings[i]);
                }
            }
        }
        text_dirty = true;
    }

    void ClearEditor() {
        Print("Clearing editor\n");        
        if(dialogue_obj_id != -1){
            int num_strings = int(strings.size());
            for(int i=0; i<num_strings; ++i){
                if(strings[i].spawned_id != -1){
                            Log( info, "Test" );                
                    DeleteObjectID(strings[i].spawned_id);
                    strings[i].spawned_id = -1;
                }
            }
        }
        SetRecording(false);
        selected_line = 0;
        dialogue_obj_id = -1;
        text_dirty = true;
        strings.resize(0);
        clear_on_complete = false;
        
        int num = GetNumCharacters();
        for(int i=0; i<num; ++i){
            MovementObject@ char = ReadCharacter(i);
            char.ReceiveMessage("set_dialogue_control false");
        }
    }

    void ResizeUpdate( int w, int h ) {
        TextCanvasTexture @text = level.GetTextElement(text_id);
        text.Create(w-text_id_position_x*2, 200);
    }

    void Init() {
        ClearEditor();
        skip_dialogue = false;
        is_waiting_time = false;
        index = 0;
        sub_index = -1;
        init_time = the_time;

        if( text_id == -1 ) {
            text_id = level.CreateTextElement();
        }

        ResizeUpdate(GetScreenWidth(),GetScreenHeight());

        TextCanvasTexture @text = level.GetTextElement(text_id);
        has_cam_control = false;
        show_dialogue = false;
        show_editor_info = true;
        waiting_for_dialogue = false;

        if( editor_text_id == -1 ) {
            editor_text_id = level.CreateTextElement();
        }

        TextCanvasTexture @editor_text = level.GetTextElement(editor_text_id);
        editor_text.Create(800, 512);
        set_animation_char_select = -1;
        set_animation_pose_select = -1;
		edit_mode = false;
        input_mode_id = -1;
		edit_text = "";

        Print("Loading dialogue poses file\n");
        if(!LoadFile("Data/Animations/dialogue_poses.txt")){
            Print("Failed to load dialogue poses file\n");
        }
        string new_str;
        while(true){
            new_str = GetFileLine();
            if(new_str == "end"){
                break;
            }
            dialogue_poses.push_back(new_str);
        }
        Print("Finished loading dialogue poses file\n");
    }

    ~Dialogue() {
        if( text_id != -1 ) {
            level.DeleteTextElement(text_id); 
            text_id = -1;
        }
        
        if( editor_text_id != -1 ) {
            level.DeleteTextElement(editor_text_id); 
            text_id = -1;
        }
    }

    string CreateStringFromParams(ObjCommands command, array<string> &in params){
        string str;
        int num_params = int(params.size());
        switch(command){
        case kCamera:
            str = "set_cam";
            for(int i=0; i<num_params; ++i){
                str += " " + params[i];
            }
            break;
        case kHeadTarget:
            str = "send_character_message "+params[0]+" \"set_head_target";
            for(int i=1; i<num_params; ++i){
                str += " " + params[i];
            }
            str += "\"";
            break;
        case kEyeTarget:
            str = "send_character_message "+params[0]+" \"set_eye_dir";
            for(int i=1; i<num_params; ++i){
                str += " " + params[i];
            }
            str += "\"";
            break;
        case kChestTarget:
            str = "send_character_message "+params[0]+" \"set_torso_target";
            for(int i=1; i<num_params; ++i){
                str += " " + params[i];
            }
            str += "\"";
            break;
        case kCharacterDialogueControl:
            str = "send_character_message "+params[0]+" \"set_dialogue_control "+params[1]+"\"";
            break;
        case kCharacter:
            str = "set_character_pos";
            for(int i=0; i<num_params; ++i){
                str += " " + params[i];
            }
            break;
        case kSetAnimation:
            str = "send_character_message "+params[0]+" \"set_animation \\\""+params[1]+"\\\"\"";
            break;
        case kDialogueVisible:
            str = "set_dialogue_visible "+params[0];
            break;
        case kSetCamControl:
            str = "set_cam_control "+params[0];
            break;
        }
        return str;
    }

    void SaveScriptToParams() {
        if(dialogue_obj_id == -1){
            return;
        }
        string dialogue_script;
        int num_lines = int(strings.size());
        for(int i=0; i<num_lines; ++i){
            if(strings[i].visible){
                dialogue_script += strings[i].str;
                dialogue_script += "\n";
            }
        }

        Object @obj = ReadObjectFromID(dialogue_obj_id);
        ScriptParams @params = obj.GetScriptParams();
        params.SetString("Script", dialogue_script);
    }

    void AddInvisibleStrings() {   
        Object @obj = ReadObjectFromID(dialogue_obj_id);
        ScriptParams @params = obj.GetScriptParams();

        int num_participants = 0;
        if(params.HasParam("NumParticipants")){
            num_participants = params.GetInt("NumParticipants");
        }

        //Place the defaults at the top, but below the title, if there are no commands before then.
        int insert_index = 0;
        for( uint i = 0; i < strings.length(); i++ ) {
            if( strings[i].str.length() == 0 )   
            {

            }
            else if( strings[i].str.substr(0,1) == "#" )
            {

            }
            else
            {
                insert_index = i;
                break;
            }
        }

        Log( info, "index " + insert_index );
         
        array<string> str_params;
        str_params.resize(7);
        str_params[0] = obj.GetTranslation().x;
        str_params[1] = obj.GetTranslation().y;
        str_params[2] = obj.GetTranslation().z;
        str_params[3] = 0;
        str_params[4] = 0;
        str_params[5] = 0;
        str_params[6] = 90;
        AddLine(CreateStringFromParams(kCamera, str_params), insert_index);
        strings[insert_index].visible = false;
        for(int i=0; i<num_participants; ++i){
            int char_id = GetDialogueCharID(i+1);
            if(char_id == -1){
                continue;
            }

            str_params.resize(5);
            str_params[0] = i+1;
                                
            MovementObject @char = ReadCharacterID(char_id);
            mat4 head_mat = char.rigged_object().GetAvgIKChainTransform("head");
            vec3 head_pos = head_mat * vec4(0,0,0,1) + head_mat * vec4(0,1,0,0);
            str_params[1] = head_pos.x;
            str_params[2] = head_pos.y;
            str_params[3] = head_pos.z;
            str_params[4] = 0.0f;
            AddLine(CreateStringFromParams(kHeadTarget, str_params), insert_index);
            strings[insert_index].visible = false;
                
            str_params.resize(5);
            mat4 chest_mat = char.rigged_object().GetAvgIKChainTransform("torso");
            vec3 torso_pos = chest_mat * vec4(0,0,0,1) + chest_mat * vec4(0,1,0,0);
            str_params[1] = torso_pos.x;
            str_params[2] = torso_pos.y;
            str_params[3] = torso_pos.z;
            str_params[4] = 0.0f;
            AddLine(CreateStringFromParams(kChestTarget, str_params), insert_index);
            strings[insert_index].visible = false;
                
            str_params.resize(5);
            vec3 eye_pos = head_mat * vec4(0,0,0,1) + head_mat * vec4(0,2,0,0);
            str_params[1] = eye_pos.x;
            str_params[2] = eye_pos.y;
            str_params[3] = eye_pos.z;
            str_params[4] = 1.0f;
            AddLine(CreateStringFromParams(kEyeTarget, str_params), insert_index);
            strings[insert_index].visible = false;
                
            str_params.resize(2);
            str_params[1] = "Data/Animations/r_actionidle.anm";
            AddLine(CreateStringFromParams(kSetAnimation, str_params), insert_index);
            strings[insert_index].visible = false;
                
            str_params.resize(5);
            Object @char_spawn = ReadObjectFromID(char_id);
            str_params[1] = char_spawn.GetTranslation().x;
            str_params[2] = char_spawn.GetTranslation().y;
            str_params[3] = char_spawn.GetTranslation().z;
            str_params[4] = 0;
            AddLine(CreateStringFromParams(kCharacter, str_params), insert_index);
            strings[insert_index].visible = false;
                
            str_params.resize(2);
            str_params[1] = "true";
            AddLine(CreateStringFromParams(kCharacterDialogueControl, str_params), insert_index);
            strings[insert_index].visible = false;
                
            str_params.resize(2);
            str_params[1] = "false";
            int last_line = int(strings.size());
            AddLine(CreateStringFromParams(kCharacterDialogueControl, str_params), last_line);
            strings[last_line].visible = false;
        }
            
        str_params.resize(1);
        str_params[0] = "false";
        int last_line = int(strings.size());
        AddLine(CreateStringFromParams(kDialogueVisible, str_params), last_line);
        strings[last_line].visible = false;

        last_line = int(strings.size());
        AddLine(CreateStringFromParams(kSetCamControl, str_params), last_line);
        strings[last_line].visible = false;
    }

    void SetDialogueObjID(int id) {
        if(dialogue_obj_id != id){
            ClearEditor();
            dialogue_obj_id = id;
            if(id != -1){
                Object @obj = ReadObjectFromID(dialogue_obj_id);
                ScriptParams @params = obj.GetScriptParams();

                if(!params.HasParam("NumParticipants") || !params.HasParam("Dialogue")){
                    Print("Selected dialogue object does not have the necessary parameters (id "+id+")\n");
                } else {
                    if(!params.HasParam("Script")){
            			if(params.GetString("Dialogue") == "empty") {
                            // Create placeholder script
            				strings.resize(0);
            				AddLine("#name \"Unnamed\"", strings.size());
            				AddLine("#participants 1", strings.size());
            				AddLine("", strings.size());
            				AddLine("say 1 \"Name\" \"Type your dialogue here.\"", strings.size());
            			} else {
                            // Parse script from file
            				LoadScriptFile(params.GetString("Dialogue"));
            			}
                    } else {
                        // Parse script directly from parameters
                        string script = params.GetString("Script");
                        string token = "\n";
                        int script_len = int(script.length());
                        int line_start = 0;
                        for(int i=0; i<script_len; ++i){
                            if(script[i] == token[0]){
                                AddLine(script.substr(line_start, i-line_start),int(strings.size()));
                                line_start = i+1;
                            }
                        }
                    }

                    AddInvisibleStrings();
                    selected_line = 1;
                }
            }
        }
    }

	void DeleteLine(int index){
        strings.removeAt(index);
    }

    void AddLine(const string &in str, int index){
        strings.resize(strings.size() + 1);
        int num_lines = strings.size();
        for(int i=num_lines-1; i>index; --i){
            strings[i] = strings[i-1];
        }
        strings[index].str = str;
        strings[index].record_locked = false;
        strings[index].visible = true;
        ParseLine(strings[index]);
        if(index <= selected_line){
            ++selected_line;
        }
    }

    void LoadScriptFile(const string &in path) {
        strings.resize(0);
        LoadFile(path);
        string new_str;
        while(true){
            new_str = GetFileLine();
            if(new_str == "end"){
                break;
            }
            AddLine(new_str, strings.size());
        }
    }


    void Play() {
        bool stop = false;

        int last_wait = -1;
        int prev_last_wait = -1;
        for(int i=0, len=strings.size(); i<len; ++i){
            if(strings[i].obj_command == kWaitForClick || strings[i].obj_command == kSay){
                prev_last_wait = last_wait;
                last_wait = i;
            }
        }

        if(the_time > init_time + 0.5){
            skip_dialogue = false; // Only skip dialogue that starts at the beginning of the level
        }

        while(!stop){
            if(index < int(strings.size())){
                stop = ExecuteScriptElement(strings[index], kInGame);
                if(index == prev_last_wait){
                    skip_dialogue = false;
                }
                if(skip_dialogue){
                    stop = false;
                }
                if(sub_index == -1){
                    ++index;
                }
            } else {
                stop = true;
                index = 0;
            }
        }
        skip_dialogue = false;
    }

    void SaveToFile(const string &in path) {
        Print("Save to file: "+path+"\n");
        int num_strings = strings.size();
        StartWriteFile();
        for(int i=0; i<num_strings; ++i){
            if(!strings[i].visible){
                continue;
            }
            AddFileString(strings[i].str);
            if(i != num_strings - 1){
                AddFileString("\n");
            }
        }
        //WriteFile("Data/Dialogues/dialogue_save_test.txt");
        WriteFile(path);
    }

    void ClearUnselectedObjects() {
        int num_strings = int(strings.size());
        for(int i=0; i<num_strings; ++i){
            if(strings[i].spawned_id != -1 && i != selected_line && !strings[i].locked && !strings[i].record_locked){
                            Log( info, "Test" );                
                DeleteObjectID(strings[i].spawned_id);
                strings[i].spawned_id = -1;
            }
        }
    }

    void RecordInput(const string &in new_string, int line, int last_wait) {
        if(new_string != strings[line].str){
            if(recording && strings[line].record_locked && last_wait > line){
                int spawned_id = strings[line].spawned_id;
                strings[line].spawned_id = -1;
                AddLine(new_string, last_wait+1);
                strings[last_wait+1].spawned_id = spawned_id;
                UpdateRecordLocked();
            } else {
                strings[line].str = new_string;
                strings[line].visible = true;
            }
            text_dirty = true;
            ExecutePreviousCommands(selected_line);
        }
    }

    int GetLastWait(int line) {
        int last_wait = -1;
        for(int j=0; j<line; ++j){
            if(strings[j].obj_command == kWaitForClick || strings[j].obj_command == kSay){
                last_wait = j;
            }
        }
        return last_wait;
    }

    void UpdateRibbonButtons() {
        bool can_edit_selected = false;
        EnterTelemetryZone("GetObjectIDs()");
        array<int> @object_ids = GetObjectIDsType(_placeholder_object);
        LeaveTelemetryZone();
        int num_objects = object_ids.length();
        for(int i=0; i<num_objects; ++i){
            if(!ObjectExists(object_ids[i])){ // This is needed because SetDialogueObjID can delete some objects
                continue;
            }
            Object @obj = ReadObjectFromID(object_ids[i]);
            ScriptParams@ params = obj.GetScriptParams();
            if(obj.IsSelected() && params.HasParam("Dialogue")){
                can_edit_selected = true;
            }
        }
        EnterTelemetryZone("RibbonItemSetEnableds()");
        RibbonItemSetEnabled("edit_selected_dialogue", can_edit_selected);
        RibbonItemSetEnabled("stop_editing_dialogue", dialogue_obj_id != -1);
        RibbonItemSetEnabled("preview_dialogue", dialogue_obj_id != -1);
        RibbonItemSetEnabled("save_dialogue", dialogue_obj_id != -1);
        RibbonItemSetEnabled("load_dialogue_pose", dialogue_obj_id != -1);
        RibbonItemSetEnabled("dialogue_recording", dialogue_obj_id != -1);
        LeaveTelemetryZone();
    }

    void Update() {     
        EnterTelemetryZone("Dialogue Update");
        if(history_str != ""){
            LoadHistoryStr();
        }
        if(index == 0){
            camera.SetFlags(kEditorCamera);
            SetGUIEnabled(true);
            if(clear_on_complete){
                ClearEditor();
            }
        }

        // TODO: update ribbon buttons should only happen in editor mode and when something has changed
        EnterTelemetryZone("Update ribbon buttons");
        UpdateRibbonButtons();
        LeaveTelemetryZone();

        
        // Apply camera transform if dialogue has control
        if(has_cam_control){
            camera.SetXRotation(cam_rot.x);
            camera.SetYRotation(cam_rot.y);
            camera.SetZRotation(cam_rot.z);
            camera.SetPos(cam_pos);
            camera.SetDistance(0.0f);
            camera.SetFOV(cam_zoom);
            UpdateListener(cam_pos,vec3(0.0f),camera.GetFacing(),camera.GetUpVector());
            if(EditorModeActive()){
                SetGrabMouse(false);
            } else {
                SetGrabMouse(true);                
            }
        }

        // Progress dialogue one character at a time
        if(waiting_for_dialogue){
            dialogue_text_disp_chars += time_step * 40.0f;
            // Continue dialogue script if we have displayed all the text that we are waiting for
            if(uint32(dialogue_text_disp_chars) >= dialogue_text.length()){
                waiting_for_dialogue = false;
                Play();   
            }
        }

        // Continue dialogue script if waiting time has completed
        if(is_waiting_time){
            wait_time -= time_step;
            if(wait_time <= 0.0f){
                is_waiting_time = false;
                Play();   
            }
        }

        if(strings.size() > 0 && show_editor_info && !has_cam_control && EditorModeActive()){
            // Handle up/down dialogue editor navigation
            if((selected_line < 0 || !strings[selected_line].visible) && !edit_mode){
                int num_lines = int(strings.size());
                int i = selected_line + 1;
                while(i < num_lines && !strings[i].visible){
                    ++i;
                }
                if(i < num_lines && strings[i].visible){
                    selected_line = i;
                }
                text_dirty = true;
                HandleSelectedString(selected_line);
                if(recording){
                    UpdateRecordLocked();
                }
                ClearUnselectedObjects();
            }
            if(selected_line >= int(strings.size()) && !edit_mode){
                int i = selected_line - 1;
                while(i > 0 && !strings[i].visible){
                    --i;
                }
                if(i > 0 && strings[i].visible){
                    selected_line = i;
                }
                text_dirty = true;
                HandleSelectedString(selected_line);
                if(recording){
                    UpdateRecordLocked();
                }
                ClearUnselectedObjects();
            }
        }

        if(GetInputPressed(controller_id, "attack") && start_time != the_time){
            if(index != 0){
                while(waiting_for_dialogue || is_waiting_time){
                    dialogue_text_disp_chars = dialogue_text.length();
                    waiting_for_dialogue = false;
                    is_waiting_time = false;
                    wait_time = 0.0f;
                    Play();   
                }
                Play();   
                PlaySoundGroup("Data/Sounds/concrete_foley/fs_light_concrete_run.xml");
            }
        }
        
        int last_wait = GetLastWait(selected_line);

        EnterTelemetryZone("Apply editor object transforms");
        // Apply editor object transforms to scripts
        for(int i=0; i<int(strings.size()); ++i){
            switch(strings[i].obj_command){
            case kCamera:
                if(strings[i].spawned_id != -1){
                    Object@ obj = ReadObjectFromID(strings[i].spawned_id);
                    vec3 pos = obj.GetTranslation();
                    vec4 v = obj.GetRotationVec4();
                    quaternion rot(v.x,v.y,v.z,v.a);
                    // Set camera euler angles from rotation matrix
                    vec3 front = Mult(rot, vec3(0,0,1));
                    float y_rot = atan2(front.x, front.z)*180.0f/pi;
                    float x_rot = asin(front[1])*-180.0f/pi;
                    vec3 up = Mult(rot, vec3(0,1,0));
                    vec3 expected_right = normalize(cross(front, vec3(0,1,0)));
                    vec3 expected_up = normalize(cross(expected_right, front));
                    float z_rot = atan2(dot(up,expected_right), dot(up, expected_up))*180.0f/pi;            
                    const float zoom_sensitivity = 3.5f;
                    float zoom = min(150.0f, 90.0f / max(0.001f,(1.0f+(obj.GetScale().x-1.0f)*zoom_sensitivity)));
                    strings[i].params[0] = pos.x;
                    strings[i].params[1] = pos.y;
                    strings[i].params[2] = pos.z;
                    strings[i].params[3] = floor(x_rot*100.0f+0.5f)/100.0f;
                    strings[i].params[4] = floor(y_rot*100.0f+0.5f)/100.0f;
                    strings[i].params[5] = floor(z_rot*100.0f+0.5f)/100.0f;
                    strings[i].params[6] = zoom;
                    
                    string new_string = CreateStringFromParams(strings[i].obj_command, strings[i].params);
                    RecordInput(new_string, i, last_wait);
                }
                break;
            case kHeadTarget:
                if(strings[i].spawned_id != -1){
                    Object@ obj = ReadObjectFromID(strings[i].spawned_id);
                    vec3 pos = obj.GetTranslation();
            
                    float scale = obj.GetScale().x;
                    if(scale < 0.1f){
                        obj.SetScale(vec3(0.1f));
                    }
                    if(scale > 0.35f){
                        obj.SetScale(vec3(0.35f));
                    }
                    float zoom = (obj.GetScale().x - 0.1f) * 4.0f;
                    
                    strings[i].params[1] = pos.x;
                    strings[i].params[2] = pos.y;
                    strings[i].params[3] = pos.z;
                    strings[i].params[4] = zoom;
                    
                    string new_string = CreateStringFromParams(strings[i].obj_command, strings[i].params);
                    RecordInput(new_string, i, last_wait);

                    int char_id = GetDialogueCharID(atoi(strings[i].params[0]));
                    if(char_id != -1){
                        MovementObject@ mo = ReadCharacterID(char_id);
                        DebugDrawLine(mo.position, pos, vec4(vec3(1.0), 0.1), vec4(vec3(1.0), 0.1), _delete_on_update);
                    }
                }
                break;
            case kChestTarget:
                if(strings[i].spawned_id != -1){
                    Object@ obj = ReadObjectFromID(strings[i].spawned_id);
                    vec3 pos = obj.GetTranslation();
            
                    float scale = obj.GetScale().x;
                    if(scale < 0.1f){
                        obj.SetScale(vec3(0.1f));
                    }
                    if(scale > 0.35f){
                        obj.SetScale(vec3(0.35f));
                    }
                    float zoom = (obj.GetScale().x - 0.1f) * 4.0f;
                    
                    strings[i].params[1] = pos.x;
                    strings[i].params[2] = pos.y;
                    strings[i].params[3] = pos.z;
                    strings[i].params[4] = zoom;
                    
                    string new_string = CreateStringFromParams(strings[i].obj_command, strings[i].params);
                    RecordInput(new_string, i, last_wait);

                    int char_id = GetDialogueCharID(atoi(strings[i].params[0]));
                    if(char_id != -1){
                        MovementObject@ mo = ReadCharacterID(char_id);
                        DebugDrawLine(mo.position, pos, vec4(vec3(1.0), 0.1), vec4(vec3(1.0), 0.1), _delete_on_update);
                    }
                }
                break;
            case kEyeTarget:
                if(strings[i].spawned_id != -1){
                    Object@ obj = ReadObjectFromID(strings[i].spawned_id);
                    vec3 pos = obj.GetTranslation();

                    float scale = obj.GetScale().x;
                    if(scale < 0.05f){
                        obj.SetScale(vec3(0.05f));
                    }
                    if(scale > 0.1f){
                        obj.SetScale(vec3(0.1f));
                    }
                    float blink_mult = (obj.GetScale().x-0.05f)/0.05f;

                    strings[i].params[1] = pos.x;
                    strings[i].params[2] = pos.y;
                    strings[i].params[3] = pos.z;
                    strings[i].params[4] = blink_mult;
                    
                    string new_string = CreateStringFromParams(strings[i].obj_command, strings[i].params);
                    RecordInput(new_string, i, last_wait);
                    
                    int char_id = GetDialogueCharID(atoi(strings[i].params[0]));
                    if(char_id != -1){
                        MovementObject@ mo = ReadCharacterID(char_id);
                        DebugDrawLine(mo.position, pos, vec4(vec3(1.0), 0.1), vec4(vec3(1.0), 0.1), _delete_on_update);
                    }
                }
                break;
            case kCharacter:
                if(strings[i].spawned_id != -1){
                    Object@ obj = ReadObjectFromID(strings[i].spawned_id);
                    vec3 pos = obj.GetTranslation();
                    vec4 v = obj.GetRotationVec4();
                    quaternion quat(v.x,v.y,v.z,v.a);
                    vec3 facing = Mult(quat, vec3(0,0,1));
                    float rot = atan2(facing.x, facing.z)*180.0f/pi;
                    obj.SetRotation(quaternion(vec4(0,1,0,rot*pi/180.0f)));
                    
                    strings[i].params[1] = pos.x;
                    strings[i].params[2] = pos.y;
                    strings[i].params[3] = pos.z;
                    strings[i].params[4] = floor(rot+0.5f);
                    
                    string new_string = CreateStringFromParams(strings[i].obj_command, strings[i].params);
                    RecordInput(new_string, i, last_wait);
                }
                break;
            }
        }
        LeaveTelemetryZone(); // editor object transforms
        LeaveTelemetryZone(); // dialogue update
    }

    void ExecutePreviousCommands(int id) {
        show_dialogue = false;
        if(id >= int(strings.size())) {
            return;
        }
        for(int i=0; i<=id; ++i){
            ExecuteScriptElement(strings[i], kInEditor);
        }
    }
    
    
    void ParseSelectedCharMessage(ScriptElement &se, const string &in msg){    
        TokenIterator token_iter;
        token_iter.Init();
        if(!token_iter.FindNextToken(msg)){
            return;
        }
        string token = token_iter.GetToken(msg);
        if(token == "set_head_target"){
            se.obj_command = kHeadTarget;
            const int kNumParams = 4;
            int old_param_size = se.params.size();
            int new_param_size = old_param_size+kNumParams;
            se.params.resize(new_param_size);
            for(int i=old_param_size; i<new_param_size; ++i){
                token_iter.FindNextToken(msg);
                se.params[i] = token_iter.GetToken(msg);
            }
        } else if(token == "set_torso_target"){
            se.obj_command = kChestTarget;
            const int kNumParams = 4;
            int old_param_size = se.params.size();
            int new_param_size = old_param_size+kNumParams;
            se.params.resize(new_param_size);
            for(int i=old_param_size; i<new_param_size; ++i){
                token_iter.FindNextToken(msg);
                se.params[i] = token_iter.GetToken(msg);
            }
        } else if(token == "set_eye_dir"){
            se.obj_command = kEyeTarget;
            const int kNumParams = 4;
            int old_param_size = se.params.size();
            int new_param_size = old_param_size+kNumParams;
            se.params.resize(new_param_size);
            for(int i=old_param_size; i<new_param_size; ++i){
                token_iter.FindNextToken(msg);
                se.params[i] = token_iter.GetToken(msg);
            }
        } else if(token == "set_animation"){
            se.obj_command = kSetAnimation;
            const int kNumParams = 1;
            int old_param_size = se.params.size();
            int new_param_size = old_param_size+kNumParams;
            se.params.resize(new_param_size);
            for(int i=old_param_size; i<new_param_size; ++i){
                token_iter.FindNextToken(msg);
                se.params[i] = token_iter.GetToken(msg);
            }
        }
    }

    // Fill script element from selected line string
    void ParseLine(ScriptElement &se){
        se.locked = false;
        se.obj_command = kUnknown;
        se.spawned_id = -1;
        string msg = se.str;        
        TokenIterator token_iter;
        token_iter.Init();
        if(!token_iter.FindNextToken(msg)){
            return;
        }
        string token = token_iter.GetToken(msg);
        if(token == "set_cam"){
            se.obj_command = kCamera;
            const int kNumParams = 7;
            se.params.resize(kNumParams);
            for(int i=0; i<kNumParams; ++i){
                token_iter.FindNextToken(msg);
                se.params[i] = token_iter.GetToken(msg);
            }
        } else if(token == "set_character_pos"){
            se.obj_command = kCharacter;
            const int kNumParams = 5;
            se.params.resize(kNumParams);
            for(int i=0; i<kNumParams; ++i){
                token_iter.FindNextToken(msg);
                se.params[i] = token_iter.GetToken(msg);
            }
        } else if(token == "send_character_message"){
            se.params.resize(1);
            token_iter.FindNextToken(msg);
            se.params[0] = token_iter.GetToken(msg);
            token_iter.FindNextToken(msg);
            token = token_iter.GetToken(msg);
            ParseSelectedCharMessage(se, token);
        } else if(token == "wait"){
            se.obj_command = kWait;
            se.params.resize(1);
            token_iter.FindNextToken(msg);
            se.params[0] = token_iter.GetToken(msg);
        } else if(token == "wait_for_click"){
            se.obj_command = kWaitForClick;
            ParseSelectedCharMessage(se, token);
        } else if(token == "set_dialogue_visible"){
            se.obj_command = kDialogueVisible;
            se.params.resize(1);
            token_iter.FindNextToken(msg);
            se.params[0] = token_iter.GetToken(msg);            
        } else if(token == "set_dialogue_name"){
            se.obj_command = kDialogueName;
            se.params.resize(1);
            token_iter.FindNextToken(msg);
            se.params[0] = token_iter.GetToken(msg);            
        } else if(token == "set_dialogue_text"){
            se.obj_command = kSetDialogueText;
            se.params.resize(1);
            token_iter.FindNextToken(msg);
            se.params[0] = token_iter.GetToken(msg);            
        } else if(token == "say"){
            se.obj_command = kSay;
            const int kNumParams = 3;
            se.params.resize(kNumParams);
            for(int i=0; i<kNumParams; ++i){
                token_iter.FindNextToken(msg);
                se.params[i] = token_iter.GetToken(msg);
            }      
        } else if(token == "add_dialogue_text"){
            se.obj_command = kAddDialogueText;
            se.params.resize(1);
            token_iter.FindNextToken(msg);
            se.params[0] = token_iter.GetToken(msg);            
        } else if(token == "set_cam_control"){
            se.obj_command = kSetCamControl;
            se.params.resize(1);
            token_iter.FindNextToken(msg);
            se.params[0] = token_iter.GetToken(msg);            
        }
    }

    int GetDialogueCharID(int id){
        Object@ obj = ReadObjectFromID(dialogue_obj_id);
        ScriptParams@ params = obj.GetScriptParams();
        if(!params.HasParam("obj_"+id)){
            Print("Error: Dialogue object "+dialogue_obj_id+" does not have parameter \""+"obj_"+id+"\"\n");
            return -1;
        }
        int connector_id = params.GetInt("obj_"+id);
        if(!ObjectExists(connector_id)){
            Print("Error: Connector does not exist\n");
            return -1;
        }
        Object@ connector_obj = ReadObjectFromID(connector_id);
        PlaceholderObject@ placeholder_object = cast<PlaceholderObject@>(connector_obj);
        int connect_id = placeholder_object.GetConnectID();
        return placeholder_object.GetConnectID();
    }

    void CreateEditorObj(ScriptElement@ se){
        switch(se.obj_command){
        case kCamera: {
            if(se.spawned_id == -1){
                se.spawned_id = CreateObject("Data/Objects/placeholder/camera_placeholder.xml", false);
            }
            vec3 pos(atof(se.params[0]), atof(se.params[1]), atof(se.params[2]));
            vec3 rot(atof(se.params[3]), atof(se.params[4]), atof(se.params[5]));
            float zoom = atof(se.params[6]);
            Object@ obj = ReadObjectFromID(se.spawned_id);
            obj.SetTranslation(pos);            
            float deg2rad = 3.14159265359/180.0f;
            quaternion rot_y(vec4(0,1,0,rot.y*deg2rad));
            quaternion rot_x(vec4(1,0,0,rot.x*deg2rad));
            quaternion rot_z(vec4(0,0,1,rot.z*deg2rad));
            obj.SetRotation(rot_y*rot_x*rot_z);            
            const float zoom_sensitivity = 3.5f;
            float scale = (90.0f / zoom - 1.0f) / zoom_sensitivity + 1.0f;
            obj.SetScale(vec3(scale));
            ScriptParams @params = obj.GetScriptParams();
            params.AddIntCheckbox("No Save", true);
            obj.SetCopyable(false);
            obj.SetDeletable(false);
            obj.SetSelectable(true);
            obj.SetTranslatable(true);
            obj.SetScalable(true);
            obj.SetRotatable(true);
            break;}
        case kCharacter: {
            if(se.spawned_id == -1){
                se.spawned_id = CreateObject("Data/Objects/placeholder/empty_placeholder.xml", false);
            }
            int char_id = atoi(se.params[0]);
            vec3 pos(atof(se.params[1]), atof(se.params[2]), atof(se.params[3]));
            float rot = floor(atof(se.params[4])+0.5f);
            Object@ obj = ReadObjectFromID(se.spawned_id);
            obj.SetTranslation(pos);
            obj.SetRotation(quaternion(vec4(0,1,0,rot*3.1415/180.0f)));
            ScriptParams @params = obj.GetScriptParams();
            params.AddIntCheckbox("No Save", true);
            obj.SetCopyable(false);
            obj.SetDeletable(false);
            obj.SetScalable(false);
            obj.SetSelectable(true);
            obj.SetTranslatable(true);
            obj.SetRotatable(true);
            break; }
        case kHeadTarget: {
            if(se.spawned_id == -1){
                se.spawned_id = CreateObject("Data/Objects/placeholder/empty_placeholder.xml", false);
            }
            int id = atoi(se.params[0]);
            vec3 pos(atof(se.params[1]), atof(se.params[2]), atof(se.params[3]));
            float zoom = atof(se.params[4]);
            Object@ obj = ReadObjectFromID(se.spawned_id);
            obj.SetTranslation(pos);
            obj.SetScale(zoom / 4.0f + 0.1f);
            PlaceholderObject@ placeholder_object = cast<PlaceholderObject@>(obj);
            placeholder_object.SetBillboard("Data/Textures/ui/head_widget.tga");
            ScriptParams @params = obj.GetScriptParams();
            params.AddIntCheckbox("No Save", true);
            obj.SetCopyable(false);
            obj.SetDeletable(false);
            obj.SetRotatable(false);
            obj.SetSelectable(true);
            obj.SetTranslatable(true);
            obj.SetScalable(true);
            break; }
        case kChestTarget: {
            if(se.spawned_id == -1){
                se.spawned_id = CreateObject("Data/Objects/placeholder/empty_placeholder.xml", false);
            }
            int id = atoi(se.params[0]);
            vec3 pos(atof(se.params[1]), atof(se.params[2]), atof(se.params[3]));
            float zoom = atof(se.params[4]);
            Object@ obj = ReadObjectFromID(se.spawned_id);
            obj.SetTranslation(pos);
            obj.SetScale(zoom / 4.0f + 0.1f);
            PlaceholderObject@ placeholder_object = cast<PlaceholderObject@>(obj);
            placeholder_object.SetBillboard("Data/Textures/ui/torso_widget.tga");
            ScriptParams @params = obj.GetScriptParams();
            params.AddIntCheckbox("No Save", true);
            obj.SetCopyable(false);
            obj.SetDeletable(false);
            obj.SetRotatable(false);
            obj.SetSelectable(true);
            obj.SetTranslatable(true);
            obj.SetScalable(true);
            break; }
        case kEyeTarget: {           
            if(se.spawned_id == -1){
                se.spawned_id = CreateObject("Data/Objects/placeholder/empty_placeholder.xml", false);
            }
            int id = atoi(se.params[0]);
            vec3 pos(atof(se.params[1]), atof(se.params[2]), atof(se.params[3]));
            float blink_mult = atof(se.params[4]);    
            Object@ obj = ReadObjectFromID(se.spawned_id);        
            obj.SetTranslation(pos);
            obj.SetScale(0.05f+0.05f*blink_mult);
            PlaceholderObject@ placeholder_object = cast<PlaceholderObject@>(obj);
            placeholder_object.SetBillboard("Data/Textures/ui/eye_widget.tga");
            ScriptParams @params = obj.GetScriptParams();
            params.AddIntCheckbox("No Save", true);
            obj.SetCopyable(false);
            obj.SetDeletable(false);
            obj.SetRotatable(false);
            obj.SetSelectable(true);
            obj.SetTranslatable(true);
            obj.SetScalable(true);
            break; }
        }
    }

    void HandleSelectedString(int line){
        set_animation_char_select = -1;
        set_animation_pose_select = -1;
        ExecutePreviousCommands(line);
        if(line < 0 || line >= int(strings.size())){
            return;
        }
        switch(strings[line].obj_command){
        case kCamera:
        case kCharacter:
        case kHeadTarget:
        case kChestTarget:
        case kEyeTarget: 
            CreateEditorObj(strings[line]);
            break;
        case kSetAnimation: {
            int num_dialogue_poses = dialogue_poses.size();
            int dialogue_pose_id = -1;
            for(int i=0; i<num_dialogue_poses; ++i){
                if(dialogue_poses[i] == strings[line].params[1]){
                    dialogue_pose_id = i;
                }
            }
            if(dialogue_pose_id != -1){
                set_animation_char_select = atoi(strings[line].params[0]);
                set_animation_pose_select = dialogue_pose_id;
            } 
            break;}
        }
    }

    void ParseSayText(int player_id, const string &in str, ProcessStringType type){
        sub_strings.resize(0);
        SayParseState state = kContinue;
        bool done = false;
        string tokens = "[]";
        int str_len = int(str.length());
        int i = 0;
        int token_start = 0;
        while(!done){
            switch(state){
                case kInBracket:
                    if(i == str_len){
                        done = true;                        
                    } else if(str[i] == tokens[1]){  
                        int sub_str_id = int(sub_strings.size());
                        sub_strings.resize(sub_str_id+1);
                        sub_strings[sub_str_id].str = str.substr(token_start,i-token_start);
                        ParseLine(sub_strings[sub_str_id]);
                        state = kContinue;
                        token_start = i+1;
                    }
                    break;
                case kContinue: {
                    bool token_end = false;
                    if(i == str_len){
                        token_end = true;
                        done = true;
                    } else if(str[i] == tokens[0]){
                        token_end = true;  
                        state = kInBracket;
                    }
                    if(token_end){
                        {
                            int sub_str_id = int(sub_strings.size());
                            sub_strings.resize(sub_str_id+1);
                            sub_strings[sub_str_id].str = "send_character_message \""+player_id+" \"start_talking\"";
                            ParseLine(sub_strings[sub_str_id]);
                        }
                        {
                            int sub_str_id = int(sub_strings.size());
                            sub_strings.resize(sub_str_id+1);
                            sub_strings[sub_str_id].str = "add_dialogue_text \""+str.substr(token_start,i-token_start)+"\"";
                            ParseLine(sub_strings[sub_str_id]);
                        }
                        {
                            int sub_str_id = int(sub_strings.size());
                            sub_strings.resize(sub_str_id+1);
                            sub_strings[sub_str_id].str = "send_character_message \""+player_id+" \"stop_talking\"";
                            ParseLine(sub_strings[sub_str_id]);
                        }
                        token_start = i+1;
                    }
                    break; }
            }
            ++i;
        }
        
        int sub_str_id = int(sub_strings.size());
        sub_strings.resize(sub_str_id+1);
        sub_strings[sub_str_id].str = "wait_for_click";
        ParseLine(sub_strings[sub_str_id]);

        dialogue_text = "";
        dialogue_text_disp_chars = 0;
    }

    bool ExecuteScriptElement(const ScriptElement &in script_element, ProcessStringType type) { 
        switch(script_element.obj_command){
        case kSetCamControl:
            if(type == kInGame){
                if(script_element.params[0] == "true"){
                    has_cam_control = true;
                } else if(script_element.params[0] == "false"){
                    has_cam_control = false;
                }
            }
            break;       
        case kCamera:
            if(type == kInGame){
                // Set camera control
                has_cam_control = true;
            }
            // Set camera position
            cam_pos.x = atof(script_element.params[0]);
            cam_pos.y = atof(script_element.params[1]);
            cam_pos.z = atof(script_element.params[2]);
            // Set camera rotation
            cam_rot.x = atof(script_element.params[3]);
            cam_rot.y = atof(script_element.params[4]);
            cam_rot.z = atof(script_element.params[5]);
            // Set camera zoom
            cam_zoom = atof(script_element.params[6]);
            break;
        case kWait:
            if(type == kInGame){
                is_waiting_time = true;
                wait_time = atof(script_element.params[0]);
            }
            return true;
        case kDialogueVisible:
            if(script_element.params[0] == "true"){
                show_dialogue = true;
            } else if(script_element.params[0] == "false"){
                show_dialogue = false;
            }
            break;
        case kSetDialogueText:
            dialogue_text = script_element.params[0];
            dialogue_text_disp_chars = 0;
            if(type == kInGame){
                waiting_for_dialogue = true;
            } else { 
                dialogue_text_disp_chars = dialogue_text.length();
            }
            return true;
        case kSay:
            if(sub_index == -1 || type == kInEditor){
                show_dialogue = true;
                dialogue_name = script_element.params[1];
                ParseSayText(atoi(script_element.params[0]), script_element.params[2], type);
                sub_index = 0;
                if(type == kInEditor){
                    while(sub_index < int(sub_strings.size())){
                        ExecuteScriptElement(sub_strings[sub_index++], type);
                    }
                    sub_index = -1;
                }
            } else {
                if(sub_index >= int(sub_strings.size())){
                    sub_index = -1;
                } else {
                    return ExecuteScriptElement(sub_strings[sub_index++], type);
                }
            }
            break;
        case kAddDialogueText:
            dialogue_text += script_element.params[0];
            if(type == kInGame){
                waiting_for_dialogue = true;
            } else { 
                dialogue_text_disp_chars = dialogue_text.length();
            }
            return true;
        case kDialogueName:
            dialogue_name = script_element.params[0];
            break;
        case kCharacter: {
            vec3 pos;
            pos.x = atof(script_element.params[1]);
            pos.y = atof(script_element.params[2]);
            pos.z = atof(script_element.params[3]);
            float rot = atof(script_element.params[4]);
            int char_id = GetDialogueCharID(atoi(script_element.params[0]));
            if(char_id != -1){
                MovementObject@ mo = ReadCharacterID(char_id);
                mo.ReceiveMessage("set_rotation "+rot);
                mo.ReceiveMessage("set_dialogue_position "+pos.x+" "+pos.y+" "+pos.z);
            }
            break; }
        case kWaitForClick:
            return true;
        default: { 
            TokenIterator token_iter;
            token_iter.Init();
            if(!token_iter.FindNextToken(script_element.str)){
                return false;
            }
            string token = token_iter.GetToken(script_element.str);
            if(token == "send_character_message"){
                token_iter.FindNextToken(script_element.str);
                token = token_iter.GetToken(script_element.str);
                int id = atoi(token);
                int char_id = GetDialogueCharID(id);
                if(char_id != -1){
                    MovementObject@ mo = ReadCharacterID(char_id);
                    token_iter.FindNextToken(script_element.str);
                    token = token_iter.GetToken(script_element.str);
                    mo.ReceiveMessage(token);
                }
            }
            if(token == "send_level_message"){
                token_iter.FindNextToken(script_element.str);
                token = token_iter.GetToken(script_element.str);
                level.SendMessage(token);
            }
            break;
            }
        }
        return false;
    }
    
    void UpdateDialogueObjectConnectors(int id){
        Object @obj = ReadObjectFromID(id);
        ScriptParams@ params = obj.GetScriptParams();
        int num_connectors = params.GetInt("NumParticipants");
        int player_id = GetPlayerCharacterID();
        for(int j=1; j<=num_connectors; ++j){
            int obj_id = params.GetInt("obj_"+j);
            if(ObjectExists(obj_id)){
                Object @new_obj = ReadObjectFromID(obj_id);
                vec4 v = obj.GetRotationVec4();
                quaternion quat(v.x,v.y,v.z,v.a);
                new_obj.SetTranslation(obj.GetTranslation() + Mult(quat,vec3((num_connectors*0.5f+0.5f-j)*obj.GetScale().x*0.35f,obj.GetScale().y*(0.5f+0.2f),0)));
                new_obj.SetRotation(quat);
                new_obj.SetScale(obj.GetScale()*0.3f);
                if(player_id == -1){
                    new_obj.SetEditorLabel(""+j);
                    new_obj.SetEditorLabelScale(6);
                    new_obj.SetEditorLabelOffset(vec3(0));
                    
                   // TextCanvasTexture @text = level.GetTextElement(number_text_canvases[j-1]);
                   // text.DebugDrawBillboard(new_obj.GetTranslation(), 0.25f*obj.GetScale().x, _persistent);//_delete_on_update);
                }
                new_obj.SetCopyable(false);
                new_obj.SetDeletable(false);
            } else {
                params.Remove("obj_"+j);
            }
        }
    }

	void SetupDialogueObjectConnectors(int id){
		Object @obj = ReadObjectFromID(id);
		ScriptParams@ params = obj.GetScriptParams();
		int num_connectors = params.GetInt("NumParticipants");
        for(int j=1; j<=num_connectors; ++j){
            if(!params.HasParam("obj_"+j)){
                int obj_id = CreateObject("Data/Objects/placeholder/empty_placeholder.xml", false);
                params.AddInt("obj_"+j, obj_id);
                Object@ object = ReadObjectFromID(obj_id);
                object.SetSelectable(true);
                PlaceholderObject@ inner_placeholder_object = cast<PlaceholderObject@>(object);
                inner_placeholder_object.SetSpecialType(kPlayerConnect);
            }
        }
        UpdateDialogueObjectConnectors(id);
	}

    void MovedObject(int id){
        if(id == -1){
            return;
        }
        Object @obj = ReadObjectFromID(id);
        if(obj.GetType() != _placeholder_object){
            return;
        }
        ScriptParams@ params = obj.GetScriptParams();
        if(!params.HasParam("Dialogue")){
            return;
        }
        UpdateDialogueObjectConnectors(id);
    }

	void UpdateParams(string str, int id) {
		Object @obj = ReadObjectFromID(id);
		ScriptParams@ params = obj.GetScriptParams();
		TokenIterator token_iter;
		token_iter.Init();
		if(token_iter.FindNextToken(str)){
			string token = token_iter.GetToken(str);
			if(token == "#name"){
				if(token_iter.FindNextToken(str)){
					params.SetString("DisplayName", token_iter.GetToken(str));
                    obj.SetEditorLabel(params.GetString("DisplayName"));
				}
			}
			if(token == "#participants"){
				if(token_iter.FindNextToken(str)){
					params.SetInt("NumParticipants", atoi(token_iter.GetToken(str)));
				}
			}
		}
	}

    void AddedObject(int id){
        if(id == -1){
            return;
        }
        Object @obj = ReadObjectFromID(id);
        if(obj.GetType() != _placeholder_object){
            return;
        }
        ScriptParams@ params = obj.GetScriptParams();
        if(!params.HasParam("Dialogue")){
            return;
        }
        // Object @obj is a dialogue object
        obj.SetCopyable(false);
        PlaceholderObject@ placeholder_object = cast<PlaceholderObject@>(obj);
        placeholder_object.SetBillboard("Data/Textures/ui/dialogue_widget.tga");
        if(!params.HasParam("DisplayName") || !params.HasParam("NumParticipants")){
			if(params.GetString("Dialogue") == "empty") {
				params.SetString("DisplayName", "Unnamed");
				params.SetInt("NumParticipants", 1);
			} else {
				// Parse file for #name token
				LoadFile(params.GetString("Dialogue"));
				string new_str;
				while(true){
					new_str = GetFileLine();
					if(new_str == "end"){
						break;
					}
					UpdateParams(new_str, id);
				}
			}
        }
        obj.SetEditorLabel(params.GetString("DisplayName"));
        obj.SetEditorLabelOffset(vec3(0,1.25,0)); 
        obj.SetEditorLabelScale(10);
        int player_id = GetPlayerCharacterID();
        // Draw dialogue name
        //if(player_id == -1){
        //    DrawDialogueTextCanvas(id);
        //}
        // Set up dialogue connectors
        SetupDialogueObjectConnectors(id);
    }

    void ReceiveMessage(const string &in msg) {
        TokenIterator token_iter;
        token_iter.Init();
        if(!token_iter.FindNextToken(msg)){
            return;
        }
        string token = token_iter.GetToken(msg);
        if(token == "notify_deleted"){
		    token_iter.FindNextToken(msg);
            NotifyDeleted(atoi(token_iter.GetToken(msg)));
        } else if(token == "skip_dialogue"){
            skip_dialogue = true;
        } else if(token == "added_object"){
            token_iter.FindNextToken(msg);
            int obj_id = atoi(token_iter.GetToken(msg));
            AddedObject(obj_id);
        } else if(token == "moved_objects"){
            while(token_iter.FindNextToken(msg)){
                int obj_id = atoi(token_iter.GetToken(msg));
                MovedObject(obj_id);
            }
        } else if(token == "stop_editing_dialogue") {
            DeactivateKeyboardEvents();
			if (edit_mode) {
				StopTextInput();
				edit_mode = false;
                Log(info, "Ending input limitation");
			}
            ClearEditor();
        } else if(token == "dialogue_set_recording") {
		    token_iter.FindNextToken(msg);
            SetRecording((token_iter.GetToken(msg) == "true"));
        } else if(token == "edit_selected_dialogue"){
            ActivateKeyboardEvents();
            array<int> @object_ids = GetObjectIDs();
            int num_objects = object_ids.length();
            for(int i=0; i<num_objects; ++i){
                if(!ObjectExists(object_ids[i])){ // This is needed because SetDialogueObjID can delete some objects
                    continue;
                }
                Object @obj = ReadObjectFromID(object_ids[i]);
                ScriptParams@ params = obj.GetScriptParams();
                if(obj.IsSelected() && obj.GetType() == _placeholder_object && params.HasParam("Dialogue")){
                    dialogue.SetDialogueObjID(object_ids[i]);
                }
            }
        } else if(token == "preview_dialogue"){
            DebugText("preview_dialogue", "preview_dialogue", 0.5f);
            if(index == 0 && dialogue_obj_id != -1){
                //camera.SetFlags(kPreviewCamera);
                //SetGUIEnabled(false);
                Play();
            }
        } else if(token == "save_dialogue"){
		    token_iter.FindNextToken(msg);
            string path = token_iter.GetToken(msg);
            Print("Path token: "+path+"\n");
            SaveToFile(path);
        } else if(token == "load_dialogue_pose"){
		    token_iter.FindNextToken(msg);
            string path = token_iter.GetToken(msg);
            
            int id = -1;
            int num_strings = int(strings.size());
            for(int i=0; i<num_strings; ++i){
                if(strings[i].obj_command == kCharacter && strings[i].spawned_id != -1 && ReadObjectFromID(strings[i].spawned_id).IsSelected()){
                    id = atoi(strings[i].params[0]);
                    break;
                }
            }

            if(id != -1){
                array<string> str_params;
                str_params.resize(2);
                str_params[0] = id;
                str_params[1] = path;

                int last_wait = GetLastWait(selected_line);
                int last_set_animation = -1;
                for(int i=selected_line; i>=0; --i){
                    if(strings[i].obj_command == kSetAnimation && strings[i].params[0] == str_params[0]){
                        last_set_animation = i;
                        break;
                    }
                }
                if(last_set_animation == -1 || last_set_animation < last_wait){
                    AddLine(CreateStringFromParams(kSetAnimation, str_params), last_wait+1);
                } else {
                    strings[last_set_animation].str = CreateStringFromParams(kSetAnimation, str_params);
                    ParseLine(strings[last_set_animation]);
                    strings[last_set_animation].visible = true;
                }
            
                ExecutePreviousCommands(selected_line);
                text_dirty = true;
            }
        }
    }

    bool HasCameraControl() {
        return has_cam_control;
    }

    void Display() {
        if(MediaMode()){
            return;
        }

        // Draw actual dialogue text
        if(show_dialogue && (camera.GetFlags() == kPreviewCamera || has_cam_control)){
            // Draw text background
            HUDImage @blackout_image = hud.AddImage();
            blackout_image.SetImageFromPath("Data/Textures/diffuse_hud.tga");
            blackout_image.position.y = 0;
            blackout_image.position.x = 0.0f;
            blackout_image.position.z = -2.0f;
            blackout_image.scale = vec3(GetScreenWidth()/16.0f, GetScreenHeight()/4.0f/16.0f, 1.0f);
            blackout_image.color = vec4(0.0f,0.0f,0.0f,0.7f);

            int font_size = int(max(18, min(GetScreenHeight() / 30, GetScreenWidth() / 50)));

            // Set up font style and canvas
            TextCanvasTexture @text = level.GetTextElement(text_id);
            text.ClearTextCanvas();
            string font_str = "Data/Fonts/arial.ttf";
            TextStyle small_style, big_style;
            small_style.font_face_id = GetFontFaceID(font_str, font_size);

            // Draw speaker name to canvas
            vec2 pen_pos = vec2(0,font_size);
            text.SetPenPosition(pen_pos);
            text.SetPenColor(255,255,255,160);
            text.SetPenRotation(0.0f);
            text.AddText(dialogue_name+":", small_style, UINT32MAX);
        
            // Draw dialogue text to canvas
            text.SetPenColor(255,255,255,255);
            int br_size = font_size;
            pen_pos.x += 40;
            pen_pos.y += br_size;
            text.SetPenPosition(pen_pos);

            //uint len_in_bytes = GetLengthInBytesForNCodepoints(dialogue_text,uint(dialogue_text_disp_chars));
            //string display_dialogue_text = dialogue_text.substr(0,int(len_in_bytes));
            
            text.AddTextMultiline(dialogue_text, small_style, uint(dialogue_text_disp_chars));

            // Draw text canvas to screen
            text.UploadTextCanvasToTexture();
            HUDImage @text_image = hud.AddImage();
            text_image.SetImageFromText(level.GetTextElement(text_id)); 
            text_image.position.x = text_id_position_x;
            text_image.position.y = GetScreenHeight()/4.0f-210;
            text_image.position.z = 4;
            text_image.color = vec4(1,1,1,1);
        }

        // Draw editor text
        if(show_editor_info && !has_cam_control && EditorModeActive()){
            if(text_dirty){
                TextCanvasTexture @editor_text = level.GetTextElement(editor_text_id);
                editor_text.ClearTextCanvas();
                int font_size = 14;
                TextStyle small_style, big_style;
                small_style.font_face_id = GetFontFaceID("Data/Fonts/inconsolata.ttf", font_size);
                big_style.font_face_id = GetFontFaceID("Data/Fonts/inconsolata.ttf", font_size);

                vec2 pen_pos = vec2(0,font_size);
                uint num_strings = strings.size();

				TextMetrics metrics;
				string test_string = "test";
				editor_text.GetTextMetrics(test_string, small_style, metrics, UINT32MAX);
				int cur_pos = selected_line * (metrics.bounds_y / 64); // font_size should do this too?
				uint i = 0;

				while(cur_pos > 600) {
					cur_pos = (selected_line - ++i) * (metrics.bounds_y / 64);
				}

                for(; i<num_strings; ++i){
                    bool show_invisible = false;
                    if(!strings[i].visible && !show_invisible){
                        continue;
                    }
                    editor_text.SetPenPosition(pen_pos);
                    int opac = 255;
                    if(!strings[i].visible){
                        opac = 128;
                    }
                    if(strings[i].locked){
                        editor_text.SetPenColor(0,0,125,opac);
                    } else if(strings[i].record_locked){
                        editor_text.SetPenColor(125,0,0,opac);
                    }else {
                        editor_text.SetPenColor(0,0,0,opac);
                    }
                    editor_text.SetPenRotation(0.0f);
                    string disp = strings[i].str;
                    if(strings[i].obj_command == kUnknown){
                        ParseLine(strings[i]);
                    }
   /* kUnknown,
    kCamera,
    kHeadTarget,
    kEyeTarget,
    kChestTarget,
    kCharacter,
    kCharacterDialogueControl,
    kDialogueVisible,
    kDialogueName,
    kSetDialogueText,
    kAddDialogueText,
    kCharacterStartTalking,
    kCharacterStopTalking,
    kWait,
    kWaitForClick,
    kSetCamControl,
    kSetAnimation,
    kSay*/
                    if(strings[i].obj_command != kSay){
                        continue;
                    } else {
                        int name_len = strings[i].params[1].length;
                        string padding;
                        for(int pad=0, len=max(0, 8 - name_len); pad<len; ++pad){
                            padding += " ";
                        }
                        disp = strings[i].params[1] + ": " + padding + strings[i].params[2];
                        if(strings[i].params[0] == "1"){
                            editor_text.SetPenColor(50,0,0,opac);
                        }
                        if(strings[i].params[0] == "2"){
                            editor_text.SetPenColor(0,50,0,opac);
                        }
                        if(strings[i].params[0] == "3"){
                            editor_text.SetPenColor(0,0,50,opac);
                        }
                    }

                    switch(strings[i].obj_command){
                        case kCharacter: disp = strings[i].params[0] + " Move"; break;
                        case kCamera: disp = "Camera"; break;
                        case kHeadTarget: disp = strings[i].params[0] + " Head"; break;
                        case kEyeTarget: disp = strings[i].params[0] + " Eye"; break;
                        case kChestTarget: disp = strings[i].params[0] + " Torso"; break;
                        case kSetAnimation: disp = strings[i].params[0] + " Pose"; break;
                        case kUnknown: continue;
                    }
					if(uint(selected_line) == i){
						if(edit_mode){
							editor_text.SetPenColor(0,125,0,opac);
							editor_text.AddText(edit_text, big_style, UINT32MAX);
						} else {
                            editor_text.AddText(disp, big_style, UINT32MAX);
                            editor_text.SetPenPosition(pen_pos + vec2(1,1));
                            editor_text.AddText(disp, big_style, UINT32MAX);
						}
                    } else {
                        editor_text.AddText(disp, small_style, UINT32MAX);
                    }
                    pen_pos.y += font_size;
                }
                editor_text.UploadTextCanvasToTexture();
                SaveScriptToParams();
                text_dirty = false;
            }
             
            if(camera.GetFlags() == kEditorCamera){
                // Draw text canvas to screen
                HUDImage @text_image = hud.AddImage();
                text_image.SetImageFromText(level.GetTextElement(editor_text_id)); 
                text_image.position.x = GetScreenWidth()/2-256+70;
                text_image.position.y = GetScreenHeight()-512-100;
                text_image.position.z = 4;
                text_image.color = vec4(1,1,1,1);
            }
        }
    }

    void SaveHistoryState(SavedChunk@ chunk) {
        Print("Called Dialogue::SaveHistoryState\n");
        string str = dialogue_obj_id + " ";
        str += selected_line + " ";
        str += recording + " ";
        chunk.WriteString(str);
    }

    void ReadChunk(SavedChunk@ chunk) {
        Print("Called Dialogue::ReadChunk\n");
        history_str = chunk.ReadString();
        Print("Read "+history_str+"\n");
    }

    void LoadHistoryStr(){
        Print("Loading history str\n");
        TokenIterator token_iter;
        token_iter.Init();
        token_iter.FindNextToken(history_str);
        SetDialogueObjID(atoi(token_iter.GetToken(history_str)));
        token_iter.FindNextToken(history_str);
        selected_line = atoi(token_iter.GetToken(history_str));
        token_iter.FindNextToken(history_str);
        SetRecording(token_iter.GetToken(history_str)=="true");
        HandleSelectedString(selected_line);
        history_str = "";
    }

    void TextInput( string text )
    {
		if(edit_mode) {
			string input = text;
			if (input.length() == 1) {
				edit_text += input;
			}
			text_dirty = true;
		}
    }

    void KeyPressed( string command, bool repeated )
    {
        if(strings.size() > 0 && show_editor_info && !has_cam_control && EditorModeActive()){
            // Handle up/down dialogue editor navigation
            if(command == "down" && !edit_mode){
                int num_lines = int(strings.size());
                int i = selected_line + 1;
                if(GetInputDown(controller_id, "shift")){
                    while(i < num_lines && strings[i].obj_command != kWaitForClick && strings[i].obj_command != kSay){
                        ++i;
                    }
                } else {
                    while(i < num_lines && !strings[i].visible){
                        ++i;
                    }
                }
                if(i < num_lines && strings[i].visible){
                    selected_line = i;
                }
                text_dirty = true;
                HandleSelectedString(selected_line);
                if(recording){
                    UpdateRecordLocked();
                }
                ClearUnselectedObjects();
            }
            if(command == "up" && !edit_mode){
                int i = selected_line - 1;
                if(GetInputDown(controller_id, "shift")){
                    while(i > 0 && strings[i].obj_command != kWaitForClick && strings[i].obj_command != kSay){
                        --i;
                    }
                } else {
                    while(i > 0 && !strings[i].visible){
                        --i;
                    }
                }
                if(i >= 0 && strings[i].visible){
                    selected_line = i;
                }
                text_dirty = true;
                HandleSelectedString(selected_line);
                if(recording){
                    UpdateRecordLocked();
                }
                ClearUnselectedObjects();
            }
            if(command == "return"){
                if (!edit_mode) {
                    StartTextInput();
                    edit_mode = true;
                    Log(info, "Starting input limitation");
                    edit_text = strings[selected_line].str;
                    text_dirty = true;
                } else {
                    StopTextInput();
                    edit_mode = false;
                    Log(info, "Ending input limitation");
                    strings[selected_line].str = edit_text;
                    UpdateParams(edit_text, dialogue_obj_id);
                    SetupDialogueObjectConnectors(dialogue_obj_id);
                    text_dirty = true;
                }
            }
            if(command == "backspace" && edit_mode) {
                edit_text = edit_text.substr(0, edit_text.length - 1);
                text_dirty = true;
            }
            if(command == "keypad+") {
                // add new line
                AddLine("", selected_line + 1);
                text_dirty = true;
            }
            if(command == "keypad-") {
                // delete line
                DeleteLine(selected_line);
                edit_mode = false;
                Log(info, "Ending input limitation");
                text_dirty = true;
            }
        }
        // Lock selected dialogue script line
        if( command == "f" && repeated == false ) {
            if(selected_line >= 0 && selected_line < int(strings.size())){
                strings[selected_line].locked = !strings[selected_line].locked;
                text_dirty = true;
            }
        }
        // Toggle recording
        if(GetInputDown(controller_id, "ctrl") && command == "r" && repeated == false){
            SetRecording(!recording);
            UpdateRecordLocked();
        }
        // Navigate left-right through dialogue script options
        if( command == "right" && repeated == false){
            if(set_animation_char_select != -1){
                ++set_animation_pose_select;
                if(set_animation_pose_select >= int(dialogue_poses.size())){
                    set_animation_pose_select = 0;
                }
                strings[selected_line].str = "send_character_message "+set_animation_char_select+
                    " \"set_animation \\\""+dialogue_poses[set_animation_pose_select]+"\\\"\"";
                ExecutePreviousCommands(selected_line);
                text_dirty = true;
            }
        }
        if( command == "left" && repeated == false){
            if(set_animation_char_select != -1){
                --set_animation_pose_select;
                if(set_animation_pose_select < 0){
                    set_animation_pose_select = int(dialogue_poses.size());
                }
                strings[selected_line].str = "send_character_message "+set_animation_char_select+
                    " \"set_animation \\\""+dialogue_poses[set_animation_pose_select]+"\\\"\"";
                ExecutePreviousCommands(selected_line);
                text_dirty = true;
            }
        }

    }

    void KeyReleased( string command )
    {

    }

    uint PollKeyboardFocus()
    {
        if( edit_mode )
        {
            return KIMF_LEVEL_EDITOR_DIALOGUE_EDITOR;
        }
        else
        {
            return KIMF_NO;
        }
    }
};

