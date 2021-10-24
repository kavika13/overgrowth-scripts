class DrikaWaitLevelMessage : DrikaElement{
	string message;
	bool received_message = false;
	DrikaWaitLevelMessage(int _index, string _message){
		index = _index;
		message = _message;
		drika_element_type = drika_wait_level_message;
		display_color = vec4(110, 94, 180, 255);
		has_settings = true;
	}
	string GetSaveString(){
		return "wait_level_message " + message;
	}

	string GetDisplayString(){
		return "WaitLevelMessage " + message;
	}
	void AddSettings(){
		ImGui_Text("Wait for message : ");
		ImGui_InputText("Message", message, 64);
	}
	void ReceiveMessage(string _message){
		if(_message == message){
			Log(info, "received correct message ");
			received_message = true;
		}
	}
	bool Trigger(){
		return received_message;
	}
	void Reset(){
		received_message = false;
	}
}
