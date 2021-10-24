void Init() {
}

void SetParameters() {
    params.AddFloatSlider("Time",10.0f,"min:0.1,max:50.0,step:1.0,text_mult:1");
    params.AddString("Text", "You're not too smart...");
}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
        OnEnter(mo);
    } else if(event == "exit"){
        OnExit(mo);
    }
}

float drown_timer = 0.0f;
bool triggered = false;
int victim_id = -1;
int font_size = 70;

void Update(){
    if(victim_id != -1){
        if(GetInputDown(ReadCharacterID(victim_id).controller_id, "crouch")){
            drown_timer += time_step;
            if(drown_timer > params.GetFloat("Time")){
                victim_id = -1;
                drown_timer = 0.0f;
                triggered = true;
                level.SendMessage("displaytext \""+params.GetString("Text")+"\"");
            }
        }else{
            drown_timer = 0.0f;
        }
    }
}

void Reset(){
    if(triggered){
        level.SendMessage("cleartext");
        triggered = false;
    }
}

void OnExit(MovementObject @mo) {
    if(mo.GetID() == victim_id){
        drown_timer = 0.0f;
        victim_id = -1;
    }
}

void OnEnter(MovementObject @mo) {
    victim_id = mo.GetID();
}
