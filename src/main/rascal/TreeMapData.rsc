module TreeMapData

import CloneDetection;
import IO;
import List;
import Map;
import Location;
import Node;
import String;

// Type alias for clone classes with IDs
alias CloneClassWithId = tuple[str id, str pattern, list[loc] locations];

// Type alias for file clone data
alias FileCloneData = tuple[int clonedLines, int totalLines, int clonePercentage, list[str] cloneIds];

// Assign unique IDs to clone classes
public list[CloneClassWithId] assignCloneIds(list[CloneClass] cloneClasses, str idPrefix) {
    list[CloneClassWithId] classesWithIds = [];
    int id = 1;
    for (CloneClass cls <- cloneClasses) {
        str cloneId = "<idPrefix>-clone<id>";
        str pattern = cls.pattern;
        list[loc] locations = cls.locations;
        classesWithIds += [<cloneId, pattern, locations>];
        id += 1;
    }
    return classesWithIds;
}

// Calculate the number of lines covered by a loc
public int getLineCoverage(loc l) {
    return l.end.line - l.begin.line + 1;
}

// Extract per-file clone data
public map[str, FileCloneData] extractFileCloneData(list[CloneClassWithId] cloneClassesWithIds, loc projectLocation) {
    // Extract project name from projectLocation
    str projectName = substring(projectLocation.path, findLast(projectLocation.path, "/") + 1);
    
    map[str, FileCloneData] fileData = ();

    // Iterate over clone classes
    for (CloneClassWithId cls <- cloneClassesWithIds) {
        str cloneId = cls.id;
        str pattern = cls.pattern;
        list[loc] locations = cls.locations;

        // Iterate over locations
        for (loc l <- locations) {
            // Extract the full relative path including project name
            str fullPath = l.path;
            str projectName = substring(projectLocation.path, findLast(projectLocation.path, "/") + 1);
            int projectIndex = findLast(fullPath, projectName);
            str filePath = projectName + "/" + substring(fullPath, projectIndex + size(projectName) + 1);
            
            // println("File path: <filePath>");
            
            // Calculate lines covered by this location
            int clonedLines = getLineCoverage(l);

            // Initialize file data if not present
            if (filePath notin fileData) {
                fileData[filePath] = <0, 0, 0, []>;
            }

            // Update clonedLines and cloneIds
            FileCloneData currentData = fileData[filePath];
            fileData[filePath] = <
                currentData.clonedLines + clonedLines,
                currentData.totalLines,
                currentData.clonePercentage,
                (cloneId notin currentData.cloneIds) ? currentData.cloneIds + [cloneId] : currentData.cloneIds
            >;
        }
    }

    // Now, for each file, get total lines and calculate clonePercentage
    for (str filePath <- domain(fileData)) {
        loc fileLocation = [l | CloneClassWithId cls <- cloneClassesWithIds, loc l <- cls.locations, endsWith(l.path, filePath)][0];
        
        str fullPath = fileLocation.path;
        int projectIndex = findLast(fullPath, projectName);
        str relativePath = substring(fullPath, projectIndex + size(projectName) + 1);
        loc fullFileLocation = projectLocation + relativePath;

        list[str] lines = readFileLines(fullFileLocation);
        int totalLines = size(lines);
        // println("Total lines: <totalLines>");

        // println("Total lines: <totalLines>");
        FileCloneData currentData = fileData[filePath];

        // Calculate clonePercentage
        int clonePercentage = totalLines > 0 ? (currentData.clonedLines * 100) / totalLines : 0;

        // Update fileData
        fileData[filePath] = <currentData.clonedLines, totalLines, clonePercentage, currentData.cloneIds>;
    }

    return fileData;
}

