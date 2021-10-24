
void SetParameters() {
    params.AddInt("lantern_id", -1);
    params.AddInt("light_id", -1);
}

void PreDraw(float curr_game_time) {
}

void Update() {
  int light_id = params.GetInt("light_id");
  int lantern_id = params.GetInt("lantern_id");
  if(light_id != -1 && lantern_id != -1){
      Object@ light_obj = ReadObjectFromID(light_id);
      Object@ lantern_obj = ReadObjectFromID(lantern_id);
      DebugText("lantern_obj", "lantern_obj: "+lantern_obj.GetTranslation(), 0.5f);
      light_obj.SetTranslation(lantern_obj.GetTranslation()+lantern_obj.GetRotation() * vec3(0,-0.05,0));
  }
}