IMDivider@ settings_content;
string current_screen;
int active_rebind = -1;
int initial_sequence_id;

void BuildUI(string landing_screen){
	float background_height = 1300;
	float background_width = 1600;
	float header_width = 550;
	float header_height = 128;
	
	const bool kAnimate = false;

	gui_elements.resize(0);
	category_elements.resize(0);

	IMContainer main_container(background_width, background_height);
	main_container.setBorderColor(vec4(0,1,0,1));
	float middle_x = main_container.getSizeX() / 2.0f;
	float middle_y = main_container.getSizeY() / 2.0f;
	main_container.setAlignment(CACenter, CACenter);
	IMImage menu_background(settings_sidebar);
	
	IMImage settings_background(white_background);
	settings_background.setSizeX(1200);
	settings_background.setSizeY(1200);
	settings_background.setZOrdering(0);
	settings_background.setColor(vec4(0,0,0,0.85f));

	if(kAnimate){
		menu_background.addUpdateBehavior(IMMoveIn ( move_in_time, vec2(0, move_in_distance * -1), inQuartTween ), "");
	}
	IMDivider mainDiv( "mainDiv", DOHorizontal );
	
	menu_background.setSizeY(background_height);
	menu_background.setSizeX(350);
	menu_background.setZOrdering(0);
	
    mainDiv.setAlignment(CACenter, CACenter);
	mainDiv.setSize(vec2(main_container.getSizeX(), main_container.getSizeY()));
	
    IMDivider buttons_holder(DOVertical);
	buttons_holder.setSize(vec2(600, mainDiv.getSizeY()));
	buttons_holder.setBorderColor(vec4(1,0,0,1));

    IMImage header_background( brushstroke_background );
    if(kAnimate){
		header_background.addUpdateBehavior(IMMoveIn ( move_in_time, vec2(0, move_in_distance * -1), inQuartTween ), "");
	}
	header_background.scaleToSizeX(header_width);
    header_background.setColor(button_background_color);
    IMDivider header_holder("header_holder", DOHorizontal);
    IMText header_text("Settings", button_font);
    if(kAnimate){
		header_text.addUpdateBehavior(IMMoveIn ( move_in_time, vec2(0, move_in_distance * -1), inQuartTween ), "");
	}
	IMContainer header_container(header_background.getSizeX(), header_background.getSizeY());
    header_container.setElement(header_text);
    header_container.setAlignment(CACenter, CACenter);
    header_text.setZOrdering(3);
    header_container.addFloatingElement(header_background, "background", vec2(0.0f, (0.0f)), 1);
    header_holder.append(header_container);
    buttons_holder.append(header_holder);
	buttons_holder.setBorderColor(vec4(0,0,1,1));

	buttons_holder.append(IMSpacer(DOVertical, 25.0f));

    buttons_holder.setAlignment(CACenter, CACenter);
	
    mainDiv.append(buttons_holder);
	AddCategoryButton("Graphics", buttons_holder);
	AddCategoryButton("Audio", buttons_holder);
	AddCategoryButton("Game", buttons_holder);
	AddCategoryButton("Input", buttons_holder);

	buttons_holder.append(IMSpacer(DOVertical, 200.0f));

    AddButton("Back", buttons_holder, arrow_icon, button_back, true, 350.0f, 10.0f);
	
	IMDivider temp_settings_content("settings_content", DOVertical);
	temp_settings_content.setAlignment(CALeft, CACenter);
	@settings_content = @temp_settings_content;
		
	mainDiv.append(settings_content);
	
	main_container.addFloatingElement(mainDiv, "menu_content", vec2(0.0f, middle_y - mainDiv.getSizeY() / 2.0f), 0);
	main_container.addFloatingElement(menu_background, "menu_background", vec2(buttons_holder.getSizeX() / 2.0f - menu_background.getSizeX() / 2.0f, middle_y - menu_background.getSizeY() / 2.0f), 0);
	main_container.addFloatingElement(settings_background, "settings_background", vec2(buttons_holder.getSizeX() / 2.0f, middle_y - settings_background.getSizeY() / 2.0f), 0);
	
	settings_background.addLeftMouseClickBehavior(IMFixedMessageOnClick("close_all_open_menus"), "");
	imGUI.getMain().setElement(@main_container);
	current_screen = "none";
	SwitchSettingsScreen(landing_screen);
	controller_wraparound = false;
}

