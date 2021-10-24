enum drika_element_types { 	none,
							drika_wait_level_message,
							drika_wait,
							drika_set_enabled,
							drika_set_character,
							drika_create_particle,
							drika_play_sound};

class DrikaElement{
	drika_element_types drika_element_type = none;
	bool edit_mode = false;
	bool visible;
	bool has_settings = false;
	vec4 display_color = vec4(1.0);
	int index = -1;

	string GetSaveString(){return "";}
	string GetDisplayString(){return "";};
	void Update(){}
	bool Trigger(){return false;}
	void Reset(){}
	void AddSettings(){}
	void EditDone(){}
	void SetCurrent(bool _current){}
	void Delete(){}
	void ReceiveMessage(string message){}
	void SetIndex(int _index){
		index = _index;
	}
}
