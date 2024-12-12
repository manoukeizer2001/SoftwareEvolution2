module CloneGroupsExport

import IO;
import List;
import Map;
import String;
import CloneDetection;
import TreeMapData;

// Function to get a descriptive name for a clone pattern
private str getCloneName(str pattern) {
    // Extract method name if it exists
    if (/method\((.*?)\)/ := pattern) {
        return "Method Clone: <pattern>";
    }
    // Extract class name if it exists
    else if (/class\((.*?)\)/ := pattern) {
        return "Class Clone: <pattern>";
    }
    // Extract block type if it exists
    else if (/block\((.*?)\)/ := pattern) {
        return "Block Clone: <pattern>";
    }
    // Extract statement type if it exists
    else if (/statement\((.*?)\)/ := pattern) {
        return "Statement Clone: <pattern>";
    }
    // Default case
    else {
        return "Code Clone: <pattern>";
    }
}

// Function to generate clone groups JSON
public void exportCloneGroupsData(list[CloneClass] cloneClasses, loc projectLoc) {
    // Create the visualization directory if it doesn't exist
    loc visualizationDir = |project://clone-detection/visualization|;
    if (!exists(visualizationDir)) {
        mkDirectory(visualizationDir);
    }

    // Prepare the clone groups data structure
    map[str, map[str, value]] cloneGroups = ();
    int groupId = 1;

    for (cloneClass <- cloneClasses) {
        // Create a group entry for each clone class
        map[str, value] groupData = ();
        // Use the pattern to generate a meaningful name
        groupData["name"] = getCloneName(cloneClass.pattern);
        
        // Process each location in the clone class
        list[map[str, value]] files = [];
        for (loc location <- cloneClass.locations) {
            map[str, value] fileInfo = ();
            // Convert project path to relative path
            str relativePath = location.path;
            if (startsWith(relativePath, "/")) {
                relativePath = substring(relativePath, 1);
            }
            fileInfo["path"] = relativePath;
            fileInfo["startLine"] = location.begin.line;
            fileInfo["endLine"] = location.end.line;
            files += [fileInfo];
        }
        
        groupData["files"] = files;
        cloneGroups["<groupId>"] = groupData;
        groupId += 1;
    }

    // Create the final JSON structure
    map[str, value] jsonData = (
        "cloneGroups": cloneGroups
    );

    // Write to cloneGroups.json
    loc outputFile = visualizationDir + "cloneGroups.json";
    writeJSON(outputFile, jsonData);
    println("Clone groups data exported to: <outputFile>");
}
