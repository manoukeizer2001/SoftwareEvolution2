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

public void exportJSON(list[CloneClass] cloneClasses, CloneStats stats, map[str, FileCloneData] fileCloneData) {
    loc visualizationDir = |home:///Documents/UVA_SE/SE/SoftwareEvolution2/visualization/test|;
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
        // Convert numbers to strings more explicitly
        str lineCountStr = "<lineCount>";
        str freqStr = "<freq>";
        str entry = "{\"lineCount\": " + lineCountStr + ", \"frequency\": " + freqStr + "}";
        println("Debug: Created entry: <entry>");
        entries += entry;
    }
    
    println("Debug: Creating final JSON string");
    str barChartJSON = "{\"cloneSizes\": [" + intercalate(",", entries) + "]}";
    println("Debug: Final JSON: <barChartJSON>");
    writeJSONFile(visualizationDir + "/barChartData.json", barChartJSON);
    
    // Add TreemapData.json export
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
}