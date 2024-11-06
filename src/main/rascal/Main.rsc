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
    loc projectLocation = |home:///Documents/UVA_SE/SE/series0/smallsql0.21_src|;
    list[Declaration] asts = getASTs(projectLocation);
    
    int volume = calculateVolume(asts);
    map[str, int] unitSizes = calculateUnitSize(asts);
    
    println("Total lines of code (volume): <volume>");
    println("Unit sizes per method:");
    for (methodName <- domain(unitSizes)) {
        println("  - <methodName>: <unitSizes[methodName]> lines");
    }
    tuple[real percentage, int totalLines, int duplicateLines] duplicationResult = calculateDuplication(asts);
    println("Duplication percentage: <precision(duplicationResult.percentage, 2)>%");
    println("Total lines analyzed: <duplicationResult.totalLines>");
    println("Duplicate lines found: <duplicationResult.duplicateLines>");
    
    return testArgument;
}

list[Declaration] getASTs(loc projectLocation) {
    M3 model = createM3FromMavenProject(projectLocation);
    list[Declaration] asts = [createAstFromFile(f, true)
        | f <- files(model.containment), isCompilationUnit(f)];
    return asts;
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

str removeComments(str source) {
    // Remove multi-line comments
    source = visit(source) {
        case /\/\*.*?\*\//s => ""
    }
    // Remove single-line comments
    source = visit(source) {
        case /\/\/.*$/ => ""
    }
    return source;
}

tuple[real percentage, int totalLines, int duplicateLines] calculateDuplication(list[Declaration] asts) {
    /*
    First pass: 
        - Sliding window algorithm
        - Map all 6-line blocks to their locations using a map
    Second pass:
        - Sort blocks by their first occurrence
        - Process blocks in order, marking duplicated lines
        - Use a set to ensure each line is only counted once
        This should handle overlapping duplicates (more accurately).
        For example, if lines 1-10 are duplicated somewhere else, 
        all those lines will be marked as duplicates only once, 
        even though they're part of multiple 6-line blocks.
    */
    // Get all source lines from ASTs, trimmed of leading whitespace
    list[str] allLines = [];
    visit(asts) {
        case \method(_, _, _, _, impl): {
            str methodSource = readFile(impl.src);
            methodSource = removeComments(methodSource);
            allLines += [trim(l) | l <- split("\n", methodSource), trim(l) != ""];
        }
    }
    
    // First pass: Store blocks and their locations
    map[str, list[int]] blockLocations = (); 
    int totalLines = size(allLines);
    
    // Map all 6-line blocks
    for (i <- [0..totalLines-5]) {
        str block = intercalate("\n", allLines[i..i+6]);
        blockLocations[block] = (block in blockLocations) ? blockLocations[block] + [i] : [i];
    }
    
    // Second pass: Track duplicated lines, handling overlaps
    set[int] duplicatedLineIndices = {};
    
    // Sort blocks by their first occurrence to handle overlaps properly
    list[tuple[str block, list[int] locations]] sortedBlocks = 
        sort([<block, locs> | block <- blockLocations, list[int] locs := blockLocations[block], size(locs) > 1],
             bool(tuple[str, list[int]] a, tuple[str, list[int]] b) { 
                 return min(a[1]) < min(b[1]); 
             });
    
    // Process blocks in order
    for (<block, locations> <- sortedBlocks) {
        for (startIndex <- locations) {
            // Only add these lines if they're not already marked as duplicates
            set[int] newLines = {startIndex + k | k <- [0..6]};
            duplicatedLineIndices += newLines;
        }
    }
    
    // Calculate duplication percentage using unique duplicated lines
    int duplicateLines = size(duplicatedLineIndices);
    real percentage = totalLines > 0 ? (toReal(duplicateLines) / totalLines) * 100 : 0.0;
    return <percentage, totalLines, duplicateLines>;
}