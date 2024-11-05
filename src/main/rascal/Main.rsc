module Main

import lang::java::m3::Core;
import lang::java::m3::AST;
import IO;
import List;
import Set;
import String;
import util::Math;
import Map;
import Location;


int main(int testArgument=0) {
    // smallsql0.21_src
    // hsqldb-2.3.1
    loc projectLocation = |home:///Documents/se/smallsql0.21_src|;
    list[Declaration] asts = getASTs(projectLocation);
    
    int volume = calculateVolume(asts);
    map[str, int] unitSizes = calculateUnitSize(asts);
    
    println("Total lines of code (volume): <volume>");
    println("Unit sizes per method:");
    for (methodName <- domain(unitSizes)) {
        println("  - <methodName>: <unitSizes[methodName]> lines");
    }
    
    return testArgument;
}

list[Declaration] getASTs(loc projectLocation) {
    M3 model = createM3FromMavenProject(projectLocation);
    list[Declaration] asts = [createAstFromFile(f, true)
        | f <- files(model.containment), isCompilationUnit(f)];
    return asts;
}

int getNumberOfInterfaces(list[Declaration] asts){
    int interfaces = 0;
    visit(asts){
        case \interface(_, _, _, _): interfaces += 1;
    }
    return interfaces;
}

int getNumberOfInterfaces(list[Declaration] asts){
    int interfaces = 0;
    visit(asts){
        case \interface(_, _, _, _): interfaces += 1;
    }
    return interfaces;
}  

int getNumberOfForLoops(list[Declaration] asts){
    int forLoops = 0;
    visit(asts) {
        case \for(_, _, _, _): forLoops += 1;
    }
    return forLoops;
}

tuple[int, list[str]] mostOccurringVariables(list[Declaration] asts) {
    map[str, int] variableCountMap = ();

    visit(asts) {
        case \variable(varName, _):
            variableCountMap[varName] = (varName in variableCountMap) ? variableCountMap[varName] + 1 : 1;
        case \variable(varName, _, _):
            variableCountMap[varName] = (varName in variableCountMap) ? variableCountMap[varName] + 1 : 1;
    }

    // Extract counts from the map by iterating over the keys using domain()
    list[int] counts = [variableCountMap[name] | str name <- domain(variableCountMap)];

    // Find the maximum count if counts is not empty
    int maxCount = counts != [] ? max(counts) : 0;

    // Find the variable names that have the maximum count
    list[str] mostFrequent = [name | str name <- domain(variableCountMap), variableCountMap[name] == maxCount];

    // Return the maximum count and the list of most occurring variables
    return <maxCount, mostFrequent>;
}

tuple[int, list[str]] mostOccurringNumber(list[Declaration] asts) {
    map[str, int] numberLiteralCountMap = ();
    
    // Visit the ASTs to count number literals
    visit(asts) {
        case \number(str numberValue):
            numberLiteralCountMap[numberValue] = 
                (numberValue in numberLiteralCountMap) ? numberLiteralCountMap[numberValue] + 1 : 1;
    }
    
    // Extract counts by iterating over the map's key-value pairs
    list[int] counts = [numberLiteralCountMap[number] | str number <- domain(numberLiteralCountMap)];
    
    // Find the maximum count if counts is not empty
    int maxCount = counts != [] ? max(counts) : 0;
    
    // Find the number literals that have the maximum count
    list[str] mostFrequent = [number | str number <- domain(numberLiteralCountMap), numberLiteralCountMap[number] == maxCount];
    
    // Return the maximum count and the list of most occurring numbers
    return <maxCount, mostFrequent>;
}

list[loc] findNullReturned(list[Declaration] asts) {
    list[loc] nullReturnLocations = [];
    
    visit(asts) {
        case \return(x: \null()):
            nullReturnLocations += x.src;
    }
    
    return nullReturnLocations;
}

int calculateVolume(list[Declaration] asts) {
    int totalLinesOfCode = 0;
    
    visit(asts) {
        case \compilationUnit(_, list[Declaration] types):
            totalLinesOfCode += (types[0].src.end.line - types[0].src.begin.line) + 1;
        case \compilationUnit(_, _, list[Declaration] types):
            totalLinesOfCode += (types[0].src.end.line - types[0].src.begin.line) + 1;
    }
    
    return totalLinesOfCode;
}

map[str, int] calculateUnitSize(list[Declaration] asts) {
    map[str, int] methodSizes = ();
    
    visit(asts) {
        case \method(_, name, _, _, impl): {
            int linesOfCode = (impl.src.end.line - impl.src.begin.line) + 1;
            methodSizes[name] = linesOfCode;
        }
        case \constructor(name, _, _, impl): {
            int linesOfCode = (impl.src.end.line - impl.src.begin.line) + 1;
            methodSizes[name] = linesOfCode;
        }
    }
    
    return methodSizes;
}
