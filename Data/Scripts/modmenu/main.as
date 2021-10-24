#include "menu_common.as"
#include "music_load.as"

MusicLoad ml("Data/Music/menu.xml");

IMGUI imGUI;
int num_mods = 0;
int show_nr_mods = 3;
int shift_amount = 1;
array<WaitingAnimation@> waiting_anims;
IMPulseAlpha waiting_pulse(1.0f, 0.0f, 1.0f);
ModSearch search;
array<ModID> current_mods;
int last_shift_direction = 0;

class WaitingAnimation{
	IMContainer@ parent;
	IMContainer@ holder;
	IMImage@ image;
	float timer = 0.0f;
	bool added = false;
	bool delete_this = false;
	ModID mod_id;
	bool subscribed;
	void Activate(){}
	void Update(){}
	void CheckSubscriptionState(){
		if(added){
			if(subscribed != ModCanActivate(mod_id)){
				imGUI.receiveMessage( IMMessage("refresh_menu_by_id") );
				subscribed = ModCanActivate(mod_id);
				delete_this = true;
			}
		}
	}
}

class Spinner : WaitingAnimation{
	Spinner(IMContainer@ _holder, IMContainer@ _parent, ModID _mod_id){
		@parent = @_parent;
		@holder = @_holder;
		mod_id = _mod_id;
		//Current state of subscribed.
		subscribed = ModCanActivate(mod_id);
	}
	void Activate(){
		if(image is null){
			holder.clear();
			parent.clearMouseOverBehaviors();
			parent.clearLeftMouseClickBehaviors();
			IMImage spinner_image(spinner_icon);
			spinner_image.scaleToSizeX(50.0f);
			spinner_image.setZOrdering(6);
			@image = @spinner_image;
			holder.setElement(spinner_image);
			added = true;
		}
	}
	void Update(){
		CheckSubscriptionState();
		if(added){
			float speed = 120.0f;
			float new_rotation = image.getRotation() + time_step * speed;
			if(new_rotation > 360){
				image.setRotation(0.0f);
			}else{
				image.setRotation(new_rotation);
			}
		}
	}
}

class Pulse : WaitingAnimation{
	Pulse(IMContainer@ _holder, IMContainer@ _parent, ModID _mod_id){
		@parent = @_parent;
		@holder = @_holder;
		mod_id = _mod_id;
		//Current state of subscribed.
		subscribed = IsWorkshopSubscribed(mod_id);
	}
	void Activate(){
		if(image is null){
			holder.clear();
			parent.clearLeftMouseClickBehaviors();
			IMImage spinner_image(spinner_icon);
			spinner_image.scaleToSizeX(50.0f);
			spinner_image.setZOrdering(6);
			@image = @spinner_image;
			holder.setElement(spinner_image);
			spinner_image.addUpdateBehavior(waiting_pulse, "pulse");
			added = true;
		}
	}
	void Update(){
		CheckSubscriptionState();
	}
}

void ResetModsList(){
	current_mods = GetModSids();
}

bool HasFocus() {
    return false;
}

void Initialize() {

    // Start playing some music
	PlaySong("overgrowth_main");

    // We're going to want a 100 'gui space' pixel header/footer
    imGUI.setHeaderHeight(200);
    imGUI.setFooterHeight(200);
	
	ReloadMods();

    // Actually setup the GUI -- must do this before we do anything
    imGUI.setup();
	
	current_mods = GetModSids();

    IMDivider mainDiv( "mainDiv", DOVertical );
    mainDiv.setAlignment(CACenter, CACenter);
	CreateModMenu(mainDiv, 0);
	
	AddModsHeader();
	search.SetCollection(current_mods);
	
    // Add it to the main panel of the GUI
    imGUI.getMain().setElement( @mainDiv );
    AddBackButton();
	
	setBackGround();
}

bool CanShift(int direction){
	int new_start_item = search.current_index + (shift_amount * direction);
	if(new_start_item <= num_mods - show_nr_mods && new_start_item > -1){
		return true;
	} else{
		return false;
	}
}

