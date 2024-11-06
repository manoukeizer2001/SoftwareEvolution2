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
    loc projectLocation = |home:///Documents/se/smallsql0.21_src|;
    list[Declaration] asts = getASTs(projectLocation);
    
    int volume = calculateVolumeWithoutComments(asts);
    tuple[int, int, int, int, int, int, int, int] unit_sizes = calculateUnitSizes(asts);
    
    println("Total lines of code excluding comments and empty lines: <volume>");
    println("Unit counts [low, moderate, high, very high]: \<<unit_sizes[0]>, <unit_sizes[1]>, <unit_sizes[2]>, <unit_sizes[3]>\>");
    println("Lines per category [low, moderate, high, very high]: \<<unit_sizes[4]>, <unit_sizes[5]>, <unit_sizes[6]>, <unit_sizes[7]>\>");
    return testArgument;
}

list[Declaration] getASTs(loc projectLocation) {
    M3 model = createM3FromMavenProject(projectLocation);
    list[Declaration] asts = [createAstFromFile(f, true)
        | f <- files(model.containment), isCompilationUnit(f)];
    return asts;
}

int calculateVolumeWithoutComments(list[Declaration] asts) {
    return (0 | it + size(cleanCode(readFileLines(types[0].src))) | 
        /\compilationUnit(_, list[Declaration] types) := asts) +
        (0 | it + size(cleanCode(readFileLines(types[0].src))) | 
        /\compilationUnit(_, _, list[Declaration] types) := asts);
}

tuple[int, int, int, int, int, int, int, int] calculateUnitSizes(list[Declaration] asts) {
    // Risk categories: [count_low, count_moderate, count_high, count_veryHigh, 
    //                  lines_low, lines_moderate, lines_high, lines_veryHigh]
    int count_low = 0, count_moderate = 0, count_high = 0, count_veryHigh = 0;
    int lines_low = 0, lines_moderate = 0, lines_high = 0, lines_veryHigh = 0;
    
    visit(asts) {
        case m:\method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions, Statement impl): {
            loc methodLoc = m@src;
            int methodSize = countMethodLines(methodLoc);
            if (methodSize <= 15) { count_low += 1; lines_low += methodSize; }
            else if (methodSize <= 30) { count_moderate += 1; lines_moderate += methodSize; }
            else if (methodSize <= 60) { count_high += 1; lines_high += methodSize; }
            else { count_veryHigh += 1; lines_veryHigh += methodSize; }
        }
        case m:\method(Type \return, str name, list[Declaration] parameters, list[Expression] exceptions): {
            loc methodLoc = m@src;
            int methodSize = countMethodLines(methodLoc);
            if (methodSize <= 15) { count_low += 1; lines_low += methodSize; }
            else if (methodSize <= 30) { count_moderate += 1; lines_moderate += methodSize; }
            else if (methodSize <= 60) { count_high += 1; lines_high += methodSize; }
            else { count_veryHigh += 1; lines_veryHigh += methodSize; }
        }
        case c:\constructor(_, _, _, Statement impl): {
            loc constructorLoc = c@src;
            int constructorSize = countMethodLines(constructorLoc);
            if (constructorSize <= 15) { count_low += 1; lines_low += constructorSize; }
            else if (constructorSize <= 30) { count_moderate += 1; lines_moderate += constructorSize; }
            else if (constructorSize <= 60) { count_high += 1; lines_high += constructorSize; }
            else { count_veryHigh += 1; lines_veryHigh += constructorSize; }
        }
    }
    
    return <count_low, count_moderate, count_high, count_veryHigh,
            lines_low, lines_moderate, lines_high, lines_veryHigh>;
}

int countMethodLines(loc methodLocation) {
    return size(cleanCode(readFileLines(methodLocation)));
}

tuple[real, real, real, real] calculateComplexityDistribution(tuple[int, int, int, int, int, int, int, int] unit_sizes, int totalLines) {
    // Extract lines per category from the tuple
    int lines_low = unit_sizes[4];
    int lines_moderate = unit_sizes[5];
    int lines_high = unit_sizes[6];
    int lines_veryHigh = unit_sizes[7];
    
    // Calculate percentages (handle division by zero)
    real percent_low = totalLines > 0 ? (lines_low * 100.0) / totalLines : 0.0;
    real percent_moderate = totalLines > 0 ? (lines_moderate * 100.0) / totalLines : 0.0;
    real percent_high = totalLines > 0 ? (lines_high * 100.0) / totalLines : 0.0;
    real percent_veryHigh = totalLines > 0 ? (lines_veryHigh * 100.0) / totalLines : 0.0;
    
    return <percent_low, percent_moderate, percent_high, percent_veryHigh>;
}

list[str] cleanCode(list[str] lines) {
    list[str] cleanedLines = [];
    bool inMultiLineComment = false;
    
    for (str line <- lines) {
        str trimmedLine = trim(line);
        
        // Skip empty lines
        if (trimmedLine == "") continue;
        
        // Handle multi-line comments
        if (startsWith(trimmedLine, "/*")) {
            inMultiLineComment = true;
            continue;
        }
        if (endsWith(trimmedLine, "*/")) {
            inMultiLineComment = false;
            continue;
        }
        if (inMultiLineComment) continue;
        
        // Skip single-line comments
        if (startsWith(trimmedLine, "//")) continue;
        
        cleanedLines += trimmedLine;
    }
    
    return cleanedLines;
}