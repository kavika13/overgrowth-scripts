void Init() {

}
Object@ thisHotspot = ReadObjectFromID(hotspot.GetID());

void SetParameters() {
}

void Reset(){

}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
        OnEnter(mo);
    } else if(event == "exit"){
        OnExit(mo);
    }
}

void OnEnter(MovementObject @mo) {
   mo.rigged_object().FixedRagdollPart(1,thisHotspot.GetTranslation());
}

void OnExit(MovementObject @mo) {
    mo.rigged_object().ClearBoneConstraints();
}

void Update(){
    
}