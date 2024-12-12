module DataExtraction

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
            // Extract only the relative path within the project
            str filePath = substring(l.path, findLast(l.path, "/") + 1);
            
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

    // println("Intermediate file data: <fileData>");

    // Now, for each file, get total lines and calculate clonePercentage
    for (str filePath <- domain(fileData)) {
        loc fileLocation = [l | CloneClassWithId cls <- cloneClassesWithIds, loc l <- cls.locations, endsWith(l.path, filePath)][0];
        
        str fullPath = fileLocation.path;

        int projectIndex = findLast(fullPath, projectName);
        str relativePath = substring(fullPath, projectIndex + size(projectName) + 1);
        str relativePathWithProjectName = projectName + "/" + substring(fullPath, projectIndex + size(projectName) + 1);
        loc fullFileLocation = projectLocation + relativePath;

        // println("Full file location: <fullFileLocation>");

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

// // Detect Clones by traversing ASTs and extract clone data
// public map[str, FileCloneData] detectCloneData(loc projectLocation) {
//     println("Starting clone detection using gathered subtrees.");
    
//     list[CloneClass] cloneClasses = detectClones(projectLocation);
//     println("Detected <size(cloneClasses)> clone classes.");
    
//     // Assign unique IDs to clone classes
//     list[CloneClassWithId] cloneClassesWithIds = assignCloneIds(cloneClasses);
//     println("Assigned IDs to <size(cloneClassesWithIds)> clone classes.");

//     // Extract per-file clone data
//     map[str, FileCloneData] fileCloneData = extractFileCloneData(cloneClassesWithIds, projectLocation);
    
//     println("Detected clone data for <size(fileCloneData)> files.");
//     for (str filePath <- domain(fileCloneData)) {
//         tuple[int clonedLines, int totalLines, int clonePercentage, list[str] cloneIds] = fileCloneData[filePath];
//         println("File: <filePath>");
//         println("  Cloned Lines: <clonedLines>");
//         println("  Total Lines: <totalLines>");
//         println("  Clone Percentage: <clonePercentage>%");
//         println("  Clone IDs: <cloneIds>");
//     }
    
//     return fileCloneData;
// }
