#include "controller.as"
// Common items for all menus in the system

string col = "#fff";
vec4 white = HexColor(col);
vec4 brightYellow = HexColor("#ffe600");
vec4 mediumYellow = HexColor("#ffde00");
vec4 khakiYellow = HexColor("#8b864e");
vec4 gold = HexColor("#EEC900");
vec4 butterMilk = HexColor("#FEF1B5");
vec4 button_background_color = HexColor("#000000");
vec4 button_border_color = HexColor("#404040");

FontSetup button_font("edosz", 75, HexColor("#CCCCCC"), true);
FontSetup button_font_mouse_over("edosz", 75, HexColor("#FFFFFF"), true);
FontSetup button_font_disabled("edosz", 75, HexColor("#595959"), true);
FontSetup title_font("edosz", 125, HexColor("#CCCCCC"), true);
FontSetup button_font_small("edosz", 50 , HexColor("#CCCCCC"), true);
FontSetup button_font_extra_small("edosz", 35 , HexColor("#CCCCCC"), true);
FontSetup button_font_small_last_played("edosz", 50 , HexColor("#000000"), true);
FontSetup button_font_large("edosz", 60 , HexColor("#CCCCCC"), true);
FontSetup noteFont("OpenSans-Regular", 40, mediumYellow, false);
FontSetup extra_small_font("OptimusPrinceps", 35, HexColor("#CCCCCC"), true);
FontSetup small_font("arial", 45, HexColor("#CCCCCC"), true);
FontSetup creditFontSmall("OptimusPrinceps", 70, white, false);
FontSetup creditFontBig("OptimusPrinceps", 120, white, false);
int move_time = 75;
int move_dist = 12;
int move_dir = 1;
IMMouseOverMove move_button_text( move_time, vec2(move_dist * move_dir, 0), inQuartTween );
IMMouseOverMove move_button_background( move_time, vec2(move_dist * move_dir, 0), inQuartTween );

IMMouseOverScale mouseover_scale( move_time, 50.0f, inQuartTween );
IMMouseOverScale mouseover_scale_background( move_time, 50.0f, inQuartTween );
IMMouseOverScale mouseover_scale_arrow( move_time, 50.0f, inQuartTween );
IMMouseOverScale mouseover_scale_button( move_time, 12.0f, inQuartTween );

int fade_in_time = 500;
int move_in_time = 250;
int move_in_distance = 300;
float text_trailing_space = 40.0f;
float default_button_width = 500.0f;
float menu_width = 2000.0f;
float menu_height = 900.0f;
bool menu_numbered = true;

float checkbox_size = 35.0f;
float checkmark_size = 40.0f;
vec2 old_mouse_pos;
int active_slider = -1;
bool checking_slider_movement = false;

const bool kAnimateMenu = false;

IMMouseOverPulseColor text_color_mouse_over(button_font_mouse_over.color, button_font_mouse_over.color, 5.0f);
IMMouseOverPulseColor mouseover_color_background(vec4(0.1f,0.1f,0.1f,1), vec4(0.1f,0.1f,0.1f,1), 5.0f);
IMPulseAlpha pulse(1.0f, 0.0f, 2.0f);
IMMouseOverShowBorder show_borders();
string button_background_diamond = "Textures/ui/menus/main/button-diamond.png";
string button_background_diamond_light = "Textures/ui/menus/main/button-diamond-light.png";
string button_background_diamond_thin = "Textures/ui/menus/main/button-diamond-thin.png";
string button_background_flag = "Textures/ui/menus/main/button-flag.png";
string button_background_flag_extended = "Textures/ui/menus/main/button-flag-extended.png";
string button_back = "Textures/ui/menus/main/button-back.png";
string brushstroke_background = "Textures/ui/menus/main/brushStroke.png";
string white_background = "Textures/ui/menus/main/white_square.png";
string button_back_square = "Textures/ui/menus/main/button_square.png";
string button_background_rectangle = "Textures/ui/menus/main/button-back-rect.png";
string checkmark = "Textures/ui/menus/main/checkmark.png";
string checkbox = "Textures/ui/menus/main/checkbox.png";
string settings_sidebar = "Textures/ui/menus/main/settings_sidebar.png";
string slider_button = "Textures/ui/menus/main/slider_button.png";
string slider_bar = "Textures/ui/menus/main/slider_bar.png";
string slider_bar_vertical = "Textures/ui/menus/main/slider_bar_vertical.png";
string slider_button_vert = "Textures/ui/menus/main/button-diamond-light-vertical.png";

string play_icon = "Textures/ui/menus/main/icon-rabbit.png";
string close_icon = "Textures/ui/menus/main/icon-x.png";
string lock_icon = "Textures/ui/menus/main/icon-lock.png";
string settings_icon = "Textures/ui/menus/main/icon-flower.png";
string mods_icon = "Textures/ui/menus/main/icon-eye.png";
string exit_icon = "Textures/ui/menus/main/icon-totem.png";
string arrow_icon = "Textures/ui/menus/main/icon-navigation.png";
string steam_icon = "Textures/ui/menus/main/icon-steam.png";
string spinner_icon = "Textures/ui/menus/main/icon-steam.png";
string navigation_arrow = "Textures/ui/menus/main/navigation_large.png";
string navigation_arrow_slim = "Textures/ui/menus/main/navigation_large_slim.png";
string no_results = "Textures/ui/arena_mode/10_kills.png";

string level_preview_image = "Textures/lugarumenu/Wonderer.jpg";

class LevelInfo
  {
    string name;
    string file;
    string image;
	string inter_level_data;
	bool coming_soon = false;

    LevelInfo(string _file, string _name, string _image, string _inter_level_data = "")
    {
        name = _name;
        file = _file;
        image = _image;
		inter_level_data = _inter_level_data;
    }
	LevelInfo(string _file, string _name, string _image, bool _coming_soon)
    {
        name = _name;
        file = _file;
        image = _image;
		coming_soon = _coming_soon;
    }
};

array<LevelInfo@> levels;
string campaign_name;
//When changing the amount of rows/items also change the size of the items so it will fit onscreen.
uint max_rows = 3;
uint max_items = 4;
bool check_locked = true;
uint current_start_item = 0;
array<GUIElement@> gui_elements;
array<GUIElement@> category_elements;
array<BackgroundObject@> bgobjects;

class GUIElement{
	IMContainer@ container;
	IMContainer@ parent;
	IMContainer@ restore_container;
	string name;
	string config_name;
	bool element_open = false;
	bool option_state = false;
	GUIElement(){};
	void ToggleElement(){};
	void EnableElement(){};
	void DisableElement(){};
	void CloseOptionMenu(){};
	void SwitchOption(string value){};
	void SwitchOption(uint32 value){};
	void PutCurrentValue(){};
	void ResetKeyBinding(){};
	void AddTooltip(){};
	void RemoveTooltip(){};
	void SlideX(int value){};
	void SlideY(int value){};
}

class CategoryButton : GUIElement{
	IMDivider@ parent_divider;
	IMDivider@ restore_divider;
	IMImage@ background_image;
	vec4 original_color;
	CategoryButton(string _name, IMContainer@ _restore_container, IMDivider@ _parent, IMImage@ _background_image){
		@parent_divider = @_parent;
		@background_image = @_background_image;
		@restore_container = @_restore_container;
		original_color = background_image.getColor();
		name = _name;
	}
	void EnableElement(){
		vec2 orig_size = parent_divider.getSize();
		parent_divider.clear();
		parent_divider.setSize(orig_size);
		
		parent_divider.appendSpacer(50.0f);
		parent_divider.append(restore_container);
		vec2 background_size = background_image.getSize();
		background_image.setImageFile(button_background_diamond_light);
		background_image.setColor(vec4(0.25,0.25,0.25,1.0));
		background_image.setSize(background_size);
		element_open = true;
	}
	void DisableElement(){
		vec2 orig_size = parent_divider.getSize();
		parent_divider.clear();
		parent_divider.append(restore_container);
		parent_divider.setSize(orig_size);
		vec2 background_size = background_image.getSize();
		background_image.setImageFile(button_background_diamond);
		background_image.setSize(background_size);
		background_image.setColor(original_color);

		element_open = false;
	}
}

class KeyRebind : GUIElement{
	string binding_category;
	string binding;
	IMText@ current_value;
	KeyRebind(string _name, IMText@ _current_value, IMContainer@ _parent, IMContainer@ _restore_container, string _binding_category, string _binding){
		@restore_container = @_restore_container;
		@parent = @_parent;
		name = _name;
		binding = _binding;
		binding_category = _binding_category;
		@current_value = @_current_value;
		PutCurrentValue();
	}
	void ResetKeyBinding(){
		ResetBinding(binding_category, binding);
	}
	void ToggleElement(){
		if(element_open){
			DisableElement();
			element_open = false;
		}else{
			EnableElement();
			element_open = true;
		}
	}
	void EnableElement(){
		vec2 orig_size = parent.getSize();
		parent.clear();
		parent.setSize(orig_size);
		float button_width = 250.0f;
		float button_height = 55.0f;
		vec4 background_color = vec4(0.5,0.5,0.5,1.0);
		
		IMContainer rebind_button(button_width, button_height);
		
		IMText current_value("Press key.", button_font_small);
		rebind_button.setElement(current_value);
		current_value.setZOrdering(4);
		
		IMImage background_image(button_background_diamond_thin);
		background_image.setZOrdering(1);
		background_image.setSize(vec2(button_width, button_height));
		background_image.setClip(false);
		
		rebind_button.addFloatingElement(background_image, "rebind_background", vec2(0,0));
		
		parent.setElement(rebind_button);
		element_open = true;		
	}
	void SwitchOption(uint32 value){
		SetKeyboardBindingValue(binding_category, binding, value);
		ToggleElement();
		PutCurrentValue();
	}
	void PutCurrentValue(){
		current_value.setText(GetLocaleStringForScancode(GetCodeForKey(GetBindingValue(binding_category,binding))));
	}
	void DisableElement(){
		vec2 orig_size = parent.getSize();
		parent.clear();
		parent.setSize(orig_size);
		parent.setElement(restore_container);
		element_open = false;
	}
}

class BasicButton : GUIElement{
	BasicButton(){
	}
}

class ModItem : GUIElement{
	string error_message;
	IMContainer@ tooltip_container;
	ModItem(IMContainer@ _parent, string _error_message){
		@parent = @_parent;
		error_message = _error_message;
	}
	void AddTooltip(){
		
		@tooltip_container = IMContainer(200, 100);
		tooltip_container.setClip(false);
		IMDivider tooltip_divider("tooltip_divider", DOVertical);
		tooltip_divider.setZOrdering(9);
		tooltip_container.setElement(tooltip_divider);
		
		IMText@ current_line = IMText("", button_font_extra_small);
		tooltip_divider.append(current_line);
		array<string> status_divided = error_message.split(" ");
		int error_line_chars = 0;
		int error_max_char_per_line = 10;
		int error_num_lines = 1;
		int error_max_lines = 5;
		
		for(uint i = 0; i < status_divided.size(); i++){
			current_line.setText( current_line.getText() + status_divided[i] + " ");
			error_line_chars += status_divided[i].length();
			if(error_line_chars > error_max_char_per_line){
				error_num_lines++;
				if(error_num_lines > error_max_lines){
					break;
				}
				error_line_chars = 0;
				IMText new_line("", button_font_extra_small);
				@current_line = @new_line;
				tooltip_divider.append(@current_line);
			}
		}
		IMImage background(white_background);
		background.setColor(vec4(0.1,0.1,0.1,0.95));
		background.setSize(vec2(500, 500));
		background.setZOrdering(8);
		tooltip_container.setPadding(5,5,5,5);
		tooltip_container.addFloatingElement(background, "background", vec2(0.0f));
		parent.addFloatingElement(tooltip_container, "tooltip", vec2(parent.getSizeX(), parent.getSizeY() / 2.0f - (error_num_lines * 20.0f)));
	}
	void RemoveTooltip(){
		tooltip_container.clear();
	}
}

