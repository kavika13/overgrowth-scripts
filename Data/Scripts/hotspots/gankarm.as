bool played;

void Reset() {
    played = false;
}

void Init() {
    Reset();
}

void SetParameters() {
    params.AddString("Name", "Gunk");
}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
        //Print("Entered Gank\n");
        OnEnter(mo);
		played = true;
    } if(event == "exit"){
        //Print("Exited Gank\n");
    }
}

void OnEnter(MovementObject @mo) {
	Object@ obj = ReadObjectFromID(mo.GetID());
	ScriptParams@ params = obj.GetScriptParams();
	if(params.HasParam("Name") && params.GetString("Name") == "Gunk"){
	mo.Execute("SetIKChainElementInflate(\"leftarm\",0,0.0f);");
	mo.Execute("SetIKChainElementInflate(\"leftarm\",1,0.0f);");
	mo.Execute("SetIKChainElementInflate(\"leftarm\",2,0.0f);");
	mo.Execute("SetIKChainElementInflate(\"leftarm\",3,0.0f);");
	mo.Execute("SetIKChainElementInflate(\"lefthand\",0,0.0f);");
	mo.Execute("SetIKChainElementInflate(\"lefthand\",1,0.0f);");
	mo.Execute("SetIKChainElementInflate(\"lefthand\",2,0.0f);");
	mo.Execute("SetIKChainElementInflate(\"lefthand\",-1,0.0f);");
	mo.Execute("SetIKChainElementInflate(\"lefthand\",-2,0.0f);");
	mo.Execute("SetIKChainElementInflate(\"lefthand\",-3,0.0f);");
	mo.Execute("SetIKChainElementInflate(\"leftfingers\",1.0,0.0f);");
	mo.Execute("SetIKChainElementInflate(\"leftfingers\",0.0,0.0f);");
	mo.Execute("SetIKChainElementInflate(\"leftfingers\",-1.0,0.0f);");
	mo.Execute("SetIKChainElementInflate(\"leftthumb\",-1.0,0.0f);");
	mo.Execute("SetIKChainElementInflate(\"leftthumb\",-1.0,0.0f);");
	mo.Execute("SetIKChainElementInflate(\"leftthumb\",-1.0,0.0f);");
	mo.Execute("this_mo.rigged_object().skeleton().SetBoneInflate(6, 0.0f);");
	mo.Execute("this_mo.rigged_object().skeleton().SetBoneInflate(13, 0.0f);");
	mo.Execute("this_mo.rigged_object().skeleton().SetBoneInflate(15, 0.0f);");
	mo.Execute("this_mo.rigged_object().skeleton().SetBoneInflate(14, 0.0f);");
	}
}
