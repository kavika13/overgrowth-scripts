
int spike_num = 5;

int spiked = -1;

int spike_tip_hotspot_id = -1;
int spike_visible_id = -1;
int spike_collidable_id = -1;

int armed = 0;

const bool super_spike = false;

void HandleEvent(string event, MovementObject @mo){
    //DebugText("wed", "Event: " + event, _fade);
    if(event == "enter"){
        OnEnter(mo);
    } else if(event == "exit"){
        OnExit(mo);
    }else if(event == "reset"){
        spike_num = 20;
        DebugText("spike_num", "spike_num: "+spike_num, 10.0);
    }
}

void OnEnter(MovementObject @mo) {
}

void OnExit(MovementObject @mo) {
}

void Dispose() {
    if(spike_collidable_id != -1){
        QueueDeleteObjectID(spike_collidable_id);
        spike_collidable_id = -1;
    }
    if(spike_visible_id != -1){
        QueueDeleteObjectID(spike_visible_id);
        spike_visible_id = -1;
    }
    if(spike_tip_hotspot_id != -1){
        QueueDeleteObjectID(spike_tip_hotspot_id);
        spike_tip_hotspot_id = -1;
    }
}

void Init() {
}

void Reset(){
    spike_num = 5;
    spiked = -1;
    UpdateObjects();
}

void SetArmed(int val){
    if(val != armed){
        armed = val;
        UpdateObjects();
    }
}

void ReceiveMessage(string msg) {
    if(!super_spike){
        if(msg == "arm_spike"){
            SetArmed(1);
        }
        if(msg == "disarm_spike"){
            if(spiked == -1){
                SetArmed(0);
            }
        }
    }
}

void UpdateObjects() {
    bool short = params.HasParam("Short");
    if(short){
        if(spike_visible_id == -1){
            spike_visible_id = CreateObject("Data/Objects/Environment/camp/sharp_stick_short_nocollide.xml", true);
            ReadObjectFromID(spike_visible_id).SetEnabled(false);
        }
        if(spike_collidable_id == -1){
            spike_collidable_id = CreateObject("Data/Objects/Environment/camp/sharp_stick_short.xml", true);
            ReadObjectFromID(spike_collidable_id).SetEnabled(false);
        }
    } else {
        if(spike_visible_id == -1){
            spike_visible_id = CreateObject("Data/Objects/Environment/camp/sharp_stick_long_nocollide.xml", true);
            ReadObjectFromID(spike_visible_id).SetEnabled(false);
        }
        if(spike_collidable_id == -1){
            spike_collidable_id = CreateObject("Data/Objects/Environment/camp/sharp_stick_long.xml", true);
            ReadObjectFromID(spike_collidable_id).SetEnabled(false);
        }
        
    }
    if(spike_tip_hotspot_id == -1){
        spike_tip_hotspot_id = CreateObject("Data/Objects/Hotspots/spike_tip.xml", true);
        ReadObjectFromID(spike_tip_hotspot_id).SetEnabled(true);
    }
    if(spike_tip_hotspot_id != -1){
        Object@ obj = ReadObjectFromID(spike_tip_hotspot_id);
        Object@ hotspot_obj = ReadObjectFromID(hotspot.GetID());
        obj.SetRotation(hotspot_obj.GetRotation());
        obj.SetTranslation(hotspot_obj.GetTranslation()+hotspot_obj.GetRotation() * vec3(0,hotspot_obj.GetScale()[1]*2+0.2,0));
        obj.SetScale(vec3(0.2));
        obj.GetScriptParams().SetInt("Parent", hotspot.GetID());
    }
    if(spike_visible_id != -1 && armed == 1){
        Object@ obj = ReadObjectFromID(spike_visible_id);
        Object@ hotspot_obj = ReadObjectFromID(hotspot.GetID());
        obj.SetRotation(hotspot_obj.GetRotation());
        obj.SetTranslation(hotspot_obj.GetTranslation()+hotspot_obj.GetRotation() * vec3(0.03,0,0.0));
        obj.SetScale(vec3(1,hotspot_obj.GetScale().y*2.0*(short?0.92:0.85),1));
    }
    if(spike_collidable_id != -1 && armed == 0){
        Object@ obj = ReadObjectFromID(spike_collidable_id);
        Object@ hotspot_obj = ReadObjectFromID(hotspot.GetID());
        obj.SetRotation(hotspot_obj.GetRotation());
        obj.SetTranslation(hotspot_obj.GetTranslation()+hotspot_obj.GetRotation() * vec3(0.03,0,0.0));
        obj.SetScale(vec3(1,hotspot_obj.GetScale().y*2.0*(short?0.92:0.85),1));
    }

    if(armed == 1){
        ReadObjectFromID(spike_collidable_id).SetEnabled(false);
        ReadObjectFromID(spike_visible_id).SetEnabled(true);
    }
    if(armed == 0){
        ReadObjectFromID(spike_collidable_id).SetEnabled(true);
        ReadObjectFromID(spike_visible_id).SetEnabled(false);
    }
}

