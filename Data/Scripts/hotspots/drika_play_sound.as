class DrikaPlaySound : DrikaElement{
	string sound_path;
	int object_id;
	DrikaPlaySound(int _index, int _object_id, string _sound_path){
		index = _index;
		object_id = _object_id;
		sound_path = _sound_path;
		drika_element_type = drika_play_sound;
		display_color = vec4(145, 99, 66, 255);
		has_settings = true;
	}
	string GetSaveString(){
		return "play_sound " + object_id + " " + sound_path;
	}

	string GetDisplayString(){
		return "PlaySound " + sound_path;
	}
	void AddSettings(){
		ImGui_Text("Sound Path : ");
		ImGui_Text(sound_path);
		if(ImGui_Button("Set Sound Path")){
			string new_path = GetUserPickedReadPath("wav", "Data/Sounds");
			if(new_path != ""){
				sound_path = new_path;
			}
		}
		ImGui_InputInt("Object ID", object_id);
	}
	bool Trigger(){
		if(ObjectExists(object_id)){
			Object@ obj = ReadObjectFromID(object_id);
			PlaySound(sound_path, obj.GetTranslation());
			return true;
		}else{
			Log(info, "Object does not exist.");
			return false;
		}
	}
}
