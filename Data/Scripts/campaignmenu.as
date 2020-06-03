#include "campaignmenudata.as"

CampaignMenuData campaign_menu_data;

void Initialize(){
    campaign_menu_data.Initialize();
    campaign_menu_data.campaign_mode = kCampaignList;        
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