class Checkbox : GUIElement{
	Checkbox(string _name, IMContainer@ _parent, IMContainer@ _restore_container, string _config_name){
		@restore_container = @_restore_container;
		@parent = @_parent;
		name = _name;
		config_name = _config_name;
		PutCurrentValue();
	}
	void ToggleElement(){
		if(option_state){
			DisableElement();
			option_state = false;
		}else{
			EnableElement();
			option_state = true;
		}
	}
	void PutCurrentValue(){
		if(GetConfigValueBool(config_name)){
			if(option_state == false){
				ToggleElement();
			}
		}else{
			if(option_state == true){
				ToggleElement();
			}
		}
	}
	void EnableElement(){
		vec2 orig_size = parent.getSize();
		parent.clear();
		parent.setSize(orig_size);
		
		IMImage checkbox_background(checkbox);
		IMImage checkmark_image(checkmark);
		checkbox_background.addMouseOverBehavior(mouseover_scale_button, "");
		checkmark_image.scaleToSizeX(checkmark_size);
		checkbox_background.scaleToSizeX(checkbox_size);
		checkmark_image.setZOrdering(2);
		checkbox_background.setZOrdering(1);
		checkmark_image.setClip(false);
		checkbox_background.setClip(false);
		
		IMContainer checkbox_holder(checkbox_size, checkbox_size);
		IMMessage onclick("option_changed");
		onclick.addString(name);
		onclick.addString("false");
		checkbox_holder.addLeftMouseClickBehavior( IMFixedMessageOnClick( onclick ), "");
		checkbox_holder.addFloatingElement(checkbox_background, "checkbox_background", vec2(0,0));
		checkbox_holder.addFloatingElement(checkmark_image, "checkmark_image", vec2(0,0));
		
		parent.setElement(checkbox_holder);
	}
	void DisableElement(){
		vec2 orig_size = parent.getSize();
		parent.clear();
		parent.setSize(orig_size);
		parent.setElement(restore_container);
	}
	void SwitchOption(string value){
		ToggleElement();
		SetConfigValueBool(config_name, option_state);
		ReloadStaticValues();
		RefreshAllOptions();
	}
}

class Slider : GUIElement{
	IMImage@ slider_image;
	IMText@ value_label;
	float max_value = 100.0f;
	float min_value = 0.0f;
	vec2 old_mouse_pos;
	bool moving = false;
	float max_x_slide = 100.0f;
	float min_x_slide = 0;
	float config_value;
	Slider(string _name, IMContainer@ _parent, IMImage@ _slider_image, IMText@ _value_label, string _config_name, float _max_value){
		@slider_image = @_slider_image;
		@parent = @_parent;
		@value_label = @_value_label;
		name = _name;
		config_name = _config_name;
		max_value = _max_value;
		max_x_slide = parent.getSizeX() - slider_image.getSizeX();
		min_x_slide = 0.0f;
		PutCurrentValue();
	}
	void PutCurrentValue(){
		config_value = GetConfigValueFloat(config_name);
		
		float new_label_value = 100.0f * config_value / max_value;
		value_label.setText(int(new_label_value) + "%");
		
		float new_slider_displacement = max_x_slide * config_value / max_value;
		slider_image.setDisplacementX( new_slider_displacement );
	}
	void SlideX(int value){
		float new_value = config_value;
		float current_x_displacement = slider_image.getDisplacementX();
		float multiplier = 5.0f;
		float new_slider_displacement;
		new_slider_displacement = min(max_x_slide,max(value + current_x_displacement, min_x_slide));
		new_value = max_value * new_slider_displacement / max_x_slide;
		new_value = max(min_value, min(new_value, max_value));
		float new_label_value = 100.0f * new_value / max_value;
		value_label.setText(ceil(new_label_value) + "%");
		
		slider_image.setDisplacementX( new_slider_displacement );
		SetConfigValueFloat(config_name, new_value);
		config_value = new_value;
		RefreshAllOptions();
	}
	void SwitchOption(string value){
		float new_value = config_value;
		float current_x_displacement = slider_image.getDisplacementX();
		float multiplier = 5.0f;
		float new_slider_displacement;
		if(value == "+"){
			new_value += (max_value / 100.0f) * multiplier;
			new_slider_displacement = max_x_slide * new_value / max_value;
		}
		else if(value == "-"){
			new_value -= (max_value / 100.0f) * multiplier;
			new_slider_displacement = max_x_slide * new_value / max_value;
		}
		else if(value == "click_jump_value"){
			float scaling_x = screenMetrics.GUIToScreen(vec2(1)).x;
			float zero_pos = parent.getScreenPosition().x;
			float mouse_pos = imGUI.guistate.mousePosition.x * scaling_x;
			float difference = (mouse_pos - zero_pos) * (1.0f + scaling_x);
			new_value = max_value * difference / max_x_slide;
			new_slider_displacement = max_x_slide * new_value / max_value;
		}
		new_value = max(min_value, min(new_value, max_value));
		float new_label_value = 100.0f * new_value / max_value;
		value_label.setText(ceil(new_label_value) + "%");
		
		slider_image.setDisplacementX( new_slider_displacement );
		SetConfigValueFloat(config_name, new_value);
		config_value = new_value;
		RefreshAllOptions();
	}
}

class ScrollBar : GUIElement{
	IMImage@ slider_image;
	int current_pos = 0;
	int threshold = 25;
	ScrollBar(IMContainer@ _parent, IMImage@ _slider_image){
		@slider_image = @_slider_image;
		@parent = @_parent;
	}
	void PutCurrentValue(){
	}
	void SwitchOption(string value){
		if(value == "+"){
			
		}
		else if(value == "-"){
			
		}
		else if(value == "click_jump_value"){
			
		}
	}
	void SlideY(int value){
		current_pos += value;
		if(current_pos > threshold){
			imGUI.receiveMessage( IMMessage("shift_menu", 1) );
			current_pos -= threshold;
		}else if(current_pos < 0 - threshold){
			imGUI.receiveMessage( IMMessage("shift_menu", -1) );
			current_pos += threshold;
		}
	}
}

class DropdownMenu : GUIElement{
	IMText@ button_label;
	DropdownConfiguration@ configuration;
	DropdownMenu(string _name, IMText@ _button_label, IMContainer@ _parent, IMContainer@ _restore_container, DropdownConfiguration@ _configuration){
		@parent = @_parent;
		@restore_container = @_restore_container;
		@button_label = @_button_label;
		name = _name;
		@configuration = @_configuration;
		PutCurrentValue();
	}
	void ToggleElement(){
		if(element_open){
			DisableElement();
			element_open = false;
		}else{
			EnableElement();
			element_open = true;
		}
	}
	void PutCurrentValue(){
		configuration.SetCurrentValue(button_label);
	}
	void DisableElement(){
		vec2 orig_size = parent.getSize();
		parent.clear();
		parent.addFloatingElement(restore_container, "main_button", vec2(0,0));
		parent.setSize(orig_size);
		
		DisableControllerSubmenu();
	}
	void EnableElement(){
		EnableControllerSubmenu();
		
		vec2 orig_size = parent.getSize();
		parent.clearLeftMouseClickBehaviors();
		parent.clear();
		parent.setSize(orig_size);
		IMDivider choices_divider(name, DOVertical);
		choices_divider.setSizeX(restore_container.getSizeX());
		array<string> options = configuration.GetDisplayOptions();
		int current_index = 0;
		for(uint i = 0; i < options.size(); i++){
			IMContainer choice_extra("divider" + options[i], DOHorizontal);
			choice_extra.setSizeX(restore_container.getSizeX());
			choice_extra.setSizeY(restore_container.getSizeY());
			IMContainer choice_holder("holder" + options[i], DOHorizontal);
			choice_holder.sendMouseOverToChildren(true);
			IMText choice(options[i], button_font_small);
			if(kAnimateMenu){
				choice.addUpdateBehavior(IMFadeIn( fade_in_time, inSineTween ), "");
			}
			choice.addMouseOverBehavior(text_color_mouse_over, "");
			choice.setClip(false);
			choice_holder.setElement(choice_extra);
			choices_divider.append(choice_holder);
			choice_holder.setSizeX(restore_container.getSizeX());
			choice_holder.setSizeY(restore_container.getSizeY());
			
			choice_holder.setZOrdering(5);
			choice_extra.setZOrdering(6);
			choice.setZOrdering(7);
			
			IMMessage onclick("option_changed");
			onclick.addString(name);
			onclick.addString(options[i]);
			choice_holder.addLeftMouseClickBehavior( IMFixedMessageOnClick( onclick ), "" );
			choice_extra.setElement(choice);
			AddControllerItem(choice_extra, onclick);

			if(i == uint(configuration.GetCurrentOptionIndex())){
				current_index = i;
			}

			IMImage background_image(white_background);
			background_image.addMouseOverBehavior(mouseover_color_background, "");
			background_image.setSize(vec2(restore_container.getSizeX(), restore_container.getSizeY()));
			background_image.setClip(false);
			background_image.setColor(vec4(0,0,0,1));
			choice_holder.addFloatingElement(background_image, "background", vec2(0,0));
		}
		choices_divider.setZOrdering(4);
		parent.addFloatingElement(choices_divider, "choices", vec2(0,0));
		SetCurrentControllerItem(current_index);
	}
	void SwitchOption(string value){
		CloseAllOptionMenus();
		configuration.SetConfigValue(value);
		ReloadStaticValues();
		RefreshAllOptions();
	}
}

class DropdownConfigurationBaseClass{
	string config_name;
	string display_name;
	array<string> config_names;
	array<string>@ display_values;
	int current_option_index = 0;
	array<string> GetDisplayOptions(){
		return display_values;
	}
	void SetCurrentValue(IMText@ label){}
	void SetConfigValue(string value){}
}
class DropdownConfigurationStringArray : DropdownConfigurationBaseClass{
	array<string>@ config_values;
	DropdownConfigurationStringArray(array<string> _config_values, array<string> _display_values){
		@config_values = @_config_values;
		@display_values = @_display_values;
	}
	void SetCurrentValue(IMText@ label){
		string current_value = GetConfigValueString(config_name);
		current_option_index = config_values.find(current_value);
		if(current_option_index != -1){
			label.setText(display_values[current_option_index]);
		}
	}
	void SetConfigValue(string value){
		int index = display_values.find(value);
		if(index != -1){
			SetConfigValueString(config_name, config_values[index]);
		}
	}
}

