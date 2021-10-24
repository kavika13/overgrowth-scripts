// Text display info
int main_text_id;
int ingame_text_id;
float text_visible;
bool show_text;

int TextInit(int width, int height) {
    int id = level.CreateTextElement();
    TextCanvasTexture @text = level.GetTextElement(id);
    text.Create(width, height);
    return id;
}

void UpdateIngameText(string str) {
    TextCanvasTexture @text = level.GetTextElement(ingame_text_id);
    text.ClearTextCanvas();
    string font_str = level.GetPath("font");
    TextStyle style;
    style.font_face_id = GetFontFaceID(font_str, 48);

    vec2 pen_pos = vec2(0,256);
    int line_break_dist = 42;
    text.SetPenPosition(pen_pos);
    text.SetPenColor(255,255,255,255);
    text.SetPenRotation(0.0f);
    
    text.AddText(str, style);

    text.UploadTextCanvasToTexture();
}

void SetIntroText() {
    TextCanvasTexture @text = level.GetTextElement(main_text_id);
    text.ClearTextCanvas();
    string font_str = level.GetPath("font");
    TextStyle small_style, big_style;
    small_style.font_face_id = GetFontFaceID(font_str, 48);
    big_style.font_face_id = GetFontFaceID(font_str, 72);

    vec2 pen_pos = vec2(0,256);
    text.SetPenPosition(pen_pos);
    text.SetPenColor(0,0,0,255);
    text.SetPenRotation(0.0f);
    text.AddText("Odds are ", small_style);
    float prob = ProbabilityOfWin(global_data.player_skill, curr_difficulty);
    int a, b;
    OddsFromProbability(1.0f-prob, a, b);
    if(a < b) {
        text.AddText("" + b+":"+a, big_style);
        text.AddText(" in your favor", small_style);
    } else if(a > b) {
        text.AddText("" + a+":"+b, big_style);
        text.AddText(" against you", small_style);
    } else {
        text.AddText("even", small_style);
    }

    int line_break_dist = 42;
    pen_pos.y += line_break_dist;
    text.SetPenPosition(pen_pos);
    text.AddText("There are ",small_style);
    text.AddText(""+audience_size,big_style);
    text.AddText(" spectators",small_style);

    pen_pos.y += line_break_dist;
    text.SetPenPosition(pen_pos);
    text.AddText("Good luck!",small_style);

    text.UploadTextCanvasToTexture();
}

void SetWinText(int new_fans, int total_fans, float excitement_level) {
    TextCanvasTexture @text = level.GetTextElement(main_text_id);
    text.ClearTextCanvas();
    string font_str = level.GetPath("font");
    TextStyle small_style, big_style;
    small_style.font_face_id = GetFontFaceID(font_str, 48);
    big_style.font_face_id = GetFontFaceID(font_str, 72);

    vec2 pen_pos = vec2(0,256);
    text.SetPenPosition(pen_pos);
    text.SetPenColor(0,0,0,255);
    text.SetPenRotation(0.0f);
    text.AddText("You won!", small_style);

    int line_break_dist = 42;
    pen_pos.y += line_break_dist;
    text.SetPenPosition(pen_pos);
    text.AddText("You gained ",small_style);
    text.AddText(""+new_fans,big_style);
    text.AddText(" fans",small_style);
    
    pen_pos.y += line_break_dist;
    text.SetPenPosition(pen_pos);
    text.AddText("Your fanbase totals ",small_style);
    text.AddText(""+total_fans,big_style);
    
    pen_pos.y += line_break_dist;
    text.SetPenPosition(pen_pos);
    text.AddText("Your skill assessment is now ",small_style);
    text.AddText(""+int((global_data.player_skill-0.5f)*40+1),big_style);

    pen_pos.y += line_break_dist;
    text.SetPenPosition(pen_pos);
    text.AddText("Audience ",small_style);
    text.AddText(""+int(excitement_level * 100.0f) + "%",big_style);
    text.AddText(" entertained",small_style);

    text.UploadTextCanvasToTexture();
}

void SetLoseText(int new_fans, float excitement_level) {
    TextCanvasTexture @text = level.GetTextElement(main_text_id);
    text.ClearTextCanvas();
    string font_str = level.GetPath("font");
    TextStyle small_style, big_style;
    small_style.font_face_id = GetFontFaceID(font_str, 48);
    big_style.font_face_id = GetFontFaceID(font_str, 72);
    int line_break_dist = 42;

    vec2 pen_pos = vec2(0,256);
    text.SetPenPosition(pen_pos);
    text.SetPenColor(0,0,0,255);
    text.SetPenRotation(0.0f);
    text.AddText("You were defeated.", small_style);
    
    if(new_fans > 0) {
        pen_pos.y += line_break_dist;
        text.SetPenPosition(pen_pos);
        text.AddText("You gained ",small_style);
        text.AddText(""+new_fans, big_style);
        text.AddText(" new fans",small_style);
    
        pen_pos.y += line_break_dist;
        text.SetPenPosition(pen_pos);
        text.AddText("Your fanbase totals ",small_style);
        text.AddText(""+global_data.fan_base,big_style);
    }

    pen_pos.y += line_break_dist;
    text.SetPenPosition(pen_pos);
    text.AddText("Your skill assessment is now ",small_style);
    text.AddText(""+int((global_data.player_skill-0.5f)*40+1),big_style);
    
    pen_pos.y += line_break_dist;
    text.SetPenPosition(pen_pos);
    text.AddText("Audience ",small_style);
    text.AddText(""+int(excitement_level * 100.0f) + "%",big_style);
    text.AddText(" entertained",small_style);

    text.UploadTextCanvasToTexture();
}

