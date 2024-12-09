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
int main(loc projectLocation = |home:///Documents/UVA_SE/SE/SoftwareEvolution2/dummy_project|) {

    if (!exists(projectLocation)) {
        println("Error: Project path does not exist: <projectLocation>");
        return 1;
    }
    
    println("Starting analysis of project at: <projectLocation>");
    
    list[Declaration] asts = getASTs(projectLocation);
    println("Number of ASTs: <size(asts)>");
    
    // // Print some info about the first AST
    // if (size(asts) > 0) {
    //     println("First AST type: <getNodeType(asts[0])>");
    //     if (asts[0]@src?) {
    //         println("First AST location: <asts[0]@src>");
    //     }
    // }

  
    list[CloneResult] type1Clones = detectClones(asts);
    println("Type 1 Clones Detected: <size(type1Clones)>");
    
    if (size(type1Clones) > 0) {
        println("\nFirst clone pair details:");
        CloneResult firstClone = type1Clones[0];
        
        if (size(firstClone) >= 3) {
            println("Location 1: <firstClone[0]>");
            println("Location 2: <firstClone[1]>");
            println("Number of nodes: <size(firstClone[2])>");
        } else {
            println("Error: CloneResult does not contain enough elements.");
        }
    }

    return 0;
}

// Helper function to get node type name - simplified version
str getNodeType(node n) = getName(n);