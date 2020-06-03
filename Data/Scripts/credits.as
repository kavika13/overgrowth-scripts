#include "ui_effects.as"
#include "ui_tools.as"
#include "music_load.as"

array<ScrollingElement@> onscreenElements;
int roomTaken = 0;
int elementIndex = 0;
int normalTextSize = 70;
int titleTextSize = 120;
int screen_height = 1440;
int screen_width = 2560;
MusicLoad ml("Data/Music/menu.xml");
bool showBorders = true;

class ScrollingElement
  {
    string text;
	string image_path;
	string type;
	int posX = 0;
	int posY = 0;
	int height = 0;
	int width = 0;
	int index = -1;

    ScrollingElement(string _text, int textSize = normalTextSize)
    {
        text = _text;
		height = textSize;
		width = text.length() * int(textSize / 3.0f);
		type = "text";
    }
	ScrollingElement(string _type, string _text){
		if(_type == "image"){
			image_path = _text;
			AHGUI::Image testImage(image_path);
			height = testImage.getSizeY();
			width = testImage.getSizeX();
		}
		type = _type;
	}
	void Render(AHGUI::Divider@ pane){
		if(type == "text"){
			vec4 color = vec4(1.0f,1.0f,1.0f,1.0f);
			AHGUI::Text singleSentence( text, "OptimusPrinceps", height, color.x, color.y, color.z, color.a );
			singleSentence.setShadowed(true);
			pane.addFloatingElement(singleSentence, "element" + index, ivec2(posX, posY), 2);
		}else if(type == "image"){
			AHGUI::Image image(image_path);
			pane.addFloatingElement(image, "element" + index, ivec2(posX, posY), 2);
		}
	}
};

array<ScrollingElement@> scrollingElements = {	ScrollingElement("Thank you for playing Overgrowth!", titleTextSize),
												ScrollingElement(" ", titleTextSize),
												ScrollingElement("image", "Textures/logo.tga"),
												ScrollingElement("Project lead", titleTextSize),
												ScrollingElement("David Rosen"),
												ScrollingElement(" "),
												ScrollingElement("Art", titleTextSize),
												ScrollingElement("Aubrey Serr"),
												ScrollingElement("Mark Stockton"),
												ScrollingElement(" "),
												ScrollingElement("Game design", titleTextSize),
												ScrollingElement("David Rosen"),
												ScrollingElement("Jillian Ogle"),
                                                ScrollingElement(" "),
                                                ScrollingElement("Level design", titleTextSize),
                                                ScrollingElement("Aubrey Serr"),
                                                ScrollingElement("Josh Goheen"),
                                                ScrollingElement("Mark Stockton"),
												ScrollingElement(" "),
												ScrollingElement("Music", titleTextSize),
												ScrollingElement("Anton Riehl"),
												ScrollingElement("Mikko Tarmia"),
												ScrollingElement(" "),
												ScrollingElement("Producers", titleTextSize),
												ScrollingElement("Jillian Ogle"),
												ScrollingElement("Lukas Orsvärn"),
												ScrollingElement(" "),
												ScrollingElement("Programming", titleTextSize),
												ScrollingElement("Brian Cronin"),
												ScrollingElement("David Rosen"),
												ScrollingElement("Gyrth McMulin"),
												ScrollingElement("Jeffrey Rosen"),
												ScrollingElement("John Graham"),
												ScrollingElement("Max Danielsson"),
												ScrollingElement("Micah J. Best"),
												ScrollingElement("Phillip Isola"),
												ScrollingElement("Tuomas Närväinen"),
												ScrollingElement("Turo Lamminen"),
												ScrollingElement(" "),
												ScrollingElement("Public relations", titleTextSize),
												ScrollingElement("John Graham"),
												ScrollingElement(" "),
												ScrollingElement("Sound effects", titleTextSize),
												ScrollingElement("Tapio Liukkonen"),
												ScrollingElement(" "),
												ScrollingElement("User interface", titleTextSize),
												ScrollingElement("Aubrey Serr"),
												ScrollingElement("Jeffrey Rosen"),
												ScrollingElement("Mark Stockton"),
												ScrollingElement("Micah J. Best"),
												ScrollingElement(" "),
												ScrollingElement("Special thanks to", titleTextSize),
												ScrollingElement("Kylie Allen"),
												ScrollingElement("Ryan Mapa")};

class CreditsGUI : AHGUI::GUI {
    // fancy ribbon background stuff
    float visible = 0.0f;
    float target_visible = 1.0f;

    CreditsGUI() {
        // Call the superclass to set things up
        super();

    }
    void ShowCredits(){
		clear();
		//Move existing elements up.
		for(uint i = 0; i<onscreenElements.size();i++){
			onscreenElements[i].posY = onscreenElements[i].posY - 1;
		}
		//Add new elements if there is room
		if(uint(elementIndex) < scrollingElements.size() && roomTaken <= 0){
			ScrollingElement@ newElement = scrollingElements[elementIndex];
			//Print(scrollingElements[elementIndex].width + "\n");
			newElement.posX = screen_width / 2 - (scrollingElements[elementIndex].width / 2);
			newElement.posY = screen_height;
			onscreenElements.insertLast(newElement);
			roomTaken = scrollingElements[elementIndex].height;
			scrollingElements[elementIndex].index = elementIndex;
			elementIndex++;
		}else{
			roomTaken--;
		}

		//Display all the elements
		for(uint i = 0; i<onscreenElements.size();i++){
			if(onscreenElements[i].posY < - onscreenElements[i].height){
				//Print("Removing " + onscreenElements[i].text + "\n");
				onscreenElements.removeAt(i);
				i--;
				continue;
			}
			onscreenElements[i].Render(root);
		}
		//If all the elements are shown return to the main menu.
		if(onscreenElements.size() == 0){
			this_ui.SendCallback("back");
		}
    }
    /*/
    /
     * @brief Called for each message received
     *
     * @param message The message in question
     *
     */
    void processMessage( AHGUI::Message@ message ) {
        // Check to see if an exit has been requested
        if( message.name == "mainmenu" ) {
            this_ui.SendCallback("back");
        }
    }

    void update() {
		ShowCredits();
        if(GetInputPressed(0,'esc')){
            this_ui.SendCallback("back");
        }
        // Update the GUI
        AHGUI::GUI::update();
    }

    void LoadLevel(string level){
        this_ui.SendCallback(level);
    }

    /*/
    /
     * @brief  Render the gui
     *
     */
     void render() {

        // Update the background
        // TODO: fold this into AHGUI
        hud.Draw();

        // Update the GUI
        AHGUI::GUI::render();

     }
}

CreditsGUI creditsGUI;

bool HasFocus(){
    return false;
}

void Initialize(){
	PlaySong("menu-lugaru");
}

void Update(){
    creditsGUI.update();
}

void DrawGUI(){
    creditsGUI.render();
}

void Draw(){
}

void Init(string str){
}

void StartArenaMeta(){

}
bool CanGoBack(){
	return false;
}
void Dispose(){

}
