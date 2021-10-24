void HandleEvent(string event, MovementObject @mo){
    if(event == "enter"){
        mo.no_grab++;
    } else if(event == "exit"){
        mo.no_grab--;

        if(mo.no_grab < 0)
            mo.no_grab = 0;
    }
}

void Draw() {
}