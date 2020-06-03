bool _debug_draw_ai_state = false;

bool _debug_draw_ai_path = false;

bool _debug_draw_jump_path = false;
bool _debug_draw_jump = false;

bool _debug_draw_investigate = false;

bool _debug_mouse_path_test = false;

void UpdateDebugSettings()
{
    _debug_draw_ai_state = GetConfigValueBool( "debug_show_ai_state" );

    _debug_draw_ai_path = GetConfigValueBool( "debug_show_ai_path" );

    _debug_draw_jump_path = GetConfigValueBool( "debug_show_ai_jump" );
    _debug_draw_jump = GetConfigValueBool( "debug_show_ai_jump" );

    _debug_draw_investigate = GetConfigValueBool( "debug_show_ai_investigate" );
    
    _debug_mouse_path_test = GetConfigValueBool( "debug_mouse_path_test" );
}

class DebugTextWrapper
{
    int debugId = -1;  
    string prev_debug_string = ""; 
    bool active;

    DebugTextWrapper()
    {
        active = false;
    }

    ~DebugTextWrapper()
    {
        if( debugId != -1 )
        {
            DebugDrawRemove(debugId);
        }
    }

    void SetText( string debug_string, vec3 pos )
    {
        if( active )
        {
            if( prev_debug_string != debug_string && debugId != -1 )
            {
                DebugDrawRemove(debugId);
                debugId = -1;
            }

            if( debugId == -1 )
            {
                debugId = DebugDrawText(pos, debug_string, 1.0f, true, _persistent);
            }
            else
            {
                DebugSetPosition( debugId, pos ); 
            }
            prev_debug_string = debug_string;
        }
        else
        {
            if( debugId != -1 )
            {
                DebugDrawRemove(debugId);
            }
        }
    }

    void SetActive( bool a )
    {
        active = a;
    }
}

class DebugPath
{
    array<int> path_lines;

    DebugPath()
    {
    }

    ~DebugPath()
    {
        ClearPath();
    }

    void ClearPath()
    {
        for(int i=0; i<int(path_lines.length()); ++i){
            DebugDrawRemove(path_lines[i]);
        }
        path_lines.resize(0);
    }

    void UpdatePath()
    {
        ClearPath();
        int num_points = path.NumPoints();

        for(int i=1; i<num_points; i++){
            vec3 color(1.0f);
            uint32 flag = path.GetFlag(i-1);

            if( DT_STRAIGHTPATH_OFFMESH_CONNECTION & flag != 0 )
            {
                color = vec3(1.0f,0,0);
            }

            path_lines.insertLast(DebugDrawLine(path.GetPoint(i-1) + vec3(0.0, 0.1, 0.0), path.GetPoint(i) + vec3(0.0, 0.1, 0.0), color, _persistent));

            path_lines.insertLast(DebugDrawLine(path.GetPoint(i-1) + vec3(0.0, 0.1, 0.0), path.GetPoint(i-1) + vec3(0.0, 0.5, 0.0), vec3(1.0f,0,0),_persistent));
            path_lines.insertLast(DebugDrawLine(path.GetPoint(i) + vec3(0.0, 0.1, 0.0), path.GetPoint(i) + vec3(0.0, 0.5, 0.0), vec3(1.0f,0,0),_persistent));
        }
    }
}

class DebugInvestigatePoints
{
    array<int> path_lines;  
    DebugInvestigatePoints()
    {
    }

    ~DebugInvestigatePoints()
    {
        ClearPath();
    }

    void ClearPath()
    {
        for(int i=0; i<int(path_lines.length()); ++i){
            DebugDrawRemove(path_lines[i]);
        }
        path_lines.resize(0);
    }

