void Init() {
}

void SetParameters() {
	params.AddFloatSlider("Delay",2.46,"min:0.01,max:10.0,step:0.01,text_mult:1");
}

array<Victim@> victims;
Object@ thisHotspot = ReadObjectFromID(hotspot.GetID());

class Victim{
	float timer = 0.0;
	int character_id = -1;
	Victim(float delay, int character_id){
		timer = delay;
		this.character_id = character_id;
	}
	bool UpdateTimer(float delta){
		timer -= delta;
		if(timer <= 0.0){
			KillCharacter(character_id);
			return true;
		}else{
			return false;
		}
	}
}

void KillCharacter(int character_id){
	MovementObject@ char = ReadCharacterID(character_id);
	char.Execute(	"SetKnockedOut(_dead);" +
					"Ragdoll(_RGDL_INJURED);");
}

void Reset(){
	victims.resize(0);
}

void HandleEvent(string event, MovementObject @mo){
	if(event == "enter"){
		OnEnter(mo);
	} else if(event == "exit"){
		OnExit(mo);
	}
}

void OnEnter(MovementObject @mo) {
	victims.insertLast(Victim(params.GetFloat("Delay"), mo.GetID()));
}

void OnExit(MovementObject @mo) {
	for(uint i = 0; i < victims.size(); i++){
		if(victims[i].character_id == mo.GetID()){
			victims.removeAt(i);
			return;
		}
	}
}

void Update(){
	for(uint i = 0; i < victims.size(); i++){
		if(victims[i].UpdateTimer(time_step)){
			victims.removeAt(i);
			return;
		}
	}
}
