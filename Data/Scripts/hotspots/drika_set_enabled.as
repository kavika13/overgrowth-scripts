class DrikaSetEnabled : DrikaElement{
	bool enabled;
	int object_id;
	DrikaSetEnabled(int _index, int _object_id, bool _enabled){
		index = _index;
		object_id = _object_id;
		enabled = _enabled;
		drika_element_type = drika_set_enabled;
		Reset();
		display_color = vec4(88, 122, 147, 255);
		has_settings = true;
	}
	string GetSaveString(){
		return "set_enabled " + object_id + " " + enabled;
	}

	string GetDisplayString(){
		return "SetEnabled " + object_id + " " + enabled;
	}
	void AddSettings(){
		ImGui_Text("Set To : ");
		ImGui_SameLine();
		ImGui_Checkbox("", enabled);
		ImGui_InputInt("Object ID", object_id);
	}
	bool Trigger(){
		if(!ObjectExists(object_id)){
			Log(info, "Object does not exist with id " + object_id);
			return false;
		}else{
			Log(info, "set " + object_id + " " + enabled);
			Object@ obj = ReadObjectFromID(object_id);
			obj.SetEnabled(enabled);
			return true;
		}
	}
	void Reset(){
		if(ObjectExists(object_id)){
			Object@ obj = ReadObjectFromID(object_id);
			obj.SetEnabled(!enabled);
		}
	}
}
