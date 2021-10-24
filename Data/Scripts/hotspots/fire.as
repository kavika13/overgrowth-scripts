void Init() {
    if(useLights){
        //The main light is used to show the flickering on teh surroundings. Including near chars.
        Object@ newLight = ReadObjectFromID(CreateObject("Data/Objects/lights/dynamic_light.xml"));
        @mainLight = @newLight;
        newLight.SetTranslation(thisHotspot.GetTranslation());
        //3x it's size to make sure all the near objects get lit.
        newLight.SetScale(vec3(3.0f));
    }
}

void SetParameters() {
    params.AddFloatSlider("FlameSideVel",0.2,"min:0.0,max:1.0,step:0.1,text_mult:10");
    params.AddFloatSlider("FlameUpVel",0.2,"min:0.0,max:10.0,step:0.1,text_mult:10");
}

class light{
    //The light class is used to create multiple point lights when flame particles spawn.
    Object@ lightObj;
    float spawnTime;
    light(Object@ _lightObj, float _spawnTime){
        //Use @ to make the script use handles in stead of new objects.
        @lightObj = @_lightObj;
        spawnTime = _spawnTime;
    }
}

class flame{
    int id;
    float spawnTime;
    flame(int _id, float _spawnTime){
        id = _id;
        spawnTime = _spawnTime;
    }
}

class victim{
    MovementObject@ char;
    Object@ charObj;
    array<light@> lights;
    array<flame@> flames;
    float origSpeed;
    array<vec3> paletteColors(5);
    bool burned = false;
    bool applyDamage = true;
    victim(MovementObject@ _char){
        @char = @_char;
        //Get the current speed multiplier to be able to reset it when the character exits.
        origSpeed = char.GetFloatVar("p_speed_mult");
        //Limit the speed while the character is inside, like the char is stuck.
        SetCharSpeed(_char, origSpeed * 0.3f);
        //Again use handles to avoid using ReadOjectFromID in each update.
        @charObj = ReadObjectFromID(char.GetID());
        //Store the original palette colors to be able to reset.
        for(int i = 0; i < charObj.GetNumPaletteColors(); i++){
            paletteColors[i] = charObj.GetPaletteColor(i);
        }
    }
    void HandleLights(){
        if(useLights){
            for(uint i = 0;i < lights.size(); i++){
                //To let the light begin at a low intensity and end low as well calculate how far it is from the middle of the duration.
                float difference = abs((the_time - lights[i].spawnTime) - (lightDuration / 2));
                //1 is totally bright and 0 is dark.
                lights[i].lightObj.SetTint(vec3(1 - difference));
                if(the_time > lights[i].spawnTime + lightDuration){
                    //The the time is over the duration, delete the light.
                    DeleteObjectID(lights[i].lightObj.GetID());
                    //Remove it from the array to avoid -1.
                    lights.removeAt(i);
                    //The same index is still the current one, so decrease the counter.
                    i--;
                }
            }
        }
    }
    void HandleFlames(){
        if(tintParticles){
            for(uint i = 0;i < flames.size(); i++){
                float difference = the_time - flames[i].spawnTime;
                //DebugText("dre", 1 - (difference / flameDuration) + "", _fade);
                TintParticle(flames[i].id, vec3(1 - (difference / flameDuration)));
                if(the_time > flames[i].spawnTime + flameDuration){
                    flames.removeAt(i);
                    i--;
                }
            }
        }
    }
    void AddLight(vec3 position, float _spawnTime){
        if(useLights){
            Object@ newLight = ReadObjectFromID(CreateObject("Data/Objects/lights/dynamic_light.xml"));
            newLight.SetTranslation(position);
            newLight.SetScale(vec3(3.0f));
            lights.insertLast(light(@newLight, _spawnTime));
        }
    }
    void Reset(){
        SetCharSpeed(char, origSpeed);
        for(int i = 0; i < 4; i++){
            charObj.SetPaletteColor(i, paletteColors[i]);
        }
        for(uint i = 0;i < lights.size(); i++){
            DeleteObjectID(lights[i].lightObj.GetID());
        }
        burned = false;
    }
}

