#include "ui_effects.as"
#include "threatcheck.as"
#include "ui_tools.as"
#include "tutorial_assignment_checks.as"
#include "music_load.as"

bool resetAllowed = true;
float time = 0.0f;
float noWinTime = 0.0f;
string levelName;
int inVictoryTrigger = 0;
const float ResetDelay = 4.0f;
float resetTimer = ResetDelay;
int currentAssignment = 0;
int lastAssignment = -1;
bool showBorders = false;
int assignmentTextSize = 70;
int footerTextSize = 50;
int enemyID = -1;
bool enemyAttacking = false;
bool enemyHighlighted = false;
float highlightTimer = 0.0f;
float highlightDuration = 0.5f;
bool highlightEnemy = false;
bool reviveCharacters = false;
string enemyPath = "Data/Objects/IGF_Characters/IGF_GuardActor.xml";
int knifeID = -1;
string knifePath = "Data/Items/rabbit_weapons/rabbit_knife.xml";
int screen_height = 1500;
int screen_width = 2560;
vec4 backgroundColor = vec4(0.0f,0.0f,0.0f,0.5f);
bool inCombat = false;

MusicLoad ml("Data/Music/challengelevel.xml");

class Assignment{
    string text;
	string extraText = "";
    string origText = "";
    AssignmentCallback@ callback;
    Assignment(string _text, AssignmentCallback _callback){
        text = _text;
        @callback = @_callback;
    }
}

array<Assignment@> assignments =
{Assignment("Welcome to the tutorial!", Delay(5.0f)),
//Assignment("BASIC MOVEMENT:", Delay(3.0f)),
Assignment("Move the mouse to rotate the camera.", MouseMove()),
Assignment("Use W, A, S and D to move around.", WASDMove()), //TODO get the input names dynamically so that it works with controllers and keyboard
Assignment("Press space to jump. Holding the button will result in a longer jump.", SpaceJump()),
Assignment("Hold shift to crouch.", ShiftCrouch()),
Assignment("Press shift while moving to roll.", ShiftRoll()),
Assignment("Sneak by holding shift and moving.", ShiftSneak()),
//Assignment("Release the crouch key while sneaking and hold the movement keys to run animal-style.", AnimalRun()),
//Assignment("ADVANCED MOVEMENT:", Delay(3.0f)),
Assignment("Jump into a wall and press space again while wall running to perform a walljump.", WallJump()),
Assignment("Hold the right mouse button while close to a ledge to grab it. While holding a ledge, move towards it to climb it.", LedgeGrab()),
Assignment("You move slower when walking through bushes. You will lose control when jumping through bushes and trees at high speed.", Plants()),
Assignment("A fire was just lit on the plateu. Enter it to catch fire, then roll to put it out.", Fire()),
//Assignment("While running along a wall, you can press shift to do a wallflip. Walljumps and wallflips confuse enemies and give you more control.", WallFlip()),
//Assignment("BASIC COMBAT:", Delay(3.0f)),
Assignment("There is now an enemy in the middle of the training area.", SendInEnemy()),
Assignment("Hold left click when you are near the enemy to attack.", AnyAttack()),
Assignment("Do a knee strike by standing still and attacking while really close to the enemy.", KneeStrike()),
Assignment("Do a front kick by standing still and attacking while a bit further from the enemy. This is good for keeping opponents away.", AttackFarStationary()),
Assignment("Punch by moving and attacking while really close to the enemy. This is a very fast attack.", AttackCloseMoving()),
Assignment("Do a spin kick by moving while a bit further away from the enemy. This is one of your most powerful ground attacks.", SpinKick()),
Assignment("Do a leg sweep by attacking while crouched.", Sweep()),
Assignment("Do a rabbit kick by attacking while in the air close to the enemy. This is your most powerful individual attack.", LegCannon()),
//Assignment("Using the movement keys in the air will help you aim your landing.", Delay(5.0f)),
//Assignment("The rabbit kick is devastating if timed correctly. Even if timed incorrectly, it will knock the enemy over. Try rabbit-kicking the enemy again.", LegCannon()),
Assignment("Sneak behind the enemy unnoticed and hold right click to choke them.", ChokeHold()),
//Assignment("Dodge by pressing back and attack. Dodging is essential against enemies with swords or other long weapons.", Dodge()),
//Assignment("REVERSALS AND COUNTER-REVERSALS", Delay(3.0f)),
Assignment("The enemy can now reverse your attacks.", ActivateEnemy()),
Assignment("The enemy now sometimes blocks your attack and throws you to the ground, this is called a reversal. Press right mouse button to escape from reversals.", ThrowEscape()),
Assignment("Try escaping from two more reversals in a row. Press right mouse button to escape from reversals", TwoThrowEscape()),
Assignment("Good!", Delay(3.0f)),
Assignment("Click the right mouse button to block an incomming attack. Keep holding the right mouse button after a block to perform a reversal.", TabToContinue()),
Assignment("The enemy can attack in %variable0% seconds. The attacks will be highlighted in red to make reversals easier.", CountDown()),
Assignment("Reverse three enemy attacks by holding right click when he attacks.", ReverseAttack()),
Assignment("Reverse two more enemy attacks by holding right click when he attacks.", ReverseAttack()),
Assignment("Reverse one more enemy attack by holding right click when he attacks.", ReverseAttack()),
Assignment("Excellent!", Delay(3.0f)),
Assignment("Spar with the enemy for %variable0% seconds. Damage dealt: %variable1% Damage taken: %variable2%", AttackCountDown()),
//Assignment("WEAPONS:", Delay(3.0f)),
Assignment("There is now an knife in the center of the training area. Stand or roll over the knife while holding Q to pick it up. Press Q while crouching to drop what you're holding.", PickUpKnife()),
Assignment("Sheathe and unsheathe weapons with the E key.", SheatheKnife()),
Assignment("Sometimes it is best to keep weapons sheathed to prevent enemies from taking them.", TabToContinue()),
Assignment("The knife is the smallest and least encumbering weapon. You can equip or unequip it while standing, crouching, running or flipping.", TabToContinue()),
Assignment("Cut the enemy by pressing left click while in cutting range. Remember that you can press E to unsheathe it.", SharpDamage()),
Assignment("Sharp weapons cause permanent damage instead of the temporary trauma from blunt weapons, fists and feet.", TabToContinue()),
//Assignment("The enemy now has your knife! Please reverse two of his knife attacks.", Delay(3.0)),
Assignment("When an enemy is nearby, throw the knife with Q. It is possible to throw the knife while flipping, but it is very inaccurate.", KnifeThrow()),
Assignment("You are now ready to fight in a real battle! Try out the arena from the main menu to sharpen your skills.", TabToContinue()),
Assignment("Press escape and click 'main menu' to exit the tutorial.", EndLevel())};

