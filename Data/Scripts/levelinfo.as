class LevelInfo
{
    string name;
    string id;
    string file;
    string image;
	string campaign_id;
    string lock_icon = "Textures/ui/menus/main/icon-lock.png";
    ModLevel modlevel;
    int highest_diff;
    bool level_played = false;
    bool hide_stars = false;
	bool coming_soon = false;
    bool unlocked = true;
    bool last_played = false;
    bool disabled = false;
    int completed_levels = -1;
    int total_levels = -1;

    LevelInfo(ModLevel level, int _highest_diff, bool _level_played, bool _unlocked, bool _last_played)
    {
        name = level.GetTitle();
        file = level.GetPath();
        image = level.GetThumbnail();
        id = level.GetID();
        //GetHighestDifficultyFinishedCampaign(_campaign_id);
        highest_diff = _highest_diff;
        //GetLevelPlayed(level.GetID());
        level_played = _level_played;
        modlevel = level;
        unlocked = _unlocked;
        last_played = _last_played;
    }

    LevelInfo(string _file, string _name, string _image, string _campaign_id, int _highest_diff, bool _level_played, bool _unlocked, bool _last_played, int _completed_levels, int _total_levels)
    {
        name = _name;
        file = _file;
        image = _image;
		campaign_id = _campaign_id;
        id = _name;
        highest_diff = _highest_diff; 
        level_played = _level_played;
        unlocked = _unlocked;
        last_played = _last_played;
        completed_levels = _completed_levels;
        total_levels = _total_levels;
    }

	LevelInfo(string _file, string _name, string _image, bool _coming_soon, bool _unlocked, bool _last_played)
    {
        name = _name;
        file = _file;
        image = _image;
		coming_soon = _coming_soon;
        id = _name;
        highest_diff = 0;
        unlocked = _unlocked;
        last_played = _last_played;
    }

	LevelInfo(string _file, string _name, string _image, int _highest_diff, bool _unlocked, bool _last_played)
    {
        name = _name;
        file = _file;
        image = _image;
		coming_soon = false;
        id = _name;
        highest_diff = _highest_diff;
        unlocked = _unlocked;
        last_played = _last_played;
    }

	LevelInfo(string _file, string _name, string _image, int _highest_diff, bool _level_played, bool _unlocked, bool _last_played)
    {
        name = _name;
        file = _file;
        image = _image;
		coming_soon = false;
        id = _name;
        highest_diff = _highest_diff;
        level_played = _level_played;
        unlocked = _unlocked;
        last_played = _last_played;
    }

	LevelInfo(string _file, string _name, string _image, bool _unlocked, bool _last_played)
    {
        name = _name;
        file = _file;
        image = _image;
		coming_soon = false;
        id = _name;
        highest_diff = 0;
        unlocked = _unlocked;
        last_played = _last_played;
    }

    ModLevel GetModLevel() {
        return modlevel;
    }
};
