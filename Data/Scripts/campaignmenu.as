#include "ui_effects.as"

int gui_id = -1;
RibbonBackground ribbon_background;
float visible = 0.0;
float target_visible = 1.0;

void Initialize(){
    gui_id = gui.AddGUI( "levelpicker", "challengemenu/challenge.html", 800, 800, 0 );
    gui.Execute(gui_id, "setTitle('select campaign')");
    /*string name = "Test name";
    string description = "Test description";
    string level_path = "Test level path";
    LevelSetReader lsr("Data/LevelSets/challenge_test.xml");
    string curr_path;
    LevelInfoReader lir;
    while(lsr.Next(curr_path)){
        lir.Load("Data/Levels/"+curr_path);
        gui.Execute(gui_id, "addLevel('"+lir.visible_name()+"', '"+lir.visible_description()+"', '"+curr_path+"', 'green')");
    }*/
    gui.Execute(gui_id, "addLevel('Turner', 'Rescue as many slaves as you can', 'a', 'green')");
    gui.Execute(gui_id, "addLevel('Gladiator', 'Achieve fame and fortune so you can buy your freedom', 'b', 'green')");
    gui.Execute(gui_id, "addLevel('Bandit', 'Become the most feared bandit on the island', 'c', 'green')");
    
    ribbon_background.Init();
}

void Update(){
    visible = UpdateVisible(visible, target_visible);
    string callback = gui.GetCallback(gui_id);
    if(callback.length() > 0){
        //this_ui.SendCallback(callback);
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