    void UpdatePath()
    {
        ClearPath();
        int num_points = investigate_points.size();

        if( num_points > 0 )
        {
            path_lines.insertLast(
                DebugDrawLine(
                    this_mo.position + vec3(0.0, 0.1, 0.0), 
                    investigate_points[0].pos + vec3(0.0, 0.1, 0.0), 
                    vec3(5.0f,5.0f,1.0f), 
                    _persistent
                )
            );
            
        }

        for(int i=1; i<num_points; i++){
            path_lines.insertLast(DebugDrawLine(
                investigate_points[i-1].pos + vec3(0.0, 0.1, 0.0), 
                investigate_points[i].pos + vec3(0.0, 0.1, 0.0), 
                vec3(5.0f,5.0f,1.0f), 
                _persistent
                )
            );

            path_lines.insertLast(DebugDrawLine(
                investigate_points[i-1].pos + vec3(0.0, 0.1, 0.0), 
                investigate_points[i-1].pos + vec3(0.0, 0.5, 0.0), 
                vec3(0.0f,0.0f,1.0f), 
                _persistent
                )
            );

            path_lines.insertLast(DebugDrawLine(
                investigate_points[i].pos + vec3(0.0, 0.1, 0.0),
                investigate_points[i].pos + vec3(0.0, 0.5, 0.0),
                vec3(0.0f,0.0f,1.0f), 
                _persistent
                )
            );
        }
    }
}


DebugTextWrapper ai_state_debug;
void DebugDrawAIState()
{
    mat4 transform = this_mo.rigged_object().GetAvgIKChainTransform("head");
    vec3 head_pos = transform * vec4(0.0f,0.0f,0.0f,1.0f);
    head_pos += vec3(0,0.5f,0);

    //Log( warning, "" + head_pos )
    if( _debug_draw_ai_state )
    {
        ai_state_debug.SetActive( true  );
        ai_state_debug.SetText("Player "+this_mo.GetID() + "\n" + GetAIGoalString(goal) + "\n" + GetAISubGoalString(sub_goal) + "\n" + GetGeneralStateString(state) + "\n", head_pos );

        string label = "P"+this_mo.GetID()+"goal: ";
        string text = label;
        text += GetAIGoalString(goal) + ", " + GetAISubGoalString(sub_goal) + ", " + GetPathFindTypeString(path_find_type) + ", " + GetClimbStageString(trying_to_climb) + ", " + GetGeneralStateString(state);
        DebugText(label, text,0.1f);
    }
    else
    {
        ai_state_debug.SetActive( false );
    }
}

DebugPath debug_path;
DebugInvestigatePoints debug_investigate_points;
void DebugDrawAIPath()
{
    if( _debug_draw_ai_path )
    {
        debug_path.UpdatePath();
        debug_investigate_points.UpdatePath();
    }
    else
    {
        debug_path.ClearPath();
        debug_investigate_points.ClearPath();
    }
}

string GetAIGoalString( AIGoal g )
{
    switch( g )
    {
        case _patrol: return "_patrol";
        case _attack: return "_attack";
        case _investigate : return "_investigate";
        case _get_help: return "_get_help";
        case _escort: return "_escort";
        case _get_weapon: return "_get_weapon";
        case _navigate: return "_navigate";
        case _struggle: return "_struggle";
        case _hold_still: return "_hold_still";
        default: return "unknown";
    }
    return "unknown";
}

string GetAISubGoalString( AISubGoal g )
{
    switch( g )
    {
        case _unknown: return "_unknown";
        case _provoke_attack: return "_provoke_attack";
        case _avoid_jump_kick: return "_avoid_jump_kick";
        case _wait_and_attack: return "_wait_and_attack";
        case _rush_and_attack: return "_rush_and_attack";
        case _defend: return "_defend";
        case _surround_target: return "_surround_target";
        case _escape_surround: return "_escape_surround";
        case _investigate_slow: return "_investigate_slow";
        case _investigate_urgent: return "_investigate_urgent";
        case _investigate_body: return "_investigate_body";
        case _investigate_around: return "_investigate_around";
    }

    return "unknown";
}

string GetPathFindTypeString( PathFindType g )
{
    switch( g )
    {
        case _pft_nav_mesh: return "_pft_nav_mesh";
        case _pft_climb: return "_pft_climb";
        case _pft_drop: return "_pft_drop";
        case _pft_jump: return "_pft_jump";
    }
    return "Unknown";
} 

string GetClimbStageString(ClimbStage g )
{
    switch( g )
    {
        case _nothing: return "_nothing";
        case  _jump: return "_jump";
        case  _wallrun: return "_wallrun";
        case  _grab: return "_grab";
        case  _climb_up: return " _climb_up";
    }
    return "Unknown";
}

string GetGeneralStateString( int state )
{
    switch( state )
    {
        case _movement_state: return "movement_state";
        case _ground_state: return "ground_state";
        case _attack_state: return "attack_state";
        case _hit_reaction_state: return "hit_reaction_state";
        case _ragdoll_state: return "ragdoll_state";
    }
    return "unknown";
}