array<victim@> victims;
float time;
float interval = 0.1f;
Object@ thisHotspot = ReadObjectFromID(hotspot.GetID());
Object@ mainLight;
array<flame@> flames;
int currentIndex = 0;
float burnSpeed = 0.002f;
bool useLights = false;
bool tintParticles = true;
float lightDuration = 2.0f;
float flameDuration = 15.0f;

void Reset(){
    for(uint i = 0; i < victims.size(); i++){
        victims[i].Reset();
    }
    victims.resize(0);
    currentIndex = 0;
}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
        OnEnter(mo);
    } else if(event == "exit"){
        OnExit(mo);
    }
}

void OnEnter(MovementObject @mo) {
    int index = InsideArray(mo.GetID());
    if(index == -1){
        victims.insertLast(victim(mo));
    }else{
        SetCharSpeed(mo, victims[index].origSpeed * 0.3f);
        victims[index].applyDamage = true;
    }
    mo.Execute("this_mo.rigged_object().anim_client().AddLayer(\"Data/Animations/r_writhe.anm\",1.0f,_ANM_FROM_START);");
}

void OnExit(MovementObject @mo) {
    //Find on which index the character is. 
    int index = InsideArray(mo.GetID());
    //If the character is not in the array (somehow) don't do anything.
    if(index != -1){
        
    }
}

