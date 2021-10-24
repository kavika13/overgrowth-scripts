class DrikaSetCharacter : DrikaElement{
	bool enabled;
	int character_id;
	string character_path;
	string original_character_path;
	DrikaSetCharacter(int _index, int _character_id, string _character_path){
		index = _index;
		character_id = _character_id;
		character_path = _character_path;
		drika_element_type = drika_set_character;
		display_color = vec4(78, 136, 124, 255);
		has_settings = true;
	}
	string GetSaveString(){
		return "set_character " + character_id + " " + character_path;
	}

	string GetDisplayString(){
		return "SetCharacter " + character_id + " " + character_path;
	}
	void AddSettings(){
		ImGui_Text("Set To Character : ");
		ImGui_Text(character_path);
		if(ImGui_Button("Set Character File")){
			string new_path = GetUserPickedReadPath("xml", "Data/Characters");
			if(new_path != ""){
				character_path = new_path;
			}
		}
		ImGui_InputInt("Character ID", character_id);
	}
	bool Trigger(){
		if(!MovementObjectExists(character_id)){
			Log(info, "Character does not exist with id " + character_id);
			return false;
		}
		MovementObject@ character = ReadCharacterID(character_id);
		original_character_path = character.char_path;
		character.char_path = character_path;
		character.Execute(	"character_getter.Load(this_mo.char_path);" +
							"this_mo.RecreateRiggedObject(this_mo.char_path);");
		Log(info, "Done setting character ");
		return true;
	}
	void Reset(){
		if(!original_character_path.isEmpty() && MovementObjectExists(character_id)){
			MovementObject@ character = ReadCharacterID(character_id);
			character.char_path = original_character_path;
			character.Execute(	"character_getter.Load(this_mo.char_path);" +
								"this_mo.RecreateRiggedObject(this_mo.char_path);");
		}
	}
}
