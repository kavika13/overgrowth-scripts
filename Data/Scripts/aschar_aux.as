class Timestep {
    private float frame_time_;
    private int num_frames_;
     
    Timestep(float frame_time, int num_frames){
        frame_time_ = frame_time;
        num_frames_ = num_frames;
    }

    float step() const {
        return frame_time_ * num_frames_;
    }

    int frames() const {
        return num_frames_;
    }
}

