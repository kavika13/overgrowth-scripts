#include "campaignmenudata.as"

CampaignMenuData campaign_menu_data;

void Initialize(){
    campaign_menu_data.Initialize();

    campaign_menu_data.campaign_mode = kChallengeList;
    LevelSetReader lsr("Data/LevelSets/challenge_test.xml");
    string curr_path;
    LevelInfoReader lir;
    while(lsr.Next(curr_path)){
        lir.Load("Data/Levels/"+curr_path);
        LevelInfo li;
        li.name = lir.visible_name();
        li.path = curr_path;
        li.description = lir.visible_description();
        campaign_menu_data.challenge_levels.push_back(li);
    }
}

void Dispose() {

}

bool CanGoBack() {
    return true;
}

void Update(){
    campaign_menu_data.Update();
}

void DrawGUI(){
    campaign_menu_data.DrawGUI();
}

void Draw(){
}
