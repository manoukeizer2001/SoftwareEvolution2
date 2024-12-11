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
    
    return 0;
}