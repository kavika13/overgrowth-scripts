// Common items for all menus in the system

float border_size = 10.0f;
vec4 border_color = vec4(0.75f,0.75f,0.75f,0.75f);
bool controller_active = GetControllerActive();
vec2 mouse_position;
bool controller_wraparound = false;
float input_interval_timer = 0.0f;
float input_longpress_timer = 0.0f;
float input_interval = 0.1f;
float input_longpress_threshold = 0.5f;
bool first_run = true;
int old_controller_index = -1;

class ControllerItem
{
    vec2 position;
	IMElement@ element;
	IMMessage@ message = null;
	IMMessage@ message_left = null;
	IMMessage@ message_right = null;
	IMMessage@ message_up = null;
	IMMessage@ message_down = null;
	IMMessage@ message_on_select = null;
	bool execute_on_select = false;
	bool skip_show_border = false;

	ControllerItem(){}
};

const int kMainController = 1;
const int kSubmenuControllerItems = 2;

array<ControllerItem@> main_controller_items;
array<ControllerItem@> submenu_controller_items;
ControllerItem@ submenu_current_item;
ControllerItem@ main_current_item;

int current_controller_item_state = kMainController;

ControllerItem@ current_item = @main_current_item;

array<ControllerItem@>@ GetCurrentControllerItems() {
    if( kMainController == current_controller_item_state ) {
        return @main_controller_items;
    } else {
        return @submenu_controller_items;
    }
}

bool list_created = false;

bool GetControllerActive(){
	return GetInterlevelData("controller_active") == "true";
}

void EnableControllerSubmenu(){
	DeactivateCurrentItem();
	@main_current_item = @current_item;
    current_controller_item_state = kSubmenuControllerItems;
	@current_item = @submenu_current_item;
}

void DisableControllerSubmenu(){
	DeactivateCurrentItem();
	GetCurrentControllerItems().resize(0);
    current_controller_item_state = kMainController;
	@current_item = @main_current_item;
	if(controller_active){
		SetItemActive(current_item);
	}
}

void ResetController(){
	main_controller_items.resize(0);
	submenu_controller_items.resize(0);
	@current_item = null;
	list_created = false;
	controller_active = false;
	SetInterlevelData("controller_active", "false");
}

void AddControllerItem(IMElement@ item, IMMessage@ message){
	
	ControllerItem new_item();
	@new_item.element = item;
	@new_item.message = message;
	GetCurrentControllerItems().insertLast(@new_item);
	
}

void AddControllerItem(IMElement@ item, IMMessage@ message_enter, IMMessage@ message_left, IMMessage@ message_right, IMMessage@ message_up, IMMessage@ message_down){

	ControllerItem new_item();
	@new_item.element = item;
	@new_item.message = message_enter;
	@new_item.message_left = message_left;
	@new_item.message_right = message_right;
	@new_item.message_up = message_up;
	@new_item.message_down = message_down;

	GetCurrentControllerItems().insertLast(@new_item);
	
}

void AddControllerItem(ControllerItem @item){
	GetCurrentControllerItems().insertLast(item);
}

void ClearControllerItems(int start_at = 0){
	GetCurrentControllerItems().removeRange(start_at, GetCurrentControllerItems().size());
}

void SetControllerItemBeforeShift(){
    old_controller_index = GetCurrentControllerItemIndex();
    ClearControllerItems();
}

void SetControllerItemAfterShift(int direction){
    if(old_controller_index == -1)return;

    int new_index = old_controller_index;
    if(controller_active){
        if(direction == 1){
            //Put the index on the left side
            new_index -= (max_items - 1);
        }else{
            //Put the index on the right side
            new_index += (max_items - 1);
        }
    }
    old_controller_index = -1;
    SetCurrentControllerItem(new_index);
}

void SetCurrentControllerItem(uint index){
    list_created = false;
	//If the index is out of bound just select the last one.
	if(index >= GetCurrentControllerItems().size()){
		index = GetCurrentControllerItems().size() - 1;
	}else if(index < 0){
        index = 0;
    }
	@current_item = @GetCurrentControllerItems()[index];
	if(controller_active){
		SetItemActive(@current_item);
	}
}

void SetCurrentControllerItem(string name){
	list_created = false;
	for(uint i = 0; i < GetCurrentControllerItems().size(); i++){
		if( GetCurrentControllerItems()[i].element.getName() == name){
			//Found it
			@current_item = @GetCurrentControllerItems()[i];
			if(controller_active){
				SetItemActive(@current_item);
			}
			return;
		}
	}
	@current_item = @GetCurrentControllerItems()[0];
	if(controller_active){
		SetItemActive(@current_item);
	}
}

int GetCurrentControllerItemIndex(){
	int index = -1;
	for(uint i = 0; i < GetCurrentControllerItems().size(); i++){
		if(current_item is GetCurrentControllerItems()[i]){
			index = i;
			break;
		}
	}
	return index;
}

