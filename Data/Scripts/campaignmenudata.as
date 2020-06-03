#include "ui_effects.as"

enum CampaignMode {
    kCampaignList,
    kChallengeList,
    kLugaruLevelList
};

class LevelInfo {
    string name;
    string path;
    string description;
}

class CampaignMenuData {
    CampaignMode campaign_mode;
    int gui_id;
    RibbonBackground ribbon_background;
    float visible;
    float target_visible;
    IMUIContext imui_context;

    array<LevelInfo> challenge_levels;

    void Initialize(){
        gui_id = -1;
        visible = 0.0f;
        target_visible = 1.0f;
        ribbon_background.Init();
        imui_context.Init();
    }

    void Update(){
        visible = UpdateVisible(visible, target_visible);
        switch(campaign_mode) {
        case kCampaignList:    
        case kChallengeList:    
            if(GetInputPressed(0,'esc')){
                this_ui.SendCallback("back");
            }
            break;
        case kLugaruLevelList:
            if(GetInputPressed(0,'esc')){
                campaign_mode = kCampaignList;
                imui_context.Init();
            }
            break;
        }
        ribbon_background.Update();
    }

    bool Button(int i, string str) {
        int column = i/12;
        int row = i%12;
        UIState state;
        bool button_pressed = imui_context.DoButton(i, 
            vec2(GetScreenWidth()*0.5 - 330 - 50 + column * 200, GetScreenHeight()*0.5 + 165 - 40*row),
            vec2(GetScreenWidth()*0.5 - 330 - 50 + column * 200 + 200, GetScreenHeight()*0.5 + 165 + 35 - 40*row),
            state);
        vec4 color(1.0f);
        switch(state){
        case kHot:
            color.a = 0.9;
            break;
        case kActive:
            color.a = 1.0;
            break;
        default:
            color.a = 0.8;
            break;
        }
        {   HUDImage @image = hud.AddImage();
            image.SetImageFromPath("Data/UI/challengemenu/images/play_ingame.png");
            float scale = 0.35f;
            image.position.x = GetScreenWidth() * 0.5 - image.GetWidth() * scale - 337 + 200 * column;
            image.position.y =  GetScreenHeight() * 0.5 + 161 - 40 * row;
            image.position.z = 5; 
            image.scale *= scale;
            image.color = color;
        }
        hud.Draw();
        color.x = 0.5;
        color.z = 0.5;
        DrawTextAtlas("Data/Fonts/edosz.ttf", 32, kSmallLowercase, str, 
                      int(GetScreenWidth() * 0.5 - 330 + column * 200), 
                      int(GetScreenHeight() * 0.5 - 173 + 40 * row), 
                      color);
        return button_pressed;
    }

    void DrawGUI(){
        imui_context.UpdateControls();
        ribbon_background.DrawGUI(visible);
        {   HUDImage @image = hud.AddImage();
            image.SetImageFromPath("Data/UI/challengelevel/images/divider_ingame.png");
            float scale = 0.6f;
            image.position.x = GetScreenWidth() * 0.5 - image.GetWidth() * scale + 215;
            image.position.y =  GetScreenHeight() * 0.5 + 205;
            image.position.z = 5; 
            image.scale *= scale;
            image.color.a = 0.7f;
        }
        hud.Draw();
        switch(campaign_mode){
        case kCampaignList:
            DrawTextAtlas("Data/Fonts/edosz.ttf", 68, kSmallLowercase, "Select Campaign", 
                          int(GetScreenWidth() * 0.5 - 400), int(GetScreenHeight() * 0.5 - 238), vec4(vec3(1.0f), 0.7f));
            if(Button(0, "Lugaru")){
                campaign_mode = kLugaruLevelList;
                imui_context.Init();
            } 
            if(Button(1, "Arena")){
                this_ui.SendCallback("arenas/stucco_courtyard_arena.xml");
            }
//            if(Button(2, "Advanced Arena (experimental)")){
//                this_ui.SendCallback("arenas/multirena_dev_copy.xml");
//            }
            break;
        case kLugaruLevelList:
            DrawTextAtlas("Data/Fonts/edosz.ttf", 68, kSmallLowercase, "Select Level", 
                          int(GetScreenWidth() * 0.5 - 400), int(GetScreenHeight() * 0.5 - 238), vec4(vec3(1.0f), 0.7f));
            for(int i=0; i<=23; ++i){
                string str = ""+(i+1);
                if(Button(i, str)){
                    switch(i){
                    case 0: this_ui.SendCallback("LugaruStory/Village.xml"); break;
                    case 1: this_ui.SendCallback("LugaruStory/Village_2.xml"); break;
                    case 2: this_ui.SendCallback("LugaruStory/Wonderer.xml"); break;
                    case 3: this_ui.SendCallback("LugaruStory/Village_3.xml"); break;
                    case 4: this_ui.SendCallback("LugaruStory/Clearing.xml"); break;
                    case 5: this_ui.SendCallback("LugaruStory/Raider_patrol.xml"); break;
                    case 6: this_ui.SendCallback("LugaruStory/Raider_camp.xml"); break;
                    case 7: this_ui.SendCallback("LugaruStory/Raider_sentries.xml"); break;
                    case 8: this_ui.SendCallback("LugaruStory/Raider_base.xml"); break;
                    case 9: this_ui.SendCallback("LugaruStory/Raider_base_2.xml"); break;
                    case 10: this_ui.SendCallback("LugaruStory/Old_raider_base.xml"); break;
                    case 11: this_ui.SendCallback("LugaruStory/Village_4.xml"); break;
                    case 12: this_ui.SendCallback("LugaruStory/Rocky_hall.xml"); break;
                    case 13: this_ui.SendCallback("LugaruStory/Heading_north.xml"); break;
                    case 14: this_ui.SendCallback("LugaruStory/Heading_north_2.xml"); break;
                    case 15: this_ui.SendCallback("LugaruStory/Jack's_camp.xml"); break;
                    case 16: this_ui.SendCallback("LugaruStory/Jack's_camp_2.xml"); break;
                    case 17: this_ui.SendCallback("LugaruStory/Rocky_hall_2.xml"); break;
                    case 18: this_ui.SendCallback("LugaruStory/Rocky_hall_3.xml"); break;
                    case 19: this_ui.SendCallback("LugaruStory/To_alpha_wolf.xml"); break;
                    case 20: this_ui.SendCallback("LugaruStory/To_alpha_wolf_2.xml"); break;
                    case 21: this_ui.SendCallback("LugaruStory/Wolf_den.xml"); break;
                    case 22: this_ui.SendCallback("LugaruStory/Wolf_den_2.xml"); break;
                    case 23: this_ui.SendCallback("LugaruStory/Rocky_hall_4.xml"); break;
                    }
                }
            }
            break;
        case kChallengeList:
            DrawTextAtlas("Data/Fonts/edosz.ttf", 68, kSmallLowercase, "Select Challenge", 
                          int(GetScreenWidth() * 0.5 - 400), int(GetScreenHeight() * 0.5 - 238), vec4(vec3(1.0f), 0.7f));
            for(int i=0, len=challenge_levels.size(); i<len; ++i){
                if(Button(i, challenge_levels[i].name)){
                    this_ui.SendCallback(challenge_levels[i].path);
                }
            }
            break;
        }
    }
}
