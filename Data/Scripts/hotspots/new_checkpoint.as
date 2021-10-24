void Init() {
    params.AddFloat("LastEnteredTime", -1.0f);
    params.SetFloat("LastEnteredTime", -1.0f);
}

void SetParameters() {
	params.AddFloat("LastEnteredTime", -1.0f);
}

void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
        OnEnter(mo);
    }
}

void OnEnter(MovementObject @mo) {
    params.SetFloat("LastEnteredTime", the_time);
}