void CreateModMenu(IMDivider@ parent, int start_at){
	int max_mods = 3;
	int mods_added = 0;
	float holder_width = 2200;
	float holder_height = 900;
	
	IMDivider mods_holder("mods_holder", DOVertical);

	IMContainer mods_container(holder_width, holder_height);
	mods_container.setElement(mods_holder);
	
	num_mods = current_mods.size();
	for(uint i = start_at; mods_added < max_mods && i < current_mods.size(); i++, mods_added++){
		bool fadein = false;
		if(last_shift_direction == -1){
			if(i == uint(start_at)){
				fadein = true;
			}
		}else if(last_shift_direction == 1){
			if(mods_added == (max_mods - 1)){
				fadein = true;
			}
		}
		IMContainer@ new_mod_item = AddModItem(mods_holder, current_mods[i], fadein, i);
	}
	last_shift_direction = 0;
	AddNextPageArrow(parent, -1);
	parent.append(mods_container);
	AddNextPageArrow(parent, 1);
}

void AddNextPageArrow(IMDivider@ parent, int direction){
	float arrow_width = 400.0f;
	float arrow_height = 50.0f;
	//The extra space is needed for the arrow scaleonmouseover animation, or else they push the other elements.
	float extra = 50.0f;

	IMImage arrow( navigation_arrow_slim );
	IMContainer arrow_container("arrow_container" + direction, DOHorizontal);
	arrow_container.setSize(vec2(arrow_width + extra, arrow_height + extra));
	/*arrow_container.showBorder();
	arrow.showBorder();*/
	if(CanShift(direction)){
		if(kAnimateMenu){
			arrow.addUpdateBehavior(IMMoveIn ( move_in_time, vec2(move_in_distance * -1, 0), inQuartTween ), "");
		}
		arrow.setClip(false);
		if(direction == -1){
			arrow.setRotation(180);
		}
		arrow.scaleToSizeX(arrow_width);
		arrow_container.setSize(vec2(arrow.getSizeX(), arrow.getSizeY()));
		arrow_container.addFloatingElement(arrow, "arrow" + direction, vec2( 0.0f ));
		arrow.setColor(button_font.color);
		arrow.addMouseOverBehavior(mouseover_scale_arrow, "");
		arrow.addLeftMouseClickBehavior( IMFixedMessageOnClick("shift_menu", direction), "");
		AddControllerItem(arrow, IMMessage("shift_menu", direction), false);
	}
	parent.append(arrow_container);
}

