#include "ui_effects.as"
#include "threatcheck.as"
#include "ui_tools.as"
#include "lugaru_tutorial_assignment_checks.as"

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
int enemyID = -1;
bool enemyAttacking = false;
bool enemyHighlighted = false;
float highlightTimer = 0.0f;
float highlightDuration = 0.5f;
bool reviveCharacters = false;
string enemyPath = "Data/Objects/IGF_Characters/lugaru_enemy_actor.xml";
int knifeID = -1;
string knifePath = "Data/Items/rabbit_weapons/rabbit_knife.xml";

class Assignment{
    string text;
    string origText = "";
    AssignmentCallback@ callback;
    Assignment(string _text, AssignmentCallback _callback){
        text = _text;
        @callback = @_callback;
    }
}

array<Assignment@> assignments =
{Assignment("WELCOME TO THE LUGARU TRAINING LEVEL!.", Delay(5.0f)),
Assignment("BASIC MOVEMENT:", Delay(3.0f)),
Assignment("You can move the mouse to rotate the camera.", MouseMove()),
Assignment("Try using the w, a, s and d keys to move around.", WASDMove()), //TODO get the input names dynamically so that it works with controllers and keyboard
Assignment("Please press space to jump.", SpaceJump()),
Assignment("You can press shift to crouch.", ShiftCrouch()),
Assignment("While running, you can press shift to roll.", ShiftRoll()),
Assignment("While crouching, you can sneak around silently using the movement keys.", ShiftSneak()),
//Assignment("Release the crouch key while sneaking and hold the movement keys to run animal-style.", AnimalRun()),
Assignment("ADVANCED MOVEMENT:", Delay(3.0f)),
Assignment("When you jump at a wall, you can hold space again during impact to perform a walljump. Be sure to use the movement keys to press against the wall", WallJump()),
Assignment("While in the air, you can press crouch to flip. Walljumps and flips confuse enemies and give you more control.", WallFlip()),
Assignment("BASIC COMBAT:", Delay(3.0f)),
Assignment("There is now an imaginary enemy in the middle of the training area.", SendInEnemy()),
Assignment("Click to attack when you are near an enemy. You can punch by standing still near an enemy and attacking.", Attack()),
Assignment("If you are close, you will perform a knee strike. The knee strike is excellent for starting attack combinations.", KneeStrike()),
Assignment("Attacking while running results in a spin kick. This is one of your most powerful ground attacks.", SpinKick()),
Assignment("Sweep the enemy's legs out by attacking while crouched. This is a very fast attack, and easy to follow up.", Sweep()),
Assignment("Your most powerful individual attack is the rabbit kick. Run at the enemy while holding the left mouse button, and press the jump key to attack.", LegCannon()),
Assignment("This attack is devastating if timed correctly. Even if timed incorrectly, it will knock the enemy over. Try rabbit-kicking the imaginary enemy.", LegCannon()),
Assignment("If you sneak behind an enemy unnoticed, you can choke him. Move close behind this enemy and hold the right mouse button.", ChokeHold()),
//Assignment("Dodge by pressing back and attack. Dodging is essential against enemies with swords or other long weapons.", Dodge()),
Assignment("REVERSALS AND COUNTER-REVERSALS", Delay(3.0f)),
Assignment("The enemy can now reverse your attacks.", ActivateEnemy()),
Assignment("If you attack, you will notice that the enemy now sometimes catches your attack and uses it against you. Hold mouse 2 after attacking to escape from reversals.", ThrowEscape()),
Assignment("Try escaping from two more reversals in a row.", TwoThrowEscape()),
Assignment("Good!", Delay(3.0f)),
Assignment("The enemy can attack in %variable0% seconds. This imaginary opponents attacks will be highlighted to make this easier.", CountDown()),
Assignment("Reverse three enemy attacks!", ReverseAttack()),
Assignment("Reverse two more enemy attacks!", ReverseAttack()),
Assignment("Reverse one more enemy attack!", ReverseAttack()),
Assignment("Excellent!", Delay(3.0f)),
Assignment("Now spar with the enemy for %variable0% more seconds. Damage dealt: %variable1% Damage taken: %variable2%.", AttackCountDown()),
Assignment("WEAPONS:", Delay(3.0f)),
Assignment("There is now an imaginary knife in the center of the training area.", SendInKnife()),
Assignment("Stand or roll over the knife while pressing e to pick it up. You can crouch and press the same key to drop it again.", PickUpKnife()),
Assignment("You can equip and unequip weapons using the e key. Sometimes it is best to keep them unequipped to prevent enemies from taking them.", SheatheKnife()),
Assignment("The knife is the smallest weapon and the least encumbering. You can equip or unequip it while standing, crouching, running or flipping.", Delay(3.0f)),
Assignment("You perform weapon attacks the same way as unarmed attacks, but sharp weapons cause permanent damage, instead of the temporary trauma from blunt weapons, fists and feet.", SharpDamage()),
//Assignment("The enemy now has your knife! Please reverse two of his knife attacks.", Delay(3.0)),
Assignment("When facing an enemy, you can throw the knife with q. It is possible to throw the knife while flipping, but it is very inaccurate.", KnifeThrow()),
Assignment("You now know everything you can learn from training. Everything else you must learn from experience!", Delay(5.0)),
Assignment("Walk out of the training area to return to the main menu.", EndLevel())};