void PreDraw(float curr_game_time) {
    UpdateObjects();
}

void Draw() {
}

void Update() {
    if(armed == 1){
        Object@ obj = ReadObjectFromID(hotspot.GetID());
        /*for(int i=0; i<200; ++i){
            DebugDrawWireSphere(obj.GetTranslation() + obj.GetRotation() * (vec3(0,obj.GetScale()[1]*2,0)) * mix(-1, 1, (i)/199.0), mix(0.01,0.1,(i)/199.0), vec3(1.0), _delete_on_draw);        
        }*/

        vec3 start = obj.GetTranslation() + obj.GetRotation() * (vec3(0,obj.GetScale()[1]*2,0)) * -1.0f;
        vec3 end = obj.GetTranslation() + obj.GetRotation() * (vec3(0,obj.GetScale()[1]*2,0)) * 1.0f;

        vec3 start_to_end = normalize(end-start);
        if(!super_spike){
            col.CheckRayCollisionCharacters(end-start_to_end*0.1, end+start_to_end*0.05);
        } else {
            col.CheckRayCollisionCharacters(start, end+start_to_end*0.05);            
        }
        if(sphere_col.NumContacts() != 0){
            MovementObject@ char = ReadCharacterID(sphere_col.GetContact(0).id);
            if(super_spike || dot(char.velocity, start_to_end) < 0.0){
                if(spike_num > 0){
                    char.rigged_object().Stab(sphere_col.GetContact(0).position, normalize(end-start), (spike_num==4)?1:0, 0);
                    --spike_num;
                }
                if(spiked == -1){
                    vec3 dir = normalize(start-end);
                    float extend = 0.4;
                    col.CheckRayCollisionCharacters(start+dir*extend, end+dir*-extend);
                    for(int i=0; i<sphere_col.NumContacts(); ++i){
                        int bone = sphere_col.GetContact(i).tri;
                        char.rigged_object().SpikeRagdollPart(bone,start,end,sphere_col.GetContact(i).position);   
                    }
                    col.CheckRayCollisionCharacters(end+dir*-extend,start+dir*extend);
                    for(int i=0; i<sphere_col.NumContacts(); ++i){
                        int bone = sphere_col.GetContact(i).tri;
                        char.rigged_object().SpikeRagdollPart(bone,end,start,sphere_col.GetContact(i).position);   
                    }
                    //string sound = "Data/Sounds/hit/hit_medium_juicy.xml";
                    string sound = "Data/Sounds/weapon_foley/cut/flesh_hit.xml";
                    PlaySoundGroup(sound, char.position);
                    spiked = char.GetID();
                    if(char.GetIntVar("knocked_out") != _dead){
                        char.Execute("TakeBloodDamage(1.0f);Ragdoll(_RGDL_INJURED);injured_ragdoll_time = RangedRandomFloat(0.0, 12.0);death_hint=_hint_avoid_spikes;");
                    }
                }
            }
            /*vec3 force = camera.GetFacing() * 5000.0f;
            vec3 hit_pos = sphere_col.GetContact(0).position;
            char.Execute("vec3 impulse = vec3("+force.x+", "+force.y+", "+force.z+");" +
                         "vec3 pos = vec3("+hit_pos.x+", "+hit_pos.y+", "+hit_pos.z+");" +
                         "HandleRagdollImpactImpulse(impulse, pos, 5.0f);");*/
        } 
    }
}