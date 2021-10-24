void Init() {
}

void SetParameters() {
    params.AddString("Objects","");
}

void Reset(){
}

void Dispose(){
}

vec3 orig_translation;
quaternion orig_rotation;

void Update(){
    TokenIterator token_iter;
    token_iter.Init();
    string str = params.GetString("Objects");
    while(token_iter.FindNextToken(str)){
        int id = atoi(token_iter.GetToken(str));
        if(ObjectExists(id)){
          Object@ obj = ReadObjectFromID(id);
          if(!params.HasParam("SavedTransform")){
            vec3 translation = obj.GetTranslation();
            quaternion quat = obj.GetRotation();
            string transform_str;
            for(int i=0; i<3; ++i){
              transform_str += translation[i] + " ";
            }
            transform_str += quat.x + " ";
            transform_str += quat.y + " ";
            transform_str += quat.z + " ";
            transform_str += quat.w;
            params.AddString("SavedTransform", transform_str);
          } else {
            string transform_str = params.GetString("SavedTransform");
            TokenIterator token_iter2;
            token_iter2.Init();
            token_iter2.FindNextToken(transform_str);
            orig_translation[0] = atof(token_iter2.GetToken(transform_str));
            token_iter2.FindNextToken(transform_str);
            orig_translation[1] = atof(token_iter2.GetToken(transform_str));
            token_iter2.FindNextToken(transform_str);
            orig_translation[2] = atof(token_iter2.GetToken(transform_str));
            token_iter2.FindNextToken(transform_str);
            orig_rotation.x = atof(token_iter2.GetToken(transform_str));
            token_iter2.FindNextToken(transform_str);
            orig_rotation.y = atof(token_iter2.GetToken(transform_str));
            token_iter2.FindNextToken(transform_str);
            orig_rotation.z = atof(token_iter2.GetToken(transform_str));
            token_iter2.FindNextToken(transform_str);
            orig_rotation.w = atof(token_iter2.GetToken(transform_str));
          }
          /*if(obj.GetEnabled()){
            DuplicateObject(obj);
            obj.SetEnabled(false);
          }*/
          vec3 pos = orig_translation;
          float translation_scale = 4.0;
          float rotation_scale = 2.0;
          float time_scale = 0.2;
          pos[1] += (sin(the_time*time_scale) * 0.01 + sin(the_time * 2.7*time_scale) * 0.015 + sin(the_time * 4.3*time_scale) * 0.008)*translation_scale;
          obj.SetTranslation(pos);
          quaternion rot;
          rot = quaternion(vec4(1,0,0,sin(the_time*3.0*time_scale)*0.01*rotation_scale));
          rot = quaternion(vec4(0,0,1,sin(the_time*3.7*time_scale)*0.01*rotation_scale))*rot;
          //rot = quaternion(vec4(0,1,0,3.1417 * -0.8)) * rot;
          obj.SetRotation(rot * orig_rotation);
        }
    }    
}