class DropdownConfigurationIntArray : DropdownConfigurationBaseClass{
	array<int>@ config_values;
	DropdownConfigurationIntArray(array<int> _config_values, array<string> _display_values){
		@config_values = @_config_values;
		@display_values = @_display_values;
	}
	void SetCurrentValue(IMText@ label){
		int current_value = GetConfigValueInt(config_name);
		current_option_index = config_values.find(current_value);
		if(current_option_index != -1){
			label.setText(display_values[current_option_index]);
		}
	}
	void SetConfigValue(string value){
		int index = display_values.find(value);
		if(index != -1){
			SetConfigValueInt(config_name, config_values[index]);
		}
	}
}

class DropdownConfigurationvec2Array : DropdownConfigurationBaseClass{
	array<vec2>@ config_values;
	DropdownConfigurationvec2Array(array<vec2> _config_values, array<string> _display_values){
		@config_values = @_config_values;
		@display_values = @_display_values;
	}
	void SetCurrentValue(IMText@ label){
		vec2 current_values = vec2( GetConfigValueInt(config_names[0]), GetConfigValueInt(config_names[1]) );
		current_option_index = config_values.find(current_values);
		if(current_option_index != -1){
			label.setText(display_values[current_option_index]);
		}else{
			//The window was resized and a non-standard value was set.
			int current_res_index = display_values.find(label.getText());
			if(current_res_index != -1){
				config_values.removeAt(current_res_index);
				display_values.removeAt(current_res_index);
			}
			int new_x = GetConfigValueInt(config_names[0]);
			int new_y = GetConfigValueInt(config_names[1]);
			config_values.insertLast(vec2(new_x, new_y));
			display_values.insertLast(new_x + "x" + new_y);
			label.setText(new_x + "x" + new_y);
		}
	}
	void SetConfigValue(string value){
		int index = display_values.find(value);
		if(index != -1){
			SetConfigValueInt(config_names[0], int(config_values[index].x ));
			SetConfigValueInt(config_names[1], int(config_values[index].y ));
		}
	}
}
class DropdownConfiguration{
	DropdownConfigurationBaseClass@ conf;
	
	DropdownConfiguration(array<string> config_values, array<string> display_values, string config_name){
		@conf = DropdownConfigurationStringArray(config_values, display_values);
		conf.config_name = config_name;
	}
	DropdownConfiguration(array<int> config_values, array<string> display_values, string config_name){
		@conf = DropdownConfigurationIntArray(config_values, display_values);
		conf.config_name = config_name;
	}
	DropdownConfiguration(array<vec2> config_values, array<string> display_values, array<string> config_names){
		@conf = DropdownConfigurationvec2Array(config_values, display_values);
		conf.config_names = config_names;
	}
	array<string> GetDisplayOptions(){
		return conf.GetDisplayOptions();
	}
	void SetCurrentValue(IMText@ label){
		conf.SetCurrentValue(label);
	}
	void SetConfigValue(string value){
		conf.SetConfigValue(value);
	}
	int GetCurrentOptionIndex(){
		return conf.current_option_index;
	}
}

void RefreshAllOptions(){
	for(uint i = 0; i < gui_elements.size(); i++){
		gui_elements[i].PutCurrentValue();
	}
}

void ResetAllKeyBindings(){
	for(uint i = 0; i < gui_elements.size(); i++){
		gui_elements[i].ResetKeyBinding();
	}
}

void CloseAllOptionMenus(){
	for(uint i = 0; i < gui_elements.size(); i++){
		if(gui_elements[i].element_open){
			gui_elements[i].DisableElement();
			gui_elements[i].element_open = false;
		}
	}
}

bool OptionMenuOpen(){
	bool open_menu = false;
	for(uint i = 0; i < gui_elements.size(); i++){
		if(gui_elements[i].element_open){
			open_menu = true;
			break;
		}
	}
	return open_menu;
}

void CreateMenu(IMDivider@ menu_holder, array<LevelInfo@>@ _levels, string _campaign_name, uint start_at, uint _max_items = max_items, 
				uint _max_rows = max_rows, bool _check_locked = check_locked, bool _menu_numbered = menu_numbered, 
				float _menu_width = menu_width, float _menu_height = menu_height){

	float arrow_width = 200.0f;
	float arrow_height = 400.0f;
	//The extra space is needed for the arrow scaleonmouseover animation, or else they push the other elements.
	float extra = 50.0f;
	current_start_item = start_at;
	
	max_items = _max_items;
	max_rows = _max_rows;
	check_locked = _check_locked;
	menu_width = _menu_width;
	menu_height = _menu_height;
	menu_numbered = _menu_numbered;
	
	levels = _levels;
	campaign_name = _campaign_name;
	
	//Create the actual level select menu between the two arrows.
	IMContainer menu_container(menu_width, menu_height);
    IMDivider level_holder("level_holder", DOVertical);
	menu_container.setElement(level_holder);
	level_holder.setAlignment(CALeft, CACenter);
	
	IMDivider@ current_row;
    uint nr_rows = 0;
	uint highest_unlocked = 0;
	uint last_played = 0;

	if(check_locked){
		highest_unlocked = GetHighestUnlockedLevel();
		last_played = GetLastPlayedLevel();
	}

	float item_width = menu_width / _max_items;
	float item_height = menu_height / _max_rows;

    for(uint i = 0; (i + start_at) < levels.size(); i++){
        if(i % _max_items == 0 || i == 0){
            nr_rows++;
            if(nr_rows > _max_rows){
                break;
            }else{
                IMDivider new_row_container("row_container", DOHorizontal);
                @current_row = @new_row_container;
                level_holder.append(new_row_container);
            }
        }
		bool unlocked = false;
		if((i + start_at) <= highest_unlocked || !check_locked){
			unlocked = true;
		}
		//If the level isn't unlocked it won't be selectable or show the preview screen.
		bool is_last_played = false;
		if(i == last_played && check_locked){
			is_last_played = true;
		}
        CreateMenuItem(current_row, levels[i + start_at], unlocked, is_last_played, (i + start_at + 1), item_width, item_height);
    }

	//The left arrow in the level select menu.
	IMContainer left_arrow_container("left_arrow_container", DOHorizontal);
	left_arrow_container.setSize(vec2(arrow_width + extra, arrow_height + extra));
	if(MenuCanShift(-1)){
		IMImage left_arrow( navigation_arrow );
		if(kAnimateMenu){
			left_arrow.addUpdateBehavior(IMMoveIn ( move_in_time, vec2(move_in_distance * -1, 0), inQuartTween ), "");
		}
		left_arrow_container.addFloatingElement(left_arrow, "left_arrow", vec2((extra / 2.0f), (extra / 2.0f)), 1);
	    left_arrow.scaleToSizeX(arrow_width);
	    left_arrow.setColor(button_font.color);
	    left_arrow.addMouseOverBehavior(mouseover_scale_arrow, "");
		left_arrow.addLeftMouseClickBehavior( IMFixedMessageOnClick("shift_menu", -1), "");
	}
	menu_holder.append(left_arrow_container);

    menu_holder.append(menu_container);

	//The right arrow in the level select menu.
	IMContainer right_arrow_container("left_arrow_container", DOHorizontal);
	right_arrow_container.setAlignment(CACenter, CACenter);
	right_arrow_container.setSize(vec2(arrow_width + extra, arrow_height + extra));
	if(MenuCanShift(1)){
	    IMImage right_arrow( navigation_arrow );
	    if(kAnimateMenu){
			right_arrow.addUpdateBehavior(IMMoveIn ( move_in_time, vec2(move_in_distance * 1, 0), inQuartTween ), "");
		}
		right_arrow_container.addFloatingElement(right_arrow, "right_arrow", vec2((extra / 2.0f), (extra / 2.0f)), 1);
	    right_arrow.scaleToSizeX(arrow_width);
	    right_arrow.setColor(button_font.color);
	    right_arrow.addMouseOverBehavior(mouseover_scale_arrow, "");
		right_arrow.addLeftMouseClickBehavior( IMFixedMessageOnClick("shift_menu", 1), "");
		//To make the right arrow point in the opposite direction, just rotate it 180 degrees.
	    right_arrow.setRotation(180);
	}
	menu_holder.append(right_arrow_container);
}