IMContainer@ AddModItem(IMDivider@ parent, ModID mod_id, bool fadein, int index){
	float mod_item_width = 2000;
	float mod_item_height = 300;
	float main_background_offset = 50.0f;
	int fadein_time = 250;
	bool steamworks_mod = IsWorkshopMod(mod_id);
	string validity = ModGetValidityString(mod_id);
	string mod_path = ModGetPath(mod_id);
	
	IMContainer mod_item_container(mod_item_width, mod_item_height);
	mod_item_container.setAlignment(CALeft, CACenter);
	IMDivider mod_item_divider("mod_item_divider", DOHorizontal);
	mod_item_container.setElement(mod_item_divider);
	mod_item_divider.appendSpacer(main_background_offset);
	
	//The main background
	IMImage main_background( white_background );
	if(fadein){
		main_background.addUpdateBehavior(IMFadeIn( fadein_time, inSineTween ), "");
	}
	main_background.setZOrdering(1);
	mod_item_container.addFloatingElement(main_background, "main_background", vec2(main_background_offset, main_background_offset));
    main_background.setSize(vec2(mod_item_width - (main_background_offset*2), mod_item_height - (main_background_offset*2)));
    main_background.setColor(button_background_color);
	
	//The activate button
	float diamond_size = 200.0f;
	vec4 diamond_color(0.1f,0.1f,0.1f,1.0f);
	vec4 title_background_color(0.2f,0.2f,0.2f,1.0f);
	float checkbox_size = 50.0f;
	float extra = 25.0f;
	vec2 preview_image_size(450, 250);
	vec2 description_size(950, 250);
	vec2 buttons_size(300, 50);
	float button_vert_offset = 15.0f;
	float checkmark_size = 50.0f;
	vec4 error_color(1.0f,0.0f,0.0f,1.0f);
	vec4 ok_color(0.0f,1.0f,0.0f,1.0f);
	
	IMContainer button_container(diamond_size, diamond_size);
	IMDivider button_divider("button_divider", DOVertical);
	button_divider.setZOrdering(4);
	
	IMImage diamond_background( white_background );
	if(fadein){
		diamond_background.addUpdateBehavior(IMFadeIn( fadein_time, inSineTween ), "");
	}
	diamond_background.setZOrdering(3);
	diamond_background.setRotation(45);
	diamond_background.setClip(false);
	diamond_background.setSize(vec2(diamond_size,diamond_size));
	diamond_background.setColor(diamond_color);
	
	IMContainer checkbox_container(checkbox_size, checkbox_size);
	checkbox_container.setAlignment(CACenter, CACenter);
	button_divider.append(checkbox_container);
	
	IMImage checkbox_image(checkbox);
	if(fadein){
		checkbox_image.addUpdateBehavior(IMFadeIn( fadein_time, inSineTween ), "");
	}
	checkbox_image.addMouseOverBehavior(mouseover_scale_button, "");
	checkbox_image.setZOrdering(0);
	checkbox_image.setClip(false);
	checkbox_image.setSize(vec2(checkbox_size));
	checkbox_container.addFloatingElement(checkbox_image, "checkbox_image", vec2(0));
	IMMessage on_click("", ModGetID(mod_id));
	//Mod has some kind of error.
	if(!ModCanActivate(mod_id)){
		checkbox_image.setColor(error_color);
		IMContainer exclamation_mark_container(checkmark_size, checkmark_size);
		IMText exclamation_mark("!", button_font_small);
		if(fadein){
			exclamation_mark.addUpdateBehavior(IMFadeIn( fadein_time, inSineTween ), "");
		}
		exclamation_mark.setZOrdering(6);
		exclamation_mark_container.setElement(exclamation_mark);
		exclamation_mark.setColor(error_color);
		checkbox_container.addFloatingElement(exclamation_mark_container, "exclamation_mark", vec2(0));
		
		IMMessage add_tooltip("add_tooltip", validity);
		add_tooltip.addInt(gui_elements.size());
		
		IMMessage remove_tooltip("remove_tooltip");
		remove_tooltip.addInt(gui_elements.size());
		
		IMMessage do_nothing("");
		checkbox_container.addMouseOverBehavior(IMFixedMessageOnMouseOver(add_tooltip, do_nothing, remove_tooltip), "");
	}
	//Mod is valid
	else{
		if(ModIsActive(mod_id)){
			IMImage checkmark_image(checkmark);
			if(fadein){
				checkmark_image.addUpdateBehavior(IMFadeIn( fadein_time, inSineTween ), "");
			}
			checkmark_image.setColor(ok_color);
			checkmark_image.scaleToSizeX(checkmark_size);
			checkmark_image.setClip(false);
			checkbox_container.addFloatingElement(checkmark_image, "checkmark", vec2(0));
		}
		on_click.name = "toggle_mod";
		on_click.addInt(index);
		checkbox_container.addLeftMouseClickBehavior(IMFixedMessageOnClick(on_click), "");
	}
	AddControllerItem(diamond_background, on_click);
	button_container.setElement(button_divider);
	button_container.addFloatingElement(diamond_background, "diamond_background", vec2(0));
	mod_item_divider.append(button_container);
	
	mod_item_divider.appendSpacer(25.0f);
	
	//The preview image
	IMContainer preview_image_container(preview_image_size.x, preview_image_size.y);
	IMImage background_preview_image(white_background);
	if(fadein){
		background_preview_image.addUpdateBehavior(IMFadeIn( fadein_time, inSineTween ), "");
	}
	background_preview_image.setColor(title_background_color);
	background_preview_image.setSize(preview_image_size);
	background_preview_image.setZOrdering(2);
	background_preview_image.setClip(false);
	preview_image_container.addFloatingElement(background_preview_image, "background_preview_image", vec2(0));
	mod_item_divider.append(preview_image_container);
	
	IMImage@ preview_image = ModGetThumbnailImage(mod_id);
	if(fadein){
		preview_image.addUpdateBehavior(IMFadeIn( fadein_time, inSineTween ), "");
	}
	preview_image.setSize(preview_image_size - 25.0f);
	preview_image.setZOrdering(4);
	preview_image_container.setElement(preview_image);

	mod_item_divider.appendSpacer(25.0f);

	//Description and title
	IMContainer description_container(description_size.x, description_size.y);
	description_container.setAlignment(CACenter, CATop);
	IMDivider description_divider("description_divider", DOVertical);
	description_container.setElement(description_divider);

	description_divider.setAlignment(CALeft, CACenter);
	description_divider.setZOrdering(4);

	IMContainer title_container(description_size.x, 60.0f);
	title_container.setAlignment(CALeft, CABottom);
	description_divider.append(title_container);
	IMImage title_background( white_background );
	if(fadein){
		title_background.addUpdateBehavior(IMFadeIn( fadein_time, inSineTween ), "");
	}
	title_background.setSize(title_container.getSize());
	title_background.setColor(title_background_color);
	title_container.addFloatingElement(title_background, "title_background", vec2(0));
	title_background.setZOrdering(3);
	
	description_divider.appendSpacer(15.0f);
	
	//Title
	IMText title_text("  " + ModGetName(mod_id), button_font_small);
	if(fadein){
		title_text.addUpdateBehavior(IMFadeIn( fadein_time, inSineTween ), "");
	}
	title_text.setZOrdering(4);
	title_container.setElement(title_text);
	string description = ModGetDescription(mod_id);
	IMText@ current_line = IMText("", small_font);
	if(fadein){
		current_line.addUpdateBehavior(IMFadeIn( fadein_time, inSineTween ), "");
	}
	description_divider.append(current_line);
	int num_lines = 1;
	int max_lines = 3;
	int line_chars = 0;
	int max_char_per_line = 55;
	
	for(uint i = 0; i < description.length(); i++){
		string new_character('0');
		new_character[0] = description[i];
		if(new_character == "\n"){
			continue;
		}
		current_line.setText( current_line.getText() + new_character);
		line_chars++;
		if(line_chars > max_char_per_line){
			num_lines++;
			if(num_lines > max_lines){
				break;
			}
			line_chars = 0;
			IMText new_line("", small_font);
			if(fadein){
				new_line.addUpdateBehavior(IMFadeIn( fadein_time, inSineTween ), "");
			}
			@current_line = @new_line;
			description_divider.append(@current_line);
		}
	}	
	mod_item_divider.append(description_container);
	
	mod_item_divider.appendSpacer(25.0f);
	
	//The play configure and details buttons at the end.
	IMContainer buttons_container(buttons_size.x, buttons_size.y);
	IMDivider buttons_divider("buttons_divider", DOVertical);
	buttons_container.setElement(buttons_divider);
	buttons_divider.setZOrdering(4);
	
	bool can_be_configured = false;
	if(can_be_configured){
		IMContainer configure_button_container(buttons_size.x, buttons_size.y + button_vert_offset);
		configure_button_container.addLeftMouseClickBehavior(IMFixedMessageOnClick("configure", ModGetID(mod_id)), "");
		AddControllerItem(configure_button_container, IMMessage("configure", ModGetID(mod_id)));
		IMText configure_button_text("Configure", button_font_small);
		if(fadein){
			configure_button_text.addUpdateBehavior(IMFadeIn( fadein_time, inSineTween ), "");
		}
		configure_button_container.setZOrdering(4);
		configure_button_text.setZOrdering(6);
		configure_button_container.setElement(configure_button_text);
		IMImage configure_button_background( white_background );
		configure_button_background.setSize(buttons_size);
		if(fadein){
			configure_button_background.addUpdateBehavior(IMFadeIn( fadein_time, inSineTween ), "");
		}
		configure_button_background.setColor(title_background_color);
		configure_button_container.addFloatingElement(configure_button_background, "configure_button_background", vec2(0, button_vert_offset / 2.0f));
		buttons_divider.append(configure_button_container);
	}

	if(steamworks_mod){
		//Detail button
		IMContainer details_button_container(buttons_size.x, buttons_size.y + button_vert_offset);
		IMMessage details_message("details", index);
		details_button_container.addLeftMouseClickBehavior(IMFixedMessageOnClick(details_message), "");
		AddControllerItem(details_button_container, IMMessage("details", ModGetID(mod_id)));
		details_button_container.sendMouseOverToChildren(true);
		IMDivider details_button_divider("details_button_divider", DOHorizontal);
		details_button_container.setElement(details_button_divider);
		details_button_container.setZOrdering(4);
		
		IMImage small_steam_image( steam_icon );
		if(fadein){
			small_steam_image.addUpdateBehavior(IMFadeIn( fadein_time, inSineTween ), "");
		}
		small_steam_image.setColor(small_font.color);
		small_steam_image.addMouseOverBehavior( text_color_mouse_over, "" );
		small_steam_image.setSize(vec2(50.0f));
		details_button_divider.append(small_steam_image);
		small_steam_image.setZOrdering(6);
		
		details_button_divider.appendSpacer(5.0f);
		
		IMText details_button_text("Details", button_font_small);
		if(fadein){
			details_button_text.addUpdateBehavior(IMFadeIn( fadein_time, inSineTween ), "");
		}
		details_button_text.addMouseOverBehavior( text_color_mouse_over, "" );
		details_button_divider.append(details_button_text);
		details_button_text.setZOrdering(6);
		IMImage details_button_background( white_background );
		if(fadein){
			details_button_background.addUpdateBehavior(IMFadeIn( fadein_time, inSineTween ), "");
		}
		details_button_background.setSize(buttons_size);
		details_button_background.setColor(title_background_color);
		
		details_button_container.addFloatingElement(details_button_background, "details_button_background", vec2(0, button_vert_offset / 2.0f));
		buttons_divider.append(details_button_container);
		
		//Unsubscribe button
		IMContainer subscribe_button_container(buttons_size.x, buttons_size.y + button_vert_offset);
		subscribe_button_container.sendMouseOverToChildren(true);
		IMText subscribe_button_text("", button_font_small);
		if(fadein){
			subscribe_button_text.addUpdateBehavior(IMFadeIn( fadein_time, inSineTween ), "");
		}
		if(IsWorkshopSubscribed(mod_id)){
			subscribe_button_text.setText("Unsubscribe");
		}else{
			subscribe_button_text.setText("Subscribe");
		}
		subscribe_button_text.addMouseOverBehavior( text_color_mouse_over, "" );
		subscribe_button_container.setZOrdering(4);
		subscribe_button_text.setZOrdering(6);
		IMContainer text_holder(buttons_size.x, buttons_size.y + button_vert_offset);
		text_holder.setElement(subscribe_button_text);
		subscribe_button_container.setElement(text_holder);

		IMMessage subscribe_message("un/subscribe", ModGetID(mod_id));
		subscribe_message.addInt(waiting_anims.size());
		subscribe_message.addInt(index);

		subscribe_button_container.addLeftMouseClickBehavior(IMFixedMessageOnClick(subscribe_message), "");
		AddControllerItem(subscribe_button_container, subscribe_message);
		//Add a spinner for waiting to un/subscribe
		waiting_anims.insertLast(Pulse(text_holder, subscribe_button_container, mod_id));
		//waiting_anims.insertLast(Spinner(text_holder, subscribe_button_container, mod_id));

		IMImage subscribe_button_background( white_background );
		if(fadein){
			subscribe_button_background.addUpdateBehavior(IMFadeIn( fadein_time, inSineTween ), "");
		}
		subscribe_button_background.setSize(buttons_size);
		subscribe_button_background.setColor(title_background_color);
		subscribe_button_container.addFloatingElement(subscribe_button_background, "subscribe_button_background", vec2(0, button_vert_offset / 2.0f));
		buttons_divider.append(subscribe_button_container);
	}	
	mod_item_divider.append(buttons_container);
	if(last_shift_direction != 0){
		mod_item_container.addUpdateBehavior(IMMoveIn ( 250.0f, vec2(0, mod_item_height * last_shift_direction), outExpoTween ), "");
	}
	
	parent.append(mod_item_container);
	gui_elements.insertLast(ModItem(checkbox_container, validity));
	return @mod_item_container;
}

