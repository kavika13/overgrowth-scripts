void Init() {
}

int collectables_needed;
int collectables_contained = 0;
bool condition_satisfied = false;

string GetTypeString() {
    return "collectable_target";
}

void SetParameters() {
    params.AddString("Collectables needed","1");
    collectables_needed = max(1, params.GetInt("Collectables needed"));
}

void HandleEventItem(string event, ItemObject @obj){
    //Print("ITEMOBJECT EVENT: "+event+"\n");
    if(event == "enter"){
        OnEnterItem(obj);
    } 
    if(event == "exit"){
        OnExitItem(obj);
    } 
}

void OnEnterItem(ItemObject @obj) {
    if(obj.GetType() == _collectable){
        ++collectables_contained;
        condition_satisfied = IsConditionSatisfied();
        //Print("Containing "+collectables_contained+" collectables\n");
    }
}

void OnExitItem(ItemObject @obj) {
    if(obj.GetType() == _collectable){
        collectables_contained = max(0, collectables_contained-1);
        condition_satisfied = IsConditionSatisfied();
        //Print("Containing "+collectables_contained+" collectables\n");
    }
}

bool IsConditionSatisfied() {
    //DebugText("a","Collectables needed: "+collectables_needed, 0.5f);
    //DebugText("b","Collectables contained: "+collectables_contained, 0.5f);
    return collectables_needed <= collectables_contained;
}