float time = 0;
float lastTime;
float hawkXTimer = 0;
bool xPos = true;
bool zPos = false;
float hawkZTimer = 1.0;
float soundInterval = 30.0f;
float moveSpeed = 0.5f;
float distance = 5.0f;
int hawkID = -1;
Object@ thisHotspot = ReadObjectFromID(hotspot.GetID());

void Init() {
	hawkID = CreateObject("Data/Objects/lugaru/hawk.xml");
	Object@ hawkObj = ReadObjectFromID(hawkID);
	hawkObj.SetTranslation(thisHotspot.GetTranslation());
}


void Update() {
    time += time_step;
    if(xPos){
    	hawkXTimer += time_step * moveSpeed;
    }else if(!xPos){
    	hawkXTimer -= time_step * moveSpeed;
    }

    if(zPos){
    	hawkZTimer += time_step * moveSpeed;
    }else if(!zPos){
    	hawkZTimer -= time_step * moveSpeed;
    }

    if(hawkXTimer > 1 || hawkXTimer < -1){
    	xPos = !xPos;
    }
    if(hawkZTimer > 1 || hawkZTimer < -1){
    	zPos = !zPos;
    }
    if(time > soundInterval){
    	time = 0;
    	PlaySound("Data/Sounds/lugaru/hawk.ogg");
    }

    if(round(time, 20) != round(lastTime, 20)){
    	
	    quaternion hotspotRot = thisHotspot.GetRotation();
	    vec3 direction = hotspotRot * vec3(hawkXTimer,0,hawkZTimer);
	    Object@ hawkObj = ReadObjectFromID(hawkID);
	    quaternion newRot;
	    vec3 newPos = thisHotspot.GetTranslation() + normalize(direction) * distance;
	    GetRotationBetweenVectors(hawkObj.GetTranslation(), newPos, newRot);

	    DebugDrawWireSphere(hawkObj.GetTranslation(), 0.1f, vec3(1), _delete_on_update);
	    DebugDrawWireSphere(thisHotspot.GetTranslation(), 0.1f, vec3(1), _delete_on_update);
	    DebugDrawWireSphere(newPos, 0.1f, vec3(1), _delete_on_update);

	    //hawkObj.SetRotation(newRot);
	    //hawkObj.SetTranslation(newPos);

	}
	lastTime = time;
}

void Reset(){
	time = 0;
	lastTime;
	hawkXTimer = 0;
	xPos = true;
	zPos = false;
	hawkZTimer = 1.0;
	soundInterval = 30.0f;
	moveSpeed = 0.5f;
	distance = 5.0f;
}

float round(float f, int decimal)
{
	return floor(f * decimal)/ decimal;
}