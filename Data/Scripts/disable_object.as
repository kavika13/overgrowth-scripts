void Init(string level_name) {
}

void ReceiveMessage(string message) {
    TokenIterator token_iter;
    token_iter.Init();

    if(!token_iter.FindNextToken(message)) {
        return;
    }

    string token = token_iter.GetToken(message);

    if(token == "disable") {
        if(!token_iter.FindNextToken(message)) {
            return;
        }

        int target_object_id = atoi(token_iter.GetToken(message));

        if(ObjectExists(target_object_id)) {
            Object@ target_object = ReadObjectFromID(target_object_id);
            target_object.SetEnabled(false);
        }
    } else if(token == "enable") {
        if(!token_iter.FindNextToken(message)) {
            return;
        }

        int target_object_id = atoi(token_iter.GetToken(message));

        if(ObjectExists(target_object_id)) {
            Object@ target_object = ReadObjectFromID(target_object_id);
            target_object.SetEnabled(true);
        }
    }
}