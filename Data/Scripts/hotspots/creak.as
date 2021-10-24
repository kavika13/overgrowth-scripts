float delay = 5.0f;
array<string> sounds = {"Data/Sounds/ambient/amb_forest_wood_creak_1.wav",
                        "Data/Sounds/ambient/amb_forest_wood_creak_2.wav",
                        "Data/Sounds/ambient/amb_forest_wood_creak_3.wav"};
void UpdateSounds(){
    delay -= time_step;
    if(delay < 0.0f){
        delay = RangedRandomFloat(0.1, 10.0f);
        MovementObject@ player = ReadCharacterID(player_id);
        vec3 position = player.position + vec3(RangedRandomFloat(-10.0f, 10.0f),RangedRandomFloat(-10.0f, 10.0f),RangedRandomFloat(-10.0f, 10.0f));
        PlaySound(sounds[rand() % sounds.size()], position);
    }
}