void CreateMenuItem(IMDivider@ row, LevelInfo@ level, bool unlocked, bool last_played, int number, float level_item_width, float level_item_height){
	float background_size_offset = 50.0f;
	float background_icon_size = int((level_item_width + level_item_height) / 4.0f);
	vec4 background_icon_color = vec4(0.1f,0.1f,0.1f,1.0f);

	IMImage background_icon( lock_icon );
	if(kAnimateMenu){
		background_icon.addUpdateBehavior(IMFadeIn( fade_in_time, inSineTween ), "");
    }
    background_icon.scaleToSizeX(background_icon_size);
    background_icon.setColor(background_icon_color);
	
	FontSetup menu_item_font(button_font_small.fontName, int((level_item_width + level_item_height) / max(13.0f, level.name.length() * 0.65f)) , button_font_small.color, button_font_small.shadowed);

	//This divider has all the elements of a level.
	IMDivider level_divider("button_divider", DOHorizontal);

	//The container is used to add floating elements.
	IMContainer level_container(level_item_width, level_item_height);
	level_divider.sendMouseOverToChildren(true);
	level_divider.append(level_container);
	IMImage background( white_background );
	if(kAnimateMenu){
		background.addUpdateBehavior(IMFadeIn( fade_in_time, inSineTween ), "");
	}
	background.setSize(vec2(level_item_width - background_size_offset, level_item_height - background_size_offset));
	background.setColor(button_background_color);
	//Calculate the middle of the container so that elements added to it can calculate when to be as floating elements.
	float middle_y = level_container.getSizeY() / 2.0f;
	float middle_x = level_container.getSizeX() / 2.0f;

	level_container.addFloatingElement(background, "background", vec2(middle_x - (background.getSizeX() / 2.0f), middle_y - (background.getSizeY() / 2.0f)), 1);
	level_container.addFloatingElement(background_icon, "background_icon", vec2(middle_x - (background_icon.getSizeX() / 2.0f), middle_y - (background_icon.getSizeY() / 2.0f)), 2);

	IMMessage on_click("run_file");
	if(unlocked){
		float number_background_width = level_item_width / 7.0f;
		float preview_size_offset = 75.0f;
		float text_holder_height = level_item_width / 8.0f;
		IMImage level_preview( level.image );
		level_preview.setSize(vec2(level_item_width - preview_size_offset, level_item_height - preview_size_offset));
		level_container.addFloatingElement(level_preview, "preview", vec2(middle_x - (level_preview.getSizeX() / 2.0f), middle_y - (level_preview.getSizeY() / 2.0f)), 3);
		
		if(!level.coming_soon){
			on_click.addString(level.file);
			on_click.addInt(number - 1);
			level_divider.addLeftMouseClickBehavior( IMFixedMessageOnClick(on_click), "" );
			background.addMouseOverBehavior(mouseover_scale_background, "");
			if(kAnimateMenu){
				level_preview.addUpdateBehavior(IMFadeIn( fade_in_time, inSineTween ), "");
			}
			level_preview.addMouseOverBehavior(mouseover_scale, "");
		}
		else{
			IMContainer text_holder(0,0);
			IMText coming_soon("COMING SOON", FontSetup("edosz", int(level_item_width / 5.5) , HexColor("#CCCCCC")));
			coming_soon.setZOrdering(7);
			text_holder.setElement(coming_soon);
			level_preview.setColor(vec4(0.25f,0.25f,0.25f,1.0f));
			level_container.addFloatingElement(text_holder, "coming_soon", vec2(0.0f, level_item_height / 5.0f));
			coming_soon.setRotation(15);
		}
		

		//This is the background for the level name.
		IMImage title_background( button_background_diamond );		
		if(kAnimateMenu){
			title_background.addUpdateBehavior(IMFadeIn( fade_in_time, inSineTween ), "");
		}
		title_background.setSize(vec2(level_item_width, text_holder_height));
		level_container.addFloatingElement(title_background, "title_background", vec2(middle_x - (title_background.getSizeX() / 2.0f), level_container.getSizeY() - title_background.getSizeY()), 4);

		//This is the text used to show the level name.
		IMText level_text(level.name, menu_item_font);
		if(last_played){
			background.setColor(vec4(0.5f,0.5f,0.5f,1));
		}
		if(kAnimateMenu){
			level_text.addUpdateBehavior(IMFadeIn( fade_in_time, inSineTween ), "");
		}
		IMDivider text_holder_holder("text_holder_holder", DOVertical);
		IMDivider text_holder("text_holder", DOHorizontal);
		text_holder.setSize(vec2(level_item_width, text_holder_height));
		text_holder_holder.setSize(vec2(level_item_width, text_holder_height));
		text_holder_holder.append(text_holder);
		text_holder.append(level_text);
		level_text.setZOrdering(7);
		level_container.addFloatingElement(text_holder_holder, "title_text", vec2(middle_x - (text_holder.getSizeX() / 2.0f), level_container.getSizeY() - text_holder.getSizeY()), 4);

		if(menu_numbered){
			//The background for the level number.
			IMImage level_number_background( button_back_square );
			if(kAnimateMenu){
				level_number_background.addUpdateBehavior(IMFadeIn( fade_in_time, inSineTween ), "");
			}
			level_number_background.setSize(vec2(number_background_width, number_background_width));
			//Because it's rotated it needs a bit more space or else the edges get cut off.
			float extra = number_background_width / 2.0f;
			//Create a new container to ensure that the number and background are centered to each other.
			//Rotate the square to create a diamond shape.
			level_number_background.setRotation(45);
			level_number_background.setZOrdering(6);
			level_number_background.setClip(false);
			IMContainer level_number_container(number_background_width, number_background_width);
			level_number_container.addFloatingElement(level_number_background, "level_number_background", vec2(0), 6);

			//The number of the level shown in the top left corner.
			IMText level_number(number + ".", button_font_small);
			if(kAnimateMenu){
				level_number.addUpdateBehavior(IMFadeIn( fade_in_time, inSineTween ), "");
			}
			level_number.setZOrdering(8);
			level_number.setClip(false);
			level_number_container.setElement(level_number);
			level_container.addFloatingElement(level_number_container, "level_number", vec2(middle_x - (level_preview.getSizeX() / 2.0f) - (level_number_container.getSizeX() / 2.0f), middle_y - (level_preview.getSizeY() / 2.0f) - (level_number_container.getSizeY() / 2.0f)) , 4);
		}
	}
	
	ControllerItem new_controller_item();
	if(number % max_items == 0){
		IMMessage press_right("shift_menu", 1);
		@new_controller_item.message_right = press_right;
	}else if((number + (max_items - 1))  % max_items == 0){
		IMMessage press_left("shift_menu", -1);
		@new_controller_item.message_left = press_left;
	}
	@new_controller_item.message = on_click;
    level_container.setName("menu_item" + (number - 1));
	@new_controller_item.element = level_container;
	AddControllerItem(@new_controller_item);
	row.append(level_divider);
}

bool MenuCanShift(int direction){
	int new_start_item = current_start_item + (max_rows * max_items * direction);
	if(uint(new_start_item) < levels.size() && new_start_item > -1){
		return true;
	} else{
		return false;
	}
}

int ShiftMenu(int direction){
	if(!MenuCanShift(direction))return current_start_item;
	//Create a new divider and add the menu again, just like in init, but start at some other level.
    current_start_item += (max_rows * max_items * direction);
    return current_start_item;
}

int NrCustomLevels(){
	int number = 0;
	array<ModID>@ active_sids = GetActiveModSids();
    for( uint i = 0; i < active_sids.length(); i++ ) {
        array<ModLevel>@ menu_items = ModGetSingleLevels(active_sids[i]); 
        for( uint k = 0; k < menu_items.length(); k++ ) {
			number++;
        }
    }
	return number;
}

int GetHighestUnlockedLevel( ) {
    SavedLevel @level = save_file.GetSavedLevel(campaign_name);

    string current_highest_level = level.GetValue("highest_level");
	string curr_level = level.GetValue("current_level");
	
    //Log(info, "Current Higest unlocked Level id \"" + current_highest_level + "\"" );
    int id_current_highest_level = -1;

    if( current_highest_level != "" ) {
        id_current_highest_level = atoi(current_highest_level);
    }else{
		//Write the first level unlocked for new users.
		id_current_highest_level = 0;
		level.SetValue("highest_level", "" + id_current_highest_level);
        save_file.WriteInPlace();
	}
	//Check if a new level has been unlocked.
	int curr_level_id = 0;
	for(int i=0, len=levels.size(); i<len; ++i) {
		if(levels[i].file == curr_level){
			curr_level_id = i;
		}
	}
	if(curr_level_id > id_current_highest_level){
		id_current_highest_level = curr_level_id;
		level.SetValue("highest_level", ""+id_current_highest_level);
		save_file.WriteInPlace();
	}
	return id_current_highest_level;
}

int GetLastPlayedLevel(){
	//The last played level gets a different background. This way the user can replay the campaign and still know where to continue.
	int last_played = -1;
	SavedLevel @level = save_file.GetSavedLevel(campaign_name);
	string curr_level = level.GetValue("current_level");
	for(int i = 0, len = levels.size(); i < len; ++i) {
		if("Data/Levels/" + levels[i].file == curr_level){
			last_played = i;
		}
	}
	return last_played;
}

void AddButton(string text, IMDivider@ parent, string icon_path = "null", string background_path = button_background_diamond, 
				bool animated = true, float button_width = default_button_width, float _text_trailing_space = text_trailing_space, 
				IMMouseOverBehavior@ background_anim = move_button_background, IMMessage@ message = null){
	float button_height = 75.0f;
	float icon_size = 75.0f;
	float button_horizontal_spacing = 60.0f;
	float button_vertical_spacing = 25.0f;
	//Needed for scale animation
	float extra_space = 10.0f;

	IMDivider main_divider(DOHorizontal);
	if(message !is null){
		AddControllerItem(main_divider, message);
		main_divider.addLeftMouseClickBehavior( IMFixedMessageOnClick(message), "" );
	}else{
		main_divider.addLeftMouseClickBehavior( IMFixedMessageOnClick(text), "" );
		AddControllerItem(main_divider, IMMessage(text));
	}
	IMContainer new_container(button_width + extra_space, button_height + extra_space);
	new_container.setAlignment(CALeft, CACenter);

	IMImage button_background( background_path);
	if(kAnimateMenu){
		button_background.addUpdateBehavior(IMFadeIn( fade_in_time, inSineTween ), "");
	}
	button_background.setSizeY(button_height);
	button_background.setSizeX(button_width);
	button_background.setClip(false);
	new_container.addFloatingElement(button_background, "background", vec2(new_container.getSizeX() / 2.0f - button_background.getSizeX() / 2.0f, new_container.getSizeY() / 2.0f - button_background.getSizeY() / 2.0f), 1);

	IMDivider text_holder(DOHorizontal);
	text_holder.setAlignment(CACenter, CACenter);
	text_holder.setSizeY(button_background.getSizeY());
	IMText new_text(text, button_font);

	if(kAnimateMenu){
		new_text.addUpdateBehavior(IMFadeIn( fade_in_time, inSineTween ), "");
	}

	text_holder.setZOrdering(3);
	if(icon_path != "null"){
		text_holder.append(IMSpacer(DOHorizontal, button_horizontal_spacing));
		IMImage icon(icon_path);
		if(kAnimateMenu){
			icon.addUpdateBehavior(IMFadeIn( fade_in_time, inSineTween ), "");
		}
		icon.setColor(button_font.color);
		icon.scaleToSizeX(icon_size);
		text_holder.append(icon);
		icon.addMouseOverBehavior(text_color_mouse_over, "");
	}
	text_holder.append(IMSpacer(DOHorizontal, _text_trailing_space));
	text_holder.append(new_text);
	new_container.setElement(text_holder);

	main_divider.sendMouseOverToChildren(true);
	if(animated){
		button_background.addMouseOverBehavior( background_anim, "" );
		text_holder.addMouseOverBehavior( move_button_text, "" );
	}
	new_text.addMouseOverBehavior(text_color_mouse_over, "");
	main_divider.append(new_container);
	parent.append(IMSpacer(DOVertical, button_vertical_spacing));
	parent.append( main_divider );
}

void AddButton(string text, IMDivider@ parent, float _text_trailing_space){
	AddButton(text, parent, "null", button_background_diamond, true, 500.0f, _text_trailing_space, mouseover_scale_button);
}

void AddBackButton(){
	float button_trailing_space = 100.0f;
	float button_width = 400.0f;
	bool animated = false;
	
    IMDivider right_panel("right_panel", DOHorizontal);
    right_panel.setBorderColor(vec4(0,1,0,1));
    right_panel.setAlignment(CALeft, CABottom);
    right_panel.append(IMSpacer(DOHorizontal, button_trailing_space));
    AddButton("Back", right_panel, arrow_icon, button_back, animated, button_width);
    imGUI.getFooter().setAlignment(CALeft, CACenter);
    imGUI.getFooter().setElement(right_panel);
}

void AddTitleHeader(string title, IMDivider@ parent){
	float vertical_trailing_space = 100;
	float horizontal_trailing_space = 300;
    float header_width = title.length() * (title_font.size * 0.4f) + horizontal_trailing_space;
    float header_height = title_font.size;

    IMContainer header_container(header_width, header_height);
    IMImage header_background( brushstroke_background );
    if(kAnimateMenu){
		header_background.addUpdateBehavior(IMMoveIn ( move_in_time, vec2(0, move_in_distance * -1), inQuartTween ), "");
    }
    header_background.setSize(vec2(header_width, header_height));
    header_background.setColor(button_background_color);
    IMDivider header_holder("header_holder", DOHorizontal);
	IMText header_text(title, title_font);
    header_holder.append(IMSpacer(DOHorizontal, vertical_trailing_space));
	if(kAnimateMenu){
		header_text.addUpdateBehavior(IMMoveIn ( move_in_time, vec2(0, move_in_distance * -1), inQuartTween ), "");
    }
    header_container.setElement(header_text);
    header_container.setAlignment(CACenter, CACenter);
    header_text.setZOrdering(3);
    imGUI.getHeader().setAlignment(CALeft, CABottom);
    header_container.setBorderColor(vec4(1,0,0,1));
    header_container.addFloatingElement(header_background, "background", vec2(0.0f, (header_container.getSizeY() / 2.0f) - (header_height / 2.0f)), 1);
    header_holder.append(header_container);
    parent.append(header_holder);
	parent.appendSpacer(50);
}

