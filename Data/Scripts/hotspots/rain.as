int rain_sound_id = -1;
float lightning_time = -1.0;
float next_lightning_time = -1.0;
float thunder_time = -1.0;
float lightning_distance; // in miles

vec3 old_sun_position;
vec3 old_sun_color;
float old_sun_ambient;

void Init() {
    old_sun_position = GetSunPosition();
    old_sun_color = GetSunColor();
    old_sun_ambient = GetSunAmbient();
}

void Dispose() {
    if(rain_sound_id != -1){
        StopSound(rain_sound_id);
    }
    SetSunAmbient(old_sun_ambient);// + 1.5*flash_amount);
    SetSkyTint(GetBaseSkyTint());
    SetSunColor(old_sun_color);
    SetSunPosition(old_sun_position);
}

void Update() {
    if(rain_sound_id == -1){
        rain_sound_id = PlaySoundLoop("Data/Sounds/weather/tapio/rain.wav", 1.0);
    }

    if(next_lightning_time < the_time){
        next_lightning_time = the_time + RangedRandomFloat(6.0, 12.0);//RangedRandomFloat(3.0, 6.0);
        lightning_distance = RangedRandomFloat(0.0, 1.0);
        thunder_time = the_time + lightning_distance * 5.0;
        lightning_time = the_time;
        SetSunPosition(normalize(vec3(RangedRandomFloat(-1.0, 1.0), RangedRandomFloat(0.5, 1.0), RangedRandomFloat(-1.0, 1.0))));
    }

    if(thunder_time < the_time && thunder_time != -1.0){
        if(lightning_distance < 0.3){
            PlaySoundGroup("Data/Sounds/weather/thunder_strike_mike_koenig.xml");
        } else {
            PlaySoundGroup("Data/Sounds/weather/tapio/thunder.xml");
        }
        thunder_time = -1.0;
    }

    if(lightning_time <= the_time){
        float flash_amount = min(1.0, max(0.0, 1.0 + (lightning_time - the_time) * 0.1));
        SetSunAmbient(1.5);// + 1.5*flash_amount);
        flash_amount = min(1.0, max(0.0, 1.0 + (lightning_time - the_time) * 2.0));
        flash_amount *= RangedRandomFloat(0.8,1.2);
        flash_amount *= 3.0;
        SetSkyTint(mix(GetBaseSkyTint() * 0.7, vec3(3.0), flash_amount));
        SetSunColor(vec3(flash_amount) * 1.0);
    }

}