void RestoreCategoryButtons(){
	for(uint i = 0; i < category_elements.size(); i++){
		if(category_elements[i].element_open){
			category_elements[i].DisableElement();
			category_elements[i].element_open = false;
		}
	}
}

void SetActiveCategory(string name){
	for(uint i = 0; i < category_elements.size(); i++){
		if(category_elements[i].name == name){
			category_elements[i].EnableElement();
		}
	}
}

void SwitchSettingsScreen(string screen_name){
	settings_content.clear();
	gui_elements.resize(0);

	ClearControllerItems(category_elements.size() + 1);

	RestoreCategoryButtons();
	SetActiveCategory(screen_name);
	
	if(screen_name == "Graphics"){
		AddGraphicsScreen();
	}
	else if(screen_name == "Audio"){
		AddAudioScreen();
	}
	else if(screen_name == "Game"){
		AddGameScreen();
	}
	else if(screen_name == "Input"){
		AddInputScreen();
	}
	list_created = false;
	current_screen = screen_name;
}

void checkCustomResolution(){
    vec2 currentResolution = vec2(GetConfigValueInt("screenwidth"), GetConfigValueInt("screenheight"));
    array<vec2> possibleResolutions = GetPossibleResolutions();

    bool found = false;
    for(uint i = 0; i < possibleResolutions.size(); ++i) {
        if(possibleResolutions[i] == currentResolution) {
            found = true;
            break;
        }
    }

    // Don't set custom_resolution to true automatically;
    // the user may have entered a possible resolution manually
    if(!found)
        SetConfigValueBool("custom_resolution", true);
}

void AddGraphicsScreen(){
	current_screen = "Graphics";

	array<string> overall_settings = GetConfigValueOptions("overall");
	AddDropDown("Overall", settings_content, DropdownConfiguration(overall_settings, overall_settings, "overall"));

    array<int> monitorIndices;
    array<string> monitorStrings;
    
    int monitorCount = GetMonitorCount();
    for(int i = 0; i < monitorCount; ++i) {
        monitorIndices.insertLast(i);
        monitorStrings.insertLast("" + (i + 1));
    }

    if(monitorCount > 1)
        AddDropDown("Target monitor", settings_content, DropdownConfiguration(monitorIndices, monitorStrings, "target_monitor"));
    
    array<vec2> possible_resolutions = GetPossibleResolutions();
    array<string> resolutions;
    for(uint i = 0; i < possible_resolutions.size(); i++){
        resolutions.insertLast(possible_resolutions[i].x + "x" + possible_resolutions[i].y);
    }
    resolutions.insertLast("Custom");
    
	array<string> config_names = {"screenwidth", "screenheight"};
	AddResolutionDropDown("Resolution", settings_content, DropdownConfiguration(possible_resolutions, resolutions, config_names ));
	
    if(GetConfigValueBool("custom_resolution"))
        AddCustomResolutionInput(settings_content);
    
	array<int> window_type_values = { 0, 1, 2, 3 };
	array<string> window_type_options = { "Windowed", "Fullscreen", "Windowed borderless", "Fullscreen borderless"};
	AddDropDown("Window mode", settings_content, DropdownConfiguration(window_type_values, window_type_options, "fullscreen"));

	array<int> aa_values = { 1, 2, 4, 8 };
	array<string> aa_options = {"none", "2X", "4X", "8X"};
	AddDropDown("Anti-aliasing", settings_content, DropdownConfiguration(aa_values, aa_options, "multisample"));
	
	array<int> anisotropy_values = { 1, 2, 4, 8 };
	array<string> anisotropy_options = {"none", "2X", "4X", "8X"};
	AddDropDown("Anisotropy", settings_content, DropdownConfiguration( anisotropy_values, anisotropy_options, "anisotropy" ));
	
	array<int> texture_detail_values = {0, 1, 2, 3};
	array<string> texture_detail_options = {"Full", "1/2", "1/4", "1/8"};
	AddDropDown("Texture Detail", settings_content, DropdownConfiguration( texture_detail_values, texture_detail_options, "texture_reduce"), "*");

	array<array<int>> detail_object_config_values = { {0, 1, 1, 0}, {1, 1, 1 ,0}, {1, 0, 0, 0}, {1, 0, 0, 1} };
	array<string> detail_object_config_variables = { "detail_objects", "detail_object_lowres", "detail_object_disable_shadows", "detail_object_decals" };
	array<string> detail_object_options = {"Off", "Low", "Medium", "High"};
	AddDropDown("Detail objects", settings_content, DropdownConfiguration( detail_object_config_values, detail_object_options, detail_object_config_variables ), "*");
	AddLabel("*Requires Restart", settings_content);
	
	DualColumns dual_columns("checkboxes_column", 800);
	AddCheckBox("VSync", dual_columns.left, "vsync", 0.0f);
	AddCheckBox("Simple Shadows", dual_columns.left, "simple_shadows", 0.0f);
	AddCheckBox("Simple Fog", dual_columns.left, "simple_fog", 0.0f);
	AddCheckBox("Simple Water", dual_columns.left, "simple_water", 0.0f);
	//AddCheckBox("Use tet mesh lighting", dual_columns, "tet_mesh_lighting");
	//AddCheckBox("Use ambient light volumes", dual_columns, "light_volume_lighting");
	AddCheckBox("GPU Particle Field", dual_columns.right, "particle_field", 0.0f);
	AddCheckBox("Enable Custom Shaders", dual_columns.right, "custom_level_shaders", 0.0f);
	AddCheckBox("No reflection capture", dual_columns.right, "no_reflection_capture", 0.0f);

	settings_content.append(dual_columns.main);
	
	AddSlider("Motion Blur", settings_content, "motion_blur_amount", 1.0f);
	AddSlider("Brightness", settings_content, "brightness", 2.0f, 200.0f);
}

