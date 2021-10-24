class DrikaWait : DrikaElement{
	float timer;
	int duration;
	DrikaWait(int _index, int _duration){
		index = _index;
		duration = _duration;
		timer = duration / 1000.0;
		drika_element_type = drika_wait;
		display_color = vec4(152, 113, 80, 255);
		has_settings = true;
	}
	string GetSaveString(){
		return "wait " + duration;
	}

	string GetDisplayString(){
		return "Wait " + duration;
	}
	void AddSettings(){
		ImGui_Text("Wait in ms : ");
		ImGui_DragInt("Duration", duration, 1.0, 1, 10000);
	}
	bool Trigger(){
		if(timer <= 0.0){
			Log(info, "timer  done");
			return true;
		}else{
			timer -= time_step;
			return false;
		}
	}
	void Reset(){
		timer = duration / 1000.0;
	}
}