string bottomText = "Press 'Tab' to skip to the next item. Press escape to open the menu.";

void Init(string _levelName) {
    SetDebugKeysEnabled(false);
    levelName = _levelName;
    //lugaruGUI.AddFooter();
    lugaruGUI.AddInstruction();
}

class LugaruGUI : AHGUI::GUI {
    LugaruGUI() {
        // Call the superclass to set things up
        super();
    }
    void Render() {

        // Update the background
        // TODO: fold this into AHGUI
        hud.Draw();

        // Update the GUI
        AHGUI::GUI::render();
     }

     void processMessage( AHGUI::Message@ message ) {

        // Check to see if an exit has been requested
        if( message.name == "mainmenu" ) {
            //this_ui.SendCallback("back");
        }
    }

     void AddFooter() {
		AHGUI::Divider@ footerBackground = root.addDivider( DDBottomRight,  DOVertical, ivec2( UNDEFINEDSIZE, 300 ) );
		footerBackground.setName("footerbackground");
		//Dark background
		AHGUI::Image background( "Textures/diffuse.tga" );
		background.setName("footerbackgroundimage");
		background.setColor(vec4(0.0,0.0,0.0,0.3));
		background.setSizeX(800);
		background.setSizeY(40 * 3);
		footerBackground.addFloatingElement(background, "footerbackgroundimage", ivec2(int(screen_width / 2.0f) - background.getSizeX() / 2, 0.0f), 0);

        AHGUI::Divider@ footer = footerBackground.addDivider( DDBottomRight,  DOVertical, ivec2( UNDEFINEDSIZE, 300 ) );
        footer.setName("footer");
        footer.setVeritcalAlignment(BACenter);
        DisplayText(DDTop, footer, 8, bottomText, footerTextSize, vec4(0,0,0,1));
        if(showBorders){
            footer.setBorderSize( 10 );
            footer.setBorderColor( 0.0, 0.0, 1.0, 0.6 );
            footer.showBorder();
        }
    }
    void UpdateFooter(){
        AHGUI::Element@ footerElement = root.findElement("footer");
        if( footerElement is null  ) {
            DisplayError("GUI Error", "Unable to find footer");
        }
        AHGUI::Divider@ footer = cast<AHGUI::Divider>(footerElement);

        // Get rid of the old contents
        footer.clear();
        footer.clearUpdateBehaviors();
        footer.setDisplacement();
        DisplayText(DDTop, footer, 8, bottomText, footerTextSize, vec4(1,1,1,1));
    }
    void AddInstruction(){
		AHGUI::Divider@ container = root.addDivider( DDTop,  DOVertical, ivec2( UNDEFINEDSIZE, 400 ) );
		container.setVeritcalAlignment(BACenter);
		AHGUI::Image background( "Textures/diffuse.tga" );
		background.setName("headerbackgroundimage");
		background.setColor(vec4(0.0,0.0,0.0,0.3));
		int sizeX = 1500;
		int sizeY = assignmentTextSize * 5;
		background.setSizeX(sizeX);
		background.setSizeY(sizeY);
		container.addFloatingElement(background, "headerbackground", ivec2(int(screen_width / 2.0f) - background.getSizeX() / 2, int(container.getSizeY() / 2.0f) - (sizeY / 2)), 0);
        AHGUI::Divider@ header = container.addDivider( DDCenter,  DOVertical, ivec2( UNDEFINEDSIZE, UNDEFINEDSIZE ) );
        header.setName("header");
        header.setVeritcalAlignment(BACenter);
        DisplayText(DDTop, header, 8, bottomText, assignmentTextSize, vec4(0,0,0,1));

        if(showBorders){
            header.setBorderSize( 10 );
            header.setBorderColor( 1.0, 0.0, 0.0, 0.6 );
            header.showBorder();

			container.setBorderSize( 10 );
            container.setBorderColor( 0.0, 1.0, 0.0, 0.6 );
            container.showBorder();
        }
    }
    void UpdateInstruction(bool fadein = false){
        AHGUI::Element@ headerElement = root.findElement("header");
        if( headerElement is null  ) {
            DisplayError("GUI Error", "Unable to find header");
        }
        AHGUI::Divider@ header = cast<AHGUI::Divider>(headerElement);
        // Get rid of the old contents
        header.clear();
        header.clearUpdateBehaviors();
        header.setDisplacement();
        DisplayText(DDTop, header, 8, assignments[lastAssignment].text, assignmentTextSize, vec4(1,1,1,1), assignments[lastAssignment].extraText, footerTextSize);
    }