string GetCurrentControllerItemName(){
	string name = "";
	for(uint i = 0; i < GetCurrentControllerItems().size(); i++){
		if(current_item is GetCurrentControllerItems()[i]){
			name = current_item.element.getName();
			break;
		}
	}
	return name;
}

void UpdateItemPositions(){
	for(uint i = 0; i < GetCurrentControllerItems().size(); i++){
		vec2 new_position = GetCurrentControllerItems()[i].element.getScreenPosition();
		float scaling_x = screenMetrics.GUIToScreen(vec2(1)).x;
		float scaling_y = screenMetrics.GUIToScreen(vec2(1)).y;
		GetCurrentControllerItems()[i].position = vec2(new_position.x + (GetCurrentControllerItems()[i].element.getSizeX() / 2.0f * scaling_x), new_position.y + (GetCurrentControllerItems()[i].element.getSizeY() / 2.0f * scaling_y));
	}
}

void PrintPositions(){
	for(uint i = 0; i < GetCurrentControllerItems().size(); i++){
		//Print("Position " + controller_items[i].position.x + " " + current_controller_items[i].position.y + "\n");
		Print("default size " + GetCurrentControllerItems()[i].element.getSize().x + "\n" );
	}
}

void DrawBoxes(){
	for(uint i = 0; i < GetCurrentControllerItems().size(); i++){
		vec2 new_position = GetCurrentControllerItems()[i].position;
		imGUI.drawBox(new_position, vec2(100.0f), vec4(1,0,0,1), 9);
		//current_controller_items[i].position = vec2(new_position.x + (current_controller_items[i].element.getSizeX() / 2.0f), new_position.y + (current_controller_items[i].element.getSizeY() / 2.0f));
	}
}

void SetItemActive(ControllerItem@ item){
	item.element.setBorderColor(border_color);
	item.element.setBorderSize(border_size);
	if(!item.skip_show_border){
		item.element.showBorder(true);
	}
}

void DeactivateCurrentItem(){
	if(!current_item.skip_show_border){
		current_item.element.showBorder(false);
	}
}

void UpdateController(){
	if(GetCurrentControllerItems().size() < 1)return;
	if(!list_created){
		if(current_item is null){
			@current_item = @GetCurrentControllerItems()[0];
		}
		if(controller_active && first_run){
			first_run = false;
			SetItemActive(@current_item);
		}
		list_created = true;
	}
	if(controller_active){
		if(mouse_position != imGUI.guistate.mousePosition){
			DeactivateCurrentItem();
			SetGrabMouse(false);
			controller_active = false;
			SetInterlevelData("controller_active", "false");
			return;
		}
		if(GetInputPressed(0, "return")){
			current_item.element.sendMessage(current_item.message);
		}
		
		//Direction input up/down/left/right
		if(input_longpress_timer > input_longpress_threshold){
			
			if(input_interval_timer > 0.0f){
				input_interval_timer -= time_step;
				return;
			}
			
			if(GetInputDown(0, "up")){
				if(current_item.message_up !is null){
					current_item.element.sendMessage(current_item.message_up);
				}else{
					GetClosestItem(vec2(0,1));
				}
				input_interval_timer = input_interval;
			}
			else if(GetInputDown(0, "down")){
				if(current_item.message_down !is null){
					current_item.element.sendMessage(current_item.message_down);
				}else{
					GetClosestItem(vec2(0,-1));
				}
				input_interval_timer = input_interval;
			}
			else if(GetInputDown(0, "left")){
				if(current_item.message_left !is null){
					current_item.element.sendMessage(current_item.message_left);
				}else{
					GetClosestItem(vec2(-1,0));
				}
				input_interval_timer = input_interval;
			}
			else if(GetInputDown(0, "right")){
				if(current_item.message_right !is null){
					current_item.element.sendMessage(current_item.message_right);
				}else{
					GetClosestItem(vec2(1,0));
				}
				input_interval_timer = input_interval;
			}
			if(!(GetInputDown(0, "up") || GetInputDown(0, "down") || GetInputDown(0, "left") || GetInputDown(0, "right")) ){
				input_longpress_timer = 0.0f;
			}
		}else{
			if( GetInputDown(0, "up") || GetInputDown(0, "down") || GetInputDown(0, "left") || GetInputDown(0, "right") ){
				input_longpress_timer += time_step;
			}else{
				input_longpress_timer = 0.0f;
			}
			if(GetInputPressed(0, "up")){
				if(current_item.message_up !is null){
					current_item.element.sendMessage(current_item.message_up);
				}else{
					GetClosestItem(vec2(0,1));
				}
				input_interval_timer = input_interval;
			}
			else if(GetInputPressed(0, "down")){
				if(current_item.message_down !is null){
					current_item.element.sendMessage(current_item.message_down);
				}else{
					GetClosestItem(vec2(0,-1));
				}
				input_interval_timer = input_interval;
			}
			else if(GetInputPressed(0, "left")){
				if(current_item.message_left !is null){
					current_item.element.sendMessage(current_item.message_left);
				}else{
					GetClosestItem(vec2(-1,0));
				}
				input_interval_timer = input_interval;
			}
			else if(GetInputPressed(0, "right")){
				if(current_item.message_right !is null){
					current_item.element.sendMessage(current_item.message_right);
				}else{
					GetClosestItem(vec2(1,0));
				}
				input_interval_timer = input_interval;
			}
		}

	}else{
		if( GetInputPressed(0, "up") || GetInputPressed(0, "down") || GetInputPressed(0, "left") || GetInputPressed(0, "right") ){
			mouse_position = imGUI.guistate.mousePosition;
			controller_active = true;
			SetInterlevelData("controller_active", "true");
			SetGrabMouse(true);
			SetItemActive(current_item);
		}
	}
	//DrawBoxes();
}