void AddVerticalBar(){
	float bar_width = 150.0f;
	float bar_x_pos = 300.0f;
	
	IMImage bar( "Textures/ui/menus/main/white_square.png" );
	bar.setSize(vec2(bar_width, screenMetrics.GUISpace.y));
	bar.setColor(button_background_color);
	imGUI.getBackgroundLayer().addFloatingElement( bar, "bar", vec2(bar_x_pos, 0.0f), 2);
}

string GetRandomBackground(){
	array<string> background_paths;
	int counter = 0;
	while(true){
		string path = "Textures/ui/menus/main/background_" + counter + ".jpg";
		if(FileExists("Data/" + path)){
	    	background_paths.insertLast(path);
	    	counter++;
		}else{
	    	break;
		}
	}
	if(background_paths.size() < 1){
		return "Textures/error.tga";
	}else{
		return background_paths[rand()%background_paths.size()];
	}
}

void AddDropDown(string text, IMDivider@ parent, DropdownConfiguration configuration, string extra_text = ""){
	float dropdown_width = 350.0f;
	float dropdown_height = 55.0f;
	float vertical_trailing_space = 10.0f;
	float value_trailing_space = 35.0f;
	float whole_option_width = 800.0f;
	
	IMDivider main_divider("main_divider" + text, DOHorizontal);
	IMDivider left_divider("left_divider" + text, DOHorizontal);
	IMDivider right_divider("right_divider" + text, DOHorizontal);
	
	left_divider.setAlignment(CALeft, CACenter);
	main_divider.setAlignment(CALeft, CACenter);
	
	IMText title(text, button_font_small);
	left_divider.append(title);

	if(extra_text != ""){
		IMText extra(extra_text, small_font);
		left_divider.append(extra);
	}

	left_divider.setSizeX(whole_option_width / 2.0f);
	
	//-------------------------------------------------
	right_divider.setAlignment(CALeft, CACenter);
	right_divider.setSizeX(whole_option_width / 2.0f);
	
	IMContainer parent_container(dropdown_width, dropdown_height + vertical_trailing_space);
	IMContainer main_button_container(dropdown_width, dropdown_height);
	main_button_container.setAlignment(CALeft, CACenter);
	
	IMImage background_image(button_background_diamond_thin);
	background_image.setZOrdering(1);
	background_image.setSize(vec2(dropdown_width, dropdown_height));
	main_button_container.addFloatingElement(background_image, "background" + text, vec2(0,0));
	
	IMDivider button_divider("button_divider", DOHorizontal);
	button_divider.setAlignment(CALeft, CACenter);
	button_divider.setZOrdering(2);
	
	IMText current_value_text("NA", button_font_small);
	current_value_text.setZOrdering(3);
	
	IMImage dropdown_icon(arrow_icon);
	dropdown_icon.setName("dropdown_icon" + text);
	dropdown_icon.scaleToSizeX(35);
	dropdown_icon.setRotation(90);
	
	IMContainer current_value_container(dropdown_width - dropdown_icon.getSizeX() - (value_trailing_space * 2.0f), dropdown_height);
	current_value_container.setAlignment(CALeft, CACenter);
	current_value_container.setElement(current_value_text);
	
	button_divider.appendSpacer(value_trailing_space);
	button_divider.append(current_value_container);
	button_divider.append(dropdown_icon);
	
	main_button_container.sendMouseOverToChildren(true);
	IMMessage dropdown_message("ui_element_clicked", text);
	main_button_container.addLeftMouseClickBehavior( IMFixedMessageOnClick(dropdown_message), "");
	background_image.addMouseOverBehavior(mouseover_scale_button, "");
	current_value_text.addMouseOverBehavior(text_color_mouse_over, "");
	
	right_divider.append(parent_container);
	
	parent_container.setElement(main_button_container);
	main_button_container.setElement(button_divider);
	
	AddControllerItem(parent_container, dropdown_message);
	gui_elements.insertLast(DropdownMenu(text, current_value_text, parent_container, main_button_container, @configuration));

	background_image.setClip(false);
	
	main_divider.append(left_divider);
	main_divider.append(right_divider);
	main_divider.setSizeY(dropdown_height + vertical_trailing_space);
	main_divider.setSizeX(whole_option_width);
	
	parent.append(main_divider);
}

void AddLabel(string text, IMDivider@ parent){
	float label_height = 40.0f;
	float value_trailing_space = 35.0f;
	float whole_option_width = 725.0f;
	
	IMContainer main_container("main_container" + text, DOHorizontal);
	IMDivider main_divider("main_divider" + text, DOHorizontal);
	
	main_container.setAlignment(CARight, CACenter);
	IMText asterisk("*", small_font);
	IMText title(text, button_font_extra_small);
	main_divider.append(asterisk);
	main_divider.append(title);
	main_container.setElement(main_divider);
	
	main_container.setSizeY(label_height);
	main_container.setSizeX(whole_option_width);
	
	parent.append(main_container);
}

void AddKeyRebind(string text, IMDivider@ parent, string binding_category, string binding){
	float button_width = 250.0f;
	float button_height = 55.0f;
	float vertical_trailing_space = 10.0f;
	float leading_trailing_space = 100.0f;
	float whole_option_width = 800.0f;
	float button_leading_trailing_space = 50.0f;
	
	IMDivider main_divider("main_divider" + text, DOHorizontal);
	IMContainer main_container(whole_option_width, button_height);
	
	main_divider.setAlignment(CALeft, CACenter);
	
	IMDivider left_divider("left_divider" + text, DOHorizontal);
	left_divider.setAlignment(CALeft, CACenter);
	IMDivider right_divider("right_divider" + text, DOHorizontal);
	right_divider.setAlignment(CARight, CACenter);
	
	IMContainer right_container("right_container" + text, DOHorizontal);
	right_container.setAlignment(CARight, CACenter);
	right_container.setElement(right_divider);
	
	IMContainer left_container("left_container" + text, DOHorizontal);
	left_container.setAlignment(CALeft, CACenter);
	left_container.setElement(left_divider);
	left_container.setSizeX(whole_option_width / 2.0f);
	
	left_divider.appendSpacer(leading_trailing_space);
	IMText title(text, button_font_small);
	left_divider.append(title);
	
	IMContainer rebind_holder(button_width, button_height + vertical_trailing_space);
	rebind_holder.setAlignment(CACenter, CACenter);
	IMMessage rebind_message("rebind_activate", gui_elements.size());
	rebind_holder.addLeftMouseClickBehavior( IMFixedMessageOnClick(rebind_message), "");
	
	IMContainer rebind_button(button_width, button_height);
	rebind_holder.setElement(rebind_button);
	right_divider.appendSpacer(button_leading_trailing_space);
	right_divider.append(rebind_holder);
	
	IMText current_value("NA", button_font_small);
	rebind_button.setElement(current_value);
	current_value.setZOrdering(4);
	
	IMImage background_image(button_background_diamond_thin);
	background_image.setZOrdering(1);
	background_image.setSize(vec2(button_width, button_height));
	background_image.setClip(false);
	
	rebind_button.addFloatingElement(background_image, "rebind_background" + text, vec2(0,0));
		
	main_divider.append(left_container);
	main_divider.append(right_container);
	main_container.setSizeY(button_height + vertical_trailing_space);
	
	AddControllerItem(rebind_holder, rebind_message);
	gui_elements.insertLast(KeyRebind(text, current_value, rebind_holder, rebind_button, binding_category, binding));
	main_container.setElement(main_divider);
	parent.append(main_container);
}

void AddBasicButton(string text, string message, float button_width, IMDivider@ parent){
	float button_height = 55.0f;
	float vertical_trailing_space = 30.0f;
	float whole_option_width = 800.0f;
	
	IMDivider main_divider("main_divider" + text, DOHorizontal);
	IMContainer main_container(whole_option_width, button_height + vertical_trailing_space);
	
	IMContainer button_holder(button_width, button_height);
	
	IMImage button_background( button_background_diamond );
	button_background.setSizeY(button_height);
	button_background.setSizeX(button_width);
	button_background.setClip(false);
	button_background.setZOrdering(0);
	button_holder.addFloatingElement(button_background, "background", vec2(0));
	
	IMMessage on_click(message);
	IMText label(text, button_font_small);
	label.addMouseOverBehavior(text_color_mouse_over, "");
	label.addLeftMouseClickBehavior(IMFixedMessageOnClick(on_click), "");
	button_holder.setElement(label);
	main_divider.append(button_holder);
	
	AddControllerItem(button_holder, on_click);
	
	gui_elements.insertLast(BasicButton());
	main_container.setElement(main_divider);
	parent.append(main_container);
}

void AddCategoryButton(string text, IMDivider@ parent){
	float button_height = 75.0f;
	float button_width = 450.0f;
	float icon_size = 75.0f;
	float button_horizontal_spacing = 60.0f;
	float button_vertical_spacing = 10.0f;
	float text_trailing_space = 75.0f;
	//Needed for scale animation
	float extra_space = 10.0f;
	
	IMDivider main_divider(DOHorizontal);
	IMMessage message("switch_category");
	message.addString(text);
	IMContainer new_container(button_width + extra_space, button_height + extra_space);
	new_container.addLeftMouseClickBehavior( IMFixedMessageOnClick(message), "" );
	new_container.setAlignment(CALeft, CACenter);

	IMImage button_background( button_background_diamond );
	if(kAnimateMenu){
		button_background.addUpdateBehavior(IMFadeIn( fade_in_time, inSineTween ), "");
	}
	button_background.setSizeY(button_height);
	button_background.setSizeX(button_width);
	button_background.setClip(false);
	new_container.addFloatingElement(button_background, "background", vec2(new_container.getSizeX() / 2.0f - button_background.getSizeX() / 2.0f, new_container.getSizeY() / 2.0f - button_background.getSizeY() / 2.0f), 1);

	IMDivider text_holder(DOHorizontal);
	text_holder.setAlignment(CACenter, CACenter);
	text_holder.setSizeY(button_background.getSizeY());
	IMText new_text(text, button_font);
	if(kAnimateMenu){
		new_text.addUpdateBehavior(IMFadeIn( fade_in_time, inSineTween ), "");
	}
	text_holder.setZOrdering(3);
	text_holder.append(IMSpacer(DOHorizontal, text_trailing_space));
	text_holder.append(new_text);
	new_container.setElement(text_holder);

	new_container.sendMouseOverToChildren(true);
	
	button_background.addMouseOverBehavior( mouseover_scale_button, "" );
	text_holder.addMouseOverBehavior( move_button_text, "" );
	
	new_text.addMouseOverBehavior(text_color_mouse_over, "");
	main_divider.append(new_container);
	parent.append(IMSpacer(DOVertical, button_vertical_spacing));
	parent.append( main_divider );

	AddControllerItem(new_container, message);
	category_elements.insertLast(CategoryButton(text, new_container, main_divider, button_background));
}

