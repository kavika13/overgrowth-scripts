enum LookTargetType {
    _none,
    _character,
    _item
};

class LookTarget {
    int id;
    float interest;
    LookTargetType type;
    LookTarget() {
        id = 0;
        type = _none;
    }
}

class KnownChar {
    int id;
    bool friendly;
    float interest;
};

const float _interest_inertia = 0.96f;

class Situation {
    array<KnownChar> known_chars;
    array<LookTarget> look_targets;

    void clear() {
        known_chars.resize(0);
        look_targets.resize(0);
    }

    void Notice(int id) {
        int already_known = -1;
        for(uint i=0; i<known_chars.size(); ++i){
            if(known_chars[i].id == id){
                already_known = i;
                break;
            }
        }
        if(already_known == -1){
            KnownChar kc;
            kc.id = id;
            kc.interest = 1.0f;
            MovementObject@ char = ReadCharacterID(id);
            kc.friendly = (character_getter.OnSameTeam(char.char_path) == 1);
            known_chars.push_back(kc);
            //Print("New char seen\n");
        } else {
            //Print("Char already seen\n");
        }
    }

    void Update() {
    }

    bool NeedsCombatPose() {
        const float _combat_pose_dist_threshold = 5.0f;
        const float _combat_pose_dist_threshold_2 = 
            _combat_pose_dist_threshold * _combat_pose_dist_threshold;

        for(uint i=0; i<known_chars.size(); ++i){
            if(!known_chars[i].friendly){
                MovementObject@ char = ReadCharacterID(known_chars[i].id);
                if(char.GetIntVar("knocked_out") == _awake &&
                   distance_squared(char.position, this_mo.position) < _combat_pose_dist_threshold_2){
                    return true;
                }
            }
        }

        return false;
    }

    void GetLookTarget(LookTarget& lt){
        for(uint i=0; i<known_chars.size(); ++i){
            vec3 char_pos = ReadCharacterID(known_chars[i].id).position;
            known_chars[i].interest = 1.0f/ distance(this_mo.position, char_pos);
            known_chars[i].interest = max(0.0f,min(1.0f,known_chars[i].interest));
        }
        look_targets.resize(0);
        for(uint i=0; i<known_chars.size(); ++i){
            LookTarget lt;
            lt.id = known_chars[i].id;
            lt.interest = known_chars[i].interest;
            lt.type= _character;
            look_targets.push_back(lt);
        }
        {
            LookTarget lt;
            lt.interest = 0.5f;
            lt.type= _none;
            look_targets.push_back(lt);
        }

        float pick_val = RangedRandomFloat(0.0f,1.0f);
        {
            float total_interest = 0.0;
            for(uint i=0; i<look_targets.size(); ++i){
                total_interest += look_targets[i].interest;
            }
            total_interest = max(total_interest, 1.0f);
            pick_val *= total_interest;
        }

        lt.type = _none;
        for(uint i=0; i<look_targets.size(); ++i){
            if(pick_val < look_targets[i].interest){
                lt = look_targets[i];
                //Print("Picked char: "+ look_targets[i].interest+"\n");
                return;
            } else {
                //Print("Picked none\n");
                pick_val -= look_targets[i].interest;
            }
        }
        return;
    }

    bool PlayCombatSong() {
        for(uint i=0; i<known_chars.size(); ++i){
            if(!known_chars[i].friendly){
                MovementObject@ char = ReadCharacterID(known_chars[i].id);
                if(char.QueryIntFunction("int IsAggressive()") == 1){
                    return true;
                }
            }
        }

        return false;
    }

    int GetForceLookTarget() {
        const float _target_look_threshold = 7.0f; // How close target must be to look at it
        const float _target_look_threshold_sqrd = 
            _target_look_threshold * _target_look_threshold;

        int closest_id = -1;
        float closest_dist = 0.0f;

        for(uint i=0; i<known_chars.size(); ++i){
            if(!known_chars[i].friendly){
                MovementObject@ char = ReadCharacterID(known_chars[i].id);
                float dist = distance_squared(char.position, this_mo.position);
                if(char.GetIntVar("knocked_out") == _awake && dist < _target_look_threshold_sqrd){
                    if(closest_id == -1 || dist < closest_dist){
                        closest_id = known_chars[i].id;
                        closest_dist = dist;
                    }
                }
            }
        }
        // If nobody to look at, check again, and look at unconscious enemies also
        if(closest_id == -1){
            for(uint i=0; i<known_chars.size(); ++i){
                if(!known_chars[i].friendly){
                    MovementObject@ char = ReadCharacterID(known_chars[i].id);
                    float dist = distance_squared(char.position, this_mo.position);
                    if(dist < _target_look_threshold_sqrd){
                        if(closest_id == -1 || dist < closest_dist){
                            closest_id = known_chars[i].id;
                            closest_dist = dist;
                        }
                    }
                }
            }
        }
        return closest_id;
    }
};
