module CloneClassData

import IO;
import List;
import Map;
import String;
import Location;
import TreeMapData;
import Util;

// Simple type definition matching JSON structure
alias CloneClassInfo = tuple[str cloneID, list[tuple[str path, int startLine, int endLine]] files];

public list[CloneClassInfo] extractCloneClassData(list[CloneClassWithId] cloneClassesWithIds, loc projectLocation) {
    list[CloneClassInfo] result = [];
    
    for (CloneClassWithId cloneClass <- cloneClassesWithIds) {
        list[tuple[str path, int startLine, int endLine]] filesList = [];
        
        for (loc location <- cloneClass.locations) {
            str relativePath = getRelativePath(location, projectLocation);
            // println(relativePath);
            filesList += <relativePath, location.begin.line, location.end.line>;

            // println("Relative path: <relativePath>");
        }
        
        result += <cloneClass.id, filesList>;
    }
    
    return result;
}