void AddAudioScreen(){
	current_screen = "Audio";
	
	AddSlider("Music volume", settings_content, "music_volume", 1.0f, 100.0f, 0.0f, 0.0f, true);
	AddSlider("Master volume", settings_content, "master_volume", 1.0f, 100.0f, 0.0f, 0.0f, true);
}

void AddGameScreen(){
	current_screen = "Game";

    array<string> difficulty_options = GetConfigValueOptions("difficulty_preset");
	AddDropDown("Difficulty Preset", settings_content, DropdownConfiguration( difficulty_options, difficulty_options, "difficulty_preset" ));

	AddSlider("Game Speed", settings_content, "global_time_scale_mult", 1.0f, 100.0f, 0.5f, 50.0f);
	AddSlider("Game Difficulty", settings_content, "game_difficulty", 1.0f);
	AddCheckBox("Tutorials", settings_content, "tutorials");
	AddCheckBox("Automatic Ledge Grab", settings_content, "auto_ledge_grab");
	
	array<int> blood_amount_values = { 0, 1, 2};
	array<string> blood_amount_options = {"None", "No dripping", "Full"};
	AddDropDown("Blood Amount", settings_content, DropdownConfiguration( blood_amount_values, blood_amount_options, "blood" ));
	
	array<string> blood_color_values = {"0.4 0 0", "0 0.4 0", "0 0.4 0.4", "0.1 0.1 0.1"};
	array<string> blood_color_options = {"Red", "Green", "Cyan", "Black"};
	AddDropDown("Blood Color", settings_content, DropdownConfiguration( blood_color_values, blood_color_options, "blood_color" ));
	AddCheckBox("Splitscreen", settings_content, "split_screen");
}

void AddInputScreen(){
	current_screen = "Input";

	DualColumns dual_columns("input_columns", 800);

	AddCheckBox("Invert mouse X", dual_columns.left, "invert_x_mouse_look", 0.0f);
	AddCheckBox("Invert mouse Y", dual_columns.left, "invert_y_mouse_look", 0.0f);
	AddCheckBox("Invert gamepad X", dual_columns.right, "invert_x_gamepad_look", 0.0f);
	AddCheckBox("Invert gamepad Y", dual_columns.right, "invert_y_gamepad_look", 0.0f);

	AddSlider("Mouse sensitivity", settings_content, "mouse_sensitivity", 2.5f, 200.0f, 0.01f, 1.0f, true);

	settings_content.append(dual_columns.main);

	AddCheckBox("Raw mouse input", settings_content, "use_raw_input");
	AddCheckBox("Automatic camera", settings_content, "auto_camera");

	AddKeyRebind("Forward", settings_content, "key", "up");
	AddKeyRebind("Backwards", settings_content, "key", "down");
	AddKeyRebind("Left", settings_content, "key", "left");
	AddKeyRebind("Right", settings_content, "key", "right");
	
	AddKeyRebind("Jump", settings_content, "key", "jump");
	AddKeyRebind("Crouch", settings_content, "key", "crouch");
	AddKeyRebind("Slow Motion", settings_content, "key", "slow");
	AddKeyRebind("Equip/sheathe item", settings_content, "key", "item");
	AddKeyRebind("Throw/pick-up item", settings_content, "key", "drop");
	AddKeyRebind("Skip dialogue", settings_content, "key", "skip_dialogue");
	
	AddBasicButton("Reset to defaults", "reset_bindings", 400, settings_content);
}

