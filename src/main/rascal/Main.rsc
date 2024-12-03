module Main

import lang::java::m3::Core;
import lang::java::m3::AST;
import IO;
import List;
import Set;
import String;
import Map;
import Location;
import BasicMetricsCalculation;
import CloneDetection;

// Define project location based on the project path
int main(loc projectLocation = |home:///Documents/se/smallsql0.21_src|) {

    if (!exists(projectLocation)) {
        println("Error: Project path does not exist: <projectLocation>");
        return 1;
    }
    list[Declaration] asts = getASTs(projectLocation);
    println("Number of ASTs: <size(asts)>");

    // Detect type 1 clones using suffix trees
    list[CloneResult] type1Clones = detectClones(asts);
    println("Type 1 Clones Detected: <size(type1Clones)>");
    for (CloneResult clone <- type1Clones) {
        println("Clone between: <clone[0]> [lines <clone[1]>] and <clone[2]> [lines <clone[3]>]");
    }

    return 0;
}
