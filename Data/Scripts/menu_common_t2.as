
string GetRandomBackground(){
	array<string> background_paths;
	int counter = 0;
	while(true){
		string path = "Textures/ui/menus/main/background_" + counter + ".jpg";
		if(FileExists("Data/" + path)){
	    	background_paths.insertLast(path);
	    	counter++;
		}else{
	    	break;
		}
	}
	if(background_paths.size() < 1){
		return "Textures/error.tga";
	}else{
		return background_paths[rand()%background_paths.size()];
	}
}
