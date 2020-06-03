class AssignmentCallback
{
	float time;
	float delay;
	bool timerStarted = false;
	bool completed = false;
	bool disabled = false;
	MovementObject@ player = ReadCharacter(GetPlayerCharacter());

    void Completed(){}
    //Every assignment has some functions that are the same.
    //Handling them in the baseclass saves some duplicate code.
    void Init(){}
    bool CheckCompleted(){
		//Don't start the timer if it's already triggered.
		if(!disabled){
			if(timerStarted){
	    		UpdateTimer();
	    	}else if(!timerStarted && !completed){
	    		Completed();
	    	}
	    	if(completed){
	    		disabled = true;
	    	}
	    	//When the assignment is completed it only needs to send back ONE true.
	    	return completed;
		}else{
			return false;
		}
    }
    void StartTimer(float _delay){
    	if(!timerStarted){
    		//Print("THE ASSIGNMENT IS COMPLETED!-----------\n");
    		PlaySound("Data/Sounds/lugaru/consolesuccess.ogg");
			delay = _delay;
			timerStarted = true;
		}
    }
    void StartTimerNoSound(float _delay){
    	if(!timerStarted){
			delay = _delay;
			timerStarted = true;
		}
    }
    void UpdateTimer(){
		time += time_step;
		if(time > delay){
			completed = true;
		}
    }
    void Reset(){
		time = 0;
		//delay = 0;
		timerStarted = false;
		completed = false;
		disabled = false;
		LocalReset();
    }
    void LocalReset(){

    }

    int GetPlayerCharacter() {
	    int num = GetNumCharacters();
	    for(int i=0; i<num; ++i){
	        MovementObject@ char = ReadCharacter(i);
	        if(char.controlled){
	        	return char.GetID();
	        }
	    }
	    return 0;
	}
	void LevelExecute(string command){
		SendCommand("level_execute", command);
	}
	void EnemyExecute(string command){
		SendCommand("enemy_execute", command);
	}
	void PlayerExecute(string command){
		SendCommand("player_execute", command);
	}
	void SendCommand(string firstCommand, string secondCommand){
		//Remove all the spaces from the actual command or else the command will be split up in the ReceiveMessage
		level.SendMessage(firstCommand + " " + join(secondCommand.split( " " ), "" ));
	}
	void SendCommand(string singleCommand){
		level.SendMessage(singleCommand);
	}
	void ReceiveAchievementEvent(string _achievement){}
	void ReceiveAchievementEventFloat(string _achievement, float _value){}
}

class Delay : AssignmentCallback
{
	Delay(float _delay){delay = _delay;}
	void Completed()
	{
		//Wait for n seconds and then continue.
		StartTimerNoSound(delay);
	}
}

class MouseMove : AssignmentCallback
{
	float negX;
	float posX;
	float negY;
	float posY;
	float threshold;
	float prevXAxis;
	float prevYAxis;

	void Init(){
		negX = 0;
		posX = 0;
		negY = 0;
		posY = 0;
		threshold = 100.0f;
		prevXAxis = -1;
		prevYAxis = -1;
	}

    void Completed()
    {
    	if(prevYAxis == -1){
    		prevYAxis = GetLookYAxis(player.controller_id);
    	}
    	if(prevXAxis == -1){
    		prevXAxis = GetLookXAxis(player.controller_id);
    	}
    	//To make sure the player has looked in every direction add the movement
    	float diffXAxis = GetLookXAxis(player.controller_id) - prevXAxis;
    	float diffYAxis = GetLookYAxis(player.controller_id) - prevYAxis;
    	if(diffXAxis < 0){
    		negX += (diffXAxis * -1);
    	}else if(diffXAxis > 0){
    		posX += diffXAxis;
    	}
    	if(diffYAxis < 0){
    		negY += (diffYAxis * -1);
    	}else if(diffXAxis > 0){
    		posY += diffYAxis;
    	}
    	//Checking for all mousemovements are large enough
    	if(negX > threshold && posX > threshold && negY > threshold && posY > threshold){
    		StartTimer(5.0f);
    	}
    }
}

