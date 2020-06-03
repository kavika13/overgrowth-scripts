void Init() {
}

void DeleteObjectsInList(array<int> &inout ids){
    int num_ids = ids.length();
    for(int i=0; i<num_ids; ++i){
        DeleteObjectID(ids[i]);
    }
    ids.resize(0);
}

array<int> spawned_object_ids;

Object@ SpawnObjectAtSpawnPoint(Object@ spawn, string &in path){
    Print("Spawning \"" + path + "\"\n");
    int obj_id = CreateObject(path);
    spawned_object_ids.push_back(obj_id);
    Object @new_obj = ReadObjectFromID(obj_id);
    new_obj.SetTranslation(spawn.GetTranslation());
    new_obj.SetRotation(spawn.GetRotation());
    return new_obj;
}

void Update() {
    if(GetInputPressed(0, "t")){
        Print("Pressed T\n");
        DeleteObjectsInList(spawned_object_ids);
        array<int> @object_ids = GetObjectIDs();
        int num_objects = object_ids.length();
        for(int i=0; i<num_objects; ++i){
            Print("Reading object " + object_ids[i] + "\n");
            Object @obj = ReadObjectFromID(object_ids[i]);
            ScriptParams@ params = obj.GetScriptParams();
            if(params.HasParam("Name")){
                string name_str = params.GetString("Name");
                if("player_spawn" == name_str){
                    Object@ char_obj = SpawnObjectAtSpawnPoint(obj,"Data/Objects/IGF_Characters/IGF_TurnerActor.xml");
                    char_obj.SetPlayer(true);
                }
                if("enemy_spawn" == name_str){
                    Object@ char_obj = SpawnObjectAtSpawnPoint(obj,"Data/Objects/IGF_Characters/IGF_GuardActor.xml");
                }
            }
        }
    }
}