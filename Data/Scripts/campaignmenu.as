#include "ui_effects.as"

int gui_id = -1;
RibbonBackground ribbon_background;
float visible = 0.0;
float target_visible = 1.0;

void Initialize(){
    gui_id = gui.AddGUI( "levelpicker", "challengemenu/challenge.html", 800, 800, 0 );
    gui.Execute(gui_id, "setTitle('select campaign')");
    gui.Execute(gui_id, "addLevel('Turner', 'Rescue as many slaves as you can', 'a', 'red')");
    gui.Execute(gui_id, "addLevel('Gladiator', 'Achieve fame and fortune so you can buy your freedom', 'Project60/16_red_desert_super_empty_script.xml', 'green')");
    gui.Execute(gui_id, "addLevel('Bandit', 'Become the most feared bandit on the island', 'b', 'red')");
    
    ribbon_background.Init();
}

void Update(){
    visible = UpdateVisible(visible, target_visible);
    string callback = gui.GetCallback(gui_id);
    if(callback.length() > 1){
        this_ui.SendCallback(callback);
    }
    if(GetInputDown(0,'esc')){
        this_ui.SendCallback("back");
    }
    ribbon_background.Update();
    ribbon_background.MoveGUI(gui_id);
}

void DrawGUI(){
    ribbon_background.DrawGUI(visible);
}

void Draw(){
}