/***
 * This function verifies that the campaign data id references are valid.
 *
 * First it verifies that the data is following strucutural rules.
 * Then the script verifies that links between different objects are correct.
 */
bool ArenaCampaignSanityCheck( GlobalArenaData@ gad )
{
    bool is_ok = true;

    is_ok = VerifyStructure( gad );

    if( is_ok )
    {
        is_ok = VerifyReferences( gad );
    }

    return is_ok;
}

/**********************************************/
/* Structure verification */
/**********************************************/
bool VerifyStructure( GlobalArenaData@ gad)
{
    bool is_ok = true;
    JSONValue root = gad.campaignJSON.getRoot();

    /*
    array<string> rootIds = JSON.getMembers( root );

    for( uint i = 0; i < rootIds.length(); i++ )
    {
        JSONValue 
        switch( 
    }
    */

    //TODO: Implement
    //
    return is_ok;
}

/**********************************************/
/* Reference verification */
/**********************************************/
bool VerifyReferences(GlobalArenaData@ gad)
{
    bool is_ok = true;

    is_ok = VerifyActionReferences( gad ) && is_ok; 
    is_ok = VerifyArenaInstanceReferences( gad ) && is_ok;
    is_ok = VerifyCharacterReferences( gad ) && is_ok;
    is_ok = VerifyWorldNodeReferences( gad ) && is_ok;
    is_ok = VerifyStateReferences( gad ) && is_ok;

    return is_ok;
}

bool VerifyStateReferences( GlobalArenaData@ gad )
{
    bool is_ok = true;
    JSONValue states = gad.getStates();

    for( uint i = 0; i < states.size(); i++ )
    {
        JSONValue state = states[i];

        if( !FileExists( "Data/" + state["glyph"].asString() ) )
        {
            Log(error, "Missing referenced state glyph: " + "Data/" + state["glyph"].asString() ); 
            is_ok = false;
        }   
    }
    return is_ok;
}


bool VerifyWorldNodeReferences( GlobalArenaData@ gad ) 
{
    bool is_ok = true;  

    JSONValue world_nodes = gad.getWorldNodes();

    for( uint i = 0; i < world_nodes.size(); i++ )
    {
        JSONValue world_node = world_nodes[i];  

        //Log( info, "Evaluating world_node id:" + world_node["id"].asString() );
        JSONValue type = world_node["type"];
        JSONValue target_id = world_node["target_id"];
        JSONValue pre_actions = world_node["pre_actions"];
        JSONValue post_actions = world_node["post_actions"];

        string type_s = type.asString();
        string id = world_node["id"].asString();

        if( type_s == "meta_choice" )
        {
            if( gad.getMetaChoice( target_id.asString() ).type() != JSONobjectValue )
            {
                Log( error, "world_node " + id + " references invalid meta_choice: " + target_id.asString() );
                is_ok = false;
            }
        }
        else if( type_s == "message" )
        {
            if( gad.getMessage( target_id.asString() ).type() != JSONobjectValue )
            {
                Log( error, "world_node " + id + " references invalid message: " + target_id.asString() );
                is_ok = false;
            }
        }
        else if( type_s == "arena_instance" )
        {
            if( gad.getArenaInstance( target_id.asString() ).type() != JSONobjectValue )
            {
                Log( error, "world_node " + id + " references invalid arena_instance: " + target_id.asString() );
                is_ok = false;
            }
        }

        for( uint j = 0; j < pre_actions.size(); j++ )
        {
            JSONValue action = pre_actions[j];
            
            is_ok = VerifyActionReferenceValue(gad,action) && is_ok;
        } 

        for( uint j = 0; j < post_actions.size(); j++ )
        {
            JSONValue action = post_actions[j];
            
            is_ok = VerifyActionReferenceValue(gad,action) && is_ok;
        } 
    } 

    return is_ok;
}