class WASDMove : AssignmentCallback
{

	void Completed()
	{
		if(length(player.velocity) > 1.0f){
			StartTimer(5.0f);
		}
	}
}

class SpaceJump : AssignmentCallback
{
	void Completed()
	{
		if(!player.GetBoolVar("on_ground")){
			StartTimer(5.0f);
		}
	}
}

class ShiftCrouch : AssignmentCallback
{
	void Completed()
	{
		float duck_amount = player.GetFloatVar("duck_amount");
		if(duck_amount >= 1.0f){
			StartTimer(5.0f);
		}
	}
}

class ShiftRoll : AssignmentCallback
{
	void Completed()
	{
		player.Execute("blinking = flip_info.IsFlipping();");
		bool isRolling = player.GetBoolVar("blinking");
		if(isRolling && player.GetBoolVar("on_ground")){
			StartTimer(5.0f);
		}
	}
}

class ShiftSneak : AssignmentCallback
{
	void Completed()
	{
		float duck_amount = player.GetFloatVar("duck_amount");
		if(duck_amount >= 1.0f && length(player.velocity) > 1.0f && player.GetBoolVar("on_ground")){
			StartTimer(5.0f);
		}
	}
}
class AnimalRun : AssignmentCallback
{
	void Completed()
	{
		if(GetInputDown(0, "crouch")){
			StartTimer(5.0f);
		}
	}
}
class WallJump : AssignmentCallback
{
	void ReceiveAchievementEvent(string _achievement){
		if(_achievement == "jump_off_wall"){
			StartTimer(5.0f);
		}
	}
}
class WallFlip : AssignmentCallback
{
	void ReceiveAchievementEvent(string _achievement){
		if(_achievement == "wall_flip"){
			StartTimer(5.0f);
		}
	}
}
class SendInEnemy : AssignmentCallback
{
	void LocalReset(){
		level.SendMessage("delete_enemy");
	}
	void Init(){
		level.SendMessage("send_in_enemy");
		EnemyExecute("Notice(" + GetPlayerCharacter() + ");");
		StartTimerNoSound(3.0f);
	}
}
class Attack : AssignmentCallback
{
	void ReceiveAchievementEvent(string _achievement){
		if(_achievement == "player_attacked"){
			StartTimer(5.0f);
		}
	}
}
class KneeStrike : AssignmentCallback
{
	void ReceiveAchievementEvent(string _achievement){
		if(_achievement == "attack_stationary_close"){
			StartTimer(5.0f);
		}
	}
}
class SpinKick : AssignmentCallback
{
	void ReceiveAchievementEvent(string _achievement){
		if(_achievement == "attack_moving"){
			StartTimer(5.0f);
		}
	}
}
class Sweep : AssignmentCallback
{
	void ReceiveAchievementEvent(string _achievement){
		if(_achievement == "attack_low"){
			StartTimer(5.0f);
		}
	}
}
class LegCannon : AssignmentCallback
{
	void ReceiveAchievementEvent(string _achievement){
		if(_achievement == "attack_air"){
			StartTimer(5.0f);
		}
	}
}
class ChokeHold : AssignmentCallback
{
	void Init(){
		EnemyExecute("always_unaware = true;");
	}
	void ReceiveAchievementEvent(string _achievement){
		if(_achievement == "choke_hold_kill"){
			StartTimer(5.0f);
		}
	}
}
class Dodge : AssignmentCallback
{
	void Init(){
		EnemyExecute("always_unaware = false;");
	}
	void ReceiveAchievementEvent(string _achievement){
		if(_achievement == "active_dodging"){
			StartTimer(5.0f);
		}
	}
}
class ActivateEnemy : AssignmentCallback
{
	void Init(){
		EnemyExecute("always_unaware = false;");
		EnemyExecute("combat_allowed = false;");
		EnemyExecute("chase_allowed = true;");
		EnemyExecute("allow_active_block = true;");
		EnemyExecute("always_active_block = true;");
		EnemyExecute("goal = _attack;");
		StartTimerNoSound(3.0f);
	}
}
class ThrowEscape : AssignmentCallback
{
	void ReceiveAchievementEvent(string _achievement){
		if(_achievement == "character_throw_escape"){
			StartTimer(5.0f);
		}
	}
}
class TwoThrowEscape : AssignmentCallback
{
	int successfull;
	void Init(){
		successfull = 0;
	}
	void ReceiveAchievementEvent(string _achievement){
		if(_achievement == "character_throw_escape"){
			successfull++;
		}else if (_achievement == "player_damage"){
			successfull = 0;
		}
		if(successfull >= 2){
			StartTimer(0.0f);
		}
	}
}
class CountDown : AssignmentCallback
{
	int seconds;
	int lastTime;
	void Init(){
		seconds = 8;
		lastTime = -1;
	}
	void Completed(){
		time += time_step;
		if(floor(time) != lastTime){
			lastTime = int(floor(time));
			seconds -= 1;
			//Print("time " + seconds + "\n");
			SendCommand("update_text_variables " + seconds );
		}
		if(seconds == 0){
			StartTimerNoSound(0.0f);
		}
	}
}
class ReverseAttack : AssignmentCallback
{
	void Init(){
		EnemyExecute("always_unaware = false;");
		EnemyExecute("combat_allowed = true;");
		EnemyExecute("chase_allowed = false;");
		EnemyExecute("allow_active_block = true;");
		EnemyExecute("always_active_block = false;");
		EnemyExecute("goal = _attack;");
	}
	void ReceiveAchievementEvent(string _achievement){
		if(_achievement == "player_counter_attacked"){
			StartTimer(3.0f);
		}
	}
}
class AttackCountDown : AssignmentCallback
{
	int seconds;
	int lastTime;
	float player_damage;
	float enemy_damage;
	void Init(){
		seconds = 50;
		lastTime = -1;
		player_damage = 0;
		enemy_damage = 0;
		SendCommand("update_text_variables " + seconds + " " + enemy_damage + " " + player_damage);
	}
	void ReceiveAchievementEventFloat(string _achievement, float _value){
		if(_achievement == "player_damage"){
			player_damage += _value;
		}else if(_achievement == "ai_damage"){
			enemy_damage += _value;
		}
	}
	void Completed(){
		time += time_step;
		if(floor(time) != lastTime){
			lastTime = int(floor(time));
			seconds -= 1;
			//Print("time " + seconds + "\n");
			SendCommand("update_text_variables " + seconds + " " + enemy_damage + " " + player_damage);
		}
		if(seconds == 0){
			StartTimer(0.0f);

		}
	}
}
class SendInKnife : AssignmentCallback
{
	void Init(){
		EnemyExecute("hostile = false;");
		EnemyExecute("always_unaware = false;");
		EnemyExecute("combat_allowed = false;");
		EnemyExecute("chase_allowed = false;");
		EnemyExecute("allow_active_block = false;");
		EnemyExecute("always_active_block = false;");
		level.SendMessage("send_in_knife");
		StartTimerNoSound(3.0f);
	}
	void LocalReset(){
		level.SendMessage("delete_knife");
	}
}
class PickUpKnife : AssignmentCallback
{
	void Completed(){
		if(GetCharPrimaryWeapon(player) != -1){
			StartTimer(3.0f);
		}
	}
}
class SheatheKnife : AssignmentCallback
{
	void Completed(){
		if(GetCharPrimarySheathedWeapon(player) != -1){
			StartTimer(3.0f);
		}
	}
}
class SharpDamage : AssignmentCallback
{
	void ReceiveAchievementEvent(string _achievement){
		if(_achievement == "ai_took_sharp_damage"){
			StartTimer(3.0f);
		}
	}
}
class KnifeThrow : AssignmentCallback
{
	void ReceiveAchievementEvent(string _achievement){
		if(_achievement == "player_threw_knife"){
			StartTimer(3.0f);
		}
	}
}
class EndLevel : AssignmentCallback
{
	void ReceiveAchievementEvent(string _achievement){
		if(_achievement == "character_reset_hotspot"){
			level.SendMessage("go_to_main_menu");
		}
	}
}
