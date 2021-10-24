int gold_;
int fame_;
int crowd_approval_;
int gov_approval_;

void NewCampaign(){
    gold_ = 0;
    fame_ = 0;
    crowd_approval_ = 0;
    gov_approval_ = 0;
    
    scenario = PickScenario();
    Equip();
    ExecuteScenario(scenario);
}