void Update(){
    //The fire effect always shows in the middle of the hotspot.
    //Limit the spawn amount for performance purposes.
    HandleFlames();
    if(floor(the_time * 100) % 5 == 0){
        float sideways = params.GetFloat("FlameSideVel");
        float up = params.GetFloat("FlameUpVel");
        //The fire particle gets projected mostly upwards and a bit to the side to widen the flame.
        int id = MakeParticle("Data/Particles/fire_expanding.xml", thisHotspot.GetTranslation(), vec3(RangedRandomFloat(-sideways,sideways),RangedRandomFloat(0.0f,up),RangedRandomFloat(0.0f,sideways)));
        flames.insertLast(flame(id, the_time));
    }
    //There is one big light at the fire position.
    if(useLights){
        //If the hotspot is moved in editor mode then move the light with it.
        if(thisHotspot.GetTranslation() != mainLight.GetTranslation()){
            mainLight.SetTranslation(thisHotspot.GetTranslation());
        }
        //Change the tint(color) of the light object to change the light intensity.
        mainLight.SetTint(vec3(RangedRandomFloat(0.2f,0.8f)));
    }
    //Now the update gets into hurting the characters inside.
    if(victims.size() != 0){

        //This time is used to update the script every interval. For performance.
        time += time_step;
        //Get the victim object from the list and use it for the rest of the loop.
        victim@ curVictim = victims[currentIndex];

        if(curVictim.applyDamage){
            if(curVictim.char.GetFloatVar("roll_ik_fade") == 1.0f || curVictim.char.GetBoolVar("pre_jump")){
                curVictim.applyDamage = false;
                curVictim.char.Execute("this_mo.rigged_object().anim_client().RemoveAllLayers();ResetLayers();");
                SetCharSpeed(curVictim.char, curVictim.origSpeed);
            }
        }

        //Even if the character enters and exits the hotspot it will still be in the victims array,
        //this way the light keep getting handled and the palette colors are kept.
        curVictim.HandleLights();
        curVictim.HandleFlames();
        if(curVictim.applyDamage){
            //Keep turning the charObj darker while it is not fully cooked.
            if(!curVictim.burned){
                for(int p = 0; p < curVictim.charObj.GetNumPaletteColors(); p++){
                    curVictim.charObj.SetPaletteColor(p, curVictim.charObj.GetPaletteColor(p) - vec3(burnSpeed));
                    //When the palette reaches 0.02f it is dark enough to keep displaying some features like clothes.
                    if(curVictim.charObj.GetPaletteColor(p).x < 0.02f){
                        //Stop burning.
                        curVictim.burned = true;
                    }
                }
            }
            int randomBoneNr = rand()%(curVictim.char.rigged_object().skeleton().NumBones() - 1);
            Skeleton @skeleton = curVictim.char.rigged_object().skeleton();
            //Check for physics or else the game crashes, for some reason.
            if(skeleton.HasPhysics(randomBoneNr)){
                mat4 transform = skeleton.GetBoneTransform(randomBoneNr);
                //The smoke particle keeps spawning all the time.
                MakeParticle("Data/Particles/stepdust.xml", transform.GetTranslationPart(), vec3(RangedRandomFloat(0.0f,0.2f),RangedRandomFloat(1.0f,5.0f),RangedRandomFloat(0.0f,0.2f)));
                //Closer the color value is to the exact middle between black and white, the more flame particles should spawn.
                float difference = abs(curVictim.charObj.GetPaletteColor(0).x - ((curVictim.paletteColors[0].x - 0.02f) / 2));
                //This causes the fire to start slow, then blaze, and end slow.
                float randomVal = RangedRandomFloat(0.0f,curVictim.paletteColors[0].x);
                if(randomVal > difference){
                    if(!curVictim.burned){
                        int id = MakeParticle("Data/Particles/fire_expanding.xml", transform.GetTranslationPart(), vec3(RangedRandomFloat(0.0f,0.2f),max(0.5f, RangedRandomFloat(0.0f,(0.5 - difference) * 10.0f)),RangedRandomFloat(0.0f,0.2f)));
                        curVictim.flames.insertLast(flame(id, the_time));
                        //Add a light once in a while on a created particle.
                        if(floor(the_time * 100) % 200 == 0){
                            curVictim.AddLight(transform.GetTranslationPart(), the_time);
                        }
                    }
                }
            }
            //Update some stuff that is not time crucial.
            if(time > interval){
                
                if(curVictim.char.GetIntVar("knocked_out") == _awake){
                    vec3 direction = vec3(RangedRandomFloat(-1.0f,1.0f), RangedRandomFloat(-1.0f,1.0f), RangedRandomFloat(-1.0f,1.0f));
                    vec3 force = direction * 0.1f;
                    //Bounce the character around a bit to make him look hurt by the fire.
                    curVictim.char.velocity += direction;
                    //Use TakeBloodDamage so that the character will hold his stomach when escaping the hotspot.
                    curVictim.char.Execute("TakeBloodDamage("+ 0.05f +");");
                    PlaySound("Data/Sounds/fire.wav", curVictim.char.position);
                    if(curVictim.char.GetIntVar("knocked_out") != _awake){
                        //Ragdoll when the character is not _awake anymore, thus dead.
                        curVictim.char.Execute("Ragdoll(_RGDL_INJURED);");
                        //Scream to sell the effect.
                        PlaySound("Data/Sounds/voice/animal2/voice_bunny_groan_3.wav", curVictim.char.position);
                    }else{
                        
                    }
                }
                //Reset the timer to let the interval start again.
                time = 0.0f;
            }
        }
        currentIndex++;
        if(uint(currentIndex) >= victims.size()){
            currentIndex = 0;
        }
    }
}

int InsideArray(int id){
    int inside = -1;
    for(uint i = 0; i < victims.size(); i++){
        if(victims[i].char.GetID() == id){
            inside = i;
        }
    }
    return inside;
}

void SetCharSpeed(MovementObject@ char, float speed){
    char.Execute("p_speed_mult = " + speed + ";" +
                    "run_speed = _base_run_speed * p_speed_mult;" +
                    "true_max_speed = _base_true_max_speed * p_speed_mult;");
}

void HandleFlames(){
        if(tintParticles){
            for(uint i = 0;i < flames.size(); i++){
                float difference = the_time - flames[i].spawnTime;
                TintParticle(flames[i].id, vec3(1 - (difference / flameDuration)));
                if(the_time > flames[i].spawnTime + flameDuration){
                    flames.removeAt(i);
                    i--;
                }
            }
        }
    }