bool VerifyCharacterReferences( GlobalArenaData@ gad )
{
    bool is_ok = true;

    JSONValue characters = gad.getCharacters();

    for( uint i = 0; i < characters.size(); i++ )
    {
        JSONValue character = characters[i];

        string id = character["id"].asString();

        JSONValue portrait =        character["portrait"];
        JSONValue states =          character["states"];
        JSONValue world_map_id =    character["world_map_id"];
        JSONValue world_node_id =   character["world_node_id"];
        JSONValue global_pre_actions =  character["global_pre_actions"];
        JSONValue global_post_actions =  character["global_post_actions"];
        JSONValue intro_pages =     character["intro"]["pages"];

        if( !FileExists( "Data/" + portrait.asString() ) )
        {
            Log( error, "character " + id + " has invalid portrait: " + portrait.asString() );
            is_ok = false;  
        }

        for( uint j = 0; j < states.size(); j++ )
        {
            JSONValue state = states[j];

            if( gad.getState(state.asString()).type() != JSONobjectValue )
            {
                Log( error, "character " + id + " has invalid state: " + state.asString() );
                is_ok = false;
            }
        }

        if( gad.getWorldMap( world_map_id.asString() ).type() != JSONobjectValue )
        {
            Log( error, "character " +  id + " world_map_id is invalid " + world_map_id.asString() ); 
            is_ok = false;  
        } 
    
        if( gad.getWorldNode( world_node_id.asString() ).type() != JSONobjectValue )
        {
            Log( error, "character " + id + " world_node_id is invalid " + world_node_id.asString() );
            is_ok = false;  
        }

        for( uint j = 0; j < global_pre_actions.size(); j++ )
        {
            is_ok = VerifyActionReferenceValue(gad,global_pre_actions[j]) && is_ok;
        }

        for( uint j = 0; j < global_post_actions.size(); j++ )
        {
            is_ok = VerifyActionReferenceValue(gad,global_post_actions[j]) && is_ok;
        }

        for( uint j = 0; j < intro_pages.size(); j++ )
        {
            JSONValue page = intro_pages[j];

            if( !FileExists( "Data/" + page["glyph"].asString() ) )
            {
                Log( error, "character " + id + " has invalid page glyph: " + page["glyph"].asString() );
                is_ok = false;
            }
        }
    }

    return is_ok;     
}

bool VerifyAction(GlobalArenaData@ gad,JSONValue action)
{
    bool is_ok = true;
    is_ok = RecursivelyCheckActionIfReferences(gad,action["if"]) && is_ok;
    is_ok = VerifyActionClause(gad,action["then"]) && is_ok;
    is_ok = VerifyActionClause(gad,action["else"]) && is_ok;
    return is_ok;
}

bool VerifyActionReferenceValue(GlobalArenaData@ gad,JSONValue action)
{
    if( action.type() == JSONobjectValue )
    {            
        return VerifyAction(gad,action);
    }
    else if( action.type() == JSONstringValue )
    {
        if( gad.getAction( action.asString() ).type() != JSONobjectValue )
        {
            Log( error, "the action id " + action.asString() + " is being referenced, but it doesn't exist.");
            return false;
        }
    }

    return true;
}

bool VerifyArenaInstanceReferences( GlobalArenaData@ gad )
{
    bool is_ok = true;

    JSONValue arena_instances = gad.getArenaInstances();

    for( uint i = 0; i < arena_instances.size(); i++ )
    {
        JSONValue arena_instance = arena_instances[i];

        JSONValue level = arena_instance["level"];
        JSONValue battle = arena_instance["battle"];
        
        if( !FileExists( "Data/Levels/" + level.asString() ) )
        {
            Log( error, "arena_instance missing level:" + arena_instance["level"].asString() );
            is_ok = false;
        }

    }

    return is_ok;     
}

bool VerifyActionReferences( GlobalArenaData@ gad )
{
    bool is_ok = true; 

    JSONValue actions = gad.getActions(); 

    for( uint i = 0; i < actions.size(); i++ )
    {
        JSONValue action = actions[i];
        
        is_ok = VerifyAction(gad,action) && is_ok;
    }
    
    return is_ok;
}

