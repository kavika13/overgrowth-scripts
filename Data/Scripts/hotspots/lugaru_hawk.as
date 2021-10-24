float time = 0;
float soundTimer = 0;
float soundInterval = 30.0f;
float moveInterval = 0.02f;
float moveSpeed = 0.01f;
int hawkID = -1;
float angle = 0.0f;

void Init() {

}


void Update() {
	if(hawkID == -1){
		Object@ thisHotspot = ReadObjectFromID(hotspot.GetID());
		hawkID = CreateObject("Data/Prototypes/Lugaru/Hawk_Offset.xml", true);
		Object@ hawkObj = ReadObjectFromID(hawkID);
		hawkObj.SetTranslation(thisHotspot.GetTranslation());
	}
    time += time_step;
    soundTimer += time_step;
    if(soundTimer > soundInterval){
		soundTimer = 0.0f;
    	PlaySound("Data/Sounds/lugaru/hawk.ogg");
    }

    if(time > moveInterval){
		time = 0;
		Object@ thisHotspot = ReadObjectFromID(hotspot.GetID());
	    Object@ hawkObj = ReadObjectFromID(hawkID);
	    quaternion oldRot = hawkObj.GetRotation();
		mat4 mat4Rot = Mat4FromQuaternion(oldRot);
		angle += moveSpeed;
		mat4Rot.SetRotationY(angle);
		quaternion newRot = QuaternionFromMat4(mat4Rot);
	    hawkObj.SetRotation(newRot);
		if(angle > 3.1415f * 2.0f){
			angle = 0;
		}
		if(EditorModeActive()){
	    	hawkObj.SetTranslation(thisHotspot.GetTranslation());
		}
	}
}

void Reset(){
	time = 0;
}
