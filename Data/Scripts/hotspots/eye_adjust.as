bool inside = false;

void Init() {
}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
        OnEnter(mo);
    } else if(event == "exit"){
        OnExit(mo);
    }
}

void OnEnter(MovementObject @mo) {
    inside = true;
}

void OnExit(MovementObject @mo) {
    inside = false;
}

void Update() {
    if(inside){
        SetHDRWhitePoint(mix(GetHDRWhitePoint(), params.GetFloat("HDR White point"), 0.05));
        SetHDRBlackPoint(mix(GetHDRBlackPoint(), params.GetFloat("HDR Black point"), 0.05));
        SetHDRBloomMult(mix(GetHDRBloomMult(), params.GetFloat("HDR Bloom multiplier"), 0.05));
    }
}

void SetParameters() {
    params.AddFloatSlider("HDR White point",GetHDRWhitePoint(),"min:0,max:2,step:0.001,text_mult:100");
    params.AddFloatSlider("HDR Black point",GetHDRBlackPoint(),"min:0,max:2,step:0.001,text_mult:100");
    params.AddFloatSlider("HDR Bloom multiplier",GetHDRBloomMult(),"min:0,max:5,step:0.001,text_mult:100");

}