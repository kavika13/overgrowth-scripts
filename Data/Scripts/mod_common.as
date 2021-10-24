
string GetModNameWithID(string id) {
    array<ModID>@ active_mods = GetActiveModSids();

    for( uint i = 0; i < active_mods.size(); i++ ) {
        if( ModGetID(active_mods[i]) == id ) {
            return ModGetName(active_mods[i]);
        }
    } 
    return "";
}