void AddCheckBox(string text, IMDivider@ parent, string config_name){
	float dropdown_width = 350.0f;
	float dropdown_height = 55.0f;
	float vertical_trailing_space = 10.0f;
	float leading_trailing_space = 200.0f;
	float whole_option_width = 800.0f;
	
	IMDivider main_divider("main_divider" + text, DOHorizontal);
	IMContainer main_container(whole_option_width, dropdown_height);
	
	main_container.setAlignment(CALeft, CACenter);
	
	main_divider.appendSpacer(leading_trailing_space);
	
	IMContainer checkbox_parent(dropdown_height, dropdown_height);
	checkbox_parent.setAlignment(CACenter, CACenter);
	
	IMContainer checkbox_holder(checkbox_size, checkbox_size);
	checkbox_parent.setElement(checkbox_holder);
	
	IMImage checkbox_background(checkbox);
	checkbox_background.setClip(false);
	checkbox_background.setZOrdering(2);
	checkbox_background.scaleToSizeX(checkbox_size);
	checkbox_background.addMouseOverBehavior(IMMouseOverScale( move_time, 12.0f, inQuartTween ), "");
	
	checkbox_holder.addFloatingElement(checkbox_background, "checkbox" + text, vec2(0,0));
	
	IMDivider checkbox_and_title_divider("checkbox_and_title_divider", DOHorizontal);
	IMContainer checkbox_and_title_container(10.0f, 10.0f);
	checkbox_and_title_container.setElement(checkbox_and_title_divider);
	IMText title(text, button_font_small);
	title.addMouseOverBehavior(text_color_mouse_over, "");
	
	checkbox_and_title_divider.append(checkbox_parent);
	checkbox_and_title_divider.appendSpacer(25.0f);
	checkbox_and_title_divider.append(title);

	main_divider.append(checkbox_and_title_container);
	main_container.setSizeY(dropdown_height + vertical_trailing_space);
	
	IMMessage onclick("option_changed");
	onclick.addString(text);
	onclick.addString("true");
	checkbox_and_title_divider.addLeftMouseClickBehavior( IMFixedMessageOnClick( onclick ), "");
	checkbox_and_title_divider.sendMouseOverToChildren();
	
	AddControllerItem(checkbox_and_title_container, onclick);
	gui_elements.insertLast(Checkbox(text, checkbox_parent, checkbox_holder, config_name));

	main_container.setElement(main_divider);
	parent.append(main_container);
}

void AddSlider(string text, IMDivider@ parent, string config_name, float max_value){
	float dropdown_width = 350.0f;
	float dropdown_height = 55.0f;
	float slider_width = 350.0f;
	float slider_height = 55.0f;
	float slider_button_size = 35.0f;
	float vertical_trailing_space = 10.0f;
	float leading_trailing_space = 200.0f;
	float whole_option_width = 800.0f;
	
	IMDivider main_divider("main_divider" + text, DOHorizontal);
	IMContainer main_container(whole_option_width, dropdown_height);
	
	main_container.setAlignment(CACenter, CACenter);
	
	IMContainer right_container("right_container" + text, DOHorizontal);
	right_container.setAlignment(CARight, CACenter);

	IMContainer left_container("left_container" + text, DOHorizontal);
	left_container.setAlignment(CALeft, CACenter);
	left_container.setSizeX(whole_option_width / 2.0f);

	IMText title(text, button_font_small);
	left_container.setElement(title);
	title.setZOrdering(2);

	IMContainer slider_parent(slider_width, slider_height);
	slider_parent.setAlignment(CACenter, CACenter);

	IMContainer slider_holder(slider_width, slider_height);
	slider_holder.setAlignment(CACenter, CACenter);

	IMImage slider_image(slider_bar);
	slider_image.setZOrdering(2);
	slider_image.scaleToSizeX(slider_width);
	slider_holder.setElement(slider_image);

	IMMessage on_enter("slider_activate");
	IMMessage on_over("slider_move_check");
	//Use the index as to find the correct ui element. So it doesn't have to search for it based on Text.
	on_over.addInt(gui_elements.size());
	on_enter.addInt(gui_elements.size());
	IMMessage on_exit("slider_deactivate");

	IMImage slider_button_image(slider_button);
	slider_button_image.setColor(button_font.color);
	slider_button_image.addMouseOverBehavior(text_color_mouse_over, "");
	slider_button_image.setClip(false);
	slider_button_image.setZOrdering(3);
	slider_button_image.setRotation(45);
	slider_button_image.scaleToSizeX(slider_button_size);

	slider_button_image.addMouseOverBehavior(IMFixedMessageOnMouseOver( on_enter, on_over, on_exit ), "");

	slider_holder.addFloatingElement(slider_button_image, "slider_button", vec2(0,slider_holder.getSizeY() / 2.0f - slider_button_size / 2.0f));
	slider_holder.setName("slider_container");
	
	IMContainer background_click_catcher(slider_width, slider_height);
	IMMessage click_jump_value("option_changed");
	click_jump_value.addString(text);
	click_jump_value.addString("click_jump_value");
	//background_click_catcher.addLeftMouseClickBehavior(IMFixedMessageOnClick(click_jump_value), "");
	slider_parent.addFloatingElement(background_click_catcher, "background_click_catcher", vec2(0), 0);

	slider_parent.setElement(slider_holder);

	right_container.setElement(slider_parent);
	main_divider.append(left_container);
	main_divider.append(right_container);
	main_container.setSizeY(dropdown_height + vertical_trailing_space);
	
	IMText percentage("25%", button_font_small);
	percentage.setSizeX(125);
	main_divider.append(percentage);
	
	IMMessage message_left("option_changed");
	message_left.addString(text);
	message_left.addString("-");
	
	IMMessage message_right("option_changed");
	message_right.addString(text);
	message_right.addString("+");
	
	AddControllerItem(slider_parent, null, message_left, message_right, null, null);
	gui_elements.insertLast(Slider(text, slider_holder, slider_button_image, percentage, config_name, max_value));
	
	main_container.setElement(main_divider);
	parent.append(main_container);
}

void AddScrollBar(IMDivider@ parent, float bar_width, float bar_height, int num_items, int max_items, int current_item){
	float slider_button_size = 35.0f;
	float vertical_trailing_space = 10.0f;
	float leading_trailing_space = 200.0f;
	bar_height -= (2.0f * 50.0f);
	float button_height = bar_height / num_items * max_items;
	
	//Don't show the scrollbar if there is enough roof for every item.
	if(num_items <= max_items){
		parent.appendSpacer(bar_width);
		return;
	}
	
	IMDivider main_divider("main_divider", DOVertical);
	IMContainer main_container(bar_width, bar_height);
	AddNextPageArrow(main_divider, -1);
	
	main_container.setAlignment(CACenter, CACenter);
	
	IMContainer slider_holder(bar_width, bar_height);
	slider_holder.setAlignment(CACenter, CACenter);

	IMImage slider_image(slider_bar_vertical);
	slider_image.setZOrdering(2);
	slider_image.scaleToSizeY(bar_height);
	slider_image.setClip(false);
	slider_holder.setElement(slider_image);

	IMMessage on_enter("slider_activate");
	IMMessage on_over("slider_move_check");
	//Use the index as to find the correct ui element. So it doesn't have to search for it based on Text.
	on_over.addInt(gui_elements.size());
	on_enter.addInt(gui_elements.size());
	IMMessage on_exit("slider_deactivate");

	IMImage slider_button_image( slider_button_vert );
	slider_button_image.setColor(button_font.color);
	slider_button_image.addMouseOverBehavior(text_color_mouse_over, "");
	slider_button_image.setClip(false);
	slider_button_image.setZOrdering(3);
	slider_button_image.setSize(vec2(slider_button_size, button_height));

	slider_button_image.addMouseOverBehavior(IMFixedMessageOnMouseOver( on_enter, on_over, on_exit ), "");
	float slider_pos_y = bar_height / num_items * current_item;
	slider_holder.addFloatingElement(slider_button_image, "slider_button", vec2(bar_width / 2.0f - slider_button_size / 2.0f, slider_pos_y));
	slider_holder.setName("slider_container");

	main_divider.append(slider_holder);
	
	IMMessage message_left("option_changed");
	message_left.addString("scroll_bar");
	message_left.addString("-");
	
	IMMessage message_right("option_changed");
	message_right.addString("scroll_bar");
	message_right.addString("+");
	
	//AddControllerItem(slider_parent, message_left, message_right);
	gui_elements.insertLast(ScrollBar(main_container, slider_button_image));
	AddNextPageArrow(main_divider, 1);
	main_container.setElement(main_divider);
	parent.append(main_container);
}

void ToggleUIElement(string name){
	for(uint i = 0; i < gui_elements.size(); i++){
		if(gui_elements[i].name == name){
			gui_elements[i].ToggleElement();
		}
	}
}

void AddNextPageArrow(IMDivider@ parent, int direction){
	float arrow_width = 50.0f;
	float arrow_height = 50.0f;
	//The extra space is needed for the arrow scaleonmouseover animation, or else they push the other elements.
	float extra = 50.0f;

	IMImage arrow( arrow_icon );
	arrow.addMouseOverBehavior( text_color_mouse_over, "" );
	IMContainer arrow_container("arrow_container" + direction, DOHorizontal);
	arrow_container.setSize(vec2(arrow_width + extra, arrow_height + extra));
	if(kAnimateMenu){
		arrow.addUpdateBehavior(IMMoveIn ( move_in_time, vec2(move_in_distance * -1, 0), inQuartTween ), "");
	}
	arrow.setClip(false);
	if(direction == -1){
		arrow.setRotation(-90);
	}else{
		arrow.setRotation(90);
	}
	arrow.scaleToSizeX(arrow_width);
	arrow_container.setSize(vec2(arrow.getSizeX(), arrow.getSizeY()));
	arrow_container.addFloatingElement(arrow, "arrow" + direction, vec2( 0.0f ));
	arrow.setColor(button_font.color);
	arrow.addLeftMouseClickBehavior( IMFixedMessageOnClick("shift_menu", direction), "");
	parent.append(arrow_container);
}

// Draw the fancy scrolling ribbon background/foreground
// Assumes:
//  - the GUI has at least one background and foreground layer
//  - there's nothing else in the first background and first foreground layer
class RibbonEffect {

    IMGUI@ theGUI;  // GUI to modify

    // Coordinates (in GUI space) for the various
    // Foreground objects
    vec2 fgUpper1Position;
    vec2 fgUpper2Position;
    vec2 fgLower1Position;
    vec2 fgLower2Position;
    // Background objects
    vec2 bgRibbonUp1Position;
    vec2 bgRibbonUp2Position;
    vec2 bgRibbonDown1Position;
    vec2 bgRibbonDown2Position;

    vec4 bgColor;
    vec4 fgColor;
    vec4 ribbonUpColor;
    vec4 ribbonDownColor;



    RibbonEffect( IMGUI@ _GUI,
              vec4 _bgColor = vec4(1.0,1.0,1.0,0.8 ),
              vec4 _fgColor = vec4( 0.7,0.7,0.7,0.7 ),
              vec4 _ribbonUpColor = vec4( 0.0,0.0,0.0,1.0 ),
              vec4 _ribbonDownColor = vec4( 0.0,0.0,0.0,1.0 ) ) {
        @theGUI = @_GUI;
        bgColor = _bgColor;
        fgColor = _fgColor;
        ribbonUpColor = _ribbonUpColor;
        ribbonDownColor = _ribbonDownColor;
    }

