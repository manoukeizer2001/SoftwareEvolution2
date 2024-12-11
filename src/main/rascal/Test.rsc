// module Main

// import lang::java::m3::Core;
// import lang::java::m3::AST;
// import IO;
// import List;
// import Set;
// import String;
// import Map;
// import Location;
// import Node;
// import BasicMetricsCalculation;
// import CloneDetection;

// // Define project location based on the project path
// // smallsql0.21_src
// // hsqldb-2.3.1
// // dummy_project
// int main(loc projectLocation = |home:///Documents/UVA_SE/SE/SoftwareEvolution2/dummy_project|) {

//     if (!exists(projectLocation)) {
//         println("Error: Project path does not exist: <projectLocation>");
//         return 1;
//     }
    
//     println("Starting analysis of project at: <projectLocation>");
    
//     list[Declaration] asts = getASTs(projectLocation);
//     println("Number of ASTs: <size(asts)>");
  
//     list[CloneResult] type1Clones = detectClones(asts);
//     println("Type 1 Clones Detected: <size(type1Clones)>");
    

//     return 0;
// }
module Test

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
int main_test(loc projectLocation = |home:///Documents/UVA_SE/SE/SoftwareEvolution2/dummy_project|) {

    if (!exists(projectLocation)) {
        println("Error: Project path does not exist: <projectLocation>");
        return 1;
    }
    
    println("Starting analysis of project at: <projectLocation>");
    
    list[Declaration] asts = getASTs(projectLocation);
    println("Number of ASTs: <size(asts)>");

     // Method 3: Serialize AST and print node locations
    // println("--- Running serializeAst ---");
    for (Declaration ast <- asts) {
        serializeAst(ast);
        println("------");
        println("------");
        println("------");
        println("------");
        println("------");
        println("------");
        println("------");

        serializeAst2(ast);
    }

   
    return 0;
}

SerializedNode serializeAst(node ast) {
    list[SerializedNode] result = [];
    
    visit(ast) {
        case node n: {
            if (n@src?) {
                println("Node <getName(n)> has source location: <n@src>");
                result += serialNode(getName(n), 1, []);
            }
        }
    }
    
 
    
    return serialNode("root", 0, []);
}

// Method 3: Serialize AST
SerializedNode serializeAst2(node ast) {
    list[SerializedNode] result = [];
    
    // Collect all nodes with source locations
    visit(ast) {
        case node n: {
            if (n@src?) {
                println("Node <getName(n)> has source location: <n@src>");
                int subtreeSize = 0;
                
                result += serialNode(getName(n), subtreeSize, []);
            } 
            else {
                println("(serializeAst2) Node <getName(n)> does not have a source location.");
            }
        }
    }
    
   
    return serialNode("root", 0, []);
}

// Node representation with size information
data SerializedNode = serialNode(str nodeType, int subtreeSize, list[SerializedNode] children);