module CloneClassData

import IO;
import List;
import Map;
import String;
import Location;
import TreeMapData;

// Simple type definition matching JSON structure
alias CloneClassInfo = tuple[str cloneID, list[tuple[str path, int startLine, int endLine]] files];

public list[CloneClassInfo] extractCloneClassData(list[CloneClassWithId] cloneClassesWithIds, loc projectLocation) {
    list[CloneClassInfo] result = [];
    
    for (CloneClassWithId cloneClass <- cloneClassesWithIds) {
        list[tuple[str path, int startLine, int endLine]] filesList = [];
        
        for (loc location <- cloneClass.locations) {
            // Extract the relative path
            str fullPath = location.path;
            str projectName = substring(projectLocation.path, findLast(projectLocation.path, "/") + 1);
            int projectIndex = findLast(fullPath, projectName);
            str relativePath = projectName + substring(fullPath, projectIndex + size(projectName));
            
            filesList += <relativePath, location.begin.line, location.end.line>;
        }
        
        result += <cloneClass.id, filesList>;
    }
    
    return result;
}