void AddModsHeader(){
	IMContainer header_container(2560, 200);
	IMDivider header_divider( "header_div", DOHorizontal );
	header_container.setElement(header_divider);
	
	AddTitleHeader("Mods", header_divider);
	AddSearchbar(header_divider, @search);
	AddGetMoreMods(header_divider);
	AddAdvanced(header_divider);
	imGUI.getHeader().setElement(header_container);
}

void AddGetMoreMods(IMDivider@ parent){
	//Get More Mods
    if( IsWorkshopAvailable() ) {	
        float get_more_width = 450;
        float get_more_height = 100;
        IMContainer get_more_container(get_more_width, get_more_height);
        get_more_container.sendMouseOverToChildren(true);
        get_more_container.addLeftMouseClickBehavior( IMFixedMessageOnClick("open_workshop"), "");
        AddControllerItem(get_more_container, IMMessage("open_workshop"));
        get_more_container.setZOrdering(0);
        IMDivider get_more_divider("get_more_divider", DOHorizontal);
        get_more_container.setElement(get_more_divider);
        IMImage steam_icon_image( steam_icon );
        steam_icon_image.setColor( button_font_small.color );
        steam_icon_image.addMouseOverBehavior( text_color_mouse_over, "" );
        steam_icon_image.scaleToSizeX(get_more_height);
        get_more_divider.append(steam_icon_image);
        get_more_divider.appendSpacer(25);
        IMText get_more_text( "Get More Mods", button_font_small );
        get_more_text.addMouseOverBehavior( text_color_mouse_over, "" );
        IMImage get_more_background( white_background );
        get_more_background.setSize(vec2(get_more_width, get_more_height));
        get_more_background.setColor(button_background_color);
        get_more_divider.append(get_more_text);
        get_more_container.addFloatingElement(get_more_background, "background", vec2(0,0));
        parent.append(get_more_container);
    }
}