    void HandleAssignmentChange(){
        if(currentAssignment == lastAssignment || uint(currentAssignment) == assignments.size()){
            return;
        }
		if(lastAssignment != -1){
			assignments[lastAssignment].callback.OnCompleted();
		}
        //Print("INITIALIZED THE NEXT ASSIGNMENT!----------\n");
        lastAssignment = currentAssignment;
        //UpdateFooter();
        UpdateInstruction();
        assignments[lastAssignment].callback.Init();
        if(assignments[lastAssignment].origText == ""){
            assignments[lastAssignment].origText = assignments[lastAssignment].text;
        }
    }
    void Update(){
        HandleAssignmentChange();
        CheckCurrentAssignment();
        AHGUI::GUI::update();
        ReviveCharacters();
        HandleEnemyHighlight();
    }
    void HandleEnemyHighlight(){
        if(highlightEnemy && enemyID != -1){
            MovementObject@ enemy = ReadCharacterID(enemyID);
            if(enemyAttacking){
                if(!enemyHighlighted){
                    //Print("Setting color to red\n");
                    Object@ obj = ReadObjectFromID(enemyID);
                    for(int i=0; i<4; ++i){
                        obj.SetPaletteColor(i, vec3(1,0,0));
                    }
                    enemyHighlighted = true;
                }
                highlightTimer += time_step;
                if(highlightTimer > highlightDuration){
                    //Print("Setting color to white\n");
                    enemyAttacking = false;
                    enemyHighlighted = false;
                    Object@ obj = ReadObjectFromID(enemyID);
                    for(int i=0; i<4; ++i){
                        obj.SetPaletteColor(i, vec3(1));
                    }
                    highlightTimer = 0.0f;
                }
            }
        }


    }
    void DisplayText(DividerDirection dd, AHGUI::Divider@ div, int maxWords, string text, int textSize, vec4 color, string extraText = "", int extraTextSize = 0){
        //The maxWords is the amount of words per line.
        array<string> sentences;
        array<string> words = text.split(" ");
        string sentence;
        for(uint i = 0; i < words.size(); i++){
            sentence += words[i] + " ";
            if((i+1) % maxWords == 0 || words.size() == (i+1)){
                sentences.insertLast(sentence);
                sentence = "";
            }
        }
        for(uint k = 0; k < sentences.size(); k++){
            AHGUI::Text singleSentence( sentences[k], "OpenSans-Regular", textSize, color.x, color.y, color.z, color.a );
			singleSentence.setShadowed(true);
            //singleSentence.addUpdateBehavior( AHGUI::FadeIn( 1000, @inSine ) );
            div.addElement(singleSentence, dd);
            if(showBorders){
                singleSentence.setBorderSize(1);
                singleSentence.setBorderColor(1.0, 1.0, 1.0, 1.0);
                singleSentence.showBorder();
            }
        }
		if(extraText != ""){
			AHGUI::Text extraSentence( extraText, "OpenSans-Regular", extraTextSize, color.x, color.y, color.z, color.a );
			extraSentence.setShadowed(true);
			div.addElement(extraSentence, dd);
		}
	}
    void CheckCurrentAssignment(){
		/*else if(GetInputPressed(0, "esc")){
			level.SendMessage("dispose_level");
	        LoadLevel("back");
		}*/
        //Print("Got returned " + newBool + "\n");
        if(lastAssignment != -1 && uint(lastAssignment) < assignments.size()){
            if(assignments[lastAssignment].callback.CheckCompleted()){
                currentAssignment++;
            }
        }
    }
}


