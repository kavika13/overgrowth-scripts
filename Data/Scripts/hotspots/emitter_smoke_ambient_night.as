void Init() {
}

const float frequency = 0.4f;
float delay = frequency;

void Update() {
    Object@ obj = ReadObjectFromID(hotspot.GetID());
    vec3 pos = obj.GetTranslation();
    vec3 scale = obj.GetScale();
    vec4 v = obj.GetRotationVec4();
    quaternion rotation(v.x,v.y,v.z,v.a);
    delay -= time_step;
    if(delay <= 0.0f){
        for(int i=0; i<1; ++i){
            vec3 offset;
            offset.x += RangedRandomFloat(-scale.x*2.0f,scale.x*2.0f);
            offset.y += RangedRandomFloat(-scale.y*2.0f,scale.y*2.0f);
            offset.z += RangedRandomFloat(-scale.z*2.0f,scale.z*2.0f);
            uint32 id = MakeParticle("Data/Particles/smoke_ambient_night.xml", pos + Mult(rotation, offset), vec3(0.0f), vec3(1.0f));
        }
        delay += frequency;
    }
}