module JSONExport

import IO;
import String;
import List;
import Map;
import CloneDetection;
import Statistics;
import BarChartData;
import lang::java::m3::AST;
import DataExtraction;
import CloneGroupsExport;

// Helper function to ensure directory exists
void ensureDirectoryExists(loc dir) {
    if (!exists(dir)) {
        mkDirectory(dir);
    }
}

// Helper function to write JSON file
void writeJSONFile(loc file, str content) {
    // Ensure parent directory exists
    ensureDirectoryExists(file.parent);
    
    // Write file (will create or overwrite)
    writeFile(file, content);
}

// Helper function to get a descriptive name for a clone pattern
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

public void exportJSON(list[CloneClass] cloneClasses, CloneStats stats, map[str, FileCloneData] fileCloneData) {
    loc visualizationDir = |home:///Documents/UVA_SE/SE/SoftwareEvolution2/visualization/test|;
    ensureDirectoryExists(visualizationDir);
    
    // First, create clone IDs that match the treemap format
    list[CloneClassWithId] cloneClassesWithIds = assignCloneIds(cloneClasses, "clone");
    
    // Stats.json (unchanged)
    str statsJSON = "{
        '  \"duplicatedLinesPercentage\": <stats.duplicatedLinesPercentage>,
        '  \"numberOfClones\": <stats.numberOfClones>,
        '  \"numberOfCloneClasses\": <stats.numberOfCloneClasses>,
        '  \"biggestCloneSize\": <stats.biggestCloneSize>,
        '  \"biggestCloneClassSize\": <stats.biggestCloneClassSize>
        '}";
    writeJSONFile(visualizationDir + "/stats.json", statsJSON);
    
    // BarChartData.json
    println("Debug: About to calculate frequencies");
    map[int, int] frequencies = calculateCloneSizeFrequencies(cloneClasses);
    println("Debug: Got frequencies: <frequencies>");
    
    println("Debug: Creating entries list");
    list[str] entries = [];
    
    // Convert the map to a list of tuples and sort it
    list[tuple[int,int]] sortedFreqs = [<k, frequencies[k]> | k <- domain(frequencies)];
    sortedFreqs = sort(sortedFreqs, bool(tuple[int,int] a, tuple[int,int] b) { 
        return a[0] < b[0]; 
    });
    
    println("Debug: Processing sorted frequencies");
    for (<lineCount, freq> <- sortedFreqs) {
        println("Debug: Processing lineCount <lineCount> with frequency <freq>");
        str lineCountStr = "<lineCount>";
        str freqStr = "<freq>";
        str entry = "{\"lineCount\": " + lineCountStr + ", \"frequency\": " + freqStr + "}";
        println("Debug: Created entry: <entry>");
        entries += entry;
    }
    
    str barChartJSON = "{\"cloneSizes\": [" + intercalate(",", entries) + "]}";
    writeJSONFile(visualizationDir + "/barChartData.json", barChartJSON);
    
    // TreemapData.json
    list[str] treeMapEntries = [];
    for (str filePath <- domain(fileCloneData)) {
        FileCloneData clonedata = fileCloneData[filePath];
        str entry = "{
            '  \"name\": \"<filePath>\",
            '  \"clonedLines\": <clonedata.clonedLines>,
            '  \"totalLines\": <clonedata.totalLines>,
            '  \"clonePercentage\": <clonedata.clonePercentage>,
            '  \"cloneIds\": [\"<intercalate("\",\"", clonedata.cloneIds)>\"]
            '}";
        treeMapEntries += entry;
    }
    
    str treeMapJSON = "{\"files\": [" + intercalate(",", treeMapEntries) + "]}";
    writeJSONFile(visualizationDir + "/treemapData.json", treeMapJSON);
    
    // Clone Groups export
    list[str] groupEntries = [];
    int cloneId = 1;  // Simple numeric ID
    
    for (CloneClassWithId cloneClass <- cloneClassesWithIds) {
        list[str] fileEntries = [];
        
        for (loc location <- cloneClass.locations) {
            // Extract only the file path part after "smallsql0.21_src/src/"
            // This should not be hardcoded
            str relativePath = location.path;
            if (/.*?smallsql0\.21_src\/src\/(.*)/ := relativePath) {
                relativePath = "smallsql0.21_src/src/<relativePath[1]>";
            }
            
            // Format file entry with proper indentation
            str fileEntry = "{
                '                    \"path\": \"<relativePath>\",
                '                    \"startLine\": <location.begin.line>,
                '                    \"endLine\": <location.end.line>
                '                }";
            fileEntries += fileEntry;
        }
        
        // Create descriptive name based on the pattern
        str name = "Clone Pattern <cloneId>";
        
        // Format group entry with proper indentation
        str groupEntry = "\"<cloneId>\": {
            '            \"name\": \"<name>\",
            '            \"files\": [
            '                <intercalate(",\n                ", fileEntries)>
            '            ]
            '        }";
        
        groupEntries += groupEntry;
        cloneId += 1;
    }
    
    // Format the final JSON with proper indentation
    str cloneGroupsJSON = "{
        '    \"cloneGroups\": {
        '        <intercalate(",\n        ", groupEntries)>
        '    }
        '}";
    
    writeJSONFile(visualizationDir + "/cloneGroups.json", cloneGroupsJSON);
}

public void exportAll(loc projectLoc) {
    // Get ASTs and detect clones
    list[Declaration] asts = getASTs(projectLoc);
    list[CloneClass] cloneClasses = detectClones(asts);
    
    // Export all visualizations
    exportStats(cloneClasses, projectLoc);
    exportTreemapData(cloneClasses, projectLoc);
    exportBarChartData(cloneClasses, projectLoc);
    exportCloneGroups(cloneClasses, projectLoc);
}