void Reset(){
    time = 0.0f;
    resetAllowed = true;
    resetTimer = ResetDelay;
}

void PostReset(){
    for(uint i = 0; i < assignments.size(); i++){
        assignments[i].callback.Reset();
    }
    currentAssignment = 0;
    lastAssignment = -1;
}

void ReceiveMessage(string msg) {
    TokenIterator token_iter;
    token_iter.Init();

    if(!token_iter.FindNextToken(msg)){
        return;
    }
    string token = token_iter.GetToken(msg);
    Print("Token: " + token + "\n");
    if(token == "reset"){
        Reset();
    } else if(token == "dispose_level"){
        gui.RemoveAll();
    } else if(token == "achievement_event"){
        token_iter.FindNextToken(msg);
        string achievement = token_iter.GetToken(msg);
        Print("achievement: " + achievement + "\n");
        assignments[lastAssignment].callback.ReceiveAchievementEvent(achievement);
        if(achievement == "ai_attacked"){
            if(!enemyAttacking){
                enemyAttacking = true;
            }
        }
    } else if(token == "achievement_event_float"){
        token_iter.FindNextToken(msg);
        string achievement = token_iter.GetToken(msg);
        Print("achievement: " + achievement + "\n");
        token_iter.FindNextToken(msg);
        string value = token_iter.GetToken(msg);
        Print("value: " + value + "\n");
        assignments[lastAssignment].callback.ReceiveAchievementEventFloat(achievement, atof(value));
    } else if(token == "send_in_enemy"){
        SendInEnemyChar();
    } else if(token == "delete_enemy"){
        DeleteObjectID(enemyID);
        enemyID = -1;
    }else if(token == "send_in_knife"){
        SendInKnifeWeapon();
    } else if(token == "delete_knife"){
        DeleteObjectID(knifeID);
        knifeID = -1;
    } else if(token == "set_highlight"){
		token_iter.FindNextToken(msg);
        string command = token_iter.GetToken(msg);
		if(command == "true"){
			highlightEnemy = true;
		}else if(command == "false"){
			highlightEnemy = false;
		}
	} else if(token == "post_reset"){
        PostReset();
    } else if(token == "character_knocked_out" || token == "character_died" || token == "cut_throat"){
        reviveCharacters = true;
	} else if(token == "revive_all"){
		for(int i = 0; i < GetNumCharacters(); i++){
            MovementObject@ char = ReadCharacter(i);
            char.Execute("Recover();");
        }
    } else if(token == "level_execute"){
        token_iter.FindNextToken(msg);
        string command = token_iter.GetToken(msg);
        level.Execute(command);
    } else if(token == "player_execute"){
        token_iter.FindNextToken(msg);
        string command = token_iter.GetToken(msg);
        MovementObject@ player = ReadCharacterID(enemyID);
        player.Execute(command);
    } else if(token == "enemy_execute"){
        token_iter.FindNextToken(msg);
        string command = token_iter.GetToken(msg);
        MovementObject@ enemy = ReadCharacterID(enemyID);
        //Print("Command: " + command + "\n");
        enemy.Execute(command);
    }else if(token == "update_text_variables"){
        array<string> values;
        string lastVariable = "";
        while(true){
            bool nextToken = token_iter.FindNextToken(msg);
            if(nextToken){
                string new_value = token_iter.GetToken(msg);
                lastVariable = new_value;
                values.insertLast(new_value);
            }else{
                break;
            }
        }
        UpdateTextVariables(values);
	}else if(token == "extra_assignment_text"){
		string completeSentence;
		while(true){
            bool nextToken = token_iter.FindNextToken(msg);
            if(nextToken){
                completeSentence += token_iter.GetToken(msg);
				completeSentence += " ";
            }else{
                break;
            }
        }
		AddExtraAssignmentText(completeSentence);
    }else if(token == "set_combat"){
		token_iter.FindNextToken(msg);
        string command = token_iter.GetToken(msg);
		if(command == "true"){
			inCombat = true;
		}else if(command == "false"){
			inCombat = false;
		}
	}
}

