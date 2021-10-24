float g_elapsed_time_before_soak_reload = 0.0f;
bool g_was_soak_level_load_sent = false;

void SetParameters() {
	params.AddString("next_level", "");
    params.AddFloat("time_to_next_level", 5.0f);
}

// void Init() {
// }

// void Dispose() {
// }

// void ReceiveMessage(string msg) {
// }

void Update() {
    string next_level_path = params.GetString("next_level");
    const float k_time_to_load_next_soak_level = params.GetFloat("time_to_next_level");

    if (next_level_path != "") {
        g_elapsed_time_before_soak_reload += time_step;

        DebugText("soaktest1", "Time til next level: " + (k_time_to_load_next_soak_level - g_elapsed_time_before_soak_reload), 0.5f);

        if (g_elapsed_time_before_soak_reload >= k_time_to_load_next_soak_level && !g_was_soak_level_load_sent) {
            g_was_soak_level_load_sent = true;
            level.SendMessage("loadlevel \"" + next_level_path + "\"");
        }
    }
}

// void PreDraw(float curr_game_time) {
// }

// void Draw() {
// }
