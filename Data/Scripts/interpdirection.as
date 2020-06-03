vec3 InterpDirections(vec3 dir1, vec3 dir2, float amount){
    vec3 new_dir = normalize(dir1 * (1.0f-amount) +
                             dir2 * amount);
    
    // Add perpendicular offset to ease transitions between opposite facings
    if(dot(dir1, dir2) < -0.8f){
        vec3 break_axis = cross(vec3(0.0f,1.0f,0.0f),dir1);
        if(dot(break_axis,dir2)<0.0f){
            break_axis *= -1.0f;
        }
        new_dir = normalize(dir1 * (1.0f-amount) +
                            break_axis * amount);
    
    }

    return new_dir;
}