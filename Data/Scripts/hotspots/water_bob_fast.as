float translation_scale;
float rotation_scale;
float time_scale;

void Init() {
}

void SetParameters() {
    params.AddString("Objects","");
    params.AddFloatSlider("translation_scale",4.0,"min:0,max:5,step:0.001");
    params.AddFloatSlider("rotation_scale",2.0,"min:0,max:5,step:0.001");
    params.AddFloatSlider("time_scale",0.2,"min:0,max:2,step:0.001");

    translation_scale = params.GetFloat("translation_scale");
    rotation_scale = params.GetFloat("rotation_scale");
    time_scale = params.GetFloat("time_scale");
}

void Reset(){
}

void Dispose(){
}

vec3 orig_translation;
quaternion orig_rotation;

void PreDraw(float curr_game_time) {
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
          pos[1] += (sin(curr_game_time*time_scale) * 0.01 + sin(curr_game_time * 2.7*time_scale) * 0.015 + sin(curr_game_time * 4.3*time_scale) * 0.008)*translation_scale;
          quaternion rot;
          rot = quaternion(vec4(1,0,0,sin(curr_game_time*3.0*time_scale)*0.01*rotation_scale));
          rot = quaternion(vec4(0,0,1,sin(curr_game_time*3.7*time_scale)*0.01*rotation_scale))*rot;
          //rot = quaternion(vec4(0,1,0,3.1417 * -0.8)) * rot;
          obj.SetTranslationRotationFast(pos, rot * orig_rotation);
        }
    }    
}
