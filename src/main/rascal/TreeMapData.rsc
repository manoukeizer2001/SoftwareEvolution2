module TreeMapData

import IO;
import List;
import Map;
import Location;
import Node;
import String;
import Util;
import DataTypes;

// Helper function to find all Java files in a directory
private list[loc] findJavaFiles(loc dir) {
    list[loc] javaFiles = [];
    for (loc entry <- dir.ls) {
        if (isDirectory(entry)) {
            javaFiles += findJavaFiles(entry);
        } else if (entry.extension == "java") {
            javaFiles += entry;
        }
    }
    return javaFiles;
}

// Calculate the number of lines covered by a loc
public int getLineCoverage(loc l) {
    return l.end.line - l.begin.line + 1;
}

// Extract per-file clone data
public map[str, FileCloneData] extractTreeMapData(list[CloneClassWithId] cloneClassesWithIds, loc projectLocation) {
    map[str, FileCloneData] fileData = ();
    
    // First, initialize all Java files with zero clones
    for (loc file <- findJavaFiles(projectLocation)) {
        str filePath = getRelativePath(file, projectLocation);
        filePath = replaceAll(filePath, "\\", "/");  // Normalize path
        list[str] lines = readFileLines(file);
        fileData[filePath] = <0, size(lines), 0, []>;
    }

    // Process clone classes
    for (CloneClassWithId cls <- cloneClassesWithIds) {
        str cloneId = cls.id;
        str pattern = cls.pattern;
        list[loc] locations = cls.locations;

        for (loc l <- locations) {
            str filePath = getRelativePath(l, projectLocation);
            filePath = replaceAll(filePath, "\\", "/");  // Normalize path
            
            if (filePath notin fileData) {
                println("Warning: File path not found in fileData: <filePath>");
                continue;
            }
            
            int clonedLines = getLineCoverage(l);
            FileCloneData currentData = fileData[filePath];
            
            fileData[filePath] = <
                currentData.clonedLines + clonedLines,
                currentData.totalLines,
                currentData.clonePercentage,  // Will calculate percentages later
                (cloneId notin currentData.cloneIds) ? currentData.cloneIds + [cloneId] : currentData.cloneIds
            >;
        }
    }

    // Calculate clone percentages for all files
    for (str filePath <- domain(fileData)) {
        FileCloneData currentData = fileData[filePath];
        int percentage = 0;
        
        if (currentData.totalLines > 0) {
            percentage = (currentData.clonedLines * 100) / currentData.totalLines;
        }
        
        fileData[filePath] = <
            currentData.clonedLines,
            currentData.totalLines,
            percentage,
            currentData.cloneIds
        >;
    }

    return fileData;
}