    // Derive the starting offsets the various visual components
    void resetPositions() {
        fgUpper1Position =      vec2( 0,    0 );
        fgUpper2Position =      vec2( 2560, 0 );
        fgLower1Position =      vec2( 0,    screenMetrics.GUISpace.y/2 );
        fgLower2Position =      vec2( 2560, screenMetrics.GUISpace.y/2 );
        bgRibbonUp1Position =   vec2( 0, 0 );
        bgRibbonUp2Position =   vec2( 0, screenMetrics.GUISpace.y );
        bgRibbonDown1Position = vec2( 0, 0 );
        bgRibbonDown2Position = vec2( 0, -screenMetrics.GUISpace.y );
    }

    // Make this a separate function so we can call it on resize
    void reset() {

        resetPositions();

        // get references to the foreground and background containers
        IMContainer@ background = theGUI.getBackgroundLayer();
        IMContainer@ foreground = theGUI.getForegroundLayer();

        background.clear();
        background.clear();

        // Make a new image
        IMImage backgroundImage("Textures/ui/menus/ribbon/blue_gradient_c_nocompress.tga");
        // fill the screen
        backgroundImage.setSize(vec2(2560.0, screenMetrics.GUISpace.y));
        backgroundImage.setColor( bgColor );
        // Call it bgBG and give it a z value of 1 to put it furthest behind
        background.addFloatingElement( backgroundImage, "bgBG", vec2( 0, 0 ), 1 );

        // Make a new image for half the upper image
        IMImage fgImageUpper1("Textures/ui/menus/ribbon/red_gradient_border_c.tga");
        fgImageUpper1.setSize(vec2(2560, screenMetrics.GUISpace.y/2));
        fgImageUpper1.setColor( fgColor );
        // use only the top half(ish) of the image
        fgImageUpper1.setImageOffset( vec2(0,0), vec2(1024, 600) );
        // flip it upside down
        fgImageUpper1.setRotation( 180 );
        // Call it gradientUpper1
        foreground.addFloatingElement( fgImageUpper1, "gradientUpper1", fgUpper1Position, 2 );

        // repeat for a second image so we can scroll unbrokenly
        IMImage fgImageUpper2("Textures/ui/menus/ribbon/red_gradient_border_c.tga");
        fgImageUpper2.setSize(vec2(2560, screenMetrics.GUISpace.y/2));
        fgImageUpper2.setColor( fgColor );
        fgImageUpper2.setImageOffset( vec2(0,0), vec2(1024, 600) );
        fgImageUpper2.setRotation( 180 );
        foreground.addFloatingElement( fgImageUpper2, "gradientUpper2", fgUpper2Position, 2 );

        // repeat again for the bottom image(s) (not flipped this time)
        IMImage bgImageLower1("Textures/ui/menus/ribbon/red_gradient_border_c.tga");
        bgImageLower1.setSize(vec2(2560, screenMetrics.GUISpace.y/2));
        bgImageLower1.setColor( fgColor );
        bgImageLower1.setImageOffset( vec2(0,0), vec2(1024, 600) );
        foreground.addFloatingElement( bgImageLower1, "gradientLower1", fgLower1Position, 2 );

        IMImage fgImageLower2("Textures/ui/menus/ribbon/red_gradient_border_c.tga");
        fgImageLower2.setSize(vec2(2560, screenMetrics.GUISpace.y/2));
        fgImageLower2.setColor( fgColor );
        fgImageLower2.setImageOffset( vec2(0,0), vec2(1024, 600) );
        foreground.addFloatingElement( fgImageLower2, "gradientLower2", fgLower2Position, 2 );

        // Repeat this same process for the two 'ribbons' which will, instead' go up and down
        IMImage bgRibbonUp1("Textures/ui/menus/ribbon/giometric_ribbon_c.tga");
        bgRibbonUp1.setImageOffset( vec2(256,0), vec2(768, 1024) );
        // Fill the left half of the screen
        bgRibbonUp1.setSize(vec2(1280, screenMetrics.GUISpace.y));
        bgRibbonUp1.setColor( ribbonUpColor );
        // Put this at the front of the blue background (z=3)
        background.addFloatingElement( bgRibbonUp1, "ribbonUp1", bgRibbonUp1Position, 3 );

        IMImage bgRibbonUp2("Textures/ui/menus/ribbon/giometric_ribbon_c.tga");
        bgRibbonUp2.setImageOffset( vec2(256,0), vec2(768, 1024) );
        bgRibbonUp2.setSize(vec2(1280, screenMetrics.GUISpace.y));
        bgRibbonUp2.setColor( ribbonUpColor );
        background.addFloatingElement( bgRibbonUp2, "ribbonUp2", bgRibbonUp2Position, 3 );

        IMImage bgRibbonDown1("Textures/ui/menus/ribbon/giometric_ribbon_c.tga");
        bgRibbonDown1.setImageOffset( vec2(256,0), vec2(768, 1024) );
        bgRibbonDown1.setSize(vec2(1280, screenMetrics.GUISpace.y));
        bgRibbonDown1.setColor( ribbonDownColor );
        background.addFloatingElement( bgRibbonDown1, "ribbonDown1", bgRibbonDown1Position, 3 );

        IMImage bgRibbonDown2("Textures/ui/menus/ribbon/giometric_ribbon_c.tga");
        bgRibbonDown2.setImageOffset( vec2(256,0), vec2(768, 1024) );
        bgRibbonDown2.setSize(vec2(1280, screenMetrics.GUISpace.y));
        bgRibbonDown2.setColor( ribbonDownColor );
        background.addFloatingElement( bgRibbonDown2, "ribbonDown2", bgRibbonDown2Position, 3 );

    }

    // Go through the motions
    void update() {
        // Calculate the new positions
        fgUpper1Position.x -= 2;
        fgUpper2Position.x -= 2;
        fgLower1Position.x -= 1;
        fgLower2Position.x -= 1;
        bgRibbonUp1Position.y -= 1;
        bgRibbonUp2Position.y -= 1;
        bgRibbonDown1Position.y += 1;
        bgRibbonDown2Position.y += 1;

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

        if( bgRibbonUp1Position.y <= -screenMetrics.GUISpace.y ) {
            bgRibbonUp1Position.y = screenMetrics.GUISpace.y;
        }

        if( bgRibbonUp2Position.y <= -screenMetrics.GUISpace.y ) {
            bgRibbonUp2Position.y = screenMetrics.GUISpace.y;
        }

        if( bgRibbonDown1Position.y >= screenMetrics.GUISpace.y ) {
            bgRibbonDown1Position.y = -screenMetrics.GUISpace.y;
        }

        if( bgRibbonDown2Position.y >= screenMetrics.GUISpace.y ) {
            bgRibbonDown2Position.y = -screenMetrics.GUISpace.y;
        }

        // Get a reference to the first background container
        IMContainer@ background = theGUI.getBackgroundLayer();
        IMContainer@ foreground = theGUI.getForegroundLayer();

        // Update the images position in the container
        foreground.moveElement( "gradientUpper1", fgUpper1Position );
        foreground.moveElement( "gradientUpper2", fgUpper2Position );
        foreground.moveElement( "gradientLower1", fgLower1Position );
        foreground.moveElement( "gradientLower2", fgLower2Position );
        background.moveElement( "ribbonUp1",      bgRibbonUp1Position );
        background.moveElement( "ribbonUp2",      bgRibbonUp2Position );
        background.moveElement( "ribbonDown1",    bgRibbonDown1Position );
        background.moveElement( "ribbonDown2",    bgRibbonDown2Position );
    }

};

// keep track of the math for our backgrounds
class BackgroundObject {
    int z;          // z ordering
    vec2 startPos; // where does it start rendering?
    float sizeX;     // how big is this in the x direction?
    vec2 shiftSize; // how much to shift it by for parallax
    string filename;// what file to load for this
    string GUIname; // name used to find this in the GUI
    float alpha;    // alpha value
    bool fadeIn;    // should we fade in

    BackgroundObject( string _fileName, string _GUIname, int _z,
                      vec2 _startPos, float _sizeX, vec2 _shiftSize, float _alpha,
                      bool _fadeIn ) {
        z = _z;
        startPos = _startPos;
        sizeX = _sizeX;
        shiftSize = _shiftSize;
        filename = _fileName;
        GUIname = _GUIname;
        alpha = _alpha;
        fadeIn = _fadeIn;
    }

    void addToGUI( IMGUI@ theGUI ) {

        // Set it to our background image
        IMImage backgroundImage( filename );

		// Make sure that no matter the aspect ratio, it covers the whole screen top to bottom
		if((backgroundImage.getSizeX() / backgroundImage.getSizeY()) > (screenMetrics.GUISpace.x / screenMetrics.GUISpace.y)){
			backgroundImage.scaleToSizeY(screenMetrics.GUISpace.y);
		}else{
			backgroundImage.scaleToSizeX(screenMetrics.GUISpace.x);
		}

        backgroundImage.setAlpha(alpha);

        if( fadeIn && kAnimateMenu) {
            backgroundImage.addUpdateBehavior( IMFadeIn( 2000, inSineTween ), filename + "-fadeIn" );
        }

        // Now set this as the element in the background container, this will center it
        theGUI.getBackgroundLayer().addFloatingElement( backgroundImage,
                                                           GUIname,
                                                           startPos,
                                                           z );

    }

    void adjustPositionByMouse( IMGUI@ theGUI ) {

        vec2 mouseRatio = vec2( theGUI.guistate.mousePosition.x/screenMetrics.GUISpace.x,
                                theGUI.guistate.mousePosition.y/screenMetrics.GUISpace.y );

        vec2 shiftPosition = vec2( shiftSize.x * mouseRatio.x,
                                   0 );//int( float(shiftSize.y) * mouseRatio.y ) );

        theGUI.getBackgroundLayer().moveElement( GUIname, startPos + shiftPosition );

    }

}

// Draw the picture for the background
void setBackGround() {
    // Clear the current background
	bgobjects.resize(0);
    imGUI.getBackgroundLayer( 0 ).clear();
	
	bgobjects.insertLast(BackgroundObject( GetInterlevelData("background"),
											"Background",
											1,
											vec2(0,0),
											screenMetrics.GUISpace.x,
											vec2(0,0),
											1.0,
											false ));
    for( uint i = 0; i < bgobjects.length(); ++i ) {
        bgobjects[i].addToGUI( imGUI );
    }
}

string ToLowerCase(string input){
	string output;
	for(uint i = 0; i < input.length(); i++){
		if(input[i] >= 65 &&  input[i] <= 90){
			string lower_case('0');
			lower_case[0] = input[i] + 32;
			output += lower_case;
		}else{
			string new_character('0');
			new_character[0] = input[i];
			output += new_character;
		}
	}
	return output;
}

