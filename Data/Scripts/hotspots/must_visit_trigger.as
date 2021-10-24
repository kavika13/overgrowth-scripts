bool visited = false;

void Init() {
}

void Reset() {
    visited = false;
}

void SetParameters() {
}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
        OnEnter(mo);
    } else if(event == "exit"){
        OnExit(mo);
    }
}

void OnEnter(MovementObject @mo) {
    if(mo.controlled){
        visited = true;
        Print("Visited!");
    }
}

void OnExit(MovementObject @mo) {
}

string GetTypeString() {
    return "must_visit_trigger";
}