void SaveUnsavedChanges() {
	bool unsaved_values = false;
	for(uint i = 0; i < gui_elements.size(); i++){
		if(gui_elements[i].unsaved_values){
			unsaved_values = true;
			gui_elements[i].SaveValueToConfig();
		}
	}
	if(unsaved_values)
		ReloadStaticValues();
}

void DiscardUnsavedChanges() {
	for(uint i = 0; i < gui_elements.size(); i++){
		if(gui_elements[i].unsaved_values){
			gui_elements[i].PutCurrentValue();
		}
	}
}

void ProcessSettingsMessage(IMMessage@ message){
	if(active_rebind != -1){
		active_rebind = -1;
	}
	CloseAllOptionMenus();
	if( message.name == "ui_element_clicked" ){
		DiscardUnsavedChanges();
		ToggleUIElement(message.getString(0));
	}
	else if( message.name == "option_changed" ){
		DiscardUnsavedChanges();
		for(uint i = 0; i < gui_elements.size(); i++){
			if(gui_elements[i].name == message.getString(0)){
				gui_elements[i].SwitchOption(message.getString(1));
			}
		}
        SwitchSettingsScreen(current_screen); // Possible resolutions may have changed
	}
	else if( message.name == "close_all_open_menus" ){
		DiscardUnsavedChanges();
		CloseAllOptionMenus();
	}
	else if( message.name == "save_unsaved_changes" ){
		SaveUnsavedChanges();
        SwitchSettingsScreen(current_screen);
	}
	else if( message.name == "discard_unsaved_changes" ){
		DiscardUnsavedChanges();
	}
	else if( message.name == "slider_deactivate" ){
		//Print("deactivate slider check\n");
		if(!checking_slider_movement){
			active_slider = -1;
		}
	}
	else if( message.name == "slider_activate" ){
		//Print("activate slider check\n");
		old_mouse_pos = imGUI.guistate.mousePosition;
		active_slider = message.getInt(0);
	}
	else if( message.name == "slider_move_check" ){
		/*continues_updating_element = message.getInt(0);*/
	}
	else if( message.name == "switch_category" ){
        SwitchSettingsScreen(message.getString(0));
	}
	else if( message.name == "rebind_activate" ){
		gui_elements[message.getInt(0)].ToggleElement();
		active_rebind = message.getInt(0);
		array<KeyboardPress> inputs = GetRawKeyboardInputs();
		if(inputs.size() > 0){
			initial_sequence_id = inputs[inputs.size()-1].s_id;
		}else{
			initial_sequence_id = -1;
		}
	}
	else if( message.name == "reset_bindings" ){
		ResetAllKeyBindings();
		RefreshAllOptions();
	}
	else if( message.name == "back" ){
		Log(info,"Received back message");
		if(OptionMenuOpen()){
			CloseAllOptionMenus();
		}else{
			imGUI.receiveMessage(IMMessage("Back"));
		}
	}
    else if(message.name == "enable_element"){
		if(message.numStrings() > 0) {
			string target_name = message.getString(0);

			for(uint i = 0; i < gui_elements.size(); ++i) {
				if(gui_elements[i].name == target_name) {
					gui_elements[i].EnableElement();
					break;
				}
			}
		}
    }
    else{
		Log( info, "Unknown processMessage " + message.getString(0) );
	}
}

void UpdateSettings(){
	UpdateMovingSlider();
	UpdateKeyRebinding();

	for(uint i = 0; i < gui_elements.size(); i++) {
		gui_elements[i].Update();
	}
}

void UpdateKeyRebinding(){
	if(active_rebind != -1){
		array<KeyboardPress> inputs = GetRawKeyboardInputs();
		if(inputs.size() > 0){
			KeyboardPress last_pressed = inputs[inputs.size()-1];
			if( last_pressed.s_id != uint16(initial_sequence_id) ) {
				//If pressed esc then do nothing.
				if(last_pressed.keycode == 27){
					Log(info,"Skipping key rebinding because esc.");
				}else{
					gui_elements[active_rebind].SwitchOption(last_pressed.scancode);
				}
				active_rebind = -1;
			}
		}
	}
}
