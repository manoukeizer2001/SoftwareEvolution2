module Main

import lang::java::m3::Core;
import lang::java::m3::AST;
import IO;
import List;
import CloneDetection;
import Statistics;
import JSONExport;
import TreeMapData;
import BarChartData;

int main(loc projectLocation = |home:///Documents/UVA_SE/SE/SoftwareEvolution2/smallsql0.21_src|) {
    if (!exists(projectLocation)) {
        println("Error: Project path does not exist: <projectLocation>");
        return 1;
    }
    
    println("Starting analysis of project at: <projectLocation>");
    
    list[Declaration] asts = getASTs(projectLocation);
    println("Number of ASTs: <size(asts)>");
  
    // Detect clones
    list[CloneClass] cloneClasses = detectClones(asts);
    
    // Calculate statistics
    CloneStats stats = calculateStatistics(cloneClasses, asts);
    
    // Add treemap data extraction
    list[CloneClassWithId] cloneClassesWithIds = assignCloneIds(cloneClasses, "type1");

    // Add file clone data extraction
    map[str, FileCloneData] fileCloneData = extractFileCloneData(cloneClassesWithIds, projectLocation);
    
    // Print file clone data in a formatted way
    // println("File Clone Data Summary:");
    // println("=======================");
    // for (str file <- fileCloneData) {
    //     println("\nFile: <file>");
    //     println("  Total Lines: <fileCloneData[file].totalLines>");
    //     println("  Cloned Lines: <fileCloneData[file].clonedLines>");
    //     println("  Clone Coverage: <fileCloneData[file].clonePercentage>%");
    //     println("  Clone Classes: <size(fileCloneData[file].cloneIds)>");
    // }

    // Add bar chart data extraction
    
    // Export results to JSON files
    exportJSON(cloneClasses, stats, fileCloneData);
    
    return 0;
}