string GetTypeString() {
    return "therium2_player_jump_height";
}

void SetParameters() {
    params.AddFloatSlider("Initial Jetpack Fuel", 5.0f, "min:0.0,max:20.0");
    params.AddFloatSlider("Initial Jump Velocity Multiplier", 1.0f, "min:0.0,max:5.0,step:0.1,text_mult:100");
}

void ReceiveMessage(string message) {
    if(message == "therium2_player_jumped") {
        float new_jetpack_fuel = params.GetFloat("Initial Jetpack Fuel");
        float initial_jump_velocity_multiplier = params.GetFloat("Initial Jump Velocity Multiplier");

        for(int i = 0, len = GetNumCharacters(); i < len; i++) {
            MovementObject@ character = ReadCharacter(i);

            if(ReadObjectFromID(character.GetID()).GetPlayer()) {
                character.Execute(
                    "jump_info.jetpack_fuel = " + new_jetpack_fuel + ";" +
                    "this_mo.velocity.y *= " + initial_jump_velocity_multiplier + ";");
            }
        }
    }
}
