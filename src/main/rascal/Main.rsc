module Main

import lang::java::m3::Core;
import lang::java::m3::AST;
import IO;
import List;
import Set;
import String;
import Map;
import Location;
import Node;
import BasicMetricsCalculation;
import CloneDetection;
import DataExtraction;

// Define project location based on the project path
// smallsql0.21_src
// hsqldb-2.3.1
// dummy_project
int main(loc projectLocation = |home:///Documents/UVA_SE/SE/SoftwareEvolution2/smallsql0.21_src|) {

    if (!exists(projectLocation)) {
        println("Error: Project path does not exist: <projectLocation>");
        return 1;
    }
    
    println("Starting analysis of project at: <projectLocation>");
    
    list[Declaration] asts = getASTs(projectLocation);
    println("Number of ASTs: <size(asts)>");
  
    // Detect different types of clone classes
    list[CloneClass] type1CloneClasses = detectClones(asts);

    list[CloneClassWithId] type1CloneClassesWithIds = assignCloneIds(type1CloneClasses, "type1");

    // Print clone classes with IDs
    // for (CloneClassWithId cls <- type1CloneClassesWithIds) {
    //     println("Clone Class: <cls.id>");
    // }
    
    // // Step 3: Extract Per-File Clone Data
    map[str, FileCloneData] fileCloneData = extractFileCloneData(type1CloneClassesWithIds, projectLocation);
    println("Extracted clone data for <size(fileCloneData)> files.");

    // print the contents of the fileCloneData of the first 2 files
    // for (str filePath <- domain(fileCloneData)) {
    //     println("File: <filePath>");
    //     println("  Cloned Lines: <fileCloneData[filePath].clonedLines>");
    //     println("  Total Lines: <fileCloneData[filePath].totalLines>");
    //     println("  Clone Percentage: <fileCloneData[filePath].clonePercentage>%");
    //     println("  Clone IDs: <fileCloneData[filePath].cloneIds>");
    // }
    
    return 0;
}

    /*
    // Convert to a JSON-like structure
    map[str, value] jsonFiles = ();
    for (str filePath <- domain(fileCloneData)) {
        tuple[int clonedLines, int totalLines, int clonePercentage, list[str] cloneIds] = fileCloneData[filePath];
        map[str, value] fileInfo = (
            "clonedLines" = clonedLines,
            "totalLines" = totalLines,
            "clonePercentage" = clonePercentage,
            "cloneIds" = cloneIds
        );
        jsonFiles[filePath] = fileInfo;
    }
    
    map[str, value] finalJson = (
        "files" = jsonFiles
    );
    
    // Serialize to JSON string
    str jsonString = toJSON(finalJson);
    
    // Write to a JSON file
    str outputPath = "cloneReport.json"; // Adjust the output path as needed
    writeFile(|file:///cloneReport.json|, jsonString);
    
    println("Clone data exported to cloneReport.json");
    */
    
    // For now, simply print the clone data
    // for (str filePath <- domain(fileCloneData)) {
    //     tuple[int clonedLines, int totalLines, int clonePercentage, list[str] cloneIds] = fileCloneData[filePath];
    //     println("File: <filePath>");
    //     println("  Cloned Lines: <clonedLines>");
    //     println("  Total Lines: <totalLines>");
    //     println("  Clone Percentage: <clonePercentage>%");
    //     println("  Clone IDs: <cloneIds>");
    // }
    