void AddAdvanced(IMDivider@ parent){
	bool show_advanced = false;
	if(show_advanced){
		//Advanced
		float advanced_width = 300;
		float advanced_height = 100;
		IMContainer advanced_container(advanced_width, advanced_height);
		IMText advanced_text( "Advanced", button_font_small );
		advanced_text.setZOrdering(3);
		IMImage advanced_background( white_background );
		advanced_background.setSize(vec2(advanced_width, advanced_height));
		advanced_background.setColor(button_background_color);
		advanced_container.setElement(advanced_text);
		advanced_container.addFloatingElement(advanced_background, "background", vec2(0,0));
		parent.append(advanced_container);
		
		parent.appendSpacer(50);
	}
}

void Dispose() {
	imGUI.clear();
}

bool CanGoBack() {
    return true;
}

void Update() {
	if(!search.active){
		UpdateController();
	}
	UpdateWaitingAnims();
	search.Update();
	UpdateKeyboardMouse();
    // process any messages produced from the update
    while( imGUI.getMessageQueueSize() > 0 ) {
        IMMessage@ message = imGUI.getNextMessage();
        if( message.name == "Back" )
        {
            this_ui.SendCallback( "back" );
        }
        else if( message.name == "load_level" )
        {
            this_ui.SendCallback( "Data/Levels/" + message.getString(0) );
        }
		else if( message.name == "shift_menu" ){
			if(!CanShift(message.getInt(0)))return;
			string current_controller_item_name = GetCurrentControllerItemName();
			ClearControllerItems();
			IMDivider mainDiv( "mainDiv", DOVertical );
			mainDiv.setAlignment(CACenter, CACenter);
			imGUI.getMain().setElement(mainDiv);
			last_shift_direction = message.getInt(0);
			search.current_index = search.current_index + (shift_amount * message.getInt(0));
			CreateModMenu(mainDiv, search.current_index);
			AddModsHeader();
		    AddBackButton();
			SetCurrentControllerItem(current_controller_item_name);
			search.ShowSearchResults();
		}
		else if( message.name == "toggle_mod" ){
			int index = message.getInt(0);
			ModID current_mod = current_mods[index];
			//Print("Toggling " + message.getString(0) + "\n");
			if(ModCanActivate(current_mod)){
				if(ModIsActive(current_mod)){
					ModActivation(current_mod, false);
				}else{
					ModActivation(current_mod, true);
				}
			}else{
				imGUI.reportError("Could not activate mod " + message.getString(0));
			}
			SaveConfig();
			imGUI.receiveMessage( IMMessage("refresh_menu_by_id") );
		}
		else if( message.name == "refresh_menu_by_name" ){
			string current_controller_item_name = GetCurrentControllerItemName();
			/*waiting_anims.resize(0);*/
			ClearControllerItems();
			IMDivider mainDiv( "mainDiv", DOVertical );
			mainDiv.setAlignment(CACenter, CACenter);
			imGUI.getMain().setElement(mainDiv);
			CreateModMenu(mainDiv, search.current_index);
			AddModsHeader();
		    AddBackButton();
			SetCurrentControllerItem(current_controller_item_name);
			search.ShowSearchResults();
		}
		else if( message.name == "refresh_menu_by_id" ){
			int index = GetCurrentControllerItemIndex();
			/*waiting_anims.resize(0);*/
			ClearControllerItems();
			IMDivider mainDiv( "mainDiv", DOVertical );
			mainDiv.setAlignment(CACenter, CACenter);
			imGUI.getMain().setElement(mainDiv);
			CreateModMenu(mainDiv, search.current_index);
			AddModsHeader();
		    AddBackButton();
			SetCurrentControllerItem(index);
			search.ShowSearchResults();
		}
		else if( message.name == "un/subscribe" ){
			int index = message.getInt(1);
			ModID current_mod = current_mods[index];
			string validity = ModGetValidityString(current_mod);
			if(IsWorkshopSubscribed(current_mod)){
				RequestWorkshopUnSubscribe(current_mod);
			}else{
				RequestWorkshopSubscribe(current_mod);

			}
			waiting_anims[message.getInt(0)].Activate();
		}
		else if( message.name == "details" ){
			//Print("Open steam workshop page for " + message.getString(0) + "\n");
			int index = message.getInt(0);
			ModID current_mod = current_mods[index];
			OpenModWorkshopPage(current_mod);
		}
		else if( message.name == "configure" ){
			//Print("Open configure page for " + message.getString(0) + "\n");
			this_ui.SendCallback("configure.as");
		}
		else if( message.name == "open_workshop" ){
			//Print("Open steam workshop for Overgrowth\n");
			OpenWorkshop();
		}
		else if( message.name == "activate_search" ){
			search.Activate();
		}
		else if( message.name == "clear_search_results" ){
			ResetModsList();
			search.ResetSearch();
			imGUI.receiveMessage( IMMessage("refresh_menu_by_id") );
		}
		else if( message.name == "add_tooltip" ){
			gui_elements[message.getInt(0)].AddTooltip();
		}
		else if( message.name == "remove_tooltip" ){
			gui_elements[message.getInt(0)].RemoveTooltip();
		}
    }
	// Do the general GUI updating
    imGUI.update();
}

