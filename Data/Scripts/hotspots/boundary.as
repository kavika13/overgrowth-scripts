void Init() {
}

string placeholderPath = "Data/Objects/block.xml";
array<int> charIDs;
array<vec3> charOldPos;
const int _ragdoll_state = 4;

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
    if(charIDs.find(mo.GetID()) == -1){
        charIDs.insertLast(mo.GetID());
		charOldPos.insertLast(mo.position);
    }
}

void OnExit(MovementObject @mo) {
    //Find on which index the character is.
    int index = charIDs.find(mo.GetID());
    //If the character is not in the array (somehow) don't do anything.
    if(index != -1){
		charIDs.removeAt(index);
		charOldPos.removeAt(index);
    }
}

void Update(){
	if(EditorModeActive()){
		ShowPlaceholder();
	}else{
		for(uint i = 0; i < charIDs.size(); i++){
			MovementObject@ this_mo = ReadCharacterID(charIDs[i]);
		    const float _push_force_mult = 2.0f;
		    vec3 push_force;
			vec3 oldPos = charOldPos[i];
			vec3 direction = normalize(this_mo.position - oldPos);
	        push_force.x -= direction.x;
	        push_force.z -= direction.z;
		    push_force *= _push_force_mult;
		    if(length_squared(push_force) > 0.0f){
		        this_mo.velocity += push_force;
		        if(this_mo.GetIntVar("state") == _ragdoll_state){
		            this_mo.rigged_object().ApplyForceToRagdoll(push_force * 500.0f, this_mo.rigged_object().skeleton().GetCenterOfMass());
		        }
		    }
		}
	}
}

void ShowPlaceholder(){
	//Object@ hotspotObj = ReadObjectFromID(hotspot.GetID());
	//PlaceholderObject@ placeholder_object = cast<PlaceholderObject@>(hotspotObj);
    //placeholder_object.SetPreview(path);
}
