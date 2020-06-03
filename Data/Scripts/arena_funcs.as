// Various functions used by all arena instances

// Create a random color tint, avoiding excess saturation
vec3 RandReasonableColor(){
    vec3 color;
    color.x = rand()%255;
    color.y = rand()%255;
    color.z = rand()%255;
    float avg = (color.x + color.y + color.z) / 3.0f;
    color = mix(color, vec3(avg), 0.7f);
    return color;
}

// Convert byte colors to float colors (255,0,0) to (1.0f,0.0f,0.0f)
vec3 FloatTintFromByte(const vec3 &in tint){
    vec3 float_tint;
    float_tint.x = tint.x / 255.0f;
    float_tint.y = tint.y / 255.0f;
    float_tint.z = tint.z / 255.0f;
    return float_tint;
}

vec3 GetRandomFurColor() {

    vec3 fur_color_byte;
    int rnd = rand()%6;                    
    
    switch(rnd) {
        case 0: fur_color_byte = vec3(255); break;
        case 1: fur_color_byte = vec3(34); break;
        case 2: fur_color_byte = vec3(137); break;
        case 3: fur_color_byte = vec3(105,73,54); break;
        case 4: fur_color_byte = vec3(53,28,10); break;
        case 5: fur_color_byte = vec3(172,124,62); break;
    }

    return FloatTintFromByte(fur_color_byte);
}