LugaruGUI lugaruGUI;

bool HasFocus(){
    return false;
}

void DrawGUI() {
    lugaruGUI.Render();
}

string StringFromFloatTime(float time){
    string time_str;
    int minutes = int(time) / 60;
    int seconds = int(time)-minutes*60;
    time_str += minutes + ":";
    if(seconds < 10){
        time_str += "0";
    }
    time_str += seconds;
    return time_str;
}

void Update() {
    time += time_step;
    lugaruGUI.Update();
    SetPlaceholderPreviews();
	UpdateMusic();
}

void UpdateTextVariables(array<string> new_variables){
    string currentText = assignments[lastAssignment].origText;
    //Don't do anything if the string is empty. This is because it's not been assigned yet.
    if(currentText == ""){
        return;
    }
    for(uint i = 0; i<new_variables.size(); i++){
        currentText = join(currentText.split("%variable" + i + "%"), new_variables[i]);
    }
    assignments[lastAssignment].text = currentText;
    //Print("New text " + currentText + "\n");
    lugaruGUI.UpdateInstruction();
}

void AddExtraAssignmentText(string extra_text){
    assignments[lastAssignment].extraText = extra_text;
    lugaruGUI.UpdateInstruction();
}

void Initialize(){


}

void SendInEnemyChar(){
    //Don't spawn more than one enemy.
    if(enemyID == -1){
        enemyID = CreateObject(enemyPath);
        Object@ charObj = ReadObjectFromID(enemyID);
        //At first the enemy can't fight back and cannot die
        MovementObject@ enemy = ReadCharacterID(enemyID);
        enemy.Execute("SetHostile(false);");
        enemy.Execute("combat_allowed = false;");
        enemy.Execute("ignore_death = true;");
        enemy.Execute("allow_active_block = false;");
        //Find the enemy spawn placeholder and put the new enemy at that point.
        array<int> @object_ids = GetObjectIDs();
        int num_objects = object_ids.length();
        for(int i=0; i<num_objects; ++i){
            Object @obj = ReadObjectFromID(object_ids[i]);
            ScriptParams@ params = obj.GetScriptParams();
            if(params.HasParam("Name")){
                string name_str = params.GetString("Name");
                if("enemy_spawn" == name_str){
                    charObj.SetTranslation(obj.GetTranslation());
                    break;
                }
            }
        }
		array<int> nav_points = GetObjectIDsType(33);
		if(nav_points.size() > 0){
			Object@ navObj = ReadObjectFromID(nav_points[0]);
			navObj.ConnectTo(charObj);
		}

    }else{
        MovementObject@ enemy = ReadCharacterID(enemyID);
        enemy.Execute("combat_allowed = false;");
        enemy.Execute("ignore_death = true;");
        enemy.Execute("allow_active_block = false;");
    }

}

