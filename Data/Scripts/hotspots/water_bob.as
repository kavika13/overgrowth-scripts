void Init() {
}

void SetParameters() {
    params.AddString("Objects","");
}

void Reset(){
}

void Dispose(){
}

void Update(){
    TokenIterator token_iter;
    token_iter.Init();
    string str = params.GetString("Objects");
    while(token_iter.FindNextToken(str)){
        int id = atoi(token_iter.GetToken(str));
        if(ObjectExists(id)){
          Object@ obj = ReadObjectFromID(id);
          if(obj.GetEnabled()){
            DuplicateObject(obj);
            obj.SetEnabled(false);
          }
          /*vec3 pos = obj.GetTranslation();
          pos[1] = -4.200 + sin(the_time) * 0.01 + sin(the_time * 2.7) * 0.015 + sin(the_time * 4.3) * 0.008;
          obj.SetTranslation(pos);
          quaternion rot;
          rot = quaternion(vec4(1,0,0,sin(the_time*3.0)*0.01));
          rot = quaternion(vec4(0,0,1,sin(the_time*3.7)*0.01))*rot;
          //rot = quaternion(vec4(0,1,0,3.1417 * -0.8)) * rot;
          obj.SetRotation(rot);*/
        }
    }    
}


void Draw(){
    /*if(EditorModeActive()){
        Object@ obj = ReadObjectFromID(hotspot.GetID());
        DebugDrawBillboard("Data/Textures/ui/speaker.png",
                           obj.GetTranslation(),
                           obj.GetScale()[1]*2.0,
                           vec4(vec3(0.5), 1.0),
                           _delete_on_draw);
    }*/
}
