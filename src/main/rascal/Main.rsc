module Main

import lang::java::m3::Core;
import lang::java::m3::AST;
import IO;
import List;
import CloneDetection;
import Statistics;
import CloneClassData;
import TreeMapData;
import BarChartData;
import JSONExport;
import DataTypes;

// smallsql0.21_src
// hsqldb-2.3.1

/*
For smallsql0.21_src in config.json:
{
    "sourceDirectory": "smallsql0.21_src/src",
    "port": 3000
} 

For hsqldb-2.3.1 in config.json:
{
    "sourceDirectory": "hsqldb-2.3.1/hsqldb",
    "port": 3000
} 
*/

/*
Main() arguments:
1. projectLocation: location of the project
2. cloneType: type of clone to detect (1 or 2)
3. calculateVolume: whether to calculate volume statistics
4. projectName: name of the project (in case we don't want to calculate volume statistics, because it takes too long)
If calculateVolume is false, placeholder values will be used for volume statistics
for smallsql0.21_src, it's 24501
for hsqldb-2.3.1, it's 175647
for other projects, it's 50000
*/

int main(loc projectLocation = |home:///Documents/UVA_SE/SE/SoftwareEvolution2/hsqldb-2.3.1|, int cloneType = 1, bool calculateVolume = false, str projectName = "hsqldb-2.3.1") {
    if (!exists(projectLocation)) {
        println("Error: Project path does not exist: <projectLocation>");
        return 1;
    }

    println("Starting analysis of project at: <projectLocation>");
    
    list[Declaration] asts = getASTs(projectLocation);
    println("Number of ASTs: <size(asts)>");
  
    // Detect clones
    list[CloneClass] cloneClasses = detectClones(asts, cloneType);
    
    // Calculate statistics
    println("Calculating statistics");
    CloneStats stats = calculateStatistics(cloneClasses, asts, calculateVolume, projectName);
    
    // Add treemap data extraction
    println("Assigning clone IDs");
    str cloneIDprefix = "type<cloneType>";
    // println("Clone ID prefix: <cloneIDprefix>");
    list[CloneClassWithId] cloneClassesWithIds = assignCloneIds(cloneClasses, cloneIDprefix);

    // print type1-clone2 (the second clone class of type1)
    // for (cloneClass <- cloneClassesWithIds) {
    //     if (cloneClass.id == "type1-clone2") {
    //         println("Content of type1-clone2:");
    //         println("Pattern: <cloneClass.pattern>");
    //         for (location <- cloneClass.locations) {
    //             println("Location: <location>");
    //         }
    //     }
    // }

    // Add file clone data extraction
    println("Extracting treemap data");
    map[str, FileCloneData] treeMapData = extractTreeMapData(cloneClassesWithIds, projectLocation);
    
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

    // Extract clone class data
    println("Extracting clone class data");
    list[CloneClassInfo] cloneClassData = extractCloneClassData(cloneClassesWithIds, projectLocation);
    
    // Print the clone class data
    // for (CloneClassInfo info <- cloneClassData) {
    //     str cloneID = info.cloneID;
    //     list[tuple[str path, int startLine, int endLine]] files = info.files;
        
    //     println("Clone ID: <cloneID>");
    //     for (tuple[str path, int startLine, int endLine] file <- files) {
    //         println("  Path: <file.path>, Start Line: <file.startLine>, End Line: <file.endLine>");
    //     }
    // }
    
    // Export results to JSON files
    println("Exporting results to JSON files");
    exportJSON(cloneClassesWithIds, stats, treeMapData, cloneClassData);
    
    return 0;
}