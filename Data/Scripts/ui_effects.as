float UpdateVisible(float visible, float target_visible){
    return mix(visible, target_visible, 0.1f);
}


class RibbonBackground {
    int gui_id;
    float display_time;
    IMUIContext imui_context;

    void Init(){
        gui_id = -1;
        display_time = 0.0;
    }

    RibbonBackground() {
        imui_context.Init();
    }
    
    void Update(){
        display_time += time_step;
    }
    
    void MoveGUI(int gui_id){
        if(gui_id != -1){
            gui.MoveTo(gui_id,GetScreenWidth()/2-400,GetScreenHeight()/2-300);
        }    
    } 
    
    void DrawGUI(float visible){
        imui_context.UpdateControls();
        if(visible < 0.01){
            return;
        }
        float ui_scale = 0.5f;
        {   HUDImage @image = hud.AddImage("Data/Textures/ui/challenge_mode/red_gradient_border_c.tga", vec3(0,0,0));
            image.position.x = 0;
            image.position.y = - image.GetHeight() * ui_scale * ((1.0-visible) + 0.125);
            image.position.z = 2;
            float stretch = GetScreenWidth() / image.GetWidth() / ui_scale;
            image.tex_scale.x = stretch;
            image.tex_scale.y = 1.0;
            image.tex_offset.x += display_time * 0.05;
            image.color = vec4(0.7,0.7,0.7,1.0);
            image.scale = vec3(ui_scale*stretch,ui_scale,1.0);}
        
        {   HUDImage @image = hud.AddImage("Data/Textures/ui/challenge_mode/red_gradient_border_c.tga", vec3(0,0,0));
            image.position.x = 0;
            image.position.y = GetScreenHeight() + image.GetHeight() * ui_scale * ((1.0-visible) + 0.375);
            image.position.z = 2;
            float stretch = GetScreenWidth() / image.GetWidth() / ui_scale;
            image.tex_scale.x = stretch;
            image.tex_scale.y = 1.0;
            image.tex_offset.x = display_time * 0.05;
            image.color = vec4(0.7,0.7,0.7,1.0);
            image.scale = vec3(ui_scale*stretch,-ui_scale,1.0);}
            
        {   HUDImage @image = hud.AddImage("Data/Textures/ui/challenge_mode/giometric_ribbon_c.tga", vec3(0,0,0));
            float stretch = GetScreenHeight() / image.GetHeight() / ui_scale;
            image.position.x = GetScreenWidth() * 0.5 - image.GetWidth() * ui_scale * 0.9;
            image.position.y =  ((1.0-visible) * GetScreenHeight() * 1.2);
            image.position.z = 3;
            image.tex_scale.y = stretch;
            image.tex_offset.y = display_time * 0.025;
            image.scale = vec3(ui_scale, ui_scale*stretch, 1.0);}
            
        {   HUDImage @image = hud.AddImage("Data/Textures/ui/challenge_mode/giometric_ribbon_c.tga", vec3(0,0,0));
            float stretch = GetScreenHeight() / image.GetHeight() / ui_scale;
            image.position.x = GetScreenWidth() * 0.5 - image.GetWidth() * ui_scale * 0.8;
            image.position.y = ((1.0-visible) * GetScreenHeight() * -1.2);
            image.position.z = 3;
            image.tex_scale.y = stretch;
            image.tex_offset.y = -display_time * 0.0125;
            image.scale = vec3(ui_scale, ui_scale*stretch, 1.0);}
        
        {   HUDImage @image = hud.AddImage("Data/Textures/ui/challenge_mode/blue_gradient_c.tga", vec3(0,0,0));
            image.position.x = -2;
            image.position.y = -2;
            image.position.z = 0;
            float stretch_x = (GetScreenWidth()+4) / image.GetWidth();
            float stretch_y = (GetScreenHeight()+4) / image.GetHeight();
            image.color.a = 0.8 * visible;
            image.scale = vec3(stretch_x, stretch_y, 1.0);}
    }
}