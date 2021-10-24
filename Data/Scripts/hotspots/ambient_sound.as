void Init() {
    hotspot.SetCollisionEnabled(false);
}

int sound_handle = -1;
string playing_sound_path;
bool one_shot = false;
float sound_play_time = 0.0f;

void Stop() {
    if(sound_handle != -1){
        StopSound(sound_handle);
        sound_handle = -1; 
    }   
}

void SetParameters() {
    params.AddString("Sound Path","Data/Sounds/filename.wav");
    params.AddIntCheckbox("Global",true);
    params.AddFloat("Fade Distance",1.0f);
    if(params.GetFloat("Fade Distance") < 0.01f){
        params.SetFloat("Fade Distance", 0.01f);
    }
    params.AddFloatSlider("Gain",1.0f,"min:0,max:1,step:0.01");
    params.AddFloat("Delay Min",3.0f);
    params.AddFloat("Delay Max",10.0f);
    string path = params.GetString("Sound Path");
    // Check for .wav suffix, otherwise FileExists returns true on folders, etc.
    bool is_wav = true;
    bool is_xml = true;
    string suffix = ".wav";
    string suffix_alternate = ".WAV";
    string xml_suffix = ".xml";
    string xml_suffix_alternate = ".XML";
    if(path.length() < 4){
        is_wav = false;
        is_xml = false;
    } else {
        for(int i=0; i<4; ++i){
            Print("Comparing "+path[path.length()-i-1]+" to "+suffix[3-i]+"\n");
            if(path[path.length()-i-1] != suffix[3-i] && path[path.length()-i-1] != suffix_alternate[3-i]){
                is_wav = false;
            }
            if(path[path.length()-i-1] != xml_suffix[3-i] && path[path.length()-i-1] != xml_suffix_alternate[3-i]){
                is_xml = false;
            }
        }
    }
    one_shot = false;
    if(is_wav && FileExists(path)){
        Print("File exists: "+path+"\n");
        if(playing_sound_path != path){
            Stop();
        }
        if(sound_handle == -1){
            Print("playing sound\n");
            sound_handle = PlaySoundLoop(path, 0.0);
            playing_sound_path = path;
        }
    } else if(is_xml && FileExists(path)){
        Print("File exists: "+path+"\n");
        Stop();
        playing_sound_path = path;
        one_shot = true;
    } else {
        Stop();
    }
}

void Reset(){
}

void Dispose(){
    Stop();
}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
        OnEnter(mo);
    } else if(event == "exit"){
        OnExit(mo);
    }
}

void OnEnter(MovementObject @mo) {
}

void OnExit(MovementObject @mo) {
}

float GetGain() {
    if(params.GetInt("Global") == 1){
        return params.GetFloat("Gain");
    } else {
        mat4 transform = ReadObjectFromID(hotspot.GetID()).GetTransform();
        vec3 pos = invert(transform) * camera.GetPos();
        float distance = 0.0f;
        for(int i=0; i<3; ++i){
            distance = max(distance, (pos[i] - 2.0)*ReadObjectFromID(hotspot.GetID()).GetScale()[i]);
            distance = max(distance, -(pos[i] + 2.0)*ReadObjectFromID(hotspot.GetID()).GetScale()[i]);
        }
        return max(0.0, 1.0f - distance / params.GetFloat("Fade Distance")) * params.GetFloat("Gain");
    }
}

void PreDraw(float curr_game_time) {
    EnterTelemetryZone("Ambient Sound Update");
    if(sound_handle != -1){
        SetSoundGain(sound_handle, GetGain());
    }
    if(one_shot){
        if(sound_play_time < the_time){
            PlaySoundGroup(playing_sound_path, ReadObjectFromID(hotspot.GetID()).GetTranslation());   
            sound_play_time = the_time + RangedRandomFloat(params.GetFloat("Delay Min"), params.GetFloat("Delay Max"));
        }
        //Print("playing_sound_path: "+playing_sound_path+"\n");     
    }
    LeaveTelemetryZone();
}


void DrawEditor(){
    Object@ obj = ReadObjectFromID(hotspot.GetID());
    DebugDrawBillboard("Data/Textures/ui/speaker.png",
                       obj.GetTranslation(),
                       obj.GetScale()[1]*2.0,
                       vec4(vec3(0.5), 1.0),
                       _delete_on_draw);
}
