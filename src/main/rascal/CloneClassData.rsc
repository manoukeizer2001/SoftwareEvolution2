module CloneClassData

import IO;
import List;
import Map;
import String;
import Location;
import TreeMapData;
import Util;
import lang::java::m3::Core;

// Simple type definition matching JSON structure
alias CloneClassInfo = tuple[str cloneID, list[tuple[str path, int startLine, int endLine]] files];

// Add function to get all Java files
private list[loc] getAllJavaFiles(loc projectLocation) {
    return [f | /file(f) <- projectLocation.ls, f.extension == "java"];
}

public list[CloneClassInfo] extractCloneClassData(list[CloneClassWithId] cloneClassesWithIds, loc projectLocation) {
    list[CloneClassInfo] result = [];
    
    // Get all Java files first
    list[loc] allFiles = getAllJavaFiles(projectLocation);
    map[str, bool] fileHasClones = ();
    
    // Initialize all files as having no clones
    for (loc file <- allFiles) {
        fileHasClones[getRelativePath(file, projectLocation)] = false;
    }
    
    // Process clone classes
    for (CloneClassWithId cloneClass <- cloneClassesWithIds) {
        list[tuple[str path, int startLine, int endLine]] filesList = [];
        
        for (loc location <- cloneClass.locations) {
            str relativePath = getRelativePath(location, projectLocation);
            filesList += <relativePath, location.begin.line, location.end.line>;
            fileHasClones[relativePath] = true;
        }
        
        result += <cloneClass.id, filesList>;
    }
    
    // Add files with no clones (with dummy clone class)
    for (str path <- fileHasClones) {
        if (!fileHasClones[path]) {
            // Add as a special "no-clones" entry
            result += <"no-clones", [<path, 0, 0>]>;
        }
    }
    
    return result;
}

