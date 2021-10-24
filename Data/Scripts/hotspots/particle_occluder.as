int occluder_decal_id = -1;

void Update() {
    if(occluder_decal_id == -1) {
        occluder_decal_id = CreateObject("Data/Objects/Decals/water_fog.xml", true);
    }

    Object@ water_decal_obj = ReadObjectFromID(occluder_decal_id);
    Object@ obj = ReadObjectFromID(hotspot.GetID());
    water_decal_obj.SetTranslation(obj.GetTranslation());
    water_decal_obj.SetRotation(obj.GetRotation());
    water_decal_obj.SetScale(obj.GetScale() * 4.00f);
}

void Dispose() {
    if(occluder_decal_id != -1) {
        QueueDeleteObjectID(occluder_decal_id);
        occluder_decal_id = -1;
    }
}

void Draw() {
    if(EditorModeActive()) {
        Object@ obj = ReadObjectFromID(hotspot.GetID());
        DebugDrawBillboard(
            "Data/UI/spawner/thumbs/Hotspot/emitter_icon.png",
            obj.GetTranslation() + obj.GetScale()[1] * vec3(0.0f, 0.5f, 0.0f),
            2.0f,
            vec4(1.0f),
            _delete_on_draw);
    }
}