void SendInKnifeWeapon(){
    //Don't spawn more than one knife.
    if(knifeID == -1){
        knifeID = CreateObject(knifePath);
        Object@ knifeObj = ReadObjectFromID(knifeID);
        //Find the knife spawn placeholder and put the new knife at that point.
        array<int> @object_ids = GetObjectIDs();
        int num_objects = object_ids.length();
        for(int i=0; i<num_objects; ++i){
            Object @obj = ReadObjectFromID(object_ids[i]);
            ScriptParams@ params = obj.GetScriptParams();
            if(params.HasParam("Name")){
                string name_str = params.GetString("Name");
                if("weapon_spawn" == name_str){
                    knifeObj.SetTranslation(obj.GetTranslation());
                    knifeObj.SetRotation(obj.GetRotation());
                    break;
                }
            }
        }
    }
}

int GetCharPrimaryWeapon(MovementObject@ mo){
    return mo.GetArrayIntVar("weapon_slots",mo.GetIntVar("primary_weapon_slot"));
}

int GetCharPrimarySheathedWeapon(MovementObject@ mo){
    return mo.GetArrayIntVar("weapon_slots", 3);
}

void ReviveCharacters(){
    //Because the state knocked_out changes in the next update the reviving needs to happen in the update after that
    if(reviveCharacters){
        for(int i = 0; i < GetNumCharacters(); i++){
            MovementObject@ char = ReadCharacter(i);
            if(char.GetIntVar("knocked_out") != _awake){
                char.Execute("Recover();");
                reviveCharacters = false;
            }
        }
    }
}

void SomeFunction(){
    Print("works\n");
}

// Attach a specific preview path to a given placeholder object
void SetSpawnPointPreview(Object@ spawn, string &in path){
    PlaceholderObject@ placeholder_object = cast<PlaceholderObject@>(spawn);
    placeholder_object.SetPreview(path);
}

// Find spawn points and set which object is displayed as a preview
void SetPlaceholderPreviews() {
    array<int> @object_ids = GetObjectIDs();
    int num_objects = object_ids.length();
    for(int i=0; i<num_objects; ++i){
        Object @obj = ReadObjectFromID(object_ids[i]);
        ScriptParams@ params = obj.GetScriptParams();
        if(params.HasParam("Name")){
            string name_str = params.GetString("Name");
            if("enemy_spawn" == name_str){
                SetSpawnPointPreview(obj, "Data/Objects/IGF_Characters/IGF_Guard.xml");
            }else if("weapon_spawn" == name_str){
                SetSpawnPointPreview(obj, "Data/Objects/Weapons/rabbit_weapons/rabbit_knife.xml");
            }else if("bush_spawn" == name_str){
                SetSpawnPointPreview(obj, "Data/Objects/Plants/Trees/temperate/green_bush.xml");
            }else if("pillar_spawn" == name_str){
                SetSpawnPointPreview(obj, "Data/Objects/Buildings/pillar1.xml");
            }
        }
    }
}

void UpdateMusic() {
	if(inCombat){
		PlaySong("combat");
        return;
	}else{
		PlaySong("ambient-happy");
        return;
	}
}