string bottomText = "PRESS 'TAB' TO SKIP TO THE NEXT ITEM. PRESS ESCAPE AT ANY TO PAUSE OR EXIT THE TUTORIAL.";

void Init(string _levelName) {
    SetDebugKeysEnabled(false);
    levelName = _levelName;
    lugaruGUI.AddFooter();
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
        AHGUI::Divider@ footer = root.addDivider( DDBottomRight,  DOVertical, ivec2( UNDEFINEDSIZE, 300 ) );
        footer.setName("footer");
        footer.setVeritcalAlignment(BACenter);

        DisplayText(DDTop, footer, 8, bottomText, 50, vec4(0,0,0,1));
        /*
        AHGUI::Text shadowText( bottomText, "OpenSans-Regular", textSize, 0.1, 0.1, 0.1, 0.5 );
        commonInstructions.addUpdateBehavior( AHGUI::FadeIn( 1000, @inSine ) );
        footer.addElement( commonInstructions, DDCenter );
        */
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
        DisplayText(DDTop, footer, 8, bottomText, 40, vec4(1,1,1,1));
    }
    void AddInstruction(){
        AHGUI::Divider@ header = root.addDivider( DDTop,  DOVertical, ivec2( UNDEFINEDSIZE, 400 ) );
        header.setName("header");
        header.setVeritcalAlignment(BACenter);

        DisplayText(DDTop, header, 8, bottomText, assignmentTextSize, vec4(0,0,0,1));

        if(showBorders){
            header.setBorderSize( 10 );
            header.setBorderColor( 1.0, 0.0, 0.0, 0.6 );
            header.showBorder();
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
        DisplayText(DDTop, header, 8, assignments[lastAssignment].text, assignmentTextSize, vec4(1,1,1,1));
    }

    void HandleAssignmentChange(){
        if(currentAssignment == lastAssignment || uint(currentAssignment) == assignments.size()){
            return;
        }
        //Print("INITIALIZED THE NEXT ASSIGNMENT!----------\n");
        lastAssignment = currentAssignment;
        UpdateFooter();
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
        if(enemyID != -1){
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
    void DisplayText(DividerDirection dd, AHGUI::Divider@ div, int maxWords, string text, int textSize, vec4 color){
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
            //singleSentence.addUpdateBehavior( AHGUI::FadeIn( 1000, @inSine ) );
            div.addElement(singleSentence, dd);
            if(showBorders){
                singleSentence.setBorderSize(1);
                singleSentence.setBorderColor(1.0, 1.0, 1.0, 1.0);
                singleSentence.showBorder( false );
            }
        }
    }
    void CheckCurrentAssignment(){
        if(GetInputPressed(0, "tab")){
            currentAssignment++;
            return;
        }
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
    //Print("Token: " + token + "\n");
    if(token == "reset"){
        Reset();
    } else if(token == "dispose_level"){
        gui.RemoveAll();
    } else if(token == "achievement_event"){
        token_iter.FindNextToken(msg);
        string achievement = token_iter.GetToken(msg);
        //Print("achievement: " + achievement + "\n");
        assignments[lastAssignment].callback.ReceiveAchievementEvent(achievement);
        if(achievement == "ai_attacked"){
            if(!enemyAttacking){
                enemyAttacking = true;
            }
        }
    } else if(token == "achievement_event_float"){
        token_iter.FindNextToken(msg);
        string achievement = token_iter.GetToken(msg);
        //Print("achievement: " + achievement + "\n");
        token_iter.FindNextToken(msg);
        string value = token_iter.GetToken(msg);
        //Print("value: " + value + "\n");
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
    } else if(token == "post_reset"){
        PostReset();
    } else if(token == "character_knocked_out" || token == "character_died"){
        reviveCharacters = true;
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
    if(GetInputPressed(0, "b")){
        ReviveCharacters();
    }
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

void Initialize(){


}

void SendInEnemyChar(){
    //Don't spawn more than one enemy.
    if(enemyID == -1){
        enemyID = CreateObject(enemyPath);
        Object@ charObj = ReadObjectFromID(enemyID);
        //At first the enemy can't fight back and cannot die
        MovementObject@ enemy = ReadCharacterID(enemyID);
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
            if(char.GetIntVar("knocked_out") != _awake && length(char.velocity) < 0.5f){
                char.Execute("Recover();");
                reviveCharacters = false;
            }else{
                reviveCharacters = true;
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
            }
            if("weapon_spawn" == name_str){
                SetSpawnPointPreview(obj, "Data/Objects/Weapons/rabbit_weapons/rabbit_knife.xml");
            }
        }
    }
}

void UpdateMusic() {
    int player_id = GetPlayerCharacterID();
    if(player_id != -1 && ReadCharacter(player_id).GetIntVar("knocked_out") != _awake){
        PlaySong("sad");
        return;
    }
    int threats_remaining = ThreatsRemaining();
    if(threats_remaining == 0){
        PlaySong("ambient-happy");
        return;
    }
    if(player_id != -1 && ReadCharacter(player_id).QueryIntFunction("int CombatSong()") == 1){
        PlaySong("combat");
        return;
    }
    PlaySong("ambient-tense");
}