class Search {
	bool active = false;
	bool pressed_return = false;
	int initial_sequence_id;
	IMText@ search_field;
	IMDivider@ parent;
	IMContainer@ clear_search;
	string query = "";
	int current_index = 0;
	int cursor_offset = 0;
	float long_press_input_timer = 0.0f;
	float long_press_timer = 0.0f;
	float long_press_threshold = 0.5f;
	float long_press_interval = 0.1f;
	uint max_query_length = 20;
	Search(){
		
	}
	void ResetSearch(){
		query = "";
		active = false;
		pressed_return = false;
	}
	void Activate(){
		if(active){return;}
		query = "";
		active = true;
		array<KeyboardPress> inputs = GetRawKeyboardInputs();
		if(inputs.size() > 0){
			initial_sequence_id = inputs[inputs.size()-1].s_id;
		}else{
			initial_sequence_id = -1;
		}
		parent.clear();
		parent.clearLeftMouseClickBehaviors();
		IMText new_search_field("", button_font_small);
		parent.append(new_search_field);
		@search_field = @new_search_field;
		IMText cursor("_", button_font_small);
		cursor.addUpdateBehavior(pulse, "");
		cursor.setZOrdering(4);
		parent.append(cursor);
	}
	void Deactivate(){
		active = false;
	}
	void SetSearchField(IMText@ _search_field, IMDivider@ _parent, IMContainer@ _clear_search){
		@search_field = @_search_field;
		@parent = @_parent;
		@clear_search = @_clear_search;
	}
	void Update(){
		if(active){
			if(GetInputPressed(0, "left")){
				if((cursor_offset) < int(query.length())){
					cursor_offset++;
					SetCurrentSearchQuery();
				}
			}
			else if(GetInputPressed(0, "right")){
				if(cursor_offset > 0){
					cursor_offset--;
					SetCurrentSearchQuery();
				}
			}
			if(long_press_timer > long_press_threshold){
				if(GetInputDown(0, "backspace")){
					long_press_input_timer += time_step;
					if(long_press_input_timer > long_press_interval){
						long_press_input_timer = 0.0f;
						//Check if there are enough chars to delete the last one.
						if(query.length() - cursor_offset > 0){
							uint new_length = query.length() - 1;
							if(new_length >= 0 && new_length <= max_query_length){
								query.erase(query.length() - cursor_offset - 1, 1);
								SetCurrentSearchQuery();
								return;
							}
						}else{
							return;
						}
					}
				}else if(GetInputDown(0, "delete")){
					long_press_input_timer += time_step;
					if(long_press_input_timer > long_press_interval){
						long_press_input_timer = 0.0f;
						//Check if there are enough chars to delete the next one.
						if(cursor_offset > 0){
							query.erase(query.length() - cursor_offset, 1);
							cursor_offset--;
							SetCurrentSearchQuery();
						}
						return;
					}
				}else if(GetInputDown(0, "left")){
					long_press_input_timer += time_step;
					if(long_press_input_timer > long_press_interval){
						long_press_input_timer = 0.0f;
						if((cursor_offset) < int(query.length())){
							cursor_offset++;
							SetCurrentSearchQuery();
						}
					}
					return;
				}else if(GetInputDown(0, "right")){
					long_press_input_timer += time_step;
					if(long_press_input_timer > long_press_interval){
						long_press_input_timer = 0.0f;
						if(cursor_offset > 0){
							cursor_offset--;
							imGUI.receiveMessage( IMMessage("refresh_menu_by_name") );
						}
					}
					return;
				}else{
					long_press_input_timer = 0.0f;
				}
				if(!GetInputDown(0, "delete") && !GetInputDown(0, "backspace") && !GetInputDown(0, "left") && !GetInputDown(0, "right")){
					long_press_timer = 0.0f;
				}
			}else{
				if(GetInputDown(0, "delete") || GetInputDown(0, "backspace") || GetInputDown(0, "left") || GetInputDown(0, "right")){
					long_press_timer += time_step;
				}else{
					long_press_timer = 0.0f;
				}
			}
			
			array<KeyboardPress> inputs = GetRawKeyboardInputs();
			if(inputs.size() > 0){
				uint16 possible_new_input = inputs[inputs.size()-1].s_id;
				if(possible_new_input != uint16(initial_sequence_id)){
					uint32 keycode = inputs[inputs.size()-1].keycode;
					initial_sequence_id = inputs[inputs.size()-1].s_id;
					//Print("new input = "+ keycode + "\n");
					
					array<int> ignore_keycodes = {27};
					if(ignore_keycodes.find(keycode) != -1 || keycode > 500){
						return;
					}
					//Enter/return pressed
					if(keycode == 13){
						current_index = 0;
						cursor_offset = 0;
						active = false;
						pressed_return = true;
						imGUI.receiveMessage( IMMessage("refresh_menu_by_name") );
						return;
					}
					//Backspace
					else if(keycode == 8){
						//Check if there are enough chars to delete the last one.
						if(query.length() - cursor_offset > 0){
							uint new_length = query.length() - 1;
							if(new_length >= 0 && new_length <= max_query_length){
								query.erase(query.length() - cursor_offset - 1, 1);
								active = true;
								SetCurrentSearchQuery();
								return;
							}
						}else{
							return;
						}
					}
					//Delete pressed
					else if(keycode == 127){
						if(cursor_offset > 0){
							query.erase(query.length() - cursor_offset, 1);
							cursor_offset--;
							active = true;
						}
						SetCurrentSearchQuery();
						return;
					}
					if(query.length() == 20){
						return;
					}
					string new_character('0');
					new_character[0] = keycode;
					query.insert(query.length() - cursor_offset, new_character);
					
					active = true;
					SetCurrentSearchQuery();
				}
			}
		}
	}
	void SetCurrentSearchQuery(){
		GetSearchResults(query);
        current_index = 0;
		imGUI.receiveMessage( IMMessage("refresh_menu_by_name") );
	}
	void ShowSearchResults(){
		if(active && !pressed_return){
			parent.clear();
			@search_field = IMText("", button_font_small);
			parent.append(search_field);
			IMText cursor("_", button_font_small);
			cursor.addUpdateBehavior(pulse, "");
			if(cursor_offset > 0){
				string first_part = query.substr(0, query.length() - cursor_offset);
				search_field.setText(first_part);
				parent.append(cursor);
				string second_part = query.substr(query.length() - cursor_offset, query.length());
				IMText second_search_field(second_part, button_font_small);
				parent.append(second_search_field);
			}else{
				search_field.setText(query);
				parent.append(cursor);
			}
		}
		//The search field is active but if the clear text button was pressed do nothing.
		else if(!active && pressed_return && query != ""){
			pressed_return = false;
			search_field.setText(query);
			IMImage clear_button(close_icon);
			clear_button.setColor(button_font.color);
			clear_button.setZOrdering(3);
			clear_search.setElement(clear_button);
			clear_button.scaleToSizeX(50.0f);
			parent.clearLeftMouseClickBehaviors();
			clear_button.addMouseOverBehavior(text_color_mouse_over, "");
			clear_button.addLeftMouseClickBehavior(IMFixedMessageOnClick("clear_search_results"), "");
			AddControllerItem(clear_search, IMMessage("clear_search_results"));
		}else if(query != "" && !pressed_return){
            search_field.setText(query);
			IMImage clear_button(close_icon);
			clear_button.setColor(button_font.color);
			clear_button.setZOrdering(3);
			clear_search.setElement(clear_button);
			clear_button.scaleToSizeX(50.0f);
			parent.clearLeftMouseClickBehaviors();
			clear_button.addMouseOverBehavior(text_color_mouse_over, "");
			clear_button.addLeftMouseClickBehavior(IMFixedMessageOnClick("clear_search_results"), "");
			AddControllerItem(clear_search, IMMessage("clear_search_results"));
		}else if(query == "" && pressed_return){
			pressed_return = false;
			imGUI.receiveMessage( IMMessage("clear_search_results") );
		}
	}
	void GetSearchResults(string query){
		
	}
}

void AddNoResults(IMDivider@ parent, bool fadein){
	int fadein_time = 250;
	vec4 background_color = vec4(0.10f,0.10f,0.10f,0.90f);
	vec2 inspector_size = vec2(1400, 700);
	float background_size_offset = 250.0f;
	
	IMContainer inspector_container(inspector_size.x, inspector_size.y);
	IMDivider inspector_divider("inspector_divider", DOVertical);
	inspector_container.setElement(inspector_divider);
	inspector_divider.setZOrdering(3);
	parent.append(inspector_container);
	
	//The main background
	IMImage main_background( white_background );
	if(fadein){
		main_background.addUpdateBehavior(IMFadeIn( fadein_time, inSineTween ), "");
	}
	main_background.setZOrdering(0);
	main_background.setSize(vec2(inspector_size.x - background_size_offset, inspector_size.y));
	inspector_container.addFloatingElement(main_background, "main_background", vec2(background_size_offset / 2.0f, 0.0f));
	main_background.setColor(background_color);
	
	IMText no_results_text("Nothing found.", button_font_large);
	inspector_divider.append(no_results_text);
	
	IMImage no_results_image(no_results);
	no_results_image.scaleToSizeX(100);
	inspector_divider.append(no_results_image);
}

void UpdateKeyboardMouse(){
	if(GetInputDown(0, "mousescrollup")){
		imGUI.receiveMessage(IMMessage( "shift_menu", -1));
	} else if(GetInputDown(0, "mousescrolldown")){
		imGUI.receiveMessage(IMMessage( "shift_menu", 1));
	}
}

void AddSearchbar(IMDivider@ parent, Search@ search){
	//Searchbar
	float searchbar_width = 500;
	float searchbar_height = 75;
	IMContainer searchbar_container(searchbar_width, searchbar_height);
	IMContainer clear_searchbar_container(0, searchbar_height);

	IMDivider searchbar_divider(DOHorizontal);
	searchbar_divider.setSize(vec2(searchbar_width, searchbar_height));
	searchbar_divider.setZOrdering(3);
	IMText search_text( "Search...", button_font_small );
	search_text.setAlpha(0.5f);
	
	IMContainer search_text_container(searchbar_width - searchbar_height, searchbar_height);
	search_text_container.addLeftMouseClickBehavior(IMFixedMessageOnClick("activate_search"), "");
	AddControllerItem(search_text_container, IMMessage("activate_search"));
	IMDivider search_text_divider(DOHorizontal);
	search_text_divider.setAlignment(CACenter, CACenter);
	search_text_divider.append(search_text);
	search_text_divider.setZOrdering(4);
	search_text.setZOrdering(4);
	search_text_container.setElement(search_text_divider);
	
	searchbar_divider.append(search_text_container);
	searchbar_divider.append(clear_searchbar_container);
	
	//Search object configuration
	search.SetSearchField(@search_text, @search_text_divider, @clear_searchbar_container);
	
	//Searchbar background
	IMImage searchbar_background( button_background_rectangle );
	searchbar_background.setAlpha(0.5f);
	searchbar_background.setSize(vec2(searchbar_width, searchbar_height));
	searchbar_container.setElement(searchbar_divider);
	searchbar_container.addFloatingElement(searchbar_background, "background", vec2(0,0));
	parent.append(searchbar_container);
}
void UpdateMovingSlider(){
	if(active_slider != -1){
		if(imGUI.guistate.leftMouseState == kMouseStillDown){
			vec2 current_mouse_pos = imGUI.guistate.mousePosition;
			checking_slider_movement = true;
			if(current_mouse_pos.x != old_mouse_pos.x){
				gui_elements[active_slider].SlideX(int(current_mouse_pos.x - old_mouse_pos.x));
				old_mouse_pos.x = current_mouse_pos.x;
			}
			if(current_mouse_pos.y != old_mouse_pos.y){
				gui_elements[active_slider].SlideY(int(current_mouse_pos.y - old_mouse_pos.y));
				old_mouse_pos.y = current_mouse_pos.y;
			}
		}else{
			if(checking_slider_movement){
				active_slider = -1;
				checking_slider_movement = false;
				imGUI.receiveMessage(IMMessage("refresh_options"));
			}
		}
	}
}