bool VerifyActionClause( GlobalArenaData@ gad, JSONValue clause )
{
    bool is_ok = true;
    if( clause.type() == JSONobjectValue )
    {
        JSONValue set_world_node = clause["set_world_node"];
        JSONValue add_states = clause["add_states"];
        JSONValue lose_states = clause["lose_states"];
        JSONValue add_hidden_states = clause["add_hidden_states"];
        JSONValue lose_hidden_states = clause["lose_hidden_states"];
        JSONValue actions = clause["actions"]; 

        if( set_world_node.type() != JSONnullValue )
        {
            if( gad.getWorldNode( set_world_node.asString() ).type() != JSONobjectValue )
            {
                Log(error, "set_world_node is set to non-existant node: " + set_world_node.asString() );
                is_ok = false;
            }
        }

        if( add_states.type() == JSONarrayValue )
        {
            for( uint j = 0; j < add_states.size(); j++ )
            {
                string state = add_states[j].asString(); 

                if( gad.getState(state).type() != JSONobjectValue )
                {
                    Log( error, "add_states lists invalid state: " + state);
                    is_ok = false;
                }
            }
        }

        if( lose_states.type() == JSONarrayValue )
        {
            for( uint j = 0; j < lose_states.size(); j++ )
            {
                string state = lose_states[j].asString(); 

                if( gad.getState(state).type() != JSONobjectValue )
                {
                    Log( error, "lose_states lists invalid state: " + state);
                    is_ok = false;
                }
            }
        }

        if( add_hidden_states.type() == JSONarrayValue )
        {
            for( uint j = 0; j < add_hidden_states.size(); j++ )
            {
                string state = add_hidden_states[j].asString(); 

                if( gad.getHiddenState(state).type() != JSONobjectValue )
                {
                    Log( error, "add_hidden_states lists invalid state: " + state);
                    is_ok = false;
                }
            }
        }

        if( lose_hidden_states.type() == JSONarrayValue )
        {
            for( uint j = 0; j < lose_hidden_states.size(); j++ )
            {
                string state = lose_hidden_states[j].asString(); 

                if( gad.getHiddenState(state).type() != JSONobjectValue )
                {
                    Log( error, "lose_hidden_states lists invalid state: " + state);
                    is_ok = false;
                }
            }
        }

        if( actions.type() == JSONarrayValue )
        {
            for( uint j = 0; j < actions.size(); j++ )
            {
                is_ok = VerifyActionReferenceValue(gad,actions[j]) && is_ok;
            }
        }
    }

    return is_ok;
}


bool RecursivelyCheckActionIfReferences( GlobalArenaData@ gad, JSONValue node )
{
    bool is_ok = true;
    if( node.type() == JSONarrayValue )
    {
        for( uint i = 0; i < node.size(); i++ )
        {
            is_ok = RecursivelyCheckActionIfReferences(gad,node[i]) && is_ok;
        }
    }
    else if( node.type() == JSONobjectValue )
    {
        JSONValue required_states = node["required_states"];
        JSONValue excluding_states = node["excluding_states"];
        JSONValue required_hidden_states = node["required_hidden_states"];
        JSONValue excluding_hidden_states = node["excluding_hidden_states"];

        if( required_states.type() == JSONarrayValue )
        {
            for( uint i = 0; i < required_states.size(); i++ )
            {
                string id = required_states[i].asString();
                if( gad.getState( id ).type() != JSONobjectValue )
                {
                    Log(error,"required_states is referencing non-existant state: " +  id );
                    is_ok = false;
                }
            }     
        }

        if( excluding_states.type() == JSONarrayValue )
        {
            for( uint i = 0; i < excluding_states.size(); i++ )
            {
                string id = excluding_states[i].asString();
                if(gad.getState( id ).type() != JSONobjectValue )
                {
                    Log(error,"excluding_states is referencing non-existant state: " +  id );
                    is_ok = false;
                }
            }     
        }

        if( required_hidden_states.type() == JSONarrayValue )
        {
            for( uint i = 0; i < required_hidden_states.size(); i++ )
            {
                string id = required_hidden_states[i].asString();
                if(gad.getHiddenState( id ).type() != JSONobjectValue )
                {
                    Log(error,"required_hidden_states is referencing non-existant state: " +  id );
                    is_ok = false;
                }
            }     
        }

        if( excluding_hidden_states.type() == JSONarrayValue )
        {
            for( uint i = 0; i < excluding_hidden_states.size(); i++ )
            {
                string id = excluding_hidden_states[i].asString();
                if(gad.getHiddenState( id ).type() != JSONobjectValue )
                {
                    Log(error,"excluding_hidden_states is referencing non-existant state: " +  id );
                    is_ok = false;
                }
            }     
        }
    }
    return is_ok;
}
