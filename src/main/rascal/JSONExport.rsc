module JSONExport

import IO;
import String;
import List;
import Map;
import CloneDetection;
import Statistics;
import BarChartData;
import lang::java::m3::AST;
import TreeMapData;
import CloneClassData;

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

public list[str] createBarChartEntries(map[int, int] frequencies) {
    list[str] entries = [];
    
    // Convert the map to a list of tuples and sort it
    list[tuple[int,int]] sortedFreqs = [<k, frequencies[k]> | k <- domain(frequencies)];
    sortedFreqs = sort(sortedFreqs, bool(tuple[int,int] a, tuple[int,int] b) { 
        return a[0] < b[0]; 
    });
    
    for (<lineCount, freq> <- sortedFreqs) {
        str entry = "{\"lineCount\": <lineCount>, \"frequency\": <freq>}";
        entries += entry;
    }
    
    return entries;
}

private list[str] createTreeMapEntries(map[str, FileCloneData] treeMapData) {
    list[str] treeMapEntries = [];
    for (str filePath <- domain(treeMapData)) {
        FileCloneData clonedata = treeMapData[filePath];
        
        // Extract the filename from the path
        str fileName = last(split("/", filePath));
        
        // Format clone groups for display
        str cloneClasses = (size(clonedata.cloneIds) > 0) ? 
            intercalate(", ", clonedata.cloneIds) : "None";
        
        // Format clone percentage to ensure proper JSON number format
        str formattedPercentage = "<clonedata.clonePercentage>.0";
        if (endsWith(formattedPercentage, ".0.0")) {
            formattedPercentage = substring(formattedPercentage, 0, size(formattedPercentage) - 2);
        }
        
        str entry = "{
            '  \"name\": \"<fileName>\",
            '  \"fullPath\": \"<filePath>\",
            '  \"size\": <clonedata.totalLines>,
            '  \"clonedLines\": <clonedata.clonedLines>,
            '  \"totalLines\": <clonedata.totalLines>,
            '  \"clonePercentage\": <formattedPercentage>,
            '  \"cloneClasses\": \"<cloneClasses>\"
            '}";
        treeMapEntries += entry;
    }
    println("Done creating tree map entries");
    return treeMapEntries;
}

private list[str] createCloneClassEntries(list[CloneClassInfo] cloneClassData) {
    list[str] cloneClassEntries = [];
    
    for (CloneClassInfo cloneClass <- cloneClassData) {
        list[str] fileEntries = [];
        for (<str path, int startLine, int endLine> <- cloneClass.files) {
            str fileEntry = "{
                '    \"path\": \"<path>\",
                '    \"startLine\": <startLine>,
                '    \"endLine\": <endLine>
                '}";
            fileEntries += fileEntry;
        }
        str entry = "{
            '  \"cloneID\": \"<cloneClass.cloneID>\",
            '  \"files\": [<intercalate(",", fileEntries)>]
            '}";
        cloneClassEntries += entry;
    }
    
    return cloneClassEntries;
}

public void exportJSON(list[CloneClassWithId] cloneClassesWithIds, CloneStats stats, map[str, FileCloneData] treeMapData, list[CloneClassInfo] cloneClassData) {
    loc visualizationDir = |home:///Documents/UVA_SE/SE/SoftwareEvolution2/visualization|;
    ensureDirectoryExists(visualizationDir);
    
    // Stats.json (unchanged)
    str statsJSON = "{
        '  \"duplicatedLinesPercentage\": <stats.duplicatedLinesPercentage>,
        '  \"numberOfClones\": <stats.numberOfClones>,
        '  \"numberOfCloneClasses\": <stats.numberOfCloneClasses>,
        '  \"biggestCloneSize\": <stats.biggestCloneSize>,
        '  \"biggestCloneClassSize\": <stats.biggestCloneClassSize>
        '}";
    writeJSONFile(visualizationDir + "/stats.json", statsJSON);
    
    // barChartData.json
    println("Debug: Calculating bar chart frequencies");
    map[int, int] frequencies = calculateCloneSizeFrequencies(cloneClassesWithIds);
    
    println("Debug: Creating entries list");
    list[str] entries = createBarChartEntries(frequencies);
    
    str barChartJSON = "{\"cloneSizes\": [" + intercalate(",", entries) + "]}";
    writeJSONFile(visualizationDir + "/barChartData.json", barChartJSON);
    
    // treeMapData.json
    println("Debug: Creating tree map entries");
    list[str] treeMapEntries = createTreeMapEntries(treeMapData);

    str treeMapJSON = "{\"files\": [" + intercalate(",", treeMapEntries) + "]}";
    writeJSONFile(visualizationDir + "/treeMapData.json", treeMapJSON);
    
    // cloneClassData.json
    println("Debug: Creating clone class entries");
    list[str] cloneClassEntries = createCloneClassEntries(cloneClassData);

    str cloneClassJSON = "{\"cloneClasses\": [" + intercalate(",", cloneClassEntries) + "]}";
    writeJSONFile(visualizationDir + "/cloneClassData.json", cloneClassJSON);
}
