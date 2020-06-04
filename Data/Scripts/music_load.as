class MusicLoad
{
    bool music_loaded = false;
    string p;
    MusicLoad(string path)
    {
        p = path;
        music_loaded = AddMusic(p);
    }

    ~MusicLoad()
    {
        if(music_loaded)
            RemoveMusic(p);
    }
};
