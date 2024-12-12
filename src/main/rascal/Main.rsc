module Main

import lang::java::m3::Core;
import lang::java::m3::AST;
import IO;
import List;
import CloneDetection;
import Statistics;
import JSONExport;

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
    
    // Export results to JSON files
    exportJSON(cloneClasses, stats);
    
    return 0;
}