ModID getModID(string id){
	array<ModID> all_mods = GetModSids();
	ModID current_mod;
	for(uint i = 0; i < all_mods.size(); i++){
		if(ModGetID(all_mods[i]) == id){
			current_mod = all_mods[i];
			return current_mod;
		}
	}
	return current_mod;
}

void UpdateWaitingAnims(){
	for(uint i = 0; i < waiting_anims.size(); i++){
		waiting_anims[i].Update();
		if(waiting_anims[i].delete_this){
			waiting_anims.removeAt(i);
		}
	}
}

void Resize() {
    imGUI.doScreenResize(); // This must be called first
	setBackGround();
}

void ScriptReloaded() {
	//Print("Script reloaded!\n");
    // Clear the old GUI
    /*imGUI.clear();*/
    // Rebuild it
    Initialize();
}

void ModActivationReload(){
	//Print("Mods reload!\n");
	/*imGUI.receiveMessage( IMMessage("refresh_menu_by_id") );*/
}

void DrawGUI() {
    imGUI.render();
}

void Draw() {
}

void Init(string str) {
}

class ModSearch : Search{
	array<ModID>@ collection;
	ModSearch(){
		
	}
	void SetCollection(array<ModID>@ _collection){
		@collection = @_collection;
	}
	void GetSearchResults(string query){
		array<ModID> results;
		array<ModID>@ all_mods = GetModSids();
		for(uint i = 0; i < all_mods.size(); i++){
			if(ToLowerCase(ModGetName(all_mods[i])).findFirst(query) != -1){
				results.insertLast(all_mods[i]);
				continue;
			}else if(ToLowerCase(ModGetDescription(all_mods[i])).findFirst(query) != -1){
				results.insertLast(all_mods[i]);
				continue;
			}
		}
		collection = results;
	}
}