void GetClosestItem(vec2 direction){
	UpdateItemPositions();
	array<ControllerItem@> items_in_direction;
	bool horiz = (direction.y == 0);
	float scaling_x = screenMetrics.GUIToScreen(vec2(1)).x;
	float scaling_y = screenMetrics.GUIToScreen(vec2(1)).y;
	for(uint i = 0; i < GetCurrentControllerItems().size(); i++){
		ControllerItem@ possible_closest = GetCurrentControllerItems()[i];		
		if(	possible_closest.position == current_item.position){continue;}
		
		if(direction.x == 1 || direction.x == -1){
			if( (direction.x == 1) == (possible_closest.position.x > current_item.position.x + (direction.x * (current_item.element.getSizeX() / 2.0f) * scaling_x)) ){	//Right and Left
			// if( (direction.x == 1) == (possible_closest.position.x > current_item.position.x ) ){	//Right and Left
				items_in_direction.insertLast(@possible_closest);
			}
		}
		else{
			if( (direction.y == -1)  == (possible_closest.position.y > current_item.position.y - (direction.y * (current_item.element.getSizeY() / 2.0f) * scaling_y)) ){	//Up and Down
			// if( (direction.y == -1)  == (possible_closest.position.y > current_item.position.y ) ){	//Up and Down
				items_in_direction.insertLast(@possible_closest);
			}
		}
	}
	//True is closest false is furthest, used for wraparound
	bool closest_furthest = true;
	if(controller_wraparound){
		//No items are found in that direction
		if(items_in_direction.size() < 1){
			//Get all the items in the opposite direction
			direction *= -1;
			closest_furthest = false;
			for(uint i = 0; i < GetCurrentControllerItems().size(); i++){
				ControllerItem@ possible_closest = GetCurrentControllerItems()[i];
				if(	possible_closest.position == current_item.position){continue;}
				if( (direction.x == -1) == (possible_closest.position.x > current_item.position.x + (direction.x * (current_item.element.getSizeX() / 2.0f) * scaling_x)) ){	//Right and Left
					items_in_direction.insertLast(@possible_closest);
				}
				else if( (direction.y == -1)  == (possible_closest.position.y > current_item.position.y - (direction.y * (current_item.element.getSizeY() / 2.0f) * scaling_y)) ){	//Up and Down
					items_in_direction.insertLast(@possible_closest);
				}
			}
		}
	}
	/*for(uint i = 0; i < items_in_direction.size(); i++){
		if(direction.x == 1 || direction.x == -1){
			//Right and Left
			if((closest_furthest == ( abs(current_item.position.x - items_in_direction[i].position.x) < abs(current_item.position.x - closest_or_furthest.position.x) ))){
				@closest_or_furthest = items_in_direction[i];
			}
		}
		else if(direction.y == 1 || direction.y == -1){
			//Up and Down
			if((closest_furthest == ( abs(current_item.position.y - items_in_direction[i].position.y) < abs(current_item.position.y - closest_or_furthest.position.y)) )){
				@closest_or_furthest = items_in_direction[i];
			}
		}
	}*/
	if(items_in_direction.size() < 1){return;}
	ControllerItem@ closest_or_furthest = items_in_direction[0];
	for(uint i = 0; i < items_in_direction.size(); i++){
		if(closest_furthest == (distance(current_item.position, items_in_direction[i].position) < distance(current_item.position, closest_or_furthest.position))){
			@closest_or_furthest = items_in_direction[i];
		}
	}
	DeactivateCurrentItem();
	@current_item = @closest_or_furthest;
	if(closest_or_furthest.execute_on_select){
		ExecuteOnSelect();
		/*return;*/
	}
	SetItemActive(current_item);
}

void ExecuteOnSelect(){
	if(current_item.message_on_select !is null && controller_active){
		current_item.element.sendMessage(current_item.message_